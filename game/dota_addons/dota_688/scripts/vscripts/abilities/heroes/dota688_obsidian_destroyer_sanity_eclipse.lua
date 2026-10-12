-- Sanity's Eclipse (6.88): in raza 375/475/575, fiecare erou inamic ia (INT OD - INT tinta) x 8/9/10 daune magice si pierde 40% din mana maxima.
-- Scepter: eroii afectati primesc si Astral Imprisonment la nivelul curent.
require("dota688/aghanim")
dota688_obsidian_destroyer_sanity_eclipse = class({})
function dota688_obsidian_destroyer_sanity_eclipse:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_obsidian_destroyer_sanity_eclipse:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	caster:EmitSound("Hero_ObsidianDestroyer.SanityEclipse.Cast")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_sanity_eclipse_area.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fx, 0, pos); ParticleManager:SetParticleControl(fx, 1, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(fx)
	EmitSoundOnLocationWithCaster(pos, "Hero_ObsidianDestroyer.SanityEclipse.Target", caster)   -- explozia, o data, in centru
	local scepter = Dota688HasScepter(caster)
	local astral = caster:FindAbilityByName("obsidian_destroyer_astral_imprisonment")
	local mult = scepter and self:GetSpecialValueFor("damage_multiplier_scepter") or self:GetSpecialValueFor("damage_multiplier")
	-- 6.88: "can hit units trapped by Astral Imprisonment" (invulnerabile si in afara lumii)
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)) do
		local imprisoned = e:HasModifier("modifier_obsidian_destroyer_astral_imprisonment_prison")
		if not e:IsMagicImmune() and (imprisoned or not e:IsInvulnerable()) then
			local diff = math.max(0, caster:GetIntellect(true) - (e.GetIntellect and e:GetIntellect(true) or 0))
			ApplyDamage({ victim = e, attacker = caster, damage = diff * mult, damage_type = DAMAGE_TYPE_MAGICAL, ability = self,
				damage_flags = imprisoned and DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY or 0 })
			e:Script_ReduceMana(e:GetMaxMana() * self:GetSpecialValueFor("mana_drain") / 100, self)
			if scepter and astral and astral:GetLevel() > 0 and e:IsAlive() then
				e:AddNewModifier(caster, astral, "modifier_obsidian_destroyer_astral_imprisonment_prison", { duration = astral:GetSpecialValueFor("prison_duration") })
			end
		end
	end
end
