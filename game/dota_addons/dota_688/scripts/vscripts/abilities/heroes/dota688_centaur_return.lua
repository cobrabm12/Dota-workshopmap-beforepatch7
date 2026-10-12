-- Return (6.88): atacatorii primesc 16/18/20/22 + 30/45/60/75% din STR daune fizice.
LinkLuaModifier("modifier_dota688_centaur_return", "abilities/heroes/dota688_centaur_return", LUA_MODIFIER_MOTION_NONE)
dota688_centaur_return = class({})
function dota688_centaur_return:GetIntrinsicModifierName() return "modifier_dota688_centaur_return" end
modifier_dota688_centaur_return = class({})
function modifier_dota688_centaur_return:IsHidden() return true end
function modifier_dota688_centaur_return:IsPurgable() return false end
function modifier_dota688_centaur_return:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_centaur_return:OnAttackLanded(params)
	if not IsServer() then return end
	local p = self:GetParent()
	if params.target ~= p or p:PassivesDisabled() or not p:IsAlive() then return end
	local att = params.attacker
	if not att or att:IsBuilding() or att:IsOther() or att:GetTeamNumber() == p:GetTeamNumber() then return end
	local a = self:GetAbility()
	if not a or a:IsNull() then return end
	local dmg = a:GetSpecialValueFor("return_damage") + p:GetStrength() * a:GetSpecialValueFor("strength_pct") / 100
	ApplyDamage({ victim = att, attacker = p, damage = dmg, damage_type = DAMAGE_TYPE_PHYSICAL, ability = a })
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_return.vpcf", PATTACH_ABSORIGIN_FOLLOW, att)
	ParticleManager:ReleaseParticleIndex(fx)
end
