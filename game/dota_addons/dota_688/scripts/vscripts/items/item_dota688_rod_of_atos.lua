require("items/dota688_item_base")
-- Rod of Atos (6.88): +30 INT, +350 HP; Cripple: -60% MS 4 s, raza 1200, cd 10.
LinkLuaModifier("modifier_dota688_atos_slow", "items/item_dota688_rod_of_atos", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_rod_of_atos", "items/item_dota688_rod_of_atos", {
	item = {
		OnSpellStart = function(self)
			local target = self:GetCursorTarget()
			if target:TriggerSpellAbsorb(self) then return end
			target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_atos_slow", { duration = self:GetSpecialValueFor("duration") })
			target:EmitSound("DOTA_Item.RodOfAtos.Cast")
		end,
	},
})
modifier_dota688_atos_slow = class({})
function modifier_dota688_atos_slow:IsDebuff() return true end
function modifier_dota688_atos_slow:IsPurgable() return true end
function modifier_dota688_atos_slow:GetEffectName() return "particles/items2_fx/rod_of_atos.vpcf" end
function modifier_dota688_atos_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_atos_slow:GetModifierMoveSpeedBonus_Percentage() return -self:GetAbility():GetSpecialValueFor("slow") end
