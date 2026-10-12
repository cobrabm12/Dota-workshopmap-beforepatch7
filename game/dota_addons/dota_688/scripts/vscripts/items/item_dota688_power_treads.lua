require("items/dota688_item_base")
-- Power Treads (6.88): +45 MS, +25 AS, +9 la atributul ales (STR/AGI/INT, comutat prin click).
Dota688DefineItem("item_dota688_power_treads", "items/item_dota688_power_treads", {
	onCreated = function(self) if IsServer() then self.attr = self:GetAbility().attr or 0 end end,
	modifier = {
		GetModifierBonusStats_Strength = function(self) return (self:GetAbility().attr or 0) == 0 and self:GetAbility():GetSpecialValueFor("bonus_stat") or 0 end,
		GetModifierBonusStats_Agility = function(self) return (self:GetAbility().attr or 0) == 1 and self:GetAbility():GetSpecialValueFor("bonus_stat") or 0 end,
		GetModifierBonusStats_Intellect = function(self) return (self:GetAbility().attr or 0) == 2 and self:GetAbility():GetSpecialValueFor("bonus_stat") or 0 end,
	},
	item = {
		OnSpellStart = function(self)
			self.attr = ((self.attr or 0) + 1) % 3
			local caster = self:GetCaster()
			caster:CalculateStatBonus(true)
			caster:EmitSound("DOTA_Item.PowerTreads.Activate")
		end,
	},
})
