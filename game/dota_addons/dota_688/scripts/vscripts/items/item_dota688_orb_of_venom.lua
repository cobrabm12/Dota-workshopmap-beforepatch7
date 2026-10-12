require("items/dota688_item_base")
-- Orb of Venom (6.88): atacurile otravesc: 3 daune/s, -12% MS (-4% ranged), 4 s.
LinkLuaModifier("modifier_dota688_venom", "items/item_dota688_orb_of_venom", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_orb_of_venom", "items/item_dota688_orb_of_venom", {
	onAttackLanded = function(self, params)
		local target = params.target
		if not target or target:IsBuilding() or target:IsOther() or target:IsMagicImmune() or target:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
		target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dota688_venom", { duration = self:GetAbility():GetSpecialValueFor("poison_duration") })
	end,
})
modifier_dota688_venom = class({})
function modifier_dota688_venom:IsDebuff() return true end
function modifier_dota688_venom:IsPurgable() return true end
function modifier_dota688_venom:OnCreated()
	if IsServer() then self:StartIntervalThink(1.0) end
end
function modifier_dota688_venom:OnIntervalThink()
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = self:GetAbility():GetSpecialValueFor("poison_damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = self:GetAbility() })
end
function modifier_dota688_venom:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_venom:GetModifierMoveSpeedBonus_Percentage()
	local a = self:GetAbility()
	return self:GetCaster():IsRangedAttacker() and a:GetSpecialValueFor("poison_movement_speed_range") or a:GetSpecialValueFor("poison_movement_speed_melee")
end
