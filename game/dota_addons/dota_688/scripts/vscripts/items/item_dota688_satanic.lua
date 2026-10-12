require("dota688/val")
require("items/dota688_item_base")
-- Satanic (6.88): +20 daune, +25 STR, +5 armura, 25% lifesteal; Unholy Rage: +175% lifesteal 4.5 s, cd 35.
LinkLuaModifier("modifier_dota688_satanic_unholy", "items/item_dota688_satanic", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_satanic", "items/item_dota688_satanic", {
	item = {
		OnSpellStart = function(self)
			self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_dota688_satanic_unholy", { duration = self:GetSpecialValueFor("unholy_duration") })
			self:GetCaster():EmitSound("DOTA_Item.Satanic.Activate")
		end,
	},
})
modifier_dota688_satanic_unholy = class({})
function modifier_dota688_satanic_unholy:IsPurgable() return false end
function modifier_dota688_satanic_unholy:GetEffectName() return "particles/items2_fx/satanic_buff.vpcf" end
function modifier_dota688_satanic_unholy:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_satanic_unholy:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() then return end
	local target = params.target
	if not target or target:IsBuilding() or target:IsOther() then return end
	self:GetParent():Heal(params.damage * Dota688Val(self, "unholy_lifesteal_percent") / 100, self:GetAbility())
end
