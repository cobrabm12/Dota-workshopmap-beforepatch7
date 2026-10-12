-- Howl (6.88): global, 10 s: eroii aliati +14/26/38/50 daune, unitatile aliate +5/10/15/20.
LinkLuaModifier("modifier_dota688_lycan_howl", "abilities/heroes/dota688_lycan_howl", LUA_MODIFIER_MOTION_NONE)
dota688_lycan_howl = class({})
function dota688_lycan_howl:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_Lycan.Howl")
	local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, u in ipairs(units) do
		u:AddNewModifier(caster, self, "modifier_dota688_lycan_howl", { duration = self:GetSpecialValueFor("howl_duration") })
	end
end
modifier_dota688_lycan_howl = class({})
function modifier_dota688_lycan_howl:IsPurgable() return true end
function modifier_dota688_lycan_howl:GetEffectName() return "particles/units/heroes/hero_lycan/lycan_howl_buff.vpcf" end
function modifier_dota688_lycan_howl:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE } end
function modifier_dota688_lycan_howl:GetModifierPreAttack_BonusDamage()
	local a = self:GetAbility()
	if self:GetParent():IsHero() then return a:GetSpecialValueFor("hero_bonus_damage") end
	return a:GetSpecialValueFor("unit_bonus_damage")
end
