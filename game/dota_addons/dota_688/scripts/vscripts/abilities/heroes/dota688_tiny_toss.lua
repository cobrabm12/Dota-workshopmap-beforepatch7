-- Toss (6.88): Tiny apuca cea mai apropiata unitate din 275 (nu pe el, inclusiv inamici imuni la vraji) si o arunca spre tinta (1300);
-- dupa 1.3 s, unitatile din 275 de locul aterizarii iau 75/150/225/300 daune magice (cladirile 33 %; unitatea aruncata +20 % daca e
-- inamica, aliatii nu iau daune). Grow mareste daunele cu 35/50/65% (scepter: 50/65/80%).
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_tossed", "abilities/heroes/dota688_tiny_toss", LUA_MODIFIER_MOTION_BOTH)
dota688_tiny_toss = class({})
function dota688_tiny_toss:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_tiny_toss:Grabbable()
	local caster = self:GetCaster()
	local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("grab_radius"), DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
	local out = {}
	for _, u in ipairs(units) do if u ~= caster and not u:IsInvulnerable() and not u:HasModifier("modifier_dota688_tossed") then table.insert(out, u) end end
	return out
end
function dota688_tiny_toss:CastFilterResultTarget(target)
	if target == self:GetCaster() then return UF_FAIL_CUSTOM end
	if #self:Grabbable() == 0 then return UF_FAIL_CUSTOM end
	return UF_SUCCESS
end
function dota688_tiny_toss:GetCustomCastErrorTarget(target)
	if target == self:GetCaster() then return "#dota_hud_error_cant_cast_on_self" end
	return "#dota688_toss_no_units"
end
function dota688_tiny_toss:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	local cands = self:Grabbable()
	if #cands == 0 then return end
	local unit = cands[1]   -- FIND_CLOSEST: cea mai apropiata
	caster:EmitSound("Ability.TossThrow")
	unit:AddNewModifier(caster, self, "modifier_dota688_tossed", { duration = self:GetSpecialValueFor("duration"), target = target:entindex() })
end
function dota688_tiny_toss:Damage()
	local caster = self:GetCaster()
	local dmg = self:GetSpecialValueFor("toss_damage")
	local grow = caster:FindAbilityByName("dota688_tiny_grow")
	if grow and grow:GetLevel() > 0 then
		local pct = Dota688HasScepter(caster) and grow:GetSpecialValueFor("grow_bonus_damage_pct_scepter") or grow:GetSpecialValueFor("grow_bonus_damage_pct")
		dmg = dmg * (1 + pct / 100)
	end
	return dmg
end
modifier_dota688_tossed = class({})
function modifier_dota688_tossed:IsHidden() return true end
function modifier_dota688_tossed:IsPurgable() return false end
function modifier_dota688_tossed:GetEffectName() return "particles/units/heroes/hero_tiny/tiny_toss_blur.vpcf" end
function modifier_dota688_tossed:OnCreated(kv)
	if not IsServer() then return end
	self.target = EntIndexToHScript(kv.target)
	self.start = self:GetParent():GetAbsOrigin()
	self.t = 0
	self.total = self:GetDuration()
	self.landing = self.target and self.target:GetAbsOrigin() or self.start
	if self:ApplyHorizontalMotionController() == false or self:ApplyVerticalMotionController() == false then self:Destroy() end
end
function modifier_dota688_tossed:UpdateHorizontalMotion(me, dt)
	self.t = math.min(self.total, self.t + dt)
	if self.target and not self.target:IsNull() then self.landing = self.target:GetAbsOrigin() end
	local f = self.t / self.total
	local pos = self.start + (self.landing - self.start) * f
	local ground = GetGroundPosition(pos, me)
	me:SetAbsOrigin(Vector(ground.x, ground.y, ground.z + 400 * 4 * f * (1 - f)))
	if self.t >= self.total then self:Land() end
end
function modifier_dota688_tossed:UpdateVerticalMotion(me, dt) end
function modifier_dota688_tossed:OnHorizontalMotionInterrupted() self:Land() end
function modifier_dota688_tossed:OnVerticalMotionInterrupted() end
function modifier_dota688_tossed:Land()
	if self.landed then return end
	self.landed = true
	local me, a, caster = self:GetParent(), self:GetAbility(), self:GetCaster()
	local pos = GetGroundPosition(me:GetAbsOrigin(), me)
	me:SetAbsOrigin(pos)
	if not a or a:IsNull() or not caster or caster:IsNull() then self:Destroy() return end   -- abilitatea a disparut in zbor
	local dmg = a:Damage()
	EmitSoundOnLocationWithCaster(pos, "Ability.TossImpact", caster)
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_toss_impact.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fx, 0, pos); ParticleManager:ReleaseParticleIndex(fx)
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, a:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if e ~= me then
			ApplyDamage({ victim = e, attacker = caster, damage = e:IsBuilding() and dmg * 0.33 or dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
		end
	end
	if me:GetTeamNumber() ~= caster:GetTeamNumber() and not me:IsMagicImmune() then
		ApplyDamage({ victim = me, attacker = caster, damage = dmg * (1 + a:GetSpecialValueFor("bonus_damage_pct") / 100), damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
	end
	self:Destroy()
end
function modifier_dota688_tossed:OnDestroy()
	if not IsServer() then return end
	local me = self:GetParent()
	me:RemoveHorizontalMotionController(self); me:RemoveVerticalMotionController(self)
	FindClearSpaceForUnit(me, me:GetAbsOrigin(), true)
end
function modifier_dota688_tossed:CheckState() return { [MODIFIER_STATE_STUNNED] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true } end
function modifier_dota688_tossed:DeclareFunctions() return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION } end
function modifier_dota688_tossed:GetOverrideAnimation() return ACT_DOTA_FLAIL end
