-- Culling Blade (6.88): omoara instant tinta sub 250/325/400 HP (si reseteaza cooldown-ul), altfel 150/250/300 daune magice.
-- La kill, Axe si aliatii din 900 primesc +30% viteza de miscare si +30 viteza de atac 6 s. Trece prin imunitatea la magie.
-- Scepter: cooldown 6, prag 300/425/550, bonusul de viteza dureaza 10 s.
require("dota688/aghanim")
local F = "abilities/heroes/dota688_axe_culling_blade"
LinkLuaModifier("modifier_dota688_culling_blade_boost", F, LUA_MODIFIER_MOTION_NONE)
dota688_axe_culling_blade = class({})
function dota688_axe_culling_blade:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetLevelSpecialValueFor("cooldown_scepter", level) end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_axe_culling_blade:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	local scepter = Dota688HasScepter(caster)
	local threshold = scepter and self:GetSpecialValueFor("kill_threshold_scepter") or self:GetSpecialValueFor("kill_threshold")
	if target:GetHealth() <= threshold and not target:IsBuilding() then
		caster:EmitSound("Hero_Axe.Culling_Blade_Success")
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControlEnt(fx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(fx, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(fx)
		target:Kill(self, caster)
		self:EndCooldown()
		local dur = scepter and self:GetSpecialValueFor("speed_duration_scepter") or self:GetSpecialValueFor("speed_duration")
		for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("speed_aoe"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
			u:AddNewModifier(caster, self, "modifier_dota688_culling_blade_boost", { duration = dur })
		end
	else
		caster:EmitSound("Hero_Axe.Culling_Blade_Fail")
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_axe/axe_culling_blade.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControlEnt(fx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(fx, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(fx)
		ApplyDamage({ victim = target, attacker = caster, damage = self:GetSpecialValueFor("damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = self, damage_flags = DOTA_DAMAGE_FLAG_BYPASSES_BLOCK })
	end
end
modifier_dota688_culling_blade_boost = class({})
function modifier_dota688_culling_blade_boost:IsPurgable() return true end
function modifier_dota688_culling_blade_boost:GetEffectName() return "particles/units/heroes/hero_axe/axe_culling_blade_boost.vpcf" end
function modifier_dota688_culling_blade_boost:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_culling_blade_boost:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("speed_bonus") end
function modifier_dota688_culling_blade_boost:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("speed_bonus") end
