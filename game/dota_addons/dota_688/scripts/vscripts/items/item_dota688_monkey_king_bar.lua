require("dota688/val")
require("items/dota688_item_base")
-- Monkey King Bar (6.88): +66 daune, +15 AS, 35% sansa de mini-bash (+160 daune, 0.01 s stun) care anuleaza evaziunea (True Strike).
Dota688DefineItem("item_dota688_monkey_king_bar", "items/item_dota688_monkey_king_bar", {
	extraFunctions = { MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL },
	modifier = {
		GetModifierProcAttack_BonusDamage_Physical = function(self, params)
			local target = params.target
			if not target or target:IsBuilding() or target:IsOther() then return 0 end
			if RollPseudoRandomPercentage(Dota688Val(self, "bash_chance"), DOTA_PSEUDO_RANDOM_ITEM_MKB, self:GetParent()) then
				if IsServer() and not target:IsMagicImmune() then
					target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_stunned", { duration = Dota688Val(self, "bash_stun") })
				end
				return Dota688Val(self, "bash_damage")
			end
			return 0
		end,
		-- True Strike: MODIFIER_PROPERTY_CANNOT_MISS nu mai exista, motorul curent foloseste starea
		CheckState = function(self) return { [MODIFIER_STATE_CANNOT_MISS] = true } end,
	},
})
