-- Finger of Death (6.88): 600/725/850 daune magice dupa 0.25 s. Scepter: 725/875/1025, cooldown 100/60/20, mana 200/420/625, loveste toate unitatile din 300 de tinta.
require("dota688/aghanim")
dota688_lion_finger_of_death = class({})
function dota688_lion_finger_of_death:GetAOERadius()
	if Dota688HasScepter(self:GetCaster()) then return self:GetSpecialValueFor("splash_radius_scepter") end
	return 0
end
function dota688_lion_finger_of_death:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetLevelSpecialValueFor("cooldown_scepter", level) end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_lion_finger_of_death:GetManaCost(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetLevelSpecialValueFor("mana_cost_scepter", level) end
	return self.BaseClass.GetManaCost(self, level)
end
function dota688_lion_finger_of_death:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	local scepter = Dota688HasScepter(caster)
	local dmg = scepter and self:GetSpecialValueFor("damage_scepter") or self:GetSpecialValueFor("damage")
	caster:EmitSound("Hero_Lion.FingerOfDeath")
	local targets = { target }
	if scepter then
		targets = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, self:GetSpecialValueFor("splash_radius_scepter"), DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		if #targets == 0 then targets = { target } end
	end
	for _, t in ipairs(targets) do
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_lion/lion_spell_finger_of_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack2", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(fx, 1, t, PATTACH_POINT_FOLLOW, "attach_hitloc", t:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(fx)
	end
	Dota688Timers:After(self:GetSpecialValueFor("damage_delay"), function()
		for _, t in ipairs(targets) do
			if not t:IsNull() and t:IsAlive() and not t:IsMagicImmune() then
				t:EmitSound("Hero_Lion.FingerOfDeathImpact")
				ApplyDamage({ victim = t, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
			end
		end
	end)
end
