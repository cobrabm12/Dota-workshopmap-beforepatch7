require("items/dota688_item_base")
-- Quelling Blade (6.88): Quell: atacurile pe unitati non-erou fac 140% daune (melee) / 115% (ranged);
-- nu pe eroi/iluzii, cladiri, ward-uri, aliati si nici pe Roshan. Nu se cumuleaza (mai multe QB = un singur Quell;
-- Battle Fury, cu Quell mai mare, il inlocuieste).
-- Chop Tree/Ward (cd 4): distruge un copac (raza 350) sau un ward inamic / o Land Mine / o Remote Mine a lui Techies (raza 450).

local CHOPPABLE = {
	npc_dota_observer_wards = true, npc_dota_sentry_wards = true,
	npc_dota688_techies_land_mine = true, npc_dota688_techies_remote_mine = true,
}

local function IsUnit(target) return target ~= nil and target.GetUnitName ~= nil end   -- copacii nu au GetUnitName

Dota688DefineItem("item_dota688_quelling_blade", "items/item_dota688_quelling_blade", {
	extraFunctions = { MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL },
	modifier = {
		GetModifierProcAttack_BonusDamage_Physical = function(self, params)
			if not IsServer() then return 0 end
			local parent = self:GetParent()
			local target = params.target
			if params.attacker ~= parent or not target or target:IsNull() then return 0 end
			if target:IsHero() or target:IsBuilding() or target:IsOther() or target:GetTeamNumber() == parent:GetTeamNumber() then return 0 end
			local tname = target:GetUnitName()
			if tname == "npc_dota_roshan" or string.find(tname, "npc_dota688_techies_", 1, true) == 1 then return 0 end   -- minele = ward-uri in 6.88
			-- un singur Quell: primul Quelling Blade al eroului; Battle Fury (160/125) are prioritate
			if parent:HasModifier("modifier_item_dota688_bfury") then return 0 end
			local all = parent:FindAllModifiersByName(self:GetName())
			if all[1] ~= nil and all[1] ~= self then return 0 end
			local a = self:GetAbility()
			local pct = parent:IsRangedAttacker() and a:GetSpecialValueFor("damage_bonus_ranged") or a:GetSpecialValueFor("damage_bonus")
			return parent:GetAverageTrueAttackDamage(nil) * (pct - 100) / 100
		end,
	},
	item = {
		CastFilterResultTarget = function(self, target)
			if not IsUnit(target) then return UF_SUCCESS end   -- copac
			if CHOPPABLE[target:GetUnitName()] then
				if target:GetTeamNumber() == self:GetCaster():GetTeamNumber() then return UF_FAIL_FRIENDLY end
				return UF_SUCCESS
			end
			return UF_FAIL_CUSTOM
		end,
		GetCustomCastErrorTarget = function(self, target) return "#dota_hud_error_cant_cast_on_other" end,
		GetCastRange = function(self, location, target)
			if IsUnit(target) then return self:GetSpecialValueFor("cast_range_ward") end
			return self.BaseClass.GetCastRange(self, location, target)
		end,
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			local target = self:GetCursorTarget()
			if not target or target:IsNull() then return end
			if not IsUnit(target) then
				if target.CutDown then
					target:CutDown(caster:GetTeamNumber())
				else
					-- copac temporar (Sprout etc.): nu e CDOTA_MapTree
					GridNav:DestroyTreesAroundPoint(target:GetAbsOrigin(), 10, false)
				end
				return
			end
			if CHOPPABLE[target:GetUnitName()] and target:IsAlive() then
				target:Kill(self, caster)
			end
		end,
	},
})
