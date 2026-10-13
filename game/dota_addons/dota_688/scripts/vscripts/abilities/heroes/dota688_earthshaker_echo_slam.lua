-- Echo Slam (6.88): 160/210/270 daune magice inamicilor din 600; fiecare inamic lovit (erou, iluzie, creep) creeaza UN ecou
-- care loveste cu 40/55/70 daune magice toti inamicii din 600 in jurul lui, inclusiv pe el insusi. Nu loveste unitatile
-- eterice. Abilitatea curenta creeaza doua ecouri pentru fiecare erou (testat: daune aproape duble pe eroi).

dota688_earthshaker_echo_slam = class({})
local ECHO_SPEED = 1100
local function Ethereal(u) return u:IsAttackImmune() and not u:IsInvulnerable() end   -- Ghost Form / Ethereal Blade / Decrepify
function dota688_earthshaker_echo_slam:OnSpellStart()
	local caster = self:GetCaster()
	local pos = caster:GetAbsOrigin()
	local flags = DOTA_UNIT_TARGET_FLAG_NONE
	local types = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
	local hit = FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, self:GetSpecialValueFor("echo_slam_damage_range"), DOTA_UNIT_TARGET_TEAM_ENEMY, types, flags, FIND_ANY_ORDER, false)
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_echoslam_start.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(fx, 1, Vector(self:GetSpecialValueFor("echo_slam_damage_range"), 0, 0))
	ParticleManager:ReleaseParticleIndex(fx)
	caster:EmitSound(#hit > 0 and "Hero_EarthShaker.EchoSlam" or "Hero_EarthShaker.EchoSlamSmall")
	for _, e in ipairs(hit) do
		if not Ethereal(e) then
			ApplyDamage({ victim = e, attacker = caster, damage = self:GetAbilityDamage(), damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
		end
	end
	-- ecourile: fiecare unitate lovita (vie sau nu) trimite un ecou spre inamicii din jurul ei
	for _, src in ipairs(hit) do
		if not src:IsNull() then
			local spos = src:GetAbsOrigin()
			for _, t in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), spos, nil, self:GetSpecialValueFor("echo_slam_echo_range"), DOTA_UNIT_TARGET_TEAM_ENEMY, types, flags, FIND_ANY_ORDER, false)) do
				ProjectileManager:CreateTrackingProjectile({
					Target = t, Source = src, Ability = self, EffectName = "particles/units/heroes/hero_earthshaker/earthshaker_echoslam.vpcf",
					iMoveSpeed = ECHO_SPEED, vSourceLoc = spos, bDodgeable = false, bProvidesVision = false,
				})
			end
		end
	end
end
function dota688_earthshaker_echo_slam:OnProjectileHit(target, location)
	if not target or target:IsNull() or Ethereal(target) then return end
	target:EmitSound("Hero_EarthShaker.EchoSlamEcho")
	ApplyDamage({ victim = target, attacker = self:GetCaster(), damage = self:GetSpecialValueFor("echo_slam_echo_damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
end
