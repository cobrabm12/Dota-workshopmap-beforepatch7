-- Rolling Boulder (6.88): dupa 0.6 s Earth Spirit se rostogoleste 800 (viteza 800) spre punctul tintit si da 100 daune magice
-- inamicilor atinsi (raza 150); se opreste cand loveste un erou inamic sau cand e stunat / hexat. Daca trece peste un
-- Stone Remnant (care e consumat), merge pana la 1600 cu viteza 1600, iar inamicii atinsi sunt incetiniti 80% pentru
-- 1.4/1.6/1.8/2.0 s. Fara stun (abilitatea curenta stuneaza 0.3-0.9 s si nu mai incetineste).
require("dota688/val")
local F = "abilities/heroes/dota688_earth_spirit_rolling_boulder"
LinkLuaModifier("modifier_dota688_rolling_boulder", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_rolling_boulder_slow", F, LUA_MODIFIER_MOTION_NONE)
local TICK = 0.03

dota688_earth_spirit_rolling_boulder = class({})
function dota688_earth_spirit_rolling_boulder:OnSpellStart()
	local caster = self:GetCaster()
	local dir = self:GetCursorPosition() - caster:GetAbsOrigin(); dir.z = 0
	if dir:Length2D() < 1 then dir = caster:GetForwardVector() end
	dir = dir:Normalized()
	caster:EmitSound("Hero_EarthSpirit.RollingBoulder.Cast")
	caster:AddNewModifier(caster, self, "modifier_dota688_rolling_boulder", { duration = 5, dx = dir.x, dy = dir.y })
end

modifier_dota688_rolling_boulder = class({})
function modifier_dota688_rolling_boulder:IsHidden() return true end
function modifier_dota688_rolling_boulder:IsPurgable() return false end
function modifier_dota688_rolling_boulder:CheckState()
	return { [MODIFIER_STATE_COMMAND_RESTRICTED] = true, [MODIFIER_STATE_DISARMED] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end
function modifier_dota688_rolling_boulder:DeclareFunctions() return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION } end
function modifier_dota688_rolling_boulder:GetOverrideAnimation() return ACT_DOTA_CAST_ABILITY_2 end
function modifier_dota688_rolling_boulder:OnCreated(kv)
	if not IsServer() then return end
	local a = self:GetAbility()
	self.dir = Vector(kv.dx, kv.dy, 0)
	self.delay = a:GetSpecialValueFor("delay")
	self.speed = a:GetSpecialValueFor("speed")
	self.maxDist = a:GetSpecialValueFor("distance")
	self.radius = a:GetSpecialValueFor("radius")
	self.travelled = 0
	self.rock = false
	self.hit = {}
	self.elapsed = 0
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_earth_spirit/espirit_rollingboulder.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	self:StartIntervalThink(TICK)
end
function modifier_dota688_rolling_boulder:Stop()
	self:StartIntervalThink(-1)
	self:Destroy()
end
function modifier_dota688_rolling_boulder:OnIntervalThink()
	local p, a = self:GetParent(), self:GetAbility()
	if not a or a:IsNull() or not p:IsAlive() then return self:Stop() end
	self.elapsed = self.elapsed + TICK
	if self.elapsed < self.delay then return end
	if not self.rolling then
		self.rolling = true
		p:EmitSound("Hero_EarthSpirit.RollingBoulder.Loop")
	end
	-- stun / hex / root opresc bolovanul (6.88)
	if p:IsStunned() or p:IsHexed() or p:IsRooted() then return self:Stop() end
	-- Stone Remnant pe drum: e consumat, bolovanul merge mai departe si mai repede, iar loviturile incetinesc
	if not self.rock then
		for _, u in ipairs(FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_BOTH,
			DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)) do
			if u:GetUnitName() == "npc_dota_earth_spirit_stone" then
				self.rock = true
				self.speed = a:GetSpecialValueFor("rock_speed")
				self.maxDist = a:GetSpecialValueFor("rock_distance")
				p:EmitSound("Hero_EarthSpirit.RollingBoulder.Stone")
				u:ForceKill(false)
				break
			end
		end
	end
	local step = math.min(self.speed * TICK, self.maxDist - self.travelled)
	local pos = GetGroundPosition(p:GetAbsOrigin() + self.dir * step, p)
	p:SetAbsOrigin(pos)
	self.travelled = self.travelled + step
	for _, e in ipairs(FindUnitsInRadius(p:GetTeamNumber(), pos, nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)) do
		if not self.hit[e:entindex()] then
			self.hit[e:entindex()] = true
			ApplyDamage({ victim = e, attacker = p, damage = a:GetSpecialValueFor("damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
			e:EmitSound("Hero_EarthSpirit.RollingBoulder.Damage")
			if self.rock then
				e:AddNewModifier(p, a, "modifier_dota688_rolling_boulder_slow", { duration = a:GetSpecialValueFor("slow_duration") })
			end
			if e:IsRealHero() then return self:Stop() end   -- se opreste la primul erou lovit
		end
	end
	if self.travelled >= self.maxDist - 1 then return self:Stop() end
end
function modifier_dota688_rolling_boulder:OnDestroy()
	if not IsServer() then return end
	local p = self:GetParent()
	p:StopSound("Hero_EarthSpirit.RollingBoulder.Loop")
	if self.fx then ParticleManager:DestroyParticle(self.fx, false); ParticleManager:ReleaseParticleIndex(self.fx) end
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_earth_spirit/espirit_rollingboulder_destroy.vpcf", PATTACH_ABSORIGIN, p)
	ParticleManager:ReleaseParticleIndex(fx)
	FindClearSpaceForUnit(p, p:GetAbsOrigin(), false)
end

modifier_dota688_rolling_boulder_slow = class({})
function modifier_dota688_rolling_boulder_slow:IsDebuff() return true end
function modifier_dota688_rolling_boulder_slow:IsPurgable() return true end
function modifier_dota688_rolling_boulder_slow:GetTexture() return "earth_spirit_rolling_boulder" end
function modifier_dota688_rolling_boulder_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_rolling_boulder_slow:GetModifierMoveSpeedBonus_Percentage() return -Dota688Val(self, "move_slow") end
