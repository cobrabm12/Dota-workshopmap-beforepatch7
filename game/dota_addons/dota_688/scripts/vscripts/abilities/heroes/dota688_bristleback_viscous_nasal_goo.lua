-- Viscous Nasal Goo (6.88): proiectil (1000); fiecare lovitura adauga un stack (max 4): -1/1.4/1.8/2.2 armura si -20% -3/6/9/12% viteza per stack, 5 s (10 s pe creepi).
-- Scepter: devine fara tinta si loveste toti inamicii din 700.
require("dota688/val")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_bristleback_viscous_nasal_goo"
LinkLuaModifier("modifier_dota688_nasal_goo", F, LUA_MODIFIER_MOTION_NONE)
dota688_bristleback_viscous_nasal_goo = class({})
function dota688_bristleback_viscous_nasal_goo:GetBehavior()
	if Dota688HasScepter(self:GetCaster()) then return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING end
	return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
end
function dota688_bristleback_viscous_nasal_goo:GetAOERadius() return self:GetSpecialValueFor("radius_scepter") end
function dota688_bristleback_viscous_nasal_goo:Launch(target)
	local caster = self:GetCaster()
	ProjectileManager:CreateTrackingProjectile({
		Target = target, Source = caster, Ability = self,
		EffectName = "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo.vpcf",
		iMoveSpeed = self:GetSpecialValueFor("goo_speed"), vSourceLoc = caster:GetAbsOrigin(), bDodgeable = true, bProvidesVision = false,
	})
end
function dota688_bristleback_viscous_nasal_goo:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_Bristleback.ViscousGoo.Cast")
	if Dota688HasScepter(caster) then
		for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius_scepter"), DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
			self:Launch(e)
		end
	else
		self:Launch(self:GetCursorTarget())
	end
end
function dota688_bristleback_viscous_nasal_goo:OnProjectileHit(target, location)
	if not target or target:IsMagicImmune() then return end
	if target:TriggerSpellAbsorb(self) then return end
	target:EmitSound("Hero_Bristleback.ViscousGoo.Target")
	local dur = target:IsHero() and self:GetSpecialValueFor("goo_duration") or self:GetSpecialValueFor("goo_duration_creep")
	local m = target:FindModifierByName("modifier_dota688_nasal_goo")
	if m then
		m:SetDuration(dur, true)
		m:SetStackCount(math.min(self:GetSpecialValueFor("stack_limit"), m:GetStackCount() + 1))
	else
		m = target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_nasal_goo", { duration = dur })
		if m then m:SetStackCount(1) end
	end
end
modifier_dota688_nasal_goo = class({})
function modifier_dota688_nasal_goo:IsDebuff() return true end
function modifier_dota688_nasal_goo:IsPurgable() return true end
function modifier_dota688_nasal_goo:GetEffectName() return "particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo_debuff.vpcf" end
function modifier_dota688_nasal_goo:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_nasal_goo:GetModifierPhysicalArmorBonus() return -Dota688Val(self, "armor_per_stack") * self:GetStackCount() end
function modifier_dota688_nasal_goo:GetModifierMoveSpeedBonus_Percentage()
	local a = self:GetAbility()
	if not a or a:IsNull() then return 0 end
	return -(a:GetSpecialValueFor("base_move_slow") + a:GetSpecialValueFor("move_slow_per_stack") * self:GetStackCount())
end
