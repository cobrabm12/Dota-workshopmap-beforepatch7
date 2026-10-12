-- Sonic Wave (6.88): con 100 -> 450 pe 900 distanta (viteza 900), 290/380/470 daune pure, trece prin imunitatea la magie.
-- Scepter: 325/440/555 daune, cooldown 40.
require("dota688/aghanim")
dota688_queenofpain_sonic_wave = class({})
function dota688_queenofpain_sonic_wave:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetLevelSpecialValueFor("cooldown_scepter", level) end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_queenofpain_sonic_wave:OnSpellStart()
	local caster = self:GetCaster()
	local dir = self:GetCursorPosition() - caster:GetAbsOrigin(); dir.z = 0
	if dir:Length2D() < 1 then dir = caster:GetForwardVector() end
	dir = dir:Normalized()
	caster:EmitSound("Hero_QueenOfPain.SonicWave")
	ProjectileManager:CreateLinearProjectile({
		Ability = self, EffectName = "particles/units/heroes/hero_queenofpain/queen_sonic_wave.vpcf", vSpawnOrigin = caster:GetAbsOrigin(),
		fDistance = self:GetSpecialValueFor("distance"), fStartRadius = self:GetSpecialValueFor("starting_aoe"), fEndRadius = self:GetSpecialValueFor("final_aoe"),
		Source = caster, bHasFrontalCone = true, bReplaceExisting = false, iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		fExpireTime = GameRules:GetGameTime() + 3, bDeleteOnHit = false, vVelocity = dir * self:GetSpecialValueFor("speed"), bProvidesVision = true, iVisionRadius = 300, iVisionTeamNumber = caster:GetTeamNumber(),
	})
end
function dota688_queenofpain_sonic_wave:OnProjectileHit(target, location)
	if not target then return end
	local dmg = Dota688HasScepter(self:GetCaster()) and self:GetSpecialValueFor("damage_scepter") or self:GetSpecialValueFor("damage")
	ApplyDamage({ victim = target, attacker = self:GetCaster(), damage = dmg, damage_type = DAMAGE_TYPE_PURE, ability = self })
end
