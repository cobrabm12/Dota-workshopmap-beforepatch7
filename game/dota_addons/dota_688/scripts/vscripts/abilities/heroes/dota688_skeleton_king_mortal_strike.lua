-- Mortal Strike (6.88): 15% sansa de critic 150/200/250/300% (200-500% pe creepi).
LinkLuaModifier("modifier_dota688_skeleton_king_mortal_strike", "abilities/heroes/dota688_skeleton_king_mortal_strike", LUA_MODIFIER_MOTION_NONE)
dota688_skeleton_king_mortal_strike = class({})
function dota688_skeleton_king_mortal_strike:GetIntrinsicModifierName() return "modifier_dota688_skeleton_king_mortal_strike" end
modifier_dota688_skeleton_king_mortal_strike = class({})
function modifier_dota688_skeleton_king_mortal_strike:IsHidden() return true end
function modifier_dota688_skeleton_king_mortal_strike:IsPurgable() return false end
function modifier_dota688_skeleton_king_mortal_strike:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE } end
function modifier_dota688_skeleton_king_mortal_strike:GetModifierPreAttack_CriticalStrike(params)
	local parent, t = self:GetParent(), params.target
	if parent:PassivesDisabled() or not t or t:IsBuilding() or t:IsOther() then return nil end
	local a = self:GetAbility()
	if not a or a:IsNull() then return 0 end
	if RollPseudoRandomPercentage(a:GetSpecialValueFor("crit_chance"), DOTA_PSEUDO_RANDOM_SKELETONKING_CRIT, parent) then
		if IsServer() then t:EmitSound("Hero_SkeletonKing.CriticalStrike") end
		return t:IsHero() and a:GetSpecialValueFor("crit_mult") or a:GetSpecialValueFor("crit_mult_creeps")
	end
	return nil
end
