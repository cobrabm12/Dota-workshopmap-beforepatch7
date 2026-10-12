-- Vengeance Aura (6.88): +12/20/28/36% daune pentru aliatii din raza 900. Daca Venge e omorata de un erou inamic, acesta primeste
-- o Vengeance Aura negativa (-12..36% daune pentru el si aliatii lui din 900) pana cand Venge reinvie.
require("dota688/val")
local F = "abilities/heroes/dota688_vengefulspirit_command_aura"
LinkLuaModifier("modifier_dota688_vengefulspirit_command_aura", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_vengefulspirit_command_aura_effect", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_vengeance_negative", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_vengeance_negative_effect", F, LUA_MODIFIER_MOTION_NONE)
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
function modifier_dota688_vengefulspirit_command_aura:DeclareFunctions() return { MODIFIER_EVENT_ON_DEATH, MODIFIER_EVENT_ON_RESPAWN } end
function modifier_dota688_vengefulspirit_command_aura:OnDeath(params)
	if not IsServer() then return end
	local p = self:GetParent()
	if params.unit ~= p or p:IsIllusion() or p:IsReincarnating() then return end
	local k = params.attacker
	if not k or k:IsNull() or not k:IsRealHero() or k:GetTeamNumber() == p:GetTeamNumber() then return end
	local a = self:GetAbility()
	if not a or a:GetLevel() < 1 then return end
	self.cursed = k
	k:AddNewModifier(p, a, "modifier_dota688_vengeance_negative", {})
end
function modifier_dota688_vengefulspirit_command_aura:OnRespawn(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	local k = self.cursed
	if k and not k:IsNull() then k:RemoveModifierByName("modifier_dota688_vengeance_negative") end
	self.cursed = nil
end
-- aura negativa (pe ucigas): -bonus_damage_pct pentru el si aliatii lui
modifier_dota688_vengeance_negative = class({})
function modifier_dota688_vengeance_negative:IsHidden() return false end
function modifier_dota688_vengeance_negative:IsDebuff() return true end
function modifier_dota688_vengeance_negative:IsPurgable() return false end
function modifier_dota688_vengeance_negative:RemoveOnDeath() return false end
function modifier_dota688_vengeance_negative:GetTexture() return "vengefulspirit_command_aura" end
function modifier_dota688_vengeance_negative:IsAura() return true end
function modifier_dota688_vengeance_negative:GetAuraRadius() return Dota688Val(self, "aura_radius") end
function modifier_dota688_vengeance_negative:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_vengeance_negative:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_vengeance_negative:GetModifierAura() return "modifier_dota688_vengeance_negative_effect" end
modifier_dota688_vengeance_negative_effect = class({})
function modifier_dota688_vengeance_negative_effect:IsDebuff() return true end
function modifier_dota688_vengeance_negative_effect:IsPurgable() return false end
function modifier_dota688_vengeance_negative_effect:GetTexture() return "vengefulspirit_command_aura" end
function modifier_dota688_vengeance_negative_effect:DeclareFunctions() return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE } end
function modifier_dota688_vengeance_negative_effect:GetModifierBaseDamageOutgoing_Percentage() return -Dota688Val(self, "bonus_damage_pct") end
modifier_dota688_vengefulspirit_command_aura_effect = class({})
function modifier_dota688_vengefulspirit_command_aura_effect:IsPurgable() return false end
function modifier_dota688_vengefulspirit_command_aura_effect:DeclareFunctions() return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE } end
function modifier_dota688_vengefulspirit_command_aura_effect:GetModifierBaseDamageOutgoing_Percentage() return Dota688Val(self, "bonus_damage_pct") end
