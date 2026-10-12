require("dota688/val")
require("items/dota688_item_base")
-- Echo Sabre (6.88): +10 INT, +10 STR, +10 AS, +15 daune, +75% regen mana; Echo Strike: atacurile melee lovesc de doua ori
-- in succesiune rapida, fiecare lovitura incetineste tinta 100% MS/AS 0.6 s (cd 5). Fara efect pe eroii ranged.
LinkLuaModifier("modifier_dota688_echo_slow", "items/item_dota688_echo_sabre", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_echo_sabre", "items/item_dota688_echo_sabre", {
	onAttackLanded = function(self, params)
		local target, parent = params.target, self:GetParent()
		local a = self:GetAbility()
		if not target or target:IsBuilding() or target:IsOther() or parent:IsRangedAttacker() then return end
		if self.echoing then
			-- a doua lovitura a ecoului
			self.echoing = nil
			target:AddNewModifier(parent, a, "modifier_dota688_echo_slow", { duration = a:GetSpecialValueFor("slow_duration") })
			return
		end
		if not a:IsCooldownReady() then return end
		a:UseResources(false, false, false, true)
		target:AddNewModifier(parent, a, "modifier_dota688_echo_slow", { duration = a:GetSpecialValueFor("slow_duration") })
		self.echoing = true
		Dota688Timers:After(0, function()
			if parent:IsNull() or target:IsNull() or not parent:IsAlive() or not target:IsAlive() then self.echoing = nil; return end
			parent:PerformAttack(target, true, true, true, false, false, false, false)
			self.echoing = nil
		end)
	end,
})
modifier_dota688_echo_slow = class({})
function modifier_dota688_echo_slow:IsDebuff() return true end
function modifier_dota688_echo_slow:IsPurgable() return true end
function modifier_dota688_echo_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_echo_slow:GetModifierMoveSpeedBonus_Percentage() return -Dota688Val(self, "movement_slow") end
function modifier_dota688_echo_slow:GetModifierAttackSpeedBonus_Constant() return -Dota688Val(self, "attack_speed_slow") end
