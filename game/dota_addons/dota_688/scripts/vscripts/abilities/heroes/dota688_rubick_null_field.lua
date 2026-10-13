-- Null Field (6.88): pasiv, aura 900: eroii aliati (inclusiv Rubick) primesc +10/14/18/22% rezistenta la magie (se inmulteste
-- cu celelalte surse). Abilitatea built-in este una veche (activa, cooldown 30, raza 1200) scoasa din kitul modern al lui Rubick.
require("dota688/val")
local F = "abilities/heroes/dota688_rubick_null_field"
LinkLuaModifier("modifier_dota688_rubick_null_field", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_rubick_null_field_effect", F, LUA_MODIFIER_MOTION_NONE)

dota688_rubick_null_field = class({})
function dota688_rubick_null_field:GetIntrinsicModifierName() return "modifier_dota688_rubick_null_field" end

modifier_dota688_rubick_null_field = class({})
function modifier_dota688_rubick_null_field:IsHidden() return true end
function modifier_dota688_rubick_null_field:IsPurgable() return false end
function modifier_dota688_rubick_null_field:IsAura() return not self:GetParent():PassivesDisabled() end
function modifier_dota688_rubick_null_field:GetAuraRadius() return Dota688Val(self, "radius") end
function modifier_dota688_rubick_null_field:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_rubick_null_field:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_dota688_rubick_null_field:GetModifierAura() return "modifier_dota688_rubick_null_field_effect" end

modifier_dota688_rubick_null_field_effect = class({})
function modifier_dota688_rubick_null_field_effect:IsPurgable() return false end
function modifier_dota688_rubick_null_field_effect:DeclareFunctions() return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS } end
function modifier_dota688_rubick_null_field_effect:GetModifierMagicalResistanceBonus() return Dota688Val(self, "magic_damage_reduction_pct") end
