-- Void (6.88): 90/160/255/335 daune magice, -50% MS si -50 AS pentru 2 s ziua / 2.5-4 s noaptea, plus un mini-stun care
-- intrerupe canalizarile si TP-ul si ziua (abilitatea curenta da mini-stun doar noaptea).
require("dota688/val")
local F = "abilities/heroes/dota688_night_stalker_void"
LinkLuaModifier("modifier_dota688_night_stalker_void", F, LUA_MODIFIER_MOTION_NONE)

dota688_night_stalker_void = class({})
function dota688_night_stalker_void:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if not target or target:TriggerSpellAbsorb(self) then return end
	target:EmitSound("Hero_Nightstalker.Void")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_night_stalker/nightstalker_void.vpcf", PATTACH_POINT_FOLLOW, target)
	ParticleManager:ReleaseParticleIndex(fx)
	local night = not GameRules:IsDaytime()
	local dur = night and self:GetSpecialValueFor("duration_night") or self:GetSpecialValueFor("duration_day")
	target:AddNewModifier(caster, self, "modifier_stunned", { duration = 0.01 })   -- mini-stun (intrerupe canalizarile)
	target:AddNewModifier(caster, self, "modifier_dota688_night_stalker_void", { duration = dur })
	ApplyDamage({ victim = target, attacker = caster, damage = self:GetAbilityDamage(), damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
end

modifier_dota688_night_stalker_void = class({})
function modifier_dota688_night_stalker_void:IsDebuff() return true end
function modifier_dota688_night_stalker_void:IsPurgable() return true end
function modifier_dota688_night_stalker_void:GetEffectName() return "particles/units/heroes/hero_night_stalker/nightstalker_void.vpcf" end
function modifier_dota688_night_stalker_void:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_night_stalker_void:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "movespeed_slow") end
function modifier_dota688_night_stalker_void:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "attackspeed_slow") end
