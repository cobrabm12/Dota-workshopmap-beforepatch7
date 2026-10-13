require("items/dota688_item_base")
require("items/item_dota688_sange")
-- Heaven's Halberd (6.88): +25 evaziune, +25 daune, +20 STR, Lesser Maim; activ: disarm 3 s (5.5 s pe ranged).
Dota688DefineItem("item_dota688_heavens_halberd", "items/item_dota688_heavens_halberd", {
	onAttackLanded = function(self, params)
		local target = params.target
		if not target or target:IsBuilding() or target:IsOther() then return end
		local a = self:GetAbility()
		if RollPseudoRandomPercentage(a:GetSpecialValueFor("maim_chance"), DOTA_PSEUDO_RANDOM_ITEM_HALBRED_MAIM, self:GetParent()) then
			target:AddNewModifier(self:GetParent(), a, "modifier_dota688_maim", { duration = a:GetSpecialValueFor("maim_duration") })
		end
	end,
	item = {
		OnSpellStart = function(self)
			local target = self:GetCursorTarget()
			if target:TriggerSpellAbsorb(self) then return end
			local d = target:IsRangedAttacker() and self:GetSpecialValueFor("disarm_range") or self:GetSpecialValueFor("disarm_melee")
			target:AddNewModifier(self:GetCaster(), self, "modifier_disarmed", { duration = d })
			target:EmitSound("DOTA_Item.HeavensHalberd.Activate")
		end,
	},
})
