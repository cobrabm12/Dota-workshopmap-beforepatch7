-- Static Storm (6.88): zona 450, 5 s, 20 pulsuri cu daune magice crescatoare pana la 200/250/300/s; inamicii sunt silenced.
-- Scepter: 7 s, 28 pulsuri, si itemele sunt blocate (mute).
require("dota688/aghanim")
local F = "abilities/heroes/dota688_disruptor_static_storm"
LinkLuaModifier("modifier_dota688_static_storm", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_static_storm_debuff", F, LUA_MODIFIER_MOTION_NONE)
dota688_disruptor_static_storm = class({})
function dota688_disruptor_static_storm:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_disruptor_static_storm:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	local scepter = Dota688HasScepter(caster)
	local dur = scepter and self:GetSpecialValueFor("duration_scepter") or self:GetSpecialValueFor("duration")
	caster:EmitSound("Hero_Disruptor.StaticStorm")
	CreateModifierThinker(caster, self, "modifier_dota688_static_storm", { duration = dur, scepter = scepter and 1 or 0 }, pos, caster:GetTeamNumber(), false)
end
modifier_dota688_static_storm = class({})
function modifier_dota688_static_storm:IsHidden() return true end
function modifier_dota688_static_storm:OnCreated(kv)
	if not IsServer() then return end
	local a = self:GetAbility()
	self.scepter = kv.scepter == 1
	self.pulses = self.scepter and a:GetSpecialValueFor("pulses_scepter") or a:GetSpecialValueFor("pulses")
	self.interval = self:GetDuration() / self.pulses
	self.n = 0
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_disruptor/disruptor_static_storm.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.fx, 0, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.fx, 1, Vector(a:GetSpecialValueFor("radius"), self:GetDuration(), a:GetSpecialValueFor("radius")))
	self:StartIntervalThink(self.interval)
end
function modifier_dota688_static_storm:OnIntervalThink()
	local a, caster = self:GetAbility(), self:GetCaster()
	self.n = self.n + 1
	local dmg = a:GetSpecialValueFor("damage_max") * self.interval * math.min(1, self.n / self.pulses)
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, a:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		ApplyDamage({ victim = e, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
		e:AddNewModifier(caster, a, "modifier_dota688_static_storm_debuff", { duration = self.interval + 0.1, scepter = self.scepter and 1 or 0 })
	end
end
function modifier_dota688_static_storm:OnDestroy() if IsServer() then ParticleManager:DestroyParticle(self.fx, false); UTIL_Remove(self:GetParent()) end end
modifier_dota688_static_storm_debuff = class({})
function modifier_dota688_static_storm_debuff:IsDebuff() return true end
function modifier_dota688_static_storm_debuff:IsPurgable() return false end
function modifier_dota688_static_storm_debuff:GetTexture() return "disruptor_static_storm" end
function modifier_dota688_static_storm_debuff:OnCreated(kv) self.scepter = kv.scepter == 1 end
function modifier_dota688_static_storm_debuff:CheckState() return { [MODIFIER_STATE_SILENCED] = true, [MODIFIER_STATE_MUTED] = self.scepter == true } end
