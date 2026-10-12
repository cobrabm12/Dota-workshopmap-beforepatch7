require("items/dota688_item_base")
-- Heart of Tarrasque (6.88): +45 STR, +250 HP; regenereaza 4.75% din HP max pe secunda daca nu a luat daune de la jucatori de 5 s (melee) / 7 s (ranged).
Dota688DefineItem("item_dota688_heart", "items/item_dota688_heart", {
	extraFunctions = { MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE },
	onCreated = function(self) self.lastHit = -100 end,
	modifier = {
		OnTakeDamage = function(self, params)
			if not IsServer() or params.unit ~= self:GetParent() then return end
			local attacker = params.attacker
			if attacker and (attacker:IsControllableByAnyPlayer() or attacker:GetUnitName() == "npc_dota_roshan") and attacker:GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
				self.lastHit = GameRules:GetGameTime()
			end
		end,
		GetModifierHealthRegenPercentage = function(self)
			local a = self:GetAbility()
			local cd = self:GetParent():IsRangedAttacker() and a:GetSpecialValueFor("cooldown_ranged_tooltip") or a:GetSpecialValueFor("cooldown_melee")
			if GameRules:GetGameTime() - (self.lastHit or -100) < cd then return 0 end
			return a:GetSpecialValueFor("health_regen_rate")
		end,
	},
})
