require("items/dota688_item_base")
-- Echo Sabre (6.88): +10 INT, +10 STR, +10 AS, +15 daune, +75% regen mana; atacurile incetinesc tinta 100% MS/AS 0.6 s (cd 5).
LinkLuaModifier("modifier_dota688_echo_slow", "items/item_dota688_echo_sabre", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_echo_sabre", "items/item_dota688_echo_sabre", {
	onAttackLanded = function(self, params)
		local target = params.target
		local a = self:GetAbility()
		if not target or target:IsBuilding() or target:IsOther() or not a:IsCooldownReady() then return end
		a:UseResources(false, false, false, true)
		target:AddNewModifier(self:GetParent(), a, "modifier_dota688_echo_slow", { duration = a:GetSpecialValueFor("slow_duration") })
	end,
})
modifier_dota688_echo_slow = class({})
function modifier_dota688_echo_slow:IsDebuff() return true end
function modifier_dota688_echo_slow:IsPurgable() return true end
function modifier_dota688_echo_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_echo_slow:GetModifierMoveSpeedBonus_Percentage() return -self:GetAbility():GetSpecialValueFor("movement_slow") end
function modifier_dota688_echo_slow:GetModifierAttackSpeedBonus_Constant() return -self:GetAbility():GetSpecialValueFor("attack_speed_slow") end
