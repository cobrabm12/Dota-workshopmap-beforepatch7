-- Midnight Pulse (6.88): zona de raza 550 timp de 11 s; la fiecare secunda inamicii din zona iau 3/3.75/4.5/5.25%
-- din viata MAXIMA ca daune pure (trece prin imunitate). Distruge copacii din zona la cast.
require("dota688/val")
LinkLuaModifier("modifier_dota688_midnight_pulse_thinker", "abilities/heroes/dota688_enigma_midnight_pulse", LUA_MODIFIER_MOTION_NONE)
dota688_enigma_midnight_pulse = class({})
function dota688_enigma_midnight_pulse:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_enigma_midnight_pulse:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	GridNav:DestroyTreesAroundPoint(pos, self:GetSpecialValueFor("radius"), false)
	-- +0.1 s ca sa prinda si a 11-a secunda (tick-urile sunt numarate)
	CreateModifierThinker(caster, self, "modifier_dota688_midnight_pulse_thinker", { duration = self:GetSpecialValueFor("duration") + 0.1 },
		pos, caster:GetTeamNumber(), false)
end

modifier_dota688_midnight_pulse_thinker = class({})
function modifier_dota688_midnight_pulse_thinker:IsHidden() return true end
function modifier_dota688_midnight_pulse_thinker:IsPurgable() return false end
function modifier_dota688_midnight_pulse_thinker:OnCreated()
	if not IsServer() then return end
	local p = self:GetParent()
	self.radius = Dota688Val(self, "radius")
	self.pct = Dota688Val(self, "damage_percent")
	self.ticks = Dota688Val(self, "duration")
	self.done = 0
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_enigma/enigma_midnight_pulse.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.fx, 0, p:GetAbsOrigin())
	ParticleManager:SetParticleControl(self.fx, 1, Vector(self.radius, 0, 0))
	p:EmitSound("Hero_Enigma.Midnight_Pulse")
	self:StartIntervalThink(1.0)
end
function modifier_dota688_midnight_pulse_thinker:OnIntervalThink()
	if self.done >= self.ticks then return end
	self.done = self.done + 1
	local caster, a = self:GetCaster(), self:GetAbility()
	if not caster or caster:IsNull() then return end
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)) do
		ApplyDamage({ victim = e, attacker = caster, damage = e:GetMaxHealth() * self.pct / 100, damage_type = DAMAGE_TYPE_PURE,
			ability = (a and not a:IsNull()) and a or nil })
	end
end
function modifier_dota688_midnight_pulse_thinker:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.fx, false)
	ParticleManager:ReleaseParticleIndex(self.fx)
	self:GetParent():StopSound("Hero_Enigma.Midnight_Pulse")
	UTIL_Remove(self:GetParent())
end
