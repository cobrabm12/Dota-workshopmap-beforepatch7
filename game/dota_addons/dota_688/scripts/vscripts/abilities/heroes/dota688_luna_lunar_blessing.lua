-- Lunar Blessing (6.88): aura 900: +14/22/30/38 daune pentru eroii aliati; Luna primeste +1000 viziune de noapte.
local F = "abilities/heroes/dota688_luna_lunar_blessing"
LinkLuaModifier("modifier_dota688_luna_lunar_blessing", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_luna_lunar_blessing_effect", F, LUA_MODIFIER_MOTION_NONE)
dota688_luna_lunar_blessing = class({})
function dota688_luna_lunar_blessing:GetIntrinsicModifierName() return "modifier_dota688_luna_lunar_blessing" end

modifier_dota688_luna_lunar_blessing = class({})
function modifier_dota688_luna_lunar_blessing:IsHidden() return true end
function modifier_dota688_luna_lunar_blessing:IsPurgable() return false end
function modifier_dota688_luna_lunar_blessing:IsAura() return true end
function modifier_dota688_luna_lunar_blessing:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_dota688_luna_lunar_blessing:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_luna_lunar_blessing:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_dota688_luna_lunar_blessing:GetModifierAura() return "modifier_dota688_luna_lunar_blessing_effect" end
function modifier_dota688_luna_lunar_blessing:DeclareFunctions() return { MODIFIER_PROPERTY_BONUS_NIGHT_VISION } end
function modifier_dota688_luna_lunar_blessing:GetBonusNightVision() return self:GetAbility():GetSpecialValueFor("bonus_night_vision") end

modifier_dota688_luna_lunar_blessing_effect = class({})
function modifier_dota688_luna_lunar_blessing_effect:IsPurgable() return false end
function modifier_dota688_luna_lunar_blessing_effect:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE } end
function modifier_dota688_luna_lunar_blessing_effect:GetModifierPreAttack_BonusDamage() return self:GetAbility():GetSpecialValueFor("bonus_damage") end
