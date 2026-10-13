-- Drunken Haze (6.88): sticla aruncata pe un inamic (proiectil care nu poate fi evitat); inamicii din raza 200 in jurul
-- tintei sunt incetiniti 14/18/22/26% si au 45/55/65/75% sansa sa rateze atacurile, 8 s pe eroi / 12 s pe creepi.
require("dota688/val")
LinkLuaModifier("modifier_dota688_drunken_haze", "abilities/heroes/dota688_brewmaster_drunken_haze", LUA_MODIFIER_MOTION_NONE)
dota688_brewmaster_drunken_haze = class({})
local PROJECTILE_SPEED = 1200   -- nu e in KV-ul 6.88 (valoare din C++); presupusa

function dota688_brewmaster_drunken_haze:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_brewmaster_drunken_haze:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_Brewmaster.DrunkenHaze.Cast")
	ProjectileManager:CreateTrackingProjectile({
		Target = self:GetCursorTarget(), Source = caster, Ability = self,
		EffectName = "particles/units/heroes/hero_brewmaster/brewmaster_drunken_haze_projectile.vpcf",
		iMoveSpeed = PROJECTILE_SPEED, vSourceLoc = caster:GetAbsOrigin(), bDodgeable = false, bProvidesVision = false,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
	})
end
function dota688_brewmaster_drunken_haze:OnProjectileHit(target, location)
	if not target or target:IsNull() then return end
	if target:TriggerSpellAbsorb(self) then return end
	local caster = self:GetCaster()
	target:EmitSound("Hero_Brewmaster.DrunkenHaze.Target")
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		local d = (e:IsHero() or e:IsConsideredHero()) and self:GetSpecialValueFor("duration") or self:GetSpecialValueFor("duration_creeps")
		e:AddNewModifier(caster, self, "modifier_dota688_drunken_haze", { duration = d })
	end
	return true
end

modifier_dota688_drunken_haze = class({})
function modifier_dota688_drunken_haze:IsDebuff() return true end
function modifier_dota688_drunken_haze:IsPurgable() return true end
function modifier_dota688_drunken_haze:GetTexture() return "brewmaster_drunken_haze" end
function modifier_dota688_drunken_haze:GetEffectName() return "particles/units/heroes/hero_brewmaster/brewmaster_drunken_haze_debuff.vpcf" end
function modifier_dota688_drunken_haze:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_drunken_haze:OnCreated()
	self.slow = Dota688Val(self, "movement_slow")
	self.miss = Dota688Val(self, "miss_chance")
end
function modifier_dota688_drunken_haze:OnRefresh() self:OnCreated() end
function modifier_dota688_drunken_haze:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_MISS_PERCENTAGE } end
function modifier_dota688_drunken_haze:GetModifierMoveSpeedBonus_Percentage() return -self.slow end
function modifier_dota688_drunken_haze:GetModifierMiss_Percentage() return self.miss end
