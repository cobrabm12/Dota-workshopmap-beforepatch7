-- Strafe (6.88): +130 AS pentru 4/6/8/10 s.
LinkLuaModifier("modifier_dota688_clinkz_strafe", "abilities/heroes/dota688_clinkz_strafe", LUA_MODIFIER_MOTION_NONE)
dota688_clinkz_strafe = class({})
function dota688_clinkz_strafe:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_dota688_clinkz_strafe", { duration = self:GetSpecialValueFor("duration") })
	self:GetCaster():EmitSound("Hero_Clinkz.Strafe")
end
modifier_dota688_clinkz_strafe = class({})
function modifier_dota688_clinkz_strafe:IsPurgable() return true end
function modifier_dota688_clinkz_strafe:GetEffectName() return "particles/units/heroes/hero_clinkz/clinkz_strafe.vpcf" end
function modifier_dota688_clinkz_strafe:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_clinkz_strafe:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("attack_speed_bonus_pct") end
