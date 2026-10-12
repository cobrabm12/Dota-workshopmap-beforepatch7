-- Electric Vortex (6.88): trage tinta spre Storm 1/1.5/2/2.5 s (100 unitati/s); Storm e incetinit 50% 3 s.
local F = "abilities/heroes/dota688_storm_spirit_electric_vortex"
LinkLuaModifier("modifier_dota688_storm_vortex_pull", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_storm_vortex_self", F, LUA_MODIFIER_MOTION_NONE)
dota688_storm_spirit_electric_vortex = class({})
function dota688_storm_spirit_electric_vortex:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	caster:EmitSound("Hero_StormSpirit.ElectricVortex")
	target:AddNewModifier(caster, self, "modifier_dota688_storm_vortex_pull", { duration = self:GetSpecialValueFor("duration") })
	caster:AddNewModifier(caster, self, "modifier_dota688_storm_vortex_self", { duration = self:GetSpecialValueFor("electric_vortex_self_slow_duration") })
end
modifier_dota688_storm_vortex_pull = class({})
function modifier_dota688_storm_vortex_pull:IsDebuff() return true end
function modifier_dota688_storm_vortex_pull:IsPurgable() return true end
function modifier_dota688_storm_vortex_pull:IsStunDebuff() return true end
function modifier_dota688_storm_vortex_pull:GetEffectName() return "particles/units/heroes/hero_stormspirit/stormspirit_electric_vortex.vpcf" end
function modifier_dota688_storm_vortex_pull:OnCreated()
	if IsServer() then self.speed = self:GetAbility():GetSpecialValueFor("electric_vortex_pull_units_per_second"); self:StartIntervalThink(0.03) end
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
function modifier_dota688_storm_vortex_self:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("electric_vortex_self_slow") end
