-- Moment of Courage (6.88): 25% sansa cand e atacata sa contraatace instant, cu 55/65/75/85% lifesteal pe acel atac. Cooldown 2.3-0.8 s.
local F = "abilities/heroes/dota688_legion_commander_moment_of_courage"
LinkLuaModifier("modifier_dota688_legion_commander_moment_of_courage", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_legion_commander_moment_of_courage_lifesteal", F, LUA_MODIFIER_MOTION_NONE)

dota688_legion_commander_moment_of_courage = class({})
function dota688_legion_commander_moment_of_courage:GetIntrinsicModifierName() return "modifier_dota688_legion_commander_moment_of_courage" end

modifier_dota688_legion_commander_moment_of_courage = class({})
function modifier_dota688_legion_commander_moment_of_courage:IsHidden() return true end
function modifier_dota688_legion_commander_moment_of_courage:IsPurgable() return false end
function modifier_dota688_legion_commander_moment_of_courage:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACKED } end
function modifier_dota688_legion_commander_moment_of_courage:OnAttacked(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	if params.target ~= parent or parent:PassivesDisabled() or not parent:IsAlive() then return end
	local attacker = params.attacker
	if not attacker or attacker:GetTeamNumber() == parent:GetTeamNumber() or attacker:IsBuilding() or attacker:IsOther() then return end
	local ability = self:GetAbility()
	if not ability:IsCooldownReady() or parent:IsDisarmed() or parent:IsStunned() then return end
	if not RollPseudoRandomPercentage(ability:GetSpecialValueFor("trigger_chance"), DOTA_PSEUDO_RANDOM_LEGION_MOMENT, parent) then return end
	ability:UseResources(false, false, false, true)
	parent:AddNewModifier(parent, ability, "modifier_dota688_legion_commander_moment_of_courage_lifesteal", { duration = ability:GetSpecialValueFor("buff_duration") })
	parent:EmitSound("Hero_LegionCommander.Courage")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_legion_commander/legion_commander_courage.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:ReleaseParticleIndex(fx)
	parent:PerformAttack(attacker, true, true, true, false, false, false, false)
end

modifier_dota688_legion_commander_moment_of_courage_lifesteal = class({})
function modifier_dota688_legion_commander_moment_of_courage_lifesteal:IsHidden() return true end
function modifier_dota688_legion_commander_moment_of_courage_lifesteal:IsPurgable() return false end
function modifier_dota688_legion_commander_moment_of_courage_lifesteal:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_legion_commander_moment_of_courage_lifesteal:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() then return end
	local target = params.target
	if not target or target:IsBuilding() or target:IsOther() then return end
	self:GetParent():Heal(params.damage * self:GetAbility():GetSpecialValueFor("hp_leech_percent") / 100, self:GetAbility())
	self:Destroy()
end
