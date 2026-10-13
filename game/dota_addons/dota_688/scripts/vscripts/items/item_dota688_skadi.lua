require("dota688/val")
require("items/dota688_item_base")
-- Eye of Skadi (6.88): +25 la toate, +225 HP, +250 mana; Cold Attack: -35% MS, -45 AS, 5 s melee / 2.5 s ranged (orb, nu se stacheaza cu alte orb-uri).
LinkLuaModifier("modifier_dota688_skadi_cold", "items/item_dota688_skadi", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_skadi", "items/item_dota688_skadi", {
	onAttackLanded = function(self, params)
		local target = params.target
		if not target or target:IsBuilding() or target:IsOther() or target:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
		local a = self:GetAbility()
		local d = self:GetParent():IsRangedAttacker() and a:GetSpecialValueFor("cold_duration_ranged") or a:GetSpecialValueFor("cold_duration_melee")
		target:AddNewModifier(self:GetParent(), a, "modifier_dota688_skadi_cold", { duration = d })
	end,
})
modifier_dota688_skadi_cold = class({})
function modifier_dota688_skadi_cold:IsDebuff() return true end
function modifier_dota688_skadi_cold:IsPurgable() return true end
function modifier_dota688_skadi_cold:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_skadi_cold:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "cold_movement_speed") end
function modifier_dota688_skadi_cold:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "cold_attack_speed") end
