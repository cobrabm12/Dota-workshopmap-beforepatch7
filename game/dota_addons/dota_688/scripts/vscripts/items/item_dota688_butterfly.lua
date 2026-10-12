require("dota688/val")
require("items/dota688_item_base")
-- Butterfly (6.88): +35 AGI, +30 daune, +35 evaziune, +30 AS; Flutter: "Trade evasion for 35% movement speed" 4 s, cd 25.
LinkLuaModifier("modifier_dota688_butterfly_flutter", "items/item_dota688_butterfly", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_butterfly", "items/item_dota688_butterfly", {
	modifier = {
		GetModifierEvasion_Constant = function(self)
			if self:GetParent():HasModifier("modifier_dota688_butterfly_flutter") then return 0 end
			return (self.stats and self.stats.GetModifierEvasion_Constant) or 0
		end,
	},
	item = {
		OnSpellStart = function(self)
			self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_dota688_butterfly_flutter", { duration = self:GetSpecialValueFor("duration") })
			self:GetCaster():EmitSound("DOTA_Item.Butterfly")
		end,
	},
})
modifier_dota688_butterfly_flutter = class({})
function modifier_dota688_butterfly_flutter:IsPurgable() return true end
function modifier_dota688_butterfly_flutter:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_butterfly_flutter:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "bonus_move_speed") end
