-- Feral Impulse (6.88): aura 900 pentru Lycan si unitatile lui: +15/20/25/30% daune si +15/20/25/30 AS.
local F = "abilities/heroes/dota688_lycan_feral_impulse"
LinkLuaModifier("modifier_dota688_lycan_feral_impulse", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_lycan_feral_impulse_effect", F, LUA_MODIFIER_MOTION_NONE)
dota688_lycan_feral_impulse = class({})
function dota688_lycan_feral_impulse:GetIntrinsicModifierName() return "modifier_dota688_lycan_feral_impulse" end

modifier_dota688_lycan_feral_impulse = class({})
function modifier_dota688_lycan_feral_impulse:IsHidden() return true end
function modifier_dota688_lycan_feral_impulse:IsPurgable() return false end
function modifier_dota688_lycan_feral_impulse:IsAura() return true end
function modifier_dota688_lycan_feral_impulse:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_dota688_lycan_feral_impulse:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_lycan_feral_impulse:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_lycan_feral_impulse:GetModifierAura() return "modifier_dota688_lycan_feral_impulse_effect" end
function modifier_dota688_lycan_feral_impulse:GetAuraEntityReject(unit)
	-- doar Lycan si unitatile controlate de jucatorul lui
	return unit ~= self:GetParent() and unit:GetPlayerOwnerID() ~= self:GetParent():GetPlayerOwnerID()
end

modifier_dota688_lycan_feral_impulse_effect = class({})
function modifier_dota688_lycan_feral_impulse_effect:IsPurgable() return false end
function modifier_dota688_lycan_feral_impulse_effect:DeclareFunctions() return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_lycan_feral_impulse_effect:GetModifierBaseDamageOutgoing_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_damage") end
function modifier_dota688_lycan_feral_impulse_effect:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("bonus_attack_speed") end
