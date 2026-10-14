require("dota688/val")
require("items/dota688_item_base")
-- Vladmir's Offering (6.88): +2 la toate; aura 900: 15% lifesteal (10% ranged), +15% daune, +4 armura (nu se cumuleaza cu
-- Basilius/Aquila), +0.8 regen mana, +3 regen HP.
Dota688DefineAura("modifier_dota688_vladmir_aura", "items/item_dota688_vladmir", {
	radius = function(self) return Dota688Val(self, "aura_radius") end,
	functions = { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS_UNIQUE, MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, MODIFIER_EVENT_ON_ATTACK_LANDED },
	effect = {
		GetModifierBaseDamageOutgoing_Percentage = function(self) return Dota688Val(self, "damage_aura") end,
		GetModifierPhysicalArmorBonusUnique = function(self) return Dota688Val(self, "armor_aura") end,
		GetModifierConstantManaRegen = function(self) return Dota688Val(self, "mana_regen_aura") end,
		GetModifierConstantHealthRegen = function(self) return Dota688Val(self, "hp_regen") end,
		OnAttackLanded = function(self, params)
			if not IsServer() or params.attacker ~= self:GetParent() then return end
			local target = params.target
			if not target or target:IsBuilding() or target:IsOther() then return end
			local a = self:GetAbility()
			local pct = self:GetParent():IsRangedAttacker() and a:GetSpecialValueFor("vampiric_aura_ranged") or a:GetSpecialValueFor("vampiric_aura")
			self:GetParent():Heal(params.damage * pct / 100, a)
		end,
	},
})
Dota688DefineItem("item_dota688_vladmir", "items/item_dota688_vladmir", {
	onCreated = function(self)
		if IsServer() and not self:GetParent():HasModifier("modifier_dota688_vladmir_aura") then
			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dota688_vladmir_aura", {})
		end
	end,
	modifier = {
		GetModifierConstantHealthRegen = function() return 0 end,   -- hp_regen e al aurei
		OnDestroy = function(self)
			if IsServer() then Dota688ReapplyAura(self:GetParent(), "modifier_dota688_vladmir_aura", { "item_dota688_vladmir" }) end
		end,
	},
})
