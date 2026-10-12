-- Darkness (6.88): noapte 50 s; inamicii au viziunea redusa la 675 (ziua si noaptea).
-- Scepter: Night Stalker are viziune neobstructionata (de zbor) pe timp de noapte, indiferent daca a folosit Darkness.
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_ns_darkness_blind", "abilities/heroes/dota688_night_stalker_darkness", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_ns_darkness_scepter", "abilities/heroes/dota688_night_stalker_darkness", LUA_MODIFIER_MOTION_NONE)
dota688_night_stalker_darkness = class({})
function dota688_night_stalker_darkness:GetIntrinsicModifierName() return "modifier_dota688_ns_darkness_scepter" end
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
-- valoarea se memoreaza la creare: efectul dureaza 50 s si poate supravietui abilitatii (Rubick, iluzie)
function modifier_dota688_ns_darkness_blind:OnCreated() self.vision = self:GetAbility() and self:GetAbility():GetSpecialValueFor("fixed_vision") or 675 end
function modifier_dota688_ns_darkness_blind:GetFixedDayVision() return self.vision end
function modifier_dota688_ns_darkness_blind:GetFixedNightVision() return self.vision end

-- Scepter: viziune de zbor noaptea
modifier_dota688_ns_darkness_scepter = class({})
function modifier_dota688_ns_darkness_scepter:IsHidden() return true end
function modifier_dota688_ns_darkness_scepter:IsPurgable() return false end
function modifier_dota688_ns_darkness_scepter:RemoveOnDeath() return false end
function modifier_dota688_ns_darkness_scepter:OnCreated()
	self.flying = false
	if IsServer() then self:StartIntervalThink(0.5) end
end
function modifier_dota688_ns_darkness_scepter:OnIntervalThink()
	local flying = (not GameRules:IsDaytime()) and Dota688HasScepter(self:GetParent())
	if flying ~= self.flying then
		self.flying = flying
		self:SetStackCount(flying and 1 or 0)
	end
end
function modifier_dota688_ns_darkness_scepter:CheckState()
	if self:GetStackCount() > 0 then return { [MODIFIER_STATE_FORCED_FLYING_VISION] = true } end
	return {}
end
