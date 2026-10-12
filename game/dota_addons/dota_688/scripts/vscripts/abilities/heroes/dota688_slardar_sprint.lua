-- Sprint (6.88): +20/28/36/44% viteza de miscare 12 s, dar Slardar primeste +15% daune.
LinkLuaModifier("modifier_dota688_slardar_sprint", "abilities/heroes/dota688_slardar_sprint", LUA_MODIFIER_MOTION_NONE)
dota688_slardar_sprint = class({})
function dota688_slardar_sprint:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_dota688_slardar_sprint", { duration = self:GetSpecialValueFor("duration") })
	self:GetCaster():EmitSound("Hero_Slardar.Sprint")
end
modifier_dota688_slardar_sprint = class({})
function modifier_dota688_slardar_sprint:IsPurgable() return false end
function modifier_dota688_slardar_sprint:GetEffectName() return "particles/units/heroes/hero_slardar/slardar_sprint.vpcf" end
function modifier_dota688_slardar_sprint:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_dota688_slardar_sprint:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_speed") end
function modifier_dota688_slardar_sprint:GetModifierIncomingDamage_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_damage") end
