require("items/dota688_item_base")
-- Phase Boots (6.88): +45 MS, +24 daune; Phase: +24% MS (20% ranged) si trece prin unitati 2.5 s, cd 8.
LinkLuaModifier("modifier_dota688_phase", "items/item_dota688_phase_boots", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_phase_boots", "items/item_dota688_phase_boots", {
	item = {
		OnSpellStart = function(self)
			self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_dota688_phase", { duration = self:GetSpecialValueFor("phase_duration") })
			self:GetCaster():EmitSound("DOTA_Item.PhaseBoots.Activate")
		end,
	},
})
modifier_dota688_phase = class({})
function modifier_dota688_phase:IsPurgable() return false end
function modifier_dota688_phase:CheckState() return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true } end
function modifier_dota688_phase:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_EVENT_ON_ATTACK_START } end
function modifier_dota688_phase:GetModifierMoveSpeedBonus_Percentage()
	local a = self:GetAbility()
	return self:GetParent():IsRangedAttacker() and a:GetSpecialValueFor("phase_movement_speed_range") or a:GetSpecialValueFor("phase_movement_speed")
end
function modifier_dota688_phase:OnAttackStart(params)
	if IsServer() and params.attacker == self:GetParent() then self:Destroy() end
end
