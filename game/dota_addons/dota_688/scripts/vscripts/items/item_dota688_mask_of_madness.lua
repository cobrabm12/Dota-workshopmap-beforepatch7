require("dota688/val")
require("items/dota688_item_base")
-- Mask of Madness (6.88): 20% lifesteal; Berserk: +100 AS, +17% MS, dar +25% daune primite, 12 s, cd 25.
LinkLuaModifier("modifier_dota688_mom_berserk", "items/item_dota688_mask_of_madness", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_mask_of_madness", "items/item_dota688_mask_of_madness", {
	item = {
		OnSpellStart = function(self)
			self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_dota688_mom_berserk", { duration = self:GetSpecialValueFor("berserk_duration") })
			self:GetCaster():EmitSound("DOTA_Item.MaskOfMadness.Activate")
		end,
	},
})
modifier_dota688_mom_berserk = class({})
function modifier_dota688_mom_berserk:IsPurgable() return false end
function modifier_dota688_mom_berserk:GetEffectName() return "particles/items2_fx/mask_of_madness.vpcf" end
function modifier_dota688_mom_berserk:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_dota688_mom_berserk:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "berserk_bonus_attack_speed") end
function modifier_dota688_mom_berserk:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "berserk_bonus_movement_speed") end
function modifier_dota688_mom_berserk:GetModifierIncomingDamage_Percentage() return Dota688Val(self, "berserk_extra_damage") end
