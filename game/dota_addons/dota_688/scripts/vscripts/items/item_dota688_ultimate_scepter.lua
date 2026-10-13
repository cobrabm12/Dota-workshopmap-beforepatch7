-- Aghanim's Scepter (6.88): +10 toate atributele, +175 HP, +175 mana. Upgrade-urile per erou: dota688/aghanim.lua.
-- Alchemist (6.86+) poate sa-l "topeasca" pe un erou aliat: acela primeste permanent upgrade-urile de scepter.
require("items/dota688_item_base")
require("dota688/aghanim")

local ALCHEMIST = "npc_dota_hero_alchemist"

Dota688DefineItem("item_dota688_ultimate_scepter", "items/item_dota688_ultimate_scepter", {
	item = {
		GetBehavior = function(self)
			local c = self:GetCaster()
			if c and not c:IsNull() and c:GetUnitName() == ALCHEMIST then
				return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
			end
			return DOTA_ABILITY_BEHAVIOR_PASSIVE
		end,
		CastFilterResultTarget = function(self, target)
			local c = self:GetCaster()
			if c:GetUnitName() ~= ALCHEMIST then
				self.castError = "#dota688_scepter_only_alchemist"
				return UF_FAIL_CUSTOM
			end
			if target == c then
				self.castError = "#dota688_scepter_not_self"
				return UF_FAIL_CUSTOM
			end
			if not target:IsRealHero() or target:GetTeamNumber() ~= c:GetTeamNumber() then
				return UF_FAIL_FRIENDLY
			end
			if target.dota688_scepter_granted then
				self.castError = "#dota688_scepter_already"
				return UF_FAIL_CUSTOM
			end
			return UF_SUCCESS
		end,
		GetCustomCastErrorTarget = function(self, target) return self.castError or "" end,
		OnSpellStart = function(self)
			local caster, target = self:GetCaster(), self:GetCursorTarget()
			if not target or target:IsNull() then return end
			Dota688Aghanim.GrantPermanent(target)
			target:EmitSound("DOTA_Item.UltimateScepter.Activate")
			local fx = ParticleManager:CreateParticle("particles/items_fx/aegis_respawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:ReleaseParticleIndex(fx)
			caster:RemoveItem(self)
		end,
	},
	onCreated = function(mod)
		if IsServer() then Dota688Aghanim.OnItemChanged(mod:GetParent()) end
	end,
	modifier = {
		OnDestroy = function(mod)
			if IsServer() then Dota688Aghanim.OnItemChanged(mod:GetParent()) end
		end,
	},
})
