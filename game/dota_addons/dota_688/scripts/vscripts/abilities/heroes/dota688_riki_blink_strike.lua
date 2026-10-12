-- Blink Strike (6.88): teleportare in spatele tintei (aliat sau inamic); inamicii primesc +55/70/85/100 daune magice si un atac.
dota688_riki_blink_strike = class({})
function dota688_riki_blink_strike:CastFilterResultTarget(target)
	if target == self:GetCaster() then return UF_FAIL_CUSTOM end
	if target:IsBuilding() or target:IsOther() then return UF_FAIL_CUSTOM end
	if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() and target:IsMagicImmune() then return UF_FAIL_MAGIC_IMMUNE_ENEMY end
	return UF_SUCCESS
end
function dota688_riki_blink_strike:GetCustomCastErrorTarget(target) return "#dota_hud_error_cant_cast_on_self" end
function dota688_riki_blink_strike:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if target:GetTeamNumber() ~= caster:GetTeamNumber() and target:TriggerSpellAbsorb(self) then return end
	local behind = target:GetAbsOrigin() - target:GetForwardVector() * 100
	caster:EmitSound("Hero_Riki.Blink_Strike")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_blink_strike.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	FindClearSpaceForUnit(caster, behind, true)
	caster:SetForwardVector(target:GetForwardVector())
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		ApplyDamage({ victim = target, attacker = caster, damage = self:GetSpecialValueFor("bonus_damage"), damage_type = self:GetAbilityDamageType(), ability = self })
		caster:PerformAttack(target, true, true, true, false, true, false, false)
	end
end
