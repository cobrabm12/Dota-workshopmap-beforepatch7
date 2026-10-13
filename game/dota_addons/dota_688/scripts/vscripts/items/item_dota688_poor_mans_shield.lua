require("items/dota688_item_base")
-- Poor Man's Shield (6.88): +6 AGI; blocheaza 20 (melee) / 10 (ranged) din daunele unui atac: mereu contra atacurilor eroilor
-- (block_chance_hero = 100, inclusiv iluziile), 53% contra restului (creep-uri, neutrali, Roshan, turnuri). Nu se cumuleaza cu
-- alte block-uri: Dota688DamageBlock alege o data pe lovitura cel mai mare block reusit.
Dota688DefineItem("item_dota688_poor_mans_shield", "items/item_dota688_poor_mans_shield", {
	extraFunctions = { MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT },
	modifier = {
		GetModifierIncomingDamageConstant = function(self, params)
			local a = self:GetAbility()
			local block = self:GetParent():IsRangedAttacker() and a:GetSpecialValueFor("damage_block_ranged") or a:GetSpecialValueFor("damage_block_melee")
			return Dota688DamageBlock(self:GetParent(), params, "item_dota688_poor_mans_shield", block)
		end,
	},
})
