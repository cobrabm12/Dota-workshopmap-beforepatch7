require("dota688/val")
require("items/dota688_item_base")
-- Orb of Venom (6.88): atacurile otravesc: 3 daune/s, -12% MS (-4% ranged), 4 s.
LinkLuaModifier("modifier_dota688_venom", "items/item_dota688_orb_of_venom", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_orb_of_venom", "items/item_dota688_orb_of_venom", {
	onAttackLanded = function(self, params)
		local target = params.target
		if not target or target:IsBuilding() or target:IsOther() or target:IsMagicImmune() or target:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
		-- otrava e Unique Attack Modifier (6.88): se aplica doar daca itemul castiga atacul (dota688/uam.lua)
		local parent, a, dur = self:GetParent(), self:GetAbility(), Dota688Val(self, "poison_duration")
		Dota688UAM:Queue(parent, target, a, function()
			if target:IsNull() or not target:IsAlive() or a:IsNull() or parent:IsNull() then return end
			target:AddNewModifier(parent, a, "modifier_dota688_venom", { duration = dur })
		end)
	end,
})
modifier_dota688_venom = class({})
function modifier_dota688_venom:IsDebuff() return true end
function modifier_dota688_venom:IsPurgable() return true end
function modifier_dota688_venom:OnCreated()
	if IsServer() then self:StartIntervalThink(1.0) end
end
function modifier_dota688_venom:OnIntervalThink()
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = Dota688Val(self, "poison_damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = self:GetAbility() })
end
function modifier_dota688_venom:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_venom:GetModifierMoveSpeedBonus_Percentage()
	local a = self:GetAbility()
	if not a or a:IsNull() then return 0 end
	return self:GetCaster():IsRangedAttacker() and a:GetSpecialValueFor("poison_movement_speed_range") or a:GetSpecialValueFor("poison_movement_speed_melee")
end
