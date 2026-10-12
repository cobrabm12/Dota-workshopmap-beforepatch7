-- Counter Helix (6.88): 20% sansa (PRD) cand Axe este atacat sa se roteasca, 75/110/145/180 daune pure in raza 275; cooldown 0.45-0.3 s.
LinkLuaModifier("modifier_dota688_axe_counter_helix", "abilities/heroes/dota688_axe_counter_helix", LUA_MODIFIER_MOTION_NONE)

dota688_axe_counter_helix = class({})
function dota688_axe_counter_helix:GetIntrinsicModifierName() return "modifier_dota688_axe_counter_helix" end

modifier_dota688_axe_counter_helix = class({})
function modifier_dota688_axe_counter_helix:IsHidden() return true end
function modifier_dota688_axe_counter_helix:IsPurgable() return false end
function modifier_dota688_axe_counter_helix:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACKED } end
function modifier_dota688_axe_counter_helix:OnAttacked(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	if params.target ~= parent or parent:PassivesDisabled() or not parent:IsAlive() then return end
	local attacker = params.attacker
	if not attacker or attacker:GetTeamNumber() == parent:GetTeamNumber() or attacker:IsBuilding() or attacker:IsOther() then return end
	local ability = self:GetAbility()
	if not ability:IsCooldownReady() then return end
	if not RollPseudoRandomPercentage(ability:GetSpecialValueFor("trigger_chance"), DOTA_PSEUDO_RANDOM_AXE_HELIX, parent) then return end
	ability:UseResources(false, false, false, true)
	parent:EmitSound("Hero_Axe.CounterHelix")
	parent:StartGesture(ACT_DOTA_CAST_ABILITY_3)
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_counterhelix.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:ReleaseParticleIndex(fx)
	local enemies = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil, ability:GetSpecialValueFor("radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _, e in ipairs(enemies) do
		ApplyDamage({ victim = e, attacker = parent, damage = ability:GetAbilityDamage(), damage_type = ability:GetAbilityDamageType(), ability = ability })
	end
end
