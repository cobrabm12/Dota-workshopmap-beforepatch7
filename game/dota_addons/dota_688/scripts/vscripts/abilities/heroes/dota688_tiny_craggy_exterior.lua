-- Craggy Exterior (6.88): +2/3/4/5 armura; atacatorii melee din raza 300 au 10/15/20/25% sansa sa fie stun-ati 1-1.75 s si sa ia 25-55 daune magice.
LinkLuaModifier("modifier_dota688_tiny_craggy_exterior", "abilities/heroes/dota688_tiny_craggy_exterior", LUA_MODIFIER_MOTION_NONE)
dota688_tiny_craggy_exterior = class({})
function dota688_tiny_craggy_exterior:GetIntrinsicModifierName() return "modifier_dota688_tiny_craggy_exterior" end

modifier_dota688_tiny_craggy_exterior = class({})
function modifier_dota688_tiny_craggy_exterior:IsHidden() return true end
function modifier_dota688_tiny_craggy_exterior:IsPurgable() return false end
function modifier_dota688_tiny_craggy_exterior:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_tiny_craggy_exterior:GetModifierPhysicalArmorBonus()
	if self:GetParent():PassivesDisabled() then return 0 end
	return self:GetAbility():GetSpecialValueFor("bonus_armor")
end
function modifier_dota688_tiny_craggy_exterior:OnAttackLanded(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	if params.target ~= parent or parent:PassivesDisabled() then return end
	local attacker = params.attacker
	if not attacker or attacker:IsBuilding() or attacker:IsOther() or attacker:GetTeamNumber() == parent:GetTeamNumber() then return end
	if (attacker:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D() > self:GetAbility():GetSpecialValueFor("radius") then return end
	if attacker:IsMagicImmune() then return end
	local a = self:GetAbility()
	if not RollPseudoRandomPercentage(a:GetSpecialValueFor("stun_chance"), DOTA_PSEUDO_RANDOM_TINY_CRAGGY, parent) then return end
	attacker:AddNewModifier(parent, a, "modifier_stunned", { duration = a:GetSpecialValueFor("stun_duration") })
	ApplyDamage({ victim = attacker, attacker = parent, damage = a:GetAbilityDamage(), damage_type = a:GetAbilityDamageType(), ability = a })
	attacker:EmitSound("Hero_Tiny.CraggyExterior")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_craggy_exterior.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
	ParticleManager:ReleaseParticleIndex(fx)
end
