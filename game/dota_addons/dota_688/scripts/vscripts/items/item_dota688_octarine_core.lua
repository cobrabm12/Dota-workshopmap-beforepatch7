require("items/dota688_item_base")
-- Octarine Core (6.88): +25 INT, +425 HP, +425 mana, +50% regen mana, 25% reducere cooldown, 25% spell lifesteal (5% pe creepi).
Dota688DefineItem("item_dota688_octarine_core", "items/item_dota688_octarine_core", {
	extraFunctions = { MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE, MODIFIER_EVENT_ON_TAKEDAMAGE },
	modifier = {
		GetModifierPercentageCooldown = function(self) return self:GetAbility():GetSpecialValueFor("bonus_cooldown") end,
		OnTakeDamage = function(self, params)
			if not IsServer() then return end
			local parent = self:GetParent()
			if params.attacker ~= parent or params.unit == parent or not params.inflictor then return end
			local unit = params.unit
			if unit:IsBuilding() or unit:IsOther() or unit:GetTeamNumber() == parent:GetTeamNumber() then return end
			local pct = unit:IsHero() and self:GetAbility():GetSpecialValueFor("hero_lifesteal") or self:GetAbility():GetSpecialValueFor("creep_lifesteal")
			parent:Heal(params.damage * pct / 100, self:GetAbility())
		end,
	},
})
