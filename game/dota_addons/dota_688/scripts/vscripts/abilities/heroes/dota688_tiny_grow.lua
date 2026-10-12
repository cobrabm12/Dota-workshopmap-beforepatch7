-- Grow (6.88): +50/100/150 daune, -20/35/50 AS, +40/50/60 MS, model mai mare. (Bonusul la Toss ramane in abilitatea built-in Toss.)
-- Scepter (copacul): +85 raza de atac, cleave 50% in raza 400, +75% daune la cladiri.
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_tiny_grow", "abilities/heroes/dota688_tiny_grow", LUA_MODIFIER_MOTION_NONE)
dota688_tiny_grow = class({})
function dota688_tiny_grow:GetIntrinsicModifierName() return "modifier_dota688_tiny_grow" end
function dota688_tiny_grow:OnUpgrade()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_Tiny.Grow")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_grow_hero_effect.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
end

modifier_dota688_tiny_grow = class({})
function modifier_dota688_tiny_grow:IsHidden() return true end
function modifier_dota688_tiny_grow:IsPurgable() return false end
function modifier_dota688_tiny_grow:RemoveOnDeath() return false end
function modifier_dota688_tiny_grow:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MODEL_SCALE,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE, MODIFIER_EVENT_ON_ATTACK_LANDED }
end
function modifier_dota688_tiny_grow:HasTree() return self:GetAbility():GetLevel() > 0 and Dota688HasScepter(self:GetParent()) end
function modifier_dota688_tiny_grow:GetModifierPreAttack_BonusDamage() return self:GetAbility():GetSpecialValueFor("bonus_damage") end
function modifier_dota688_tiny_grow:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("bonus_attack_speed") end
function modifier_dota688_tiny_grow:GetModifierMoveSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("bonus_movement_speed") end
function modifier_dota688_tiny_grow:GetModifierModelScale() return 20 * self:GetAbility():GetLevel() end
function modifier_dota688_tiny_grow:GetModifierAttackRangeBonus()
	if self:HasTree() then return self:GetAbility():GetSpecialValueFor("bonus_range_scepter") end
	return 0
end
function modifier_dota688_tiny_grow:GetModifierDamageOutgoing_Percentage(params)
	if self:HasTree() and params and params.target and params.target:IsBuilding() and params.inflictor == nil then
		return self:GetAbility():GetSpecialValueFor("bonus_building_damage_scepter")
	end
	return 0
end
function modifier_dota688_tiny_grow:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() or not self:HasTree() then return end
	local t = params.target
	if not t or t:IsBuilding() or t:IsOther() or t:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
	local a = self:GetAbility()
	DoCleaveAttack(self:GetParent(), t, a, params.damage * a:GetSpecialValueFor("bonus_cleave_damage_scepter") / 100, 150, a:GetSpecialValueFor("bonus_cleave_radius_scepter"), 460,
		"particles/units/heroes/hero_tiny/tiny_craggy_hit.vpcf")
end
