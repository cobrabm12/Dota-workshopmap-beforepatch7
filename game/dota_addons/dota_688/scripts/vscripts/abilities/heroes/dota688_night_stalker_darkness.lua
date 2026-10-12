-- Darkness (6.88): noapte 50 s; inamicii au viziunea redusa la 675 (ziua si noaptea).
LinkLuaModifier("modifier_dota688_ns_darkness_blind", "abilities/heroes/dota688_night_stalker_darkness", LUA_MODIFIER_MOTION_NONE)
dota688_night_stalker_darkness = class({})
function dota688_night_stalker_darkness:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_Nightstalker.Darkness")
	GameRules:BeginNightstalkerNight(self:GetSpecialValueFor("duration"))
	for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)) do
		u:AddNewModifier(caster, self, "modifier_dota688_ns_darkness_blind", { duration = self:GetSpecialValueFor("duration") })
	end
end
modifier_dota688_ns_darkness_blind = class({})
function modifier_dota688_ns_darkness_blind:IsHidden() return true end
function modifier_dota688_ns_darkness_blind:IsPurgable() return false end
function modifier_dota688_ns_darkness_blind:DeclareFunctions() return { MODIFIER_PROPERTY_FIXED_DAY_VISION, MODIFIER_PROPERTY_FIXED_NIGHT_VISION } end
function modifier_dota688_ns_darkness_blind:GetFixedDayVision() return self:GetAbility():GetSpecialValueFor("fixed_vision") end
function modifier_dota688_ns_darkness_blind:GetFixedNightVision() return self:GetAbility():GetSpecialValueFor("fixed_vision") end
