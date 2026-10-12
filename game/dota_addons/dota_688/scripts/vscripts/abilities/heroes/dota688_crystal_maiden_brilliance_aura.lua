-- Arcane Aura (6.88): regenerare de mana globala pentru aliati: 1/1.5/2/3; Crystal Maiden: 2/3/4/8.
local F = "abilities/heroes/dota688_crystal_maiden_brilliance_aura"
LinkLuaModifier("modifier_dota688_crystal_maiden_brilliance_aura", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_crystal_maiden_brilliance_aura_effect", F, LUA_MODIFIER_MOTION_NONE)

dota688_crystal_maiden_brilliance_aura = class({})
function dota688_crystal_maiden_brilliance_aura:GetIntrinsicModifierName() return "modifier_dota688_crystal_maiden_brilliance_aura" end

modifier_dota688_crystal_maiden_brilliance_aura = class({})
function modifier_dota688_crystal_maiden_brilliance_aura:IsHidden() return true end
function modifier_dota688_crystal_maiden_brilliance_aura:IsPurgable() return false end
function modifier_dota688_crystal_maiden_brilliance_aura:IsAura() return true end
function modifier_dota688_crystal_maiden_brilliance_aura:GetAuraRadius() return 60000 end  -- global
function modifier_dota688_crystal_maiden_brilliance_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_crystal_maiden_brilliance_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_crystal_maiden_brilliance_aura:GetModifierAura() return "modifier_dota688_crystal_maiden_brilliance_aura_effect" end

modifier_dota688_crystal_maiden_brilliance_aura_effect = class({})
function modifier_dota688_crystal_maiden_brilliance_aura_effect:IsPurgable() return false end
function modifier_dota688_crystal_maiden_brilliance_aura_effect:DeclareFunctions() return { MODIFIER_PROPERTY_MANA_REGEN_CONSTANT } end
function modifier_dota688_crystal_maiden_brilliance_aura_effect:GetModifierConstantManaRegen()
	local a = self:GetAbility()
	if not a or a:IsNull() then return 0 end
	if self:GetParent() == self:GetCaster() then return a:GetSpecialValueFor("mana_regen_self") end
	return a:GetSpecialValueFor("mana_regen")
end
