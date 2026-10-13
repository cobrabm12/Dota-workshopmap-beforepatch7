require("items/dota688_item_base")
-- Vanguard (6.88): +250 HP, +8 regen HP; blocheaza mereu (fara sansa in KV-ul 6.88) 32 (melee) / 16 (ranged) din daunele unui atac.
-- Nu se cumuleaza cu alte block-uri: Dota688DamageBlock alege o data pe lovitura cel mai mare block reusit.
Dota688DefineItem("item_dota688_vanguard", "items/item_dota688_vanguard", {
	extraFunctions = { MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT },
	modifier = {
		GetModifierIncomingDamageConstant = function(self, params)
			local a = self:GetAbility()
			local block = self:GetParent():IsRangedAttacker() and a:GetSpecialValueFor("block_damage_ranged") or a:GetSpecialValueFor("block_damage_melee")
			return Dota688DamageBlock(self:GetParent(), params, "item_dota688_vanguard", block)
		end,
	},
})
