-- Vengeance Aura (6.88): +12/20/28/36% daune pentru aliatii din raza 900.
require("dota688/val")
local F = "abilities/heroes/dota688_vengefulspirit_command_aura"
LinkLuaModifier("modifier_dota688_vengefulspirit_command_aura", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_vengefulspirit_command_aura_effect", F, LUA_MODIFIER_MOTION_NONE)
dota688_vengefulspirit_command_aura = class({})
function dota688_vengefulspirit_command_aura:GetIntrinsicModifierName() return "modifier_dota688_vengefulspirit_command_aura" end
modifier_dota688_vengefulspirit_command_aura = class({})
function modifier_dota688_vengefulspirit_command_aura:IsHidden() return true end
function modifier_dota688_vengefulspirit_command_aura:IsPurgable() return false end
function modifier_dota688_vengefulspirit_command_aura:IsAura() return not self:GetParent():PassivesDisabled() end
function modifier_dota688_vengefulspirit_command_aura:GetAuraRadius() return Dota688Val(self, "aura_radius") end
function modifier_dota688_vengefulspirit_command_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_vengefulspirit_command_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_vengefulspirit_command_aura:GetModifierAura() return "modifier_dota688_vengefulspirit_command_aura_effect" end
modifier_dota688_vengefulspirit_command_aura_effect = class({})
function modifier_dota688_vengefulspirit_command_aura_effect:IsPurgable() return false end
function modifier_dota688_vengefulspirit_command_aura_effect:DeclareFunctions() return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE } end
function modifier_dota688_vengefulspirit_command_aura_effect:GetModifierBaseDamageOutgoing_Percentage() return Dota688Val(self, "bonus_damage_pct") end
