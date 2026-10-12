-- Fade Bolt (6.88): 75/150/225/300 daune magice, sare la inamicii din 440 (-4% per salt); -20/25/30/35 daune de atac eroilor (-10..-17 creepi) 10 s.
LinkLuaModifier("modifier_dota688_rubick_fade_bolt", "abilities/heroes/dota688_rubick_fade_bolt", LUA_MODIFIER_MOTION_NONE)
dota688_rubick_fade_bolt = class({})
function dota688_rubick_fade_bolt:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	caster:EmitSound("Hero_Rubick.FadeBolt.Cast")
	local hit = {}
	local dmg = self:GetSpecialValueFor("damage")
	local function Bolt(from, t, d)
		if not t or t:IsNull() then return end
		hit[t] = true
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_rubick/rubick_fade_bolt.vpcf", PATTACH_ABSORIGIN_FOLLOW, from)
		ParticleManager:SetParticleControlEnt(fx, 0, from, PATTACH_POINT_FOLLOW, "attach_hitloc", from:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(fx, 1, t, PATTACH_POINT_FOLLOW, "attach_hitloc", t:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(fx)
		t:EmitSound("Hero_Rubick.FadeBolt.Target")
		ApplyDamage({ victim = t, attacker = caster, damage = d, damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
		t:AddNewModifier(caster, self, "modifier_dota688_rubick_fade_bolt", { duration = self:GetSpecialValueFor("duration") })
		Dota688Timers:After(self:GetSpecialValueFor("jump_delay"), function()
			if t:IsNull() then return end
			for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), t:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)) do
				if not hit[e] then Bolt(t, e, d * (1 - self:GetSpecialValueFor("jump_damage_reduction_pct") / 100)); return end
			end
		end)
	end
	Bolt(caster, target, dmg)
end
modifier_dota688_rubick_fade_bolt = class({})
function modifier_dota688_rubick_fade_bolt:IsDebuff() return true end
function modifier_dota688_rubick_fade_bolt:IsPurgable() return true end
function modifier_dota688_rubick_fade_bolt:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE } end
function modifier_dota688_rubick_fade_bolt:GetModifierPreAttack_BonusDamage()
	local a = self:GetAbility()
	return -(self:GetParent():IsHero() and a:GetSpecialValueFor("hero_attack_damage_reduction") or a:GetSpecialValueFor("creep_attack_damage_reduction"))
end
