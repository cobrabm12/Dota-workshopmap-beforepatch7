-- Guardian Angel (6.88): aliatii din 600 primesc imunitate la daune fizice 6/7/8 s. Scepter: 8/9/10 s, global si afecteaza si cladirile.
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_guardian_angel", "abilities/heroes/dota688_omniknight_guardian_angel", LUA_MODIFIER_MOTION_NONE)
dota688_omniknight_guardian_angel = class({})
function dota688_omniknight_guardian_angel:OnSpellStart()
	local caster = self:GetCaster()
	local scepter = Dota688HasScepter(caster)
	local dur = scepter and self:GetSpecialValueFor("duration_scepter") or self:GetSpecialValueFor("duration")
	caster:EmitSound("Hero_Omniknight.GuardianAngel.Cast")
	local radius = scepter and FIND_UNITS_EVERYWHERE or self:GetSpecialValueFor("radius")
	local types = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + (scepter and DOTA_UNIT_TARGET_BUILDING or 0)
	for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, types, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)) do
		u:AddNewModifier(caster, self, "modifier_dota688_guardian_angel", { duration = dur })
	end
end
modifier_dota688_guardian_angel = class({})
function modifier_dota688_guardian_angel:IsPurgable() return true end
function modifier_dota688_guardian_angel:GetEffectName() return "particles/units/heroes/hero_omniknight/omniknight_guardian_angel_ally.vpcf" end
function modifier_dota688_guardian_angel:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_guardian_angel:DeclareFunctions() return { MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_PERCENTAGE } end
function modifier_dota688_guardian_angel:GetModifierIncomingPhysicalDamage_Percentage() return -100 end
