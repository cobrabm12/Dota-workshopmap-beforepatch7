require("items/dota688_item_base")
-- Iron Talon (6.88): +2 armura; Quell +40% daune pe non-eroi (melee) / +15% (ranged); activ: scoate 40% din HP curent al unui creep non-ancient (cd 14) sau taie un copac (cd 4).
Dota688DefineItem("item_dota688_iron_talon", "items/item_dota688_iron_talon", {
	extraFunctions = { MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL },
	modifier = {
		-- Quell (6.88): atacurile pe unitati non-erou fac 140% (melee) / 115% (ranged) daune; nu pe eroi, cladiri,
		-- ward-uri, aliati, Roshan. Nu se cumuleaza cu Battle Fury, Quelling Blade sau alt Iron Talon.
		GetModifierProcAttack_BonusDamage_Physical = function(self, params)
			if not IsServer() then return 0 end
			local parent = self:GetParent()
			local target = params.target
			if params.attacker ~= parent or not target or target:IsNull() then return 0 end
			if target:IsHero() or target:IsBuilding() or target:IsOther() or target:GetTeamNumber() == parent:GetTeamNumber() then return 0 end
			local tname = target:GetUnitName()
			if tname == "npc_dota_roshan" or string.find(tname, "npc_dota688_techies_", 1, true) == 1 then return 0 end
			if parent:HasModifier("modifier_item_dota688_bfury") or parent:HasModifier("modifier_item_dota688_quelling_blade") then return 0 end
			local all = parent:FindAllModifiersByName(self:GetName())
			if all[1] ~= nil and all[1] ~= self then return 0 end
			local a = self:GetAbility()
			local pct = parent:IsRangedAttacker() and a:GetSpecialValueFor("damage_bonus_ranged") or a:GetSpecialValueFor("damage_bonus")
			return parent:GetAverageTrueAttackDamage(nil) * (pct - 100) / 100
		end,
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
