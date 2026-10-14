-- Black Hole (6.88): channel 4 s; trage inamicii din raza 420; 50/100/150 daune pure/s (dublu in centrul de 200); stun pe durata; trece prin imunitate.
-- Scepter: adauga nivelul curent de Midnight Pulse (daune pure % din HP max pe secunda) in Black Hole.
require("dota688/val")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_enigma_black_hole"
LinkLuaModifier("modifier_dota688_enigma_black_hole_thinker", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_enigma_black_hole_pull", F, LUA_MODIFIER_MOTION_NONE)
dota688_enigma_black_hole = class({})
function dota688_enigma_black_hole:GetAOERadius() return self:GetSpecialValueFor("pull_radius") end
function dota688_enigma_black_hole:OnSpellStart()
	local pos = self:GetCursorPosition()
	self.thinker = CreateModifierThinker(self:GetCaster(), self, "modifier_dota688_enigma_black_hole_thinker", { duration = self:GetChannelTime() }, pos, self:GetCaster():GetTeamNumber(), false)
	self:GetCaster():EmitSound("Hero_Enigma.Black_Hole")
end
function dota688_enigma_black_hole:OnChannelFinish(interrupted)
	self:GetCaster():StopSound("Hero_Enigma.Black_Hole")
	if self.thinker and not self.thinker:IsNull() then
		local m = self.thinker:FindModifierByName("modifier_dota688_enigma_black_hole_thinker")
		if m then m:Destroy() end
	end
end
modifier_dota688_enigma_black_hole_thinker = class({})
function modifier_dota688_enigma_black_hole_thinker:OnCreated()
	if not IsServer() then return end
	local a = self:GetAbility()
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_enigma/enigma_blackhole.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:SetParticleControl(self.fx, 0, self:GetParent():GetAbsOrigin())
	AddFOWViewer(self:GetCaster():GetTeamNumber(), self:GetParent():GetAbsOrigin(), a:GetSpecialValueFor("vision_radius"), a:GetSpecialValueFor("duration"), false)
	-- Scepter: Midnight Pulse in interiorul gaurii negre
	self.pulsePct = 0
	local pulse = self:GetCaster():FindAbilityByName("dota688_enigma_midnight_pulse") or self:GetCaster():FindAbilityByName("enigma_midnight_pulse")
	if pulse and pulse:GetLevel() > 0 and Dota688HasScepter(self:GetCaster()) then
		self.pulse = pulse
		self.pulsePct = pulse:GetSpecialValueFor("damage_percent")
	end
	self:StartIntervalThink(a:GetSpecialValueFor("tick_rate"))
end
function modifier_dota688_enigma_black_hole_thinker:OnIntervalThink()
	local a, caster, center = self:GetAbility(), self:GetCaster(), self:GetParent():GetAbsOrigin()
	local tick = a:GetSpecialValueFor("tick_rate")
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), center, nil, a:GetSpecialValueFor("pull_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)) do
		if not e:HasModifier("modifier_dota688_enigma_black_hole_pull") then
			e:AddNewModifier(caster, a, "modifier_dota688_enigma_black_hole_pull", { duration = self:GetRemainingTime(), x = center.x, y = center.y })
		end
		local d = (e:GetAbsOrigin() - center):Length2D()
		local dmg = (d <= a:GetSpecialValueFor("near_radius")) and (a:GetSpecialValueFor("near_damage") + a:GetSpecialValueFor("far_damage")) or a:GetSpecialValueFor("far_damage")
		ApplyDamage({ victim = e, attacker = caster, damage = dmg * tick, damage_type = DAMAGE_TYPE_PURE, ability = a })
		if self.pulsePct and self.pulsePct > 0 then
			-- Midnight Pulse 6.88 face daune pure
			ApplyDamage({ victim = e, attacker = caster, damage = e:GetMaxHealth() * self.pulsePct / 100 * tick, damage_type = DAMAGE_TYPE_PURE, ability = self.pulse })
		end
	end
end
function modifier_dota688_enigma_black_hole_thinker:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.fx, false)
	-- canalizare intrerupta: victimele scapa imediat
	local caster = self:GetCaster()
	for _, e in ipairs(FindUnitsInRadius(DOTA_TEAM_NOTEAM, self:GetParent():GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)) do
		local m = caster and not caster:IsNull() and e:FindModifierByNameAndCaster("modifier_dota688_enigma_black_hole_pull", caster) or e:FindModifierByName("modifier_dota688_enigma_black_hole_pull")
		if m then m:Destroy() end
	end
	UTIL_Remove(self:GetParent())
end
modifier_dota688_enigma_black_hole_pull = class({})
function modifier_dota688_enigma_black_hole_pull:IsDebuff() return true end
function modifier_dota688_enigma_black_hole_pull:IsPurgable() return false end
function modifier_dota688_enigma_black_hole_pull:IsStunDebuff() return true end
function modifier_dota688_enigma_black_hole_pull:OnCreated(kv)
	if not IsServer() then return end
	self.center = Vector(kv.x, kv.y, self:GetParent():GetAbsOrigin().z)
	self.speed = Dota688Val(self, "pull_speed")
	self:StartIntervalThink(0.03)
end
function modifier_dota688_enigma_black_hole_pull:OnIntervalThink()
	local p = self:GetParent()
	local to = self.center - p:GetAbsOrigin(); to.z = 0
	local d = to:Length2D()
	if d > 10 then
		-- rotatie usoara + tragere spre centru
		local dir = to:Normalized()
		local tangent = Vector(-dir.y, dir.x, 0)
		p:SetAbsOrigin(p:GetAbsOrigin() + dir * math.min(d, self.speed * 0.03) + tangent * 2)
	end
end
function modifier_dota688_enigma_black_hole_pull:OnDestroy()
	if IsServer() then FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), false) end
end
function modifier_dota688_enigma_black_hole_pull:CheckState() return { [MODIFIER_STATE_STUNNED] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true } end
function modifier_dota688_enigma_black_hole_pull:DeclareFunctions() return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION } end
function modifier_dota688_enigma_black_hole_pull:GetOverrideAnimation() return ACT_DOTA_FLAIL end
