-- Pulse Nova (6.88): toggle; 100/130/160 daune magice/s in raza 450, costa 20/40/60 mana/s. Scepter: 160/190/220 daune.
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_pulse_nova", "abilities/heroes/dota688_leshrac_pulse_nova", LUA_MODIFIER_MOTION_NONE)
dota688_leshrac_pulse_nova = class({})
function dota688_leshrac_pulse_nova:OnToggle()
	local caster = self:GetCaster()
	if self:GetToggleState() then
		caster:AddNewModifier(caster, self, "modifier_dota688_pulse_nova", {})
		caster:EmitSound("Hero_Leshrac.Pulse_Nova")
	else
		caster:RemoveModifierByName("modifier_dota688_pulse_nova")
		caster:StopSound("Hero_Leshrac.Pulse_Nova")
	end
end
function dota688_leshrac_pulse_nova:OnOwnerDied()
	if self:GetToggleState() then self:ToggleAbility() end
end
modifier_dota688_pulse_nova = class({})
function modifier_dota688_pulse_nova:IsPurgable() return false end
function modifier_dota688_pulse_nova:GetEffectName() return "particles/units/heroes/hero_leshrac/leshrac_pulse_nova.vpcf" end
function modifier_dota688_pulse_nova:OnCreated() if IsServer() then self:StartIntervalThink(1.0) end end
function modifier_dota688_pulse_nova:OnIntervalThink()
	local p, a = self:GetParent(), self:GetAbility()
	local cost = a:GetSpecialValueFor("mana_cost_per_second")
	if p:GetMana() < cost or not p:IsAlive() or p:IsSilenced() then
		if a:GetToggleState() then a:ToggleAbility() end
		return
	end
	p:SpendMana(cost, a)
	local dmg = Dota688HasScepter(p) and a:GetSpecialValueFor("damage_scepter") or a:GetSpecialValueFor("damage")
	for _, e in ipairs(FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, a:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		ApplyDamage({ victim = e, attacker = p, damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
	end
end
