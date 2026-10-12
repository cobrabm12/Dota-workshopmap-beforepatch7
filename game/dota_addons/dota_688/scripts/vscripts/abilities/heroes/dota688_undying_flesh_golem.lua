-- Flesh Golem (6.88): 30 s; aura 750: inamicii iau +1..20/25/30% daune si sunt incetiniti 1..20% (mai mult aproape de Undying); unitatile care mor sub aura vindeca 6% (2% creepi) din HP max.
local F = "abilities/heroes/dota688_undying_flesh_golem"
LinkLuaModifier("modifier_dota688_flesh_golem", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_flesh_golem_plague", F, LUA_MODIFIER_MOTION_NONE)
dota688_undying_flesh_golem = class({})
function dota688_undying_flesh_golem:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_dota688_flesh_golem", { duration = self:GetSpecialValueFor("duration") })
	self:GetCaster():EmitSound("Hero_Undying.FleshGolem.Cast")
end
modifier_dota688_flesh_golem = class({})
function modifier_dota688_flesh_golem:IsPurgable() return false end
function modifier_dota688_flesh_golem:IsAura() return true end
function modifier_dota688_flesh_golem:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_dota688_flesh_golem:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_dota688_flesh_golem:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_flesh_golem:GetModifierAura() return "modifier_dota688_flesh_golem_plague" end
function modifier_dota688_flesh_golem:DeclareFunctions() return { MODIFIER_PROPERTY_MODEL_CHANGE } end
function modifier_dota688_flesh_golem:GetModifierModelChange() return "models/heroes/undying/undying_flesh_golem.vmdl" end
modifier_dota688_flesh_golem_plague = class({})
function modifier_dota688_flesh_golem_plague:IsDebuff() return true end
function modifier_dota688_flesh_golem_plague:IsPurgable() return false end
function modifier_dota688_flesh_golem_plague:GetEffectName() return "particles/units/heroes/hero_undying/undying_fg_debuff.vpcf" end
function modifier_dota688_flesh_golem_plague:Factor()
	local a, c = self:GetAbility(), self:GetCaster()
	if not c or c:IsNull() then return 0 end
	local d = (self:GetParent():GetAbsOrigin() - c:GetAbsOrigin()):Length2D()
	local full, r = a:GetSpecialValueFor("full_power_radius"), a:GetSpecialValueFor("radius")
	if d <= full then return 1 end
	return math.max(0, 1 - (d - full) / math.max(1, r - full))
end
function modifier_dota688_flesh_golem_plague:DeclareFunctions() return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_EVENT_ON_DEATH } end
function modifier_dota688_flesh_golem_plague:GetModifierIncomingDamage_Percentage()
	local a = self:GetAbility(); local f = self:Factor()
	return a:GetSpecialValueFor("min_damage_amp") + (a:GetSpecialValueFor("max_damage_amp") - a:GetSpecialValueFor("min_damage_amp")) * f
end
function modifier_dota688_flesh_golem_plague:GetModifierMoveSpeedBonus_Percentage()
	local a = self:GetAbility(); local f = self:Factor()
	return -(a:GetSpecialValueFor("min_speed_slow") + (a:GetSpecialValueFor("max_speed_slow") - a:GetSpecialValueFor("min_speed_slow")) * f)
end
function modifier_dota688_flesh_golem_plague:OnDeath(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	local c, a = self:GetCaster(), self:GetAbility()
	if not c or c:IsNull() or not c:IsAlive() then return end
	local pct = self:GetParent():IsHero() and a:GetSpecialValueFor("death_heal") or a:GetSpecialValueFor("death_heal_creep")
	c:Heal(c:GetMaxHealth() * pct / 100, a)
end
