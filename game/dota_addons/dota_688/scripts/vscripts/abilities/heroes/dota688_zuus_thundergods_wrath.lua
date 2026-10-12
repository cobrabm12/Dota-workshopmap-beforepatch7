-- Thundergod's Wrath (6.88): 225/325/425 daune magice tuturor eroilor inamici de pe harta + true sight 900 / viziune 500 pentru 3 s.
-- Scepter: 440/540/640 daune.
require("dota688/aghanim")
dota688_zuus_thundergods_wrath = class({})
function dota688_zuus_thundergods_wrath:OnSpellStart()
	local caster = self:GetCaster()
	local dmg = Dota688HasScepter(caster) and self:GetSpecialValueFor("damage_scepter") or self:GetSpecialValueFor("damage")
	caster:EmitSound("Hero_Zuus.GodsWrath.PreCast")
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_ANY_ORDER, false)) do
		local pos = e:GetAbsOrigin()
		AddFOWViewer(caster:GetTeamNumber(), pos, self:GetSpecialValueFor("sight_radius_day"), self:GetSpecialValueFor("sight_duration"), false)
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath.vpcf", PATTACH_ABSORIGIN_FOLLOW, e)
		ParticleManager:SetParticleControlEnt(fx, 1, e, PATTACH_POINT_FOLLOW, "attach_hitloc", pos, true)
		ParticleManager:ReleaseParticleIndex(fx)
		if not e:IsMagicImmune() then
			e:EmitSound("Hero_Zuus.GodsWrath.Target")
			ApplyDamage({ victim = e, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
		end
		-- true sight 900 (6.88) in jurul tintei
		CreateModifierThinker(caster, self, "modifier_dota688_truesight_thinker", { duration = self:GetSpecialValueFor("sight_duration"), radius = self:GetSpecialValueFor("true_sight_radius") }, pos, caster:GetTeamNumber(), false)
	end
end
LinkLuaModifier("modifier_dota688_truesight_thinker", "abilities/heroes/dota688_zuus_thundergods_wrath", LUA_MODIFIER_MOTION_NONE)
modifier_dota688_truesight_thinker = class({})
function modifier_dota688_truesight_thinker:IsHidden() return true end
function modifier_dota688_truesight_thinker:OnCreated(kv) if IsServer() then self.radius = kv.radius or 900 end end
function modifier_dota688_truesight_thinker:IsAura() return true end
function modifier_dota688_truesight_thinker:GetAuraRadius() return self.radius or 900 end
function modifier_dota688_truesight_thinker:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_dota688_truesight_thinker:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_truesight_thinker:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_dota688_truesight_thinker:GetModifierAura() return "modifier_truesight" end
function modifier_dota688_truesight_thinker:OnDestroy() if IsServer() then UTIL_Remove(self:GetParent()) end end
