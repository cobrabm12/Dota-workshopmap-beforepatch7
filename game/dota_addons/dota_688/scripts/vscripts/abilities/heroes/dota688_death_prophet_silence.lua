-- Silence (6.88): zona 425, silence 3/4/5/6 s.
LinkLuaModifier("modifier_dota688_death_prophet_silence", "abilities/heroes/dota688_death_prophet_silence", LUA_MODIFIER_MOTION_NONE)
dota688_death_prophet_silence = class({})
function dota688_death_prophet_silence:GetAOERadius() return self:GetSpecialValueFor("radius") end
-- Witchcraft (6.87, nu mai e pe erou in 6.88f): -10/15/20/25 mana si -1/2/3/4 s cooldown la Silence, daca ar exista
local function Witchcraft(self)
	local w = self:GetCaster():FindAbilityByName("dota688_death_prophet_witchcraft")
	if w and w:GetLevel() > 0 then return w end
	return nil
end
function dota688_death_prophet_silence:GetManaCost(level)
	local w = Witchcraft(self)
	return math.max(0, self.BaseClass.GetManaCost(self, level) + (w and w:GetSpecialValueFor("silence_mana_cost_adjust") or 0))
end
function dota688_death_prophet_silence:GetCooldown(level)
	local w = Witchcraft(self)
	return math.max(0, self.BaseClass.GetCooldown(self, level) + (w and w:GetSpecialValueFor("silence_cooldown_adjust") or 0))
end
function dota688_death_prophet_silence:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	EmitSoundOnLocationWithCaster(pos, "Hero_DeathProphet.Silence", caster)
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_death_prophet/death_prophet_silence.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fx, 0, pos); ParticleManager:SetParticleControl(fx, 1, Vector(self:GetSpecialValueFor("radius"), 1, 1))
	ParticleManager:ReleaseParticleIndex(fx)
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		e:AddNewModifier(caster, self, "modifier_dota688_death_prophet_silence", { duration = self:GetSpecialValueFor("duration") })
	end
end
modifier_dota688_death_prophet_silence = class({})
function modifier_dota688_death_prophet_silence:IsDebuff() return true end
function modifier_dota688_death_prophet_silence:IsPurgable() return true end
function modifier_dota688_death_prophet_silence:GetEffectName() return "particles/generic_gameplay/generic_silenced.vpcf" end
function modifier_dota688_death_prophet_silence:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_dota688_death_prophet_silence:CheckState() return { [MODIFIER_STATE_SILENCED] = true } end
