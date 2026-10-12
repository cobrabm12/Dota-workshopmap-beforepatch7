require("dota688/val")
require("items/dota688_item_base")
-- Guardian Greaves (6.88): +55 MS, +250 mana, +5 la toate, +5 armura; aura 900: +4 regen, +2 armura (x15/+15 sub 20% HP); Mend: purge + 250 HP / 160 mana aliatilor din 900, cd 40.
Dota688DefineAura("modifier_dota688_greaves_aura", "items/item_dota688_guardian_greaves", {
	radius = function(self) return Dota688Val(self, "aura_radius") end,
	functions = { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS },
	effect = {
		GetModifierConstantHealthRegen = function(self)
			local a = self:GetAbility(); local p = self:GetParent()
			local low = p:GetHealth() / math.max(1, p:GetMaxHealth()) * 100 < a:GetSpecialValueFor("aura_bonus_threshold")
			return low and a:GetSpecialValueFor("aura_health_regen_bonus") or a:GetSpecialValueFor("aura_health_regen")
		end,
		GetModifierPhysicalArmorBonus = function(self)
			local a = self:GetAbility(); local p = self:GetParent()
			local low = p:GetHealth() / math.max(1, p:GetMaxHealth()) * 100 < a:GetSpecialValueFor("aura_bonus_threshold")
			return low and a:GetSpecialValueFor("aura_armor_bonus") or a:GetSpecialValueFor("aura_armor")
		end,
	},
})
Dota688DefineItem("item_dota688_guardian_greaves", "items/item_dota688_guardian_greaves", {
	boots = true,   -- viteza cizmelor nu se aduna cu alte cizme (6.88)
	onCreated = function(self)
		if IsServer() and not self:GetParent():HasModifier("modifier_dota688_greaves_aura") then
			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dota688_greaves_aura", {})
		end
	end,
	modifier = {
		OnDestroy = function(self)
			if IsServer() and not self:GetParent():HasItemInInventory("item_dota688_guardian_greaves") then self:GetParent():RemoveModifierByName("modifier_dota688_greaves_aura") end
		end,
	},
	item = {
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			caster:EmitSound("DOTA_Item.GuardianGreaves.Activate")
			local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("replenish_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _, u in ipairs(allies) do
				u:Heal(self:GetSpecialValueFor("replenish_health"), self)
				u:GiveMana(self:GetSpecialValueFor("replenish_mana"))
				if u == caster then u:Purge(false, true, false, false, false) end
				local fx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, u)
				ParticleManager:ReleaseParticleIndex(fx)
			end
		end,
	},
})
