-- Chaos Strike (6.88): 10% sansa de critic 125/175/225/275%; tinta pierde 5 armura pentru 8 s.
local F = "abilities/heroes/dota688_chaos_knight_chaos_strike"
LinkLuaModifier("modifier_dota688_chaos_knight_chaos_strike", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_chaos_knight_chaos_strike_armor", F, LUA_MODIFIER_MOTION_NONE)

dota688_chaos_knight_chaos_strike = class({})
function dota688_chaos_knight_chaos_strike:GetIntrinsicModifierName() return "modifier_dota688_chaos_knight_chaos_strike" end

modifier_dota688_chaos_knight_chaos_strike = class({})
function modifier_dota688_chaos_knight_chaos_strike:IsHidden() return true end
function modifier_dota688_chaos_knight_chaos_strike:IsPurgable() return false end
function modifier_dota688_chaos_knight_chaos_strike:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE, MODIFIER_EVENT_ON_ATTACK_LANDED }
end
function modifier_dota688_chaos_knight_chaos_strike:GetModifierPreAttack_CriticalStrike(params)
	local parent = self:GetParent()
	if parent:PassivesDisabled() or not params.target or params.target:IsBuilding() or params.target:IsOther() then return nil end
	if RollPseudoRandomPercentage(self:GetAbility():GetSpecialValueFor("crit_chance"), DOTA_PSEUDO_RANDOM_CHAOS_CRIT, parent) then
		self.procTarget = params.target
		return self:GetAbility():GetSpecialValueFor("crit_damage")
	end
	return nil
end
function modifier_dota688_chaos_knight_chaos_strike:OnAttackLanded(params)
	if not IsServer() then return end
	if params.attacker ~= self:GetParent() or params.target ~= self.procTarget then return end
	self.procTarget = nil
	params.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dota688_chaos_knight_chaos_strike_armor", { duration = self:GetAbility():GetSpecialValueFor("armor_duration") })
	params.target:EmitSound("Hero_ChaosKnight.ChaosStrike")
end

modifier_dota688_chaos_knight_chaos_strike_armor = class({})
function modifier_dota688_chaos_knight_chaos_strike_armor:IsDebuff() return true end
function modifier_dota688_chaos_knight_chaos_strike_armor:IsPurgable() return true end
function modifier_dota688_chaos_knight_chaos_strike_armor:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function modifier_dota688_chaos_knight_chaos_strike_armor:GetModifierPhysicalArmorBonus() return self:GetAbility():GetSpecialValueFor("armor_reduction") end
