require("items/dota688_item_base")
-- Soul Ring (6.88): +3 regen HP, +50% regen mana; activ: -150 HP, +150 mana temporara 10 s, cd 30.
LinkLuaModifier("modifier_dota688_soul_ring_buff", "items/item_dota688_soul_ring", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_soul_ring", "items/item_dota688_soul_ring", {
	item = {
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			local cost = self:GetSpecialValueFor("health_sacrifice")
			if caster:GetHealth() <= cost then return end
			caster:SetHealth(caster:GetHealth() - cost)
			caster:AddNewModifier(caster, self, "modifier_dota688_soul_ring_buff", { duration = self:GetSpecialValueFor("duration") })
			caster:GiveMana(self:GetSpecialValueFor("mana_gain"))
			caster:EmitSound("DOTA_Item.SoulRing.Activate")
		end,
	},
})
modifier_dota688_soul_ring_buff = class({})
function modifier_dota688_soul_ring_buff:IsPurgable() return false end
function modifier_dota688_soul_ring_buff:DeclareFunctions() return { MODIFIER_PROPERTY_MANA_BONUS } end
function modifier_dota688_soul_ring_buff:GetModifierManaBonus() return self:GetAbility():GetSpecialValueFor("mana_gain") end
