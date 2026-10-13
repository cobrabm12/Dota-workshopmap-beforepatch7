require("dota688/val")
require("items/dota688_item_base")
-- Ring of Basilius / Aquila (6.88): daune/stats + aura 900: +2 armura, +0.65 regen mana; toggle: doar eroi.
Dota688DefineAura("modifier_dota688_basilius_aura", "items/item_dota688_ring_of_basilius", {
	radius = function(self) return Dota688Val(self, "aura_radius") end,
	functions = { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS_UNIQUE, MODIFIER_PROPERTY_MANA_REGEN_CONSTANT },   -- armura nu se cumuleaza cu Vladmir (6.88)
	reject = function(self, unit)
		if self:GetAbility():GetToggleState() then return not unit:IsHero() and unit ~= self:GetParent() end
		return false
	end,
	effect = {
		GetModifierPhysicalArmorBonusUnique = function(self) return Dota688Val(self, "aura_bonus_armor") end,
		GetModifierConstantManaRegen = function(self) return Dota688Val(self, "aura_mana_regen") end,
	},
})
local function Define(name)
	Dota688DefineItem(name, "items/item_dota688_ring_of_basilius", {
		onCreated = function(self)
			if IsServer() and not self:GetParent():HasModifier("modifier_dota688_basilius_aura") then
				self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dota688_basilius_aura", {})
			end
		end,
		modifier = {
			OnDestroy = function(self)
				if IsServer() and not self:GetParent():HasItemInInventory("item_dota688_ring_of_basilius") and not self:GetParent():HasItemInInventory("item_dota688_ring_of_aquila") then
					self:GetParent():RemoveModifierByName("modifier_dota688_basilius_aura")
				end
			end,
		},
		item = { OnToggle = function(self) end },
	})
end
Define("item_dota688_ring_of_basilius")
Define("item_dota688_ring_of_aquila")
