-- Hunter in the Night (6.88): pasiv cu 4 niveluri; noaptea (inclusiv in timpul lui Darkness) Night Stalker primeste
-- +20/25/30/35 % viteza de miscare si +45/60/75/90 viteza de atac. Afectat de Break.
-- Rescris in Lua: in clientul curent abilitatea e "innate" si motorul (C++) ii forteaza nivelul maxim la 0, deci nu mai
-- putea fi invatata din HUD (verificat in joc: GetMaxLevel() = 0 chiar cu "MaxLevel" "4" in override).
require("dota688/val")
LinkLuaModifier("modifier_dota688_night_stalker_hunter_in_the_night", "abilities/heroes/dota688_night_stalker_hunter_in_the_night", LUA_MODIFIER_MOTION_NONE)
dota688_night_stalker_hunter_in_the_night = class({})
function dota688_night_stalker_hunter_in_the_night:GetIntrinsicModifierName() return "modifier_dota688_night_stalker_hunter_in_the_night" end

modifier_dota688_night_stalker_hunter_in_the_night = class({})
function modifier_dota688_night_stalker_hunter_in_the_night:IsHidden() return self:GetStackCount() == 0 end
function modifier_dota688_night_stalker_hunter_in_the_night:IsPurgable() return false end
function modifier_dota688_night_stalker_hunter_in_the_night:RemoveOnDeath() return false end
function modifier_dota688_night_stalker_hunter_in_the_night:OnCreated()
	if IsServer() then self:OnIntervalThink(); self:StartIntervalThink(0.25) end
end
-- stack 1 = e noapte (serverul decide; clientul citeste stack-ul pentru tooltip si iconita)
function modifier_dota688_night_stalker_hunter_in_the_night:OnIntervalThink()
	self:SetStackCount(GameRules:IsDaytime() and 0 or 1)
end
function modifier_dota688_night_stalker_hunter_in_the_night:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_dota688_night_stalker_hunter_in_the_night:Active()
	return self:GetStackCount() == 1 and not self:GetParent():PassivesDisabled()
end
function modifier_dota688_night_stalker_hunter_in_the_night:GetModifierMoveSpeedBonus_Percentage()
	return self:Active() and Dota688Val(self, "bonus_movement_speed_pct_night") or 0
end
function modifier_dota688_night_stalker_hunter_in_the_night:GetModifierAttackSpeedBonus_Constant()
	return self:Active() and Dota688Val(self, "bonus_attack_speed_night") or 0
end
