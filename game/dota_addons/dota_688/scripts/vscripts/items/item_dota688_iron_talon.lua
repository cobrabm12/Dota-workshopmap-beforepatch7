require("items/dota688_item_base")
-- Iron Talon (6.88): +2 armura; +40% daune pe creepi (melee) / +15%? (ranged – 6.88: doar melee); activ: scoate 40% din HP curent al unui creep non-ancient (cd 14) sau taie un copac (cd 4).
Dota688DefineItem("item_dota688_iron_talon", "items/item_dota688_iron_talon", {
	extraFunctions = { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE },
	modifier = {
		GetModifierPreAttack_BonusDamage = function(self) return 0 end,
		-- bonusul de daune pe creepi: % din daunele de baza (quelling); folosim DamageOutgoing pe non-eroi
	},
	item = {
		CastFilterResultTarget = function(self, target)
			if target.CutDown then return UF_SUCCESS end   -- copac
			if target.IsAncient and target:IsAncient() then return UF_FAIL_ANCIENT end
			if target:IsHero() or target:IsBuilding() or target:IsOther() then return UF_FAIL_CUSTOM end
			if target:GetTeamNumber() == self:GetCaster():GetTeamNumber() then return UF_FAIL_FRIENDLY end
			return UF_SUCCESS
		end,
		OnSpellStart = function(self)
			local target = self:GetCursorTarget()
			local caster = self:GetCaster()
			if target.CutDown then   -- copac (CDOTA_MapTree); IsTree() nu mai exista

				target:CutDown(caster:GetTeamNumber())
				self:EndCooldown(); self:StartCooldown(self:GetSpecialValueFor("alternative_cooldown"))
				return
			end
			local dmg = target:GetHealth() * self:GetSpecialValueFor("creep_damage_pct") / 100
			ApplyDamage({ victim = target, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_IGNORES_PHYSICAL_ARMOR, ability = self })
			target:EmitSound("DOTA_Item.IronTalon.Activate")
		end,
	},
})
