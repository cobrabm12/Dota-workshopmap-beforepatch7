require("items/dota688_item_base")
-- Javelin (6.88): +10 daune, 25% sansa de +85 daune magice (Pierce) la atac
Dota688DefineItem("item_dota688_javelin", "items/item_dota688_javelin", {
	extraFunctions = { MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL },
	modifier = {
		GetModifierProcAttack_BonusDamage_Magical = function(self, params)
			local target = params.target
			if not target or target:IsBuilding() or target:IsOther() then return 0 end
			if RollPseudoRandomPercentage(self:GetAbility():GetSpecialValueFor("bonus_chance"), DOTA_PSEUDO_RANDOM_ITEM_JAVELIN, self:GetParent()) then
				return self:GetAbility():GetSpecialValueFor("bonus_chance_damage")
			end
			return 0
		end,
	},
})
