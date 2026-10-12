-- Burrowstrike (6.88): Sand King trece pe sub pamant pana la punct (350/450/550/650), stunand 2.17 s si lovind cu 100/160/220/280 daune magice tot ce e pe drum (latime 150).
-- Scepter: raza 700/900/1100/1300, viteza 3000, eroii loviti primesc Caustic Finale.
require("dota688/aghanim")
require("dota688/stun")
LinkLuaModifier("modifier_dota688_burrowstrike", "abilities/heroes/dota688_sandking_burrowstrike", LUA_MODIFIER_MOTION_HORIZONTAL)
dota688_sandking_burrowstrike = class({})
function dota688_sandking_burrowstrike:GetCastRange(location, target)
	if Dota688HasScepter(self:GetCaster()) then return self:GetSpecialValueFor("cast_range_scepter") end
	return self.BaseClass.GetCastRange(self, location, target)
end
function dota688_sandking_burrowstrike:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local pos = target and target:GetAbsOrigin() or self:GetCursorPosition()
	local dir = pos - caster:GetAbsOrigin(); dir.z = 0
	local range = self:GetCastRange(pos, target)
	if dir:Length2D() > range then dir = dir:Normalized() * range end
	if dir:Length2D() < 1 then dir = caster:GetForwardVector() * 50 end
	caster:EmitSound("Ability.SandKing_BurrowStrike")
	caster:AddNewModifier(caster, self, "modifier_dota688_burrowstrike", { dx = dir.x, dy = dir.y })
end
modifier_dota688_burrowstrike = class({})
function modifier_dota688_burrowstrike:IsHidden() return true end
function modifier_dota688_burrowstrike:IsPurgable() return false end
function modifier_dota688_burrowstrike:OnCreated(kv)
	if not IsServer() then return end
	local a, p = self:GetAbility(), self:GetParent()
	self.scepter = Dota688HasScepter(p)
	self.delta = Vector(kv.dx, kv.dy, 0)
	self.dir = self.delta:Normalized()
	self.target = p:GetAbsOrigin() + self.delta
	self.speed = self.scepter and a:GetSpecialValueFor("burrow_speed_scepter") or a:GetSpecialValueFor("burrow_speed")
	self.hit = {}
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_sandking/sandking_burrowstrike.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fx, 0, p:GetAbsOrigin()); ParticleManager:SetParticleControl(fx, 1, self.target)
	ParticleManager:SetParticleControl(fx, 2, Vector(self.speed, 0, 0))
	ParticleManager:ReleaseParticleIndex(fx)
	p:StartGesture(ACT_DOTA_CAST_ABILITY_1)
	if self:ApplyHorizontalMotionController() == false then self:Destroy() end
end
function modifier_dota688_burrowstrike:Strike(u)
	local p, a = self:GetParent(), self:GetAbility()
	self.hit[u:entindex()] = true
	if u:IsMagicImmune() then return end
	ApplyDamage({ victim = u, attacker = p, damage = a:GetAbilityDamage(), damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
	Dota688Stun(u, p, a, a:GetSpecialValueFor("burrow_duration"))
	if self.scepter and u:IsHero() then
		local caustic = p:FindAbilityByName("dota688_sandking_caustic_finale")
		if caustic and caustic:GetLevel() > 0 then
			u:AddNewModifier(p, caustic, "modifier_dota688_sandking_caustic_finale_debuff", { duration = caustic:GetSpecialValueFor("caustic_finale_duration") })
		end
	end
end
function modifier_dota688_burrowstrike:UpdateHorizontalMotion(me, dt)
	local a = self:GetAbility()
	local to = self.target - me:GetAbsOrigin(); to.z = 0
	local d = to:Length2D()
	local step = math.min(d, self.speed * dt)
	me:SetAbsOrigin(me:GetAbsOrigin() + self.dir * step)
	for _, u in ipairs(FindUnitsInRadius(me:GetTeamNumber(), me:GetAbsOrigin(), nil, a:GetSpecialValueFor("burrow_width"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if not self.hit[u:entindex()] then self:Strike(u) end
	end
	if d <= step + 1 then self:Destroy() end
end
function modifier_dota688_burrowstrike:OnHorizontalMotionInterrupted() self:Destroy() end
function modifier_dota688_burrowstrike:OnDestroy()
	if not IsServer() then return end
	local p = self:GetParent()
	p:RemoveHorizontalMotionController(self)
	p:RemoveGesture(ACT_DOTA_CAST_ABILITY_1)
	FindClearSpaceForUnit(p, p:GetAbsOrigin(), false)
end
function modifier_dota688_burrowstrike:CheckState() return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true, [MODIFIER_STATE_INVULNERABLE] = true, [MODIFIER_STATE_NO_HEALTH_BAR] = true } end
