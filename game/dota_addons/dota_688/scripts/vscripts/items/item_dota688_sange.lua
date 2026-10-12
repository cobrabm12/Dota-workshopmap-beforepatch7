require("items/dota688_item_base")
-- Sange (6.88): +16 STR, +10 daune; Lesser Maim: 20% sansa sa incetineasca 20% MS/AS (10% ranged) 4 s.
LinkLuaModifier("modifier_dota688_maim", "items/item_dota688_sange", LUA_MODIFIER_MOTION_NONE)
local function MaimProc(self, params)
	local target = params.target
	if not target or target:IsBuilding() or target:IsOther() then return end
	local a = self:GetAbility()
	if RollPseudoRandomPercentage(a:GetSpecialValueFor("maim_chance"), DOTA_PSEUDO_RANDOM_ITEM_MAIM, self:GetParent()) then
		target:AddNewModifier(self:GetParent(), a, "modifier_dota688_maim", { duration = a:GetSpecialValueFor("maim_duration") })
	end
end
Dota688DefineItem("item_dota688_sange", "items/item_dota688_sange", { onAttackLanded = MaimProc })
Dota688DefineItem("item_dota688_sange_and_yasha", "items/item_dota688_sange", { onAttackLanded = MaimProc })

modifier_dota688_maim = class({})
function modifier_dota688_maim:IsDebuff() return true end
function modifier_dota688_maim:IsPurgable() return true end
function modifier_dota688_maim:OnCreated()
	local a = self:GetAbility()
	local ranged = self:GetCaster():IsRangedAttacker()
	self.ms = a:GetSpecialValueFor(ranged and "maim_slow_movement_range" or "maim_slow_movement")
	self.as = a:GetSpecialValueFor(ranged and "maim_slow_attack_range" or "maim_slow_attack")
end
function modifier_dota688_maim:OnRefresh() self:OnCreated() end
function modifier_dota688_maim:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_maim:GetModifierMoveSpeedBonus_Percentage() return self.ms end
function modifier_dota688_maim:GetModifierAttackSpeedBonus_Constant() return self.as end
