require("items/dota688_item_base")
-- Abyssal Blade (6.88): +250 HP, +15 regen, +10 daune, +10 STR, block 40/20 (doar atacuri, nu se cumuleaza cu alte block-uri);
-- bash 25%/10% (1.4 s, +85 daune) - nu pe Spirit Breaker, Faceless Void, Slardar, Troll Warlord si nu se cumuleaza cu Skull Basher;
-- activ: stun 2 s prin imunitate (blocat de Linken).
local NO_BASH = { npc_dota_hero_spirit_breaker = true, npc_dota_hero_faceless_void = true, npc_dota_hero_slardar = true, npc_dota_hero_troll_warlord = true }
Dota688DefineItem("item_dota688_abyssal_blade", "items/item_dota688_abyssal_blade", {
	extraFunctions = { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL, MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT },
	modifier = {
		GetModifierProcAttack_BonusDamage_Physical = function(self, params)
			local target = params.target
			local a = self:GetAbility()
			if not target or target:IsBuilding() or target:IsOther() then return 0 end
			local parent = self:GetParent()
			if NO_BASH[parent:GetUnitName()] or (parent:HasItemInInventory("item_dota688_basher") or parent:HasItemInInventory("item_basher")) then return 0 end
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
			local a = self:GetAbility()
			local block = self:GetParent():IsRangedAttacker() and a:GetSpecialValueFor("block_damage_ranged") or a:GetSpecialValueFor("block_damage_melee")
			return Dota688DamageBlock(self:GetParent(), params, "item_dota688_abyssal_blade", block)
		end,
	},
	item = {
		OnSpellStart = function(self)
			local target = self:GetCursorTarget()
			if target:TriggerSpellAbsorb(self) then return end
			target:AddNewModifier(self:GetCaster(), self, "modifier_stunned", { duration = self:GetSpecialValueFor("stun_duration") })
			target:EmitSound("DOTA_Item.AbyssalBlade.Activate")
		end,
	},
})
