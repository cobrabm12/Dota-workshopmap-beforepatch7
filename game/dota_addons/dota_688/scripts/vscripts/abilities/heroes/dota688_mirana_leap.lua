-- Leap (6.88): Mirana sare inainte 600/700/800/900 (viteza 1600, acceleratie 7000; evita proiectilele); la aterizare ea si
-- unitatile aliate din 775 primesc +4/8/12/16% viteza de miscare si +8/16/24/32 viteza de atac 10 s. Fara incarcaturi (7.x).
require("dota688/val")
local F = "abilities/heroes/dota688_mirana_leap"
LinkLuaModifier("modifier_dota688_mirana_leap", F, LUA_MODIFIER_MOTION_BOTH)
LinkLuaModifier("modifier_dota688_mirana_leap_buff", F, LUA_MODIFIER_MOTION_NONE)
dota688_mirana_leap = class({})
function dota688_mirana_leap:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Ability.Leap")
	ProjectileManager:ProjectileDodge(caster)
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_mirana/mirana_leap_start.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	caster:RemoveModifierByName("modifier_dota688_mirana_leap")
	caster:AddNewModifier(caster, self, "modifier_dota688_mirana_leap", {})
end
function dota688_mirana_leap:Land(caster)
	local dur = self:GetDuration()
	for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("leap_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)) do
		u:AddNewModifier(caster, self, "modifier_dota688_mirana_leap_buff", { duration = dur })   -- include si Mirana
	end
end

-- saritura: viteza initiala leap_speed, creste cu leap_acceleration/s, arc vertical
modifier_dota688_mirana_leap = class({})
function modifier_dota688_mirana_leap:IsHidden() return true end
function modifier_dota688_mirana_leap:IsPurgable() return false end
function modifier_dota688_mirana_leap:OnCreated()
	if not IsServer() then return end
	local p = self:GetParent()
	self.dir = p:GetForwardVector(); self.dir.z = 0
	self.dir = self.dir:Normalized()
	self.start = p:GetAbsOrigin()
	self.distance = Dota688Val(self, "leap_distance")
	self.speed = Dota688Val(self, "leap_speed")
	self.accel = Dota688Val(self, "leap_acceleration")
	self.height = 150
	self.traveled = 0
	if self:ApplyHorizontalMotionController() == false or self:ApplyVerticalMotionController() == false then self:Destroy() end
end
function modifier_dota688_mirana_leap:UpdateHorizontalMotion(me, dt)
	if self.landed then return end
	self.speed = self.speed + self.accel * dt
	self.traveled = math.min(self.distance, self.traveled + self.speed * dt)
	local f = self.distance > 0 and self.traveled / self.distance or 1
	local pos = self.start + self.dir * self.traveled
	local ground = GetGroundPosition(pos, me)
	me:SetAbsOrigin(Vector(ground.x, ground.y, ground.z + self.height * 4 * f * (1 - f)))
	if f >= 1 then self:Land() end
end
function modifier_dota688_mirana_leap:UpdateVerticalMotion(me, dt) end
function modifier_dota688_mirana_leap:OnHorizontalMotionInterrupted() self:Land() end
function modifier_dota688_mirana_leap:OnVerticalMotionInterrupted() end
function modifier_dota688_mirana_leap:Land()
	if self.landed then return end
	self.landed = true
	local me, a = self:GetParent(), self:GetAbility()
	me:SetAbsOrigin(GetGroundPosition(me:GetAbsOrigin(), me))
	if a and not a:IsNull() then a:Land(me) end
	self:Destroy()
end
function modifier_dota688_mirana_leap:OnDestroy()
	if not IsServer() then return end
	local me = self:GetParent()
	me:RemoveHorizontalMotionController(self); me:RemoveVerticalMotionController(self)
	FindClearSpaceForUnit(me, me:GetAbsOrigin(), true)
end
function modifier_dota688_mirana_leap:CheckState() return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true } end
function modifier_dota688_mirana_leap:DeclareFunctions() return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION } end
function modifier_dota688_mirana_leap:GetOverrideAnimation() return ACT_DOTA_CAST_ABILITY_3 end

modifier_dota688_mirana_leap_buff = class({})
function modifier_dota688_mirana_leap_buff:IsPurgable() return true end
function modifier_dota688_mirana_leap_buff:GetTexture() return "mirana_leap" end
function modifier_dota688_mirana_leap_buff:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_mirana_leap_buff:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "leap_speedbonus") end
function modifier_dota688_mirana_leap_buff:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "leap_speedbonus_as") end
