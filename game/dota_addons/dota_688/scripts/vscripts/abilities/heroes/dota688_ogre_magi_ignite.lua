-- Ignite (6.88): proiectil (1000) pe un inamic: arde 26/34/42/50 daune magice/s si -20/22/24/26% viteza de miscare, 5/6/7/8 s.
-- Multicast nivel 1/2/3: loveste toti inamicii din 150/300/450 de tinta, +150/300/450 cast range, iar la 2x/3x/4x se mai lanseaza
-- pe inamici aleatori din 1400 (la 0.5 s).
require("dota688/val")
require("abilities/heroes/dota688_ogre_magi_multicast")
LinkLuaModifier("modifier_dota688_ogre_magi_ignite", "abilities/heroes/dota688_ogre_magi_ignite", LUA_MODIFIER_MOTION_NONE)
dota688_ogre_magi_ignite = class({})
function dota688_ogre_magi_ignite:GetCastRange(location, target)
	return self.BaseClass.GetCastRange(self, location, target) + Dota688OgreMulticast.Value(self:GetCaster(), "ignite_cast_range")
end
function dota688_ogre_magi_ignite:GetAOERadius() return Dota688OgreMulticast.Value(self:GetCaster(), "ignite_aoe") end
function dota688_ogre_magi_ignite:Launch(target)
	ProjectileManager:CreateTrackingProjectile({
		Target = target, Source = self:GetCaster(), Ability = self, EffectName = "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite.vpcf",
		iMoveSpeed = self:GetSpecialValueFor("projectile_speed"), bDodgeable = true, bProvidesVision = false,
		iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
	})
end
function dota688_ogre_magi_ignite:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if not target or target:IsNull() then return end
	caster:EmitSound("Hero_OgreMagi.Ignite.Cast")
	self:Launch(target)
	local count = Dota688OgreMulticast.Roll(caster)
	if count < 2 then return end
	local used = { [target:entindex()] = true }
	Dota688OgreMulticast.Repeat(self, count, self:GetSpecialValueFor("multicast_delay"), function(i)
		if caster:IsNull() or not caster:IsAlive() then return end
		local cands = {}
		for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, Dota688OgreMulticast.IGNITE_SEARCH, DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_ANY_ORDER, false)) do
			if not used[e:entindex()] then table.insert(cands, e) end
		end
		if #cands == 0 then return end
		local t = cands[RandomInt(1, #cands)]
		used[t:entindex()] = true
		Dota688OgreMulticast.Effect(caster, i)
		self:Launch(t)
	end)
end
function dota688_ogre_magi_ignite:OnProjectileHit(target, location)
	if not target or target:IsNull() or not target:IsAlive() then return true end
	if target:TriggerSpellAbsorb(self) then return true end
	local caster = self:GetCaster()
	local dur = self:GetSpecialValueFor("duration")
	local radius = Dota688OgreMulticast.Value(caster, "ignite_aoe")
	target:EmitSound("Hero_OgreMagi.Ignite.Target")
	local units = { target }
	if radius > 0 then
		units = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	end
	for _, u in ipairs(units) do
		u:AddNewModifier(caster, self, "modifier_dota688_ogre_magi_ignite", { duration = dur })
	end
	return true
end

modifier_dota688_ogre_magi_ignite = class({})
function modifier_dota688_ogre_magi_ignite:IsDebuff() return true end
function modifier_dota688_ogre_magi_ignite:IsPurgable() return true end
function modifier_dota688_ogre_magi_ignite:GetTexture() return "ogre_magi_ignite" end
function modifier_dota688_ogre_magi_ignite:GetEffectName() return "particles/units/heroes/hero_ogre_magi/ogre_magi_ignite_debuff.vpcf" end
function modifier_dota688_ogre_magi_ignite:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_ogre_magi_ignite:OnCreated()
	if not IsServer() then return end
	self.ticks = 0
	self.maxTicks = math.floor(self:GetDuration() + 0.001)   -- o arsura pe secunda
	self:StartIntervalThink(1.0)
end
function modifier_dota688_ogre_magi_ignite:OnRefresh() self:OnCreated() end
function modifier_dota688_ogre_magi_ignite:OnIntervalThink() self:Burn() end
function modifier_dota688_ogre_magi_ignite:Burn()
	if self.ticks >= self.maxTicks then return end
	self.ticks = self.ticks + 1
	local caster = self:GetCaster()
	if not caster or caster:IsNull() then return end
	local p = self:GetParent()
	p:EmitSound("Hero_OgreMagi.Ignite.Damage")
	ApplyDamage({ victim = p, attacker = caster, damage = Dota688Val(self, "burn_damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = self:GetAbility() })
end
function modifier_dota688_ogre_magi_ignite:OnDestroy()
	if not IsServer() then return end
	-- ultima arsura cade odata cu expirarea (nu si dupa purge / moarte)
	local p = self:GetParent()
	if self.ticks and self.ticks < self.maxTicks and self:GetRemainingTime() <= 0.05 and not p:IsNull() and p:IsAlive() then self:Burn() end
end
function modifier_dota688_ogre_magi_ignite:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_ogre_magi_ignite:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "slow_movement_speed_pct") end
