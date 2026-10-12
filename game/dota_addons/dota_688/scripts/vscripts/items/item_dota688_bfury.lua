require("items/dota688_item_base")
-- Battle Fury (6.88): +55 daune, +6 regen, +150% regen mana; Cleave 35% in raza 280 (melee); Quelling: +160% daune pe creepi? (6.88: +60%... quelling_bonus 160 = 160% din daune? NU: bonus de 60%); taie copaci (cd 4).
Dota688DefineItem("item_dota688_bfury", "items/item_dota688_bfury", {
	extraFunctions = { MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL },
	onAttackLanded = function(self, params)
		local parent = self:GetParent()
		local target = params.target
		if parent:IsRangedAttacker() or not target or target:IsBuilding() or target:IsOther() or target:GetTeamNumber() == parent:GetTeamNumber() then return end
		local a = self:GetAbility()
		DoCleaveAttack(parent, target, a, params.damage * a:GetSpecialValueFor("cleave_damage_percent") / 100, 150, a:GetSpecialValueFor("cleave_radius"), 520, "particles/items_fx/battlefury_cleave.vpcf")
	end,
	modifier = {
		GetModifierProcAttack_BonusDamage_Physical = function(self, params)
			local target = params.target
			if not target or target:IsHero() or target:IsBuilding() or target:IsOther() or target:GetTeamNumber() == self:GetParent():GetTeamNumber() then return 0 end
			if target:GetUnitName() == "npc_dota_roshan" then return 0 end
			-- Quell nu se cumuleaza: doar primul Battle Fury (si el are prioritate fata de Quelling Blade / Iron Talon)
			if IsServer() then
				local all = self:GetParent():FindAllModifiersByName(self:GetName())
				if all[1] ~= nil and all[1] ~= self then return 0 end
			end
			local a = self:GetAbility()
			local pct = self:GetParent():IsRangedAttacker() and a:GetSpecialValueFor("quelling_bonus_ranged") or a:GetSpecialValueFor("quelling_bonus")
			return self:GetParent():GetAverageTrueAttackDamage(nil) * (pct - 100) / 100
		end,
	},
	item = {
		OnSpellStart = function(self)
			local target = self:GetCursorTarget()
			if target and target.CutDown then target:CutDown(self:GetCaster():GetTeamNumber()) end
		end,
	},
})
