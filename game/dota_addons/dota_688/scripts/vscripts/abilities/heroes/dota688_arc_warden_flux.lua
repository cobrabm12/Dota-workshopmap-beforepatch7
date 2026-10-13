-- Flux (6.88): tinta inamica ia 15/30/45/60 daune magice pe secunda (aplicate la fiecare 0.5 s) si este incetinita cu
-- 20/30/40/50% timp de 6 s. Cat timp o alta unitate a echipei tintei este la cel mult 225 de ea, INTREGUL efect (daune si
-- incetinire) este suspendat. Abilitatea curenta suspenda doar daunele; incetinirea ramane mereu activa.
require("dota688/val")
local F = "abilities/heroes/dota688_arc_warden_flux"
LinkLuaModifier("modifier_dota688_arc_warden_flux", F, LUA_MODIFIER_MOTION_NONE)

dota688_arc_warden_flux = class({})
function dota688_arc_warden_flux:GetCastAnimation() return ACT_DOTA_CAST_ABILITY_1 end
function dota688_arc_warden_flux:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	caster:EmitSound("Hero_ArcWarden.Flux.Cast")
	if not target then return end
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_flux_cast.vpcf", PATTACH_CUSTOMORIGIN, caster)
	ParticleManager:SetParticleControlEnt(fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 2, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
	if target:TriggerSpellAbsorb(self) then return end
	target:EmitSound("Hero_ArcWarden.Flux.Target")
	target:AddNewModifier(caster, self, "modifier_dota688_arc_warden_flux", { duration = self:GetSpecialValueFor("duration") })
end

-- stack 1 = efect suspendat (alta unitate aliata a tintei in raza), 0 = activ; stack-ul se replica, deci si incetinirea
-- calculata pe client urmeaza starea
modifier_dota688_arc_warden_flux = class({})
function modifier_dota688_arc_warden_flux:IsDebuff() return true end
function modifier_dota688_arc_warden_flux:IsPurgable() return true end
function modifier_dota688_arc_warden_flux:OnCreated()
	if not IsServer() then return end
	local a, p = self:GetAbility(), self:GetParent()
	self.interval = a:GetSpecialValueFor("think_interval")
	if self.interval <= 0 then self.interval = 0.5 end
	self.dmg = a:GetSpecialValueFor("damage_per_second") * self.interval
	self.radius = a:GetSpecialValueFor("search_radius")
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_arc_warden/arc_warden_flux_tgt.vpcf", PATTACH_ABSORIGIN_FOLLOW, p)
	ParticleManager:SetParticleControlEnt(self.fx, 1, p, PATTACH_POINT_FOLLOW, "attach_hitloc", p:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.fx, 2, p, PATTACH_POINT_FOLLOW, "attach_hitloc", p:GetAbsOrigin(), true)
	self:AddParticle(self.fx, false, false, -1, false, false)
	self:UpdateState()
	self:StartIntervalThink(self.interval)
end
function modifier_dota688_arc_warden_flux:OnRefresh()
	if not IsServer() then return end
	local a = self:GetAbility()
	if a and not a:IsNull() then
		self.dmg = a:GetSpecialValueFor("damage_per_second") * self.interval
		self.radius = a:GetSpecialValueFor("search_radius")
	end
	self:UpdateState()
end
-- o alta unitate (erou sau creep) a echipei tintei in search_radius -> suspendat
function modifier_dota688_arc_warden_flux:UpdateState()
	local p = self:GetParent()
	local muted = false
	for _, u in ipairs(FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)) do
		if u ~= p and u:IsAlive() then muted = true; break end
	end
	self:SetStackCount(muted and 1 or 0)
	if self.fx then ParticleManager:SetParticleControl(self.fx, 4, Vector(muted and 0 or 1, 0, 0)) end
	return not muted
end
function modifier_dota688_arc_warden_flux:OnIntervalThink()
	if not self:UpdateState() then return end
	local a = self:GetAbility()
	local caster = self:GetCaster()
	if not caster or caster:IsNull() then return end
	ApplyDamage({ victim = self:GetParent(), attacker = caster, damage = self.dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = (a and not a:IsNull()) and a or nil })
end
function modifier_dota688_arc_warden_flux:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_arc_warden_flux:GetModifierMoveSpeedBonus_Percentage()
	if self:GetStackCount() > 0 then return 0 end
	return -Dota688Val(self, "move_speed_slow_pct")
end
