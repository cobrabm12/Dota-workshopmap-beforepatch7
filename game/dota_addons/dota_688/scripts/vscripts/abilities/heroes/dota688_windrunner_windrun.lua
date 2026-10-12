-- Windrun (6.88): +50% MS, 100% evaziune fata de atacuri, inamicii din raza 300 sunt incetiniti 8/16/24/30%; 3/4/5/6 s.
local F = "abilities/heroes/dota688_windrunner_windrun"
LinkLuaModifier("modifier_dota688_windrunner_windrun", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_windrunner_windrun_slow", F, LUA_MODIFIER_MOTION_NONE)
dota688_windrunner_windrun = class({})
function dota688_windrunner_windrun:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_dota688_windrunner_windrun", { duration = self:GetSpecialValueFor("duration") })
	self:GetCaster():EmitSound("Hero_Windrunner.Windrun")
end
modifier_dota688_windrunner_windrun = class({})
function modifier_dota688_windrunner_windrun:IsPurgable() return true end
function modifier_dota688_windrunner_windrun:GetEffectName() return "particles/units/heroes/hero_windrunner/windrunner_windrun.vpcf" end
function modifier_dota688_windrunner_windrun:IsAura() return true end
function modifier_dota688_windrunner_windrun:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_dota688_windrunner_windrun:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_dota688_windrunner_windrun:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_windrunner_windrun:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES end
function modifier_dota688_windrunner_windrun:GetModifierAura() return "modifier_dota688_windrunner_windrun_slow" end
function modifier_dota688_windrunner_windrun:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_EVASION_CONSTANT } end
function modifier_dota688_windrunner_windrun:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("movespeed_bonus_pct") end
function modifier_dota688_windrunner_windrun:GetModifierEvasion_Constant() return self:GetAbility():GetSpecialValueFor("evasion_pct_tooltip") end
modifier_dota688_windrunner_windrun_slow = class({})
function modifier_dota688_windrunner_windrun_slow:IsDebuff() return true end
function modifier_dota688_windrunner_windrun_slow:IsPurgable() return false end
function modifier_dota688_windrunner_windrun_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_windrunner_windrun_slow:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("enemy_movespeed_bonus_pct") end
