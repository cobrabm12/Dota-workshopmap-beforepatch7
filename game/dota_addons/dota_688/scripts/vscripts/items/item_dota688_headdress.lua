require("dota688/val")
require("items/dota688_item_base")
-- Headdress (6.88): +2 la toate; aura +3 regen HP (900).
Dota688DefineAura("modifier_dota688_headdress_aura", "items/item_dota688_headdress", {
	radius = function(self) return Dota688Val(self, "aura_radius") end,
	functions = { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT },
	effect = { GetModifierConstantHealthRegen = function(self) return Dota688Val(self, "aura_health_regen") end },
})
Dota688DefineItem("item_dota688_headdress", "items/item_dota688_headdress", {
	onCreated = function(self)
		if IsServer() and not self:GetParent():HasModifier("modifier_dota688_headdress_aura") then
			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dota688_headdress_aura", {})
		end
	end,
	modifier = {
		OnDestroy = function(self)
			if IsServer() then Dota688ReapplyAura(self:GetParent(), "modifier_dota688_headdress_aura", { "item_dota688_headdress" }) end
		end,
	},
})
