-- Adaptive Strike (6.88): un singur proiectil; daunele cresc cu AGI, stun-ul si knockback-ul cresc cu STR.
-- Daca AGI >= 150% STR: daune maxime / stun minim; daca STR >= 150% AGI: stun maxim / daune minime; intre: liniar.
dota688_morphling_adaptive_strike = class({})

function dota688_morphling_adaptive_strike:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	caster:EmitSound("Hero_Morphling.AdaptiveStrike")
	ProjectileManager:CreateTrackingProjectile({
		Target = target, Source = caster, Ability = self,
		EffectName = "particles/units/heroes/hero_morphling/morphling_adaptive_strike.vpcf",
		iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
		bDodgeable = true, bProvidesVision = false,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
	})
end

function dota688_morphling_adaptive_strike:OnProjectileHit(target, location)
	if not target or target:IsNull() then return end
	local caster = self:GetCaster()
	local agi, str = caster:GetAgility(), caster:GetStrength()
	local ratio = (str > 0) and (agi / str) or 2
	-- t = 0 -> complet STR, t = 1 -> complet AGI
	local t
	if ratio >= 1.5 then t = 1
	elseif ratio <= 1 / 1.5 then t = 0
	else t = (ratio - 1 / 1.5) / (1.5 - 1 / 1.5) end
	local function lerp(a, b, x) return a + (b - a) * x end
	local dmgMult = lerp(self:GetSpecialValueFor("damage_min"), self:GetSpecialValueFor("damage_max"), t)
	local stun = lerp(self:GetSpecialValueFor("stun_max"), self:GetSpecialValueFor("stun_min"), t)
	local knock = lerp(self:GetSpecialValueFor("knockback_max"), self:GetSpecialValueFor("knockback_min"), t)
	local damage = self:GetSpecialValueFor("damage_base") + agi * dmgMult

	target:EmitSound("Hero_Morphling.AdaptiveStrike_Impact")
	ApplyDamage({ victim = target, attacker = caster, damage = damage, damage_type = self:GetAbilityDamageType(), ability = self })
	if target:IsAlive() then
		target:AddNewModifier(caster, self, "modifier_stunned", { duration = stun })
		target:AddNewModifier(caster, self, "modifier_knockback", {
			duration = stun, knockback_duration = stun, knockback_distance = knock, knockback_height = 0,
			center_x = caster:GetAbsOrigin().x, center_y = caster:GetAbsOrigin().y, center_z = caster:GetAbsOrigin().z,
		})
	end
	return true
end
