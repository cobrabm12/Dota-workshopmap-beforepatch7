-- Anchor Smash (6.88): inamicii din 375 (eroi si creepi, inclusiv ancienti, fara Roshan) iau 75/125/175/225 daune fizice si
-- au daunele de baza reduse cu 45/50/55/60% pentru 6 s. Trece prin imunitatea la magie (6.88: SPELL_IMMUNITY_ENEMIES_YES).
-- Fara atacul modern cu daune bonus (procuri de iteme) si fara raza legata de raza de atac.
require("dota688/val")
local F = "abilities/heroes/dota688_tidehunter_anchor_smash"
LinkLuaModifier("modifier_dota688_tidehunter_anchor_smash", F, LUA_MODIFIER_MOTION_NONE)

dota688_tidehunter_anchor_smash = class({})
function dota688_tidehunter_anchor_smash:GetCastAnimation() return ACT_DOTA_CAST_ABILITY_3 end
function dota688_tidehunter_anchor_smash:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_Tidehunter.AnchorSmash")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_anchor_hero.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	local dmg, dur = self:GetAbilityDamage(), self:GetSpecialValueFor("reduction_duration")
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)) do
		if e:GetUnitName() ~= "npc_dota_roshan" then
			e:AddNewModifier(caster, self, "modifier_dota688_tidehunter_anchor_smash", { duration = dur })
			ApplyDamage({ victim = e, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_PHYSICAL, ability = self })
		end
	end
end

modifier_dota688_tidehunter_anchor_smash = class({})
function modifier_dota688_tidehunter_anchor_smash:IsDebuff() return true end
function modifier_dota688_tidehunter_anchor_smash:IsPurgable() return true end
function modifier_dota688_tidehunter_anchor_smash:DeclareFunctions() return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE } end
function modifier_dota688_tidehunter_anchor_smash:GetModifierBaseDamageOutgoing_Percentage() return Dota688Val(self, "damage_reduction") end
