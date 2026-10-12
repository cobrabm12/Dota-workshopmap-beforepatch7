-- Electric Vortex (6.88): trage tinta spre Storm 1/1.5/2/2.5 s (100 unitati/s); Storm e incetinit 50% 3 s.
-- Scepter: devine fara tinta si afecteaza toti inamicii din raza 475 in jurul lui Storm.
require("dota688/val")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_storm_spirit_electric_vortex"
LinkLuaModifier("modifier_dota688_storm_vortex_pull", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_storm_vortex_self", F, LUA_MODIFIER_MOTION_NONE)
dota688_storm_spirit_electric_vortex = class({})
function dota688_storm_spirit_electric_vortex:GetBehavior()
	if Dota688HasScepter(self:GetCaster()) then return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AOE end
	return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
end
function dota688_storm_spirit_electric_vortex:GetAOERadius() return self:GetSpecialValueFor("radius_scepter") end
function dota688_storm_spirit_electric_vortex:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_StormSpirit.ElectricVortex")
	local targets = {}
	if Dota688HasScepter(caster) then
		targets = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius_scepter"), DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS, FIND_ANY_ORDER, false)
	else
		local target = self:GetCursorTarget()
		if target:TriggerSpellAbsorb(self) then return end
		targets = { target }
	end
	for _, target in ipairs(targets) do
		target:AddNewModifier(caster, self, "modifier_dota688_storm_vortex_pull", { duration = self:GetSpecialValueFor("duration") })
	end
	caster:AddNewModifier(caster, self, "modifier_dota688_storm_vortex_self", { duration = self:GetSpecialValueFor("electric_vortex_self_slow_duration") })
end
modifier_dota688_storm_vortex_pull = class({})
function modifier_dota688_storm_vortex_pull:IsDebuff() return true end
function modifier_dota688_storm_vortex_pull:IsPurgable() return true end
function modifier_dota688_storm_vortex_pull:IsStunDebuff() return true end
function modifier_dota688_storm_vortex_pull:GetEffectName() return "particles/units/heroes/hero_stormspirit/stormspirit_electric_vortex.vpcf" end
function modifier_dota688_storm_vortex_pull:OnCreated()
	if IsServer() then self.speed = Dota688Val(self, "electric_vortex_pull_units_per_second"); self:StartIntervalThink(0.03) end
end
function modifier_dota688_storm_vortex_pull:OnIntervalThink()
	local caster, p = self:GetCaster(), self:GetParent()
	if not caster or caster:IsNull() then return end
	local to = caster:GetAbsOrigin() - p:GetAbsOrigin(); to.z = 0
	if to:Length2D() > 50 then p:SetAbsOrigin(p:GetAbsOrigin() + to:Normalized() * self.speed * 0.03) end
end
function modifier_dota688_storm_vortex_pull:OnDestroy() if IsServer() then FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), false) end end
function modifier_dota688_storm_vortex_pull:CheckState() return { [MODIFIER_STATE_STUNNED] = true } end
modifier_dota688_storm_vortex_self = class({})
function modifier_dota688_storm_vortex_self:IsPurgable() return true end
function modifier_dota688_storm_vortex_self:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_storm_vortex_self:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "electric_vortex_self_slow") end
