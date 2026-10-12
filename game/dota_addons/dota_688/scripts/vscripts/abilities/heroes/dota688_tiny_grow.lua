-- Grow (6.88): +50/100/150 daune, -20/35/50 AS, +40/50/60 MS, model mai mare. (Bonusul la Toss ramane in abilitatea built-in Toss.)
LinkLuaModifier("modifier_dota688_tiny_grow", "abilities/heroes/dota688_tiny_grow", LUA_MODIFIER_MOTION_NONE)
dota688_tiny_grow = class({})
function dota688_tiny_grow:GetIntrinsicModifierName() return "modifier_dota688_tiny_grow" end
function dota688_tiny_grow:OnUpgrade()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_Tiny.Grow")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_grow.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
end

modifier_dota688_tiny_grow = class({})
function modifier_dota688_tiny_grow:IsHidden() return true end
function modifier_dota688_tiny_grow:IsPurgable() return false end
function modifier_dota688_tiny_grow:RemoveOnDeath() return false end
function modifier_dota688_tiny_grow:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MODEL_SCALE }
end
function modifier_dota688_tiny_grow:GetModifierPreAttack_BonusDamage() return self:GetAbility():GetSpecialValueFor("bonus_damage") end
function modifier_dota688_tiny_grow:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("bonus_attack_speed") end
function modifier_dota688_tiny_grow:GetModifierMoveSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("bonus_movement_speed") end
function modifier_dota688_tiny_grow:GetModifierModelScale() return 20 * self:GetAbility():GetLevel() end
