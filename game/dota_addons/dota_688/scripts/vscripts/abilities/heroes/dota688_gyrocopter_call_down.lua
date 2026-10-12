-- Call Down (6.88): doua rachete in acelasi punct (zona 600, raza de cast 1000): prima loveste la 2 s (200/275/350 daune magice,
-- -30% viteza de miscare 2 s), a doua la 4 s (100/150/200 daune magice, -60% viteza de miscare 4 s). Indicatorul e vazut doar de aliati.
-- Scepter 6.88 = Side Gunner (dota688/aghanim_extras.lua), Call Down ramane neschimbat.
-- (Varianta moderna: 3 lovituri in linie, la 500 una de alta - nu exista in 6.88.)
local F = "abilities/heroes/dota688_gyrocopter_call_down"
LinkLuaModifier("modifier_dota688_gyrocopter_call_down", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_gyrocopter_call_down_slow", F, LUA_MODIFIER_MOTION_NONE)

local FIRST_DELAY = 2.0    -- prima racheta
local SECOND_DELAY = 4.0   -- a doua racheta

dota688_gyrocopter_call_down = class({})
function dota688_gyrocopter_call_down:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_gyrocopter_call_down:OnSpellStart()
	local caster, point = self:GetCaster(), self:GetCursorPosition()
	caster:EmitSound("Hero_Gyrocopter.CallDown.Fire")
	CreateModifierThinker(caster, self, "modifier_dota688_gyrocopter_call_down", { duration = SECOND_DELAY + 0.5 }, point, caster:GetTeamNumber(), false)
end

-- thinker in punctul tintit: marcajul pentru aliati, cele doua rachete
modifier_dota688_gyrocopter_call_down = class({})
function modifier_dota688_gyrocopter_call_down:IsHidden() return true end
function modifier_dota688_gyrocopter_call_down:OnCreated()
	if not IsServer() then return end
	local a, caster = self:GetAbility(), self:GetCaster()
	local point = self:GetParent():GetAbsOrigin()
	self.radius = a:GetSpecialValueFor("radius")
	self.missiles = {
		{ damage = a:GetSpecialValueFor("damage_first"), slow = a:GetSpecialValueFor("slow_first"), duration = a:GetSpecialValueFor("slow_duration_first"),
		  fx = "particles/units/heroes/hero_gyrocopter/gyro_calldown_first.vpcf", explosion = "particles/units/heroes/hero_gyrocopter/gyro_calldown_explosion.vpcf" },
		{ damage = a:GetSpecialValueFor("damage_second"), slow = a:GetSpecialValueFor("slow_second"), duration = a:GetSpecialValueFor("slow_duration_second"),
		  fx = "particles/units/heroes/hero_gyrocopter/gyro_calldown_second.vpcf", explosion = "particles/units/heroes/hero_gyrocopter/gyro_calldown_explosion_second.vpcf" },
	}
	self.marker = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_gyrocopter/gyro_calldown_marker.vpcf", PATTACH_WORLDORIGIN, nil, caster:GetTeamNumber())
	ParticleManager:SetParticleControl(self.marker, 0, point)
	ParticleManager:SetParticleControl(self.marker, 1, Vector(self.radius, 1, -self.radius))
	for _, m in ipairs(self.missiles) do
		local fx = ParticleManager:CreateParticle(m.fx, PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControlEnt(fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(fx, 1, point)
		ParticleManager:SetParticleControl(fx, 5, Vector(self.radius, self.radius, self.radius))
		ParticleManager:ReleaseParticleIndex(fx)
	end
	self.hits = 0
	self:StartIntervalThink(FIRST_DELAY)
end
function modifier_dota688_gyrocopter_call_down:OnIntervalThink()
	self.hits = self.hits + 1
	local m = self.missiles[self.hits]
	if m then self:Explode(m) end
	if self.hits >= #self.missiles then self:Destroy() else self:StartIntervalThink(SECOND_DELAY - FIRST_DELAY) end
end
function modifier_dota688_gyrocopter_call_down:Explode(m)
	local a, caster = self:GetAbility(), self:GetCaster()
	local point = self:GetParent():GetAbsOrigin()
	EmitSoundOnLocationWithCaster(point, "Hero_Gyrocopter.CallDown.Damage", self:GetParent())
	local fx = ParticleManager:CreateParticle(m.explosion, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fx, 0, point)
	ParticleManager:SetParticleControl(fx, 1, Vector(self.radius, self.radius, self.radius))
	ParticleManager:ReleaseParticleIndex(fx)
	if not caster or caster:IsNull() then return end
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), point, nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		ApplyDamage({ victim = e, attacker = caster, damage = m.damage, damage_type = DAMAGE_TYPE_MAGICAL, ability = (a and not a:IsNull()) and a or nil })
		if e:IsAlive() then
			local slow = e:AddNewModifier(caster, (a and not a:IsNull()) and a or nil, "modifier_dota688_gyrocopter_call_down_slow", { duration = m.duration })
			if slow then slow:SetStackCount(m.slow) end
		end
	end
end
function modifier_dota688_gyrocopter_call_down:OnDestroy()
	if not IsServer() then return end
	if self.marker then ParticleManager:DestroyParticle(self.marker, false); ParticleManager:ReleaseParticleIndex(self.marker) end
	UTIL_Remove(self:GetParent())
end

-- incetinirea (stack count = procentul rachetei care a lovit ultima)
modifier_dota688_gyrocopter_call_down_slow = class({})
function modifier_dota688_gyrocopter_call_down_slow:IsDebuff() return true end
function modifier_dota688_gyrocopter_call_down_slow:IsPurgable() return true end
function modifier_dota688_gyrocopter_call_down_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_gyrocopter_call_down_slow:GetModifierMoveSpeedBonus_Percentage() return -self:GetStackCount() end
