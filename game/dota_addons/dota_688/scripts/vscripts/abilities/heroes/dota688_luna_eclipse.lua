-- Eclipse (6.88): 5/8/11 Lucent Beams (nivelul curent) la 0.6 s pe inamici aleatori din 675 (max 5 lovituri pe unitate).
-- Scepter: 6/12/18 raze la 0.3 s, fara limita pe unitate; poate fi aruncat pe un aliat/pe Luna (razele il urmeaza) sau pe o zona (raza de cast 2500).
require("dota688/aghanim")
require("dota688/stun")
LinkLuaModifier("modifier_dota688_eclipse", "abilities/heroes/dota688_luna_eclipse", LUA_MODIFIER_MOTION_NONE)
dota688_luna_eclipse = class({})
function dota688_luna_eclipse:GetBehavior()
	if Dota688HasScepter(self:GetCaster()) then return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE end
	return DOTA_ABILITY_BEHAVIOR_NO_TARGET
end
function dota688_luna_eclipse:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_luna_eclipse:GetCastRange(location, target)
	if Dota688HasScepter(self:GetCaster()) then return self:GetSpecialValueFor("cast_range_tooltip_scepter") end
	return 0
end
function dota688_luna_eclipse:OnSpellStart()
	local caster = self:GetCaster()
	local scepter = Dota688HasScepter(caster)
	local target = caster
	if scepter then target = self:GetCursorTarget() end   -- nil = aruncat pe o zona
	local pos = (not target) and self:GetCursorPosition() or nil
	caster:EmitSound("Hero_Luna.Eclipse.Cast")
	local beams = scepter and self:GetSpecialValueFor("beams_scepter") or self:GetSpecialValueFor("beams")
	local interval = scepter and self:GetSpecialValueFor("beam_interval_scepter") or self:GetSpecialValueFor("beam_interval")
	local kv = { duration = beams * interval + 0.1, beams = beams, interval = interval, hits = scepter and 9999 or self:GetSpecialValueFor("hit_count") }
	if target then
		target:AddNewModifier(caster, self, "modifier_dota688_eclipse", kv)
	else
		CreateModifierThinker(caster, self, "modifier_dota688_eclipse", kv, pos, caster:GetTeamNumber(), false)
	end
end
modifier_dota688_eclipse = class({})
function modifier_dota688_eclipse:IsHidden() return false end
function modifier_dota688_eclipse:IsPurgable() return false end
function modifier_dota688_eclipse:GetTexture() return "luna_eclipse" end
function modifier_dota688_eclipse:OnCreated(kv)
	if not IsServer() then return end
	self.left, self.hitsMax, self.hits = kv.beams, kv.hits, {}
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_luna/luna_eclipse_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	self:StartIntervalThink(kv.interval)
end
function modifier_dota688_eclipse:OnIntervalThink()
	local a, caster, p = self:GetAbility(), self:GetCaster(), self:GetParent()
	if self.left <= 0 then self:Destroy() return end
	self.left = self.left - 1
	local beam = caster:FindAbilityByName("luna_lucent_beam")
	if not beam or beam:GetLevel() < 1 then return end
	local cands = {}
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), p:GetAbsOrigin(), nil, a:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if (self.hits[e:entindex()] or 0) < self.hitsMax then table.insert(cands, e) end
	end
	if #cands == 0 then
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_luna/luna_eclipse_impact_notarget.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(fx, 0, p:GetAbsOrigin() + RandomVector(RandomFloat(100, a:GetSpecialValueFor("radius"))))
		ParticleManager:ReleaseParticleIndex(fx)
		return
	end
	local e = cands[RandomInt(1, #cands)]
	self.hits[e:entindex()] = (self.hits[e:entindex()] or 0) + 1
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_luna/luna_eclipse_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, e)
	ParticleManager:ReleaseParticleIndex(fx)
	e:EmitSound("Hero_Luna.Eclipse.Target")
	ApplyDamage({ victim = e, attacker = caster, damage = beam:GetAbilityDamage(), damage_type = DAMAGE_TYPE_MAGICAL, ability = beam })
	Dota688Stun(e, caster, beam, beam:GetSpecialValueFor("stun_duration"))
end
function modifier_dota688_eclipse:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.fx, false)
	local p = self:GetParent()
	if p:GetUnitName() == "npc_dota_thinker" then UTIL_Remove(p) end
end
