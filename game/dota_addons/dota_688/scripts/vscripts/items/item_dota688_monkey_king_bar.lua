require("items/dota688_item_base")
-- Monkey King Bar (6.88): +66 daune, +15 AS, 35% sansa de mini-bash (+160 daune, 0.01 s stun) care anuleaza evaziunea (True Strike).
Dota688DefineItem("item_dota688_monkey_king_bar", "items/item_dota688_monkey_king_bar", {
	extraFunctions = { MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL, MODIFIER_PROPERTY_IGNORE_PHYSICAL_ARMOR, MODIFIER_PROPERTY_CANNOT_MISS },
	modifier = {
		GetModifierProcAttack_BonusDamage_Physical = function(self, params)
			local target = params.target
			if not target or target:IsBuilding() or target:IsOther() then return 0 end
			if RollPseudoRandomPercentage(self:GetAbility():GetSpecialValueFor("bash_chance"), DOTA_PSEUDO_RANDOM_ITEM_MKB, self:GetParent()) then
				if IsServer() and not target:IsMagicImmune() then
					target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_stunned", { duration = self:GetAbility():GetSpecialValueFor("bash_stun") })
				end
				return self:GetAbility():GetSpecialValueFor("bash_damage")
			end
			return 0
		end,
		GetModifierCannotMiss = function(self) return 1 end,
		GetModifierIgnorePhysicalArmor = function(self) return 0 end,
	},
})
