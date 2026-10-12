-- Degen Aura (6.88): inamicii din raza 350 au -10/18/26/34% viteza de miscare si de atac.
local F = "abilities/heroes/dota688_omniknight_degen_aura"
LinkLuaModifier("modifier_dota688_omniknight_degen_aura", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_omniknight_degen_aura_effect", F, LUA_MODIFIER_MOTION_NONE)
dota688_omniknight_degen_aura = class({})
function dota688_omniknight_degen_aura:GetIntrinsicModifierName() return "modifier_dota688_omniknight_degen_aura" end

modifier_dota688_omniknight_degen_aura = class({})
function modifier_dota688_omniknight_degen_aura:IsHidden() return true end
function modifier_dota688_omniknight_degen_aura:IsPurgable() return false end
function modifier_dota688_omniknight_degen_aura:IsAura() return not self:GetParent():PassivesDisabled() end
function modifier_dota688_omniknight_degen_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_dota688_omniknight_degen_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_dota688_omniknight_degen_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_omniknight_degen_aura:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES end
function modifier_dota688_omniknight_degen_aura:GetModifierAura() return "modifier_dota688_omniknight_degen_aura_effect" end
function modifier_dota688_omniknight_degen_aura:GetAuraEntityReject(unit) return unit:IsMagicImmune() end

modifier_dota688_omniknight_degen_aura_effect = class({})
function modifier_dota688_omniknight_degen_aura_effect:IsDebuff() return true end
function modifier_dota688_omniknight_degen_aura_effect:IsPurgable() return false end
function modifier_dota688_omniknight_degen_aura_effect:GetEffectName() return "particles/units/heroes/hero_omniknight/omniknight_degen_aura_debuff.vpcf" end
function modifier_dota688_omniknight_degen_aura_effect:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_omniknight_degen_aura_effect:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("speed_bonus") end
function modifier_dota688_omniknight_degen_aura_effect:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("speed_bonus") end
