require("items/dota688_item_base")
-- Stout Shield (6.88): 50% sansa sa blocheze 16 (melee) / 8 (ranged) din daunele unui atac. Block-urile nu se cumuleaza:
-- Dota688DamageBlock alege o data pe lovitura cel mai mare block reusit (un block cu sansa al carui zar a picat nu conteaza).
Dota688DefineItem("item_dota688_stout_shield", "items/item_dota688_stout_shield", {
	extraFunctions = { MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT },
	modifier = {
		GetModifierIncomingDamageConstant = function(self, params)
			local a = self:GetAbility()
			local block = self:GetParent():IsRangedAttacker() and a:GetSpecialValueFor("damage_block_ranged") or a:GetSpecialValueFor("damage_block_melee")
			return Dota688DamageBlock(self:GetParent(), params, "item_dota688_stout_shield", block)
		end,
	},
})
