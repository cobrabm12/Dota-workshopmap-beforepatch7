require("items/dota688_item_base")
-- Skull Basher (6.88): +10 daune, +10 STR; bash 25% melee / 10% ranged: stun 1.4 s si +85 daune, cooldown 2.3 s.
-- Nu se declanseaza pe Spirit Breaker, Faceless Void, Slardar si Troll Warlord (6.88, Note1); nu se cumuleaza cu alte bash-uri.
-- Item-ul built-in curent nu il mai excludea pe Troll Warlord (testat: 4 bash-uri in 15 s pe Troll).
local NO_BASH = { npc_dota_hero_spirit_breaker = true, npc_dota_hero_faceless_void = true, npc_dota_hero_slardar = true, npc_dota_hero_troll_warlord = true }
Dota688DefineItem("item_dota688_basher", "items/item_dota688_basher", {
	extraFunctions = { MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL },
	modifier = {
		GetModifierProcAttack_BonusDamage_Physical = function(self, params)
			local target, a, parent = params.target, self:GetAbility(), self:GetParent()
			if not target or target:IsBuilding() or target:IsOther() then return 0 end
			if NO_BASH[parent:GetUnitName()] then return 0 end
			-- un singur Skull Basher activ (primul din inventar)
			if parent:FindItemInInventory("item_dota688_basher") ~= a then return 0 end
			if self.bashCd and self.bashCd > GameRules:GetGameTime() then return 0 end
			local chance = parent:IsRangedAttacker() and a:GetSpecialValueFor("bash_chance_ranged") or a:GetSpecialValueFor("bash_chance_melee")
			if RollPseudoRandomPercentage(chance, DOTA_PSEUDO_RANDOM_ITEM_BASHER, parent) then
				if IsServer() then
					target:AddNewModifier(parent, a, "modifier_stunned", { duration = a:GetSpecialValueFor("bash_duration") })
					target:EmitSound("DOTA_Item.SkullBasher")
					self.bashCd = GameRules:GetGameTime() + a:GetSpecialValueFor("bash_cooldown")
				end
				return a:GetSpecialValueFor("bonus_chance_damage")
			end
			return 0
		end,
	},
})
