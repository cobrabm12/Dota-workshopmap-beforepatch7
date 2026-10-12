-- Empower (6.88): +20/30/40/50% daune si cleave 20/30/40/50% in raza 240 (melee) pentru 40 s.
-- Scepter: Empower devine si aura (raza 900) pentru eroii aliati; eroii la distanta primesc jumatate din valori si
-- atacurile lor fac splash 10/15/20/25% in raza 240 in jurul tintei. Poate fi dat in continuare pe unitati.
require("dota688/aghanim")
local F = "abilities/heroes/dota688_magnataur_empower"
LinkLuaModifier("modifier_dota688_magnataur_empower", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_magnataur_empower_aura", F, LUA_MODIFIER_MOTION_NONE)
dota688_magnataur_empower = class({})
function dota688_magnataur_empower:GetIntrinsicModifierName() return "modifier_dota688_magnataur_empower_aura" end
function dota688_magnataur_empower:OnSpellStart()
	local target = self:GetCursorTarget()
	target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_magnataur_empower", { duration = self:GetSpecialValueFor("empower_duration") })
	target:EmitSound("Hero_Magnataur.Empower.Cast")
end

modifier_dota688_magnataur_empower = class({})
function modifier_dota688_magnataur_empower:IsPurgable() return true end
function modifier_dota688_magnataur_empower:GetEffectName() return "particles/units/heroes/hero_magnataur/magnataur_empower.vpcf" end
function modifier_dota688_magnataur_empower:DeclareFunctions() return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_magnataur_empower:Halved()
	return self:GetParent():IsRangedAttacker() and Dota688HasScepter(self:GetCaster())
end
function modifier_dota688_magnataur_empower:GetModifierBaseDamageOutgoing_Percentage()
	local v = self:GetAbility():GetSpecialValueFor("bonus_damage_pct")
	if self:Halved() then v = v / 2 end
	return v
end
function modifier_dota688_magnataur_empower:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() then return end
	local t = params.target
	if not t or t:IsBuilding() or t:IsOther() or t:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
	local a = self:GetAbility()
	if not a or a:IsNull() then return end
	if self:GetParent():IsRangedAttacker() then
		if not Dota688HasScepter(self:GetCaster()) then return end
		-- splash in jurul tintei (scepter)
		for _, e in ipairs(FindUnitsInRadius(self:GetParent():GetTeamNumber(), t:GetAbsOrigin(), nil, a:GetSpecialValueFor("splash_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
			if e ~= t then
				ApplyDamage({ victim = e, attacker = self:GetParent(), damage = params.damage * a:GetSpecialValueFor("splash_damage_pct") / 100, damage_type = DAMAGE_TYPE_PHYSICAL, ability = a })
			end
		end
		return
	end
	DoCleaveAttack(self:GetParent(), t, a, params.damage * a:GetSpecialValueFor("cleave_damage_pct") / 100, 150, a:GetSpecialValueFor("cleave_radius"), 460, "particles/units/heroes/hero_magnataur/magnataur_empower_cleave_effect.vpcf")
end

-- Scepter: aura pe eroii aliati
modifier_dota688_magnataur_empower_aura = class({})
function modifier_dota688_magnataur_empower_aura:IsHidden() return true end
function modifier_dota688_magnataur_empower_aura:IsPurgable() return false end
function modifier_dota688_magnataur_empower_aura:RemoveOnDeath() return false end
function modifier_dota688_magnataur_empower_aura:IsAura() return self:GetAbility():GetLevel() > 0 and Dota688HasScepter(self:GetParent()) end
function modifier_dota688_magnataur_empower_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("aura_radius") end
function modifier_dota688_magnataur_empower_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_magnataur_empower_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_dota688_magnataur_empower_aura:GetModifierAura() return "modifier_dota688_magnataur_empower" end
function modifier_dota688_magnataur_empower_aura:GetAuraEntityReject(unit)
	-- nu suprascriem un Empower dat direct (cu durata)
	local m = unit:FindModifierByName("modifier_dota688_magnataur_empower")
	return m ~= nil and m:GetDuration() > 0
end
