require("items/dota688_item_base")
-- Abyssal Blade (6.88): +250 HP, +15 regen, +10 daune, +10 STR, block 40/20; bash 25%/10% (1.4 s, +85 daune); activ: stun 2 s prin imunitate.
Dota688DefineItem("item_dota688_abyssal_blade", "items/item_dota688_abyssal_blade", {
	extraFunctions = { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL, MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT },
	modifier = {
		GetModifierProcAttack_BonusDamage_Physical = function(self, params)
			local target = params.target
			local a = self:GetAbility()
			if not target or target:IsBuilding() or target:IsOther() then return 0 end
			if not a:IsCooldownReady() and (self.bashCd or 0) > GameRules:GetGameTime() then return 0 end
			if self.bashCd and self.bashCd > GameRules:GetGameTime() then return 0 end
			local chance = self:GetParent():IsRangedAttacker() and a:GetSpecialValueFor("bash_chance_ranged") or a:GetSpecialValueFor("bash_chance_melee")
			if RollPseudoRandomPercentage(chance, DOTA_PSEUDO_RANDOM_ITEM_BASHER, self:GetParent()) then
				if IsServer() then
					target:AddNewModifier(self:GetParent(), a, "modifier_stunned", { duration = a:GetSpecialValueFor("bash_duration") })
					self.bashCd = GameRules:GetGameTime() + a:GetSpecialValueFor("bash_cooldown")
				end
				return a:GetSpecialValueFor("bonus_chance_damage")
			end
			return 0
		end,
		GetModifierIncomingDamageConstant = function(self, params)
			if not IsServer() or params.damage_type ~= DAMAGE_TYPE_PHYSICAL or not params.attacker then return 0 end
			if bit.band(params.damage_flags or 0, DOTA_DAMAGE_FLAG_HPLOSS) ~= 0 then return 0 end
			local a = self:GetAbility()
			local block = self:GetParent():IsRangedAttacker() and a:GetSpecialValueFor("block_damage_ranged") or a:GetSpecialValueFor("block_damage_melee")
			return -math.min(block, params.damage)
		end,
	},
	item = {
		OnSpellStart = function(self)
			local target = self:GetCursorTarget()
			target:AddNewModifier(self:GetCaster(), self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })
			target:EmitSound("DOTA_Item.AbyssalBlade.Activate")
		end,
	},
})
