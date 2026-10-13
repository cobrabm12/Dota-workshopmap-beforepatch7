-- Power Cogs (6.88): 8 roti dintate in cerc (raza 215) in jurul lui Clockwerk, timp de 5/6/7/8 s. Rotile sunt obstacole:
-- unitatile prinse inauntru (inclusiv Clockwerk) nu pot trece printre ele. Un erou inamic din afara care ajunge la 170 de
-- o roata primeste un soc: 80/120/160/200 daune magice, pierde tot atata mana si e impins 250 (0.85 s) departe de cerc;
-- dupa un soc roata se descarca (ramane doar obstacol). Rotile mor dupa 2/2/2/3 atacuri inamice, dar un singur atac al
-- lui Clockwerk distruge una. Motorul curent il lasa pe Clockwerk sa treaca prin roti, iar atacul lui impinge roata
-- in loc sa o distruga (si foloseste alte valori: daune separate de mana arsa, raza de declansare 185).
require("dota688/val")
local F = "abilities/heroes/dota688_rattletrap_power_cogs"
LinkLuaModifier("modifier_dota688_power_cogs_thinker", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_power_cogs_cog", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_power_cogs_caster", F, LUA_MODIFIER_MOTION_NONE)

local COG_UNIT = "npc_dota_rattletrap_cog"
local COG_COUNT = 8        -- 6.88: numar fix de roti (nu apare in KV)
local TICK = 0.05
local P = "particles/units/heroes/hero_rattletrap/"

dota688_rattletrap_power_cogs = class({})
function dota688_rattletrap_power_cogs:GetCastAnimation() return ACT_DOTA_CAST_ABILITY_2 end
function dota688_rattletrap_power_cogs:OnSpellStart()
	local caster = self:GetCaster()
	local dur = self:GetSpecialValueFor("duration")
	caster:EmitSound("Hero_Rattletrap.Power_Cogs")
	local fx = ParticleManager:CreateParticle(P .. "rattletrap_cog_deploy.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	CreateModifierThinker(caster, self, "modifier_dota688_power_cogs_thinker", { duration = dur }, caster:GetAbsOrigin(), caster:GetTeamNumber(), false)
	-- Clockwerk nu are voie sa treaca prin roti (motorul curent ii da aceasta stare)
	caster:AddNewModifier(caster, self, "modifier_dota688_power_cogs_caster", { duration = dur })
end

--------------------------------------------------------------------------------------------------------------------------
-- thinker-ul cercului: aseaza rotile, prinde unitatile si declanseaza socurile
modifier_dota688_power_cogs_thinker = class({})
function modifier_dota688_power_cogs_thinker:IsHidden() return true end
function modifier_dota688_power_cogs_thinker:IsPurgable() return false end
function modifier_dota688_power_cogs_thinker:OnCreated()
	if not IsServer() then return end
	local a, caster = self:GetAbility(), self:GetCaster()
	self.center = self:GetParent():GetAbsOrigin()
	self.radius = a:GetSpecialValueFor("cogs_radius")
	self.trigger = a:GetSpecialValueFor("trigger_distance")
	self.buffer = a:GetSpecialValueFor("extra_pull_buffer")
	self.drain = a:GetSpecialValueFor("drain_amount")
	self.pushLen = a:GetSpecialValueFor("push_length")
	self.pushDur = a:GetSpecialValueFor("push_duration")
	self.lastHit = {}
	self.cogs = {}
	local dur = self:GetDuration()
	local fwd = caster:GetForwardVector(); fwd.z = 0
	local base = math.atan2(fwd.y, fwd.x)
	local cogHull = 80   -- DOTA_HULL_SIZE_HUGE
	self:TrapUnits(cogHull)
	for i = 0, COG_COUNT - 1 do
		local ang = base + i * 2 * math.pi / COG_COUNT
		local dir = Vector(math.cos(ang), math.sin(ang), 0)
		local pos = GetGroundPosition(self.center + dir * self.radius, nil)
		-- fara proprietar: motorul curent lasa proprietarul rotii sa treaca prin ea
		local cog = CreateUnitByName(COG_UNIT, pos, false, nil, nil, caster:GetTeamNumber())
		if cog then
			cog:SetAbsOrigin(pos)
			cog:SetForwardVector(dir)
			cog:AddNewModifier(caster, a, "modifier_dota688_power_cogs_cog", { duration = dur })
			table.insert(self.cogs, cog)
		end
	end
	self:StartIntervalThink(TICK)
end

-- unitatile de pe linia rotilor: cele din cerc sunt mutate inauntru, cele de la marginea exterioara sunt mutate afara
function modifier_dota688_power_cogs_thinker:TrapUnits(cogHull)
	local c = self.center
	for _, u in ipairs(FindUnitsInRadius(self:GetCaster():GetTeamNumber(), c, nil, self.radius + cogHull + 50, DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER, false)) do
		if not u:IsBuilding() and u:GetUnitName() ~= COG_UNIT then
			local d = u:GetAbsOrigin() - c; d.z = 0
			local dist = d:Length2D()
			local hull = u:GetHullRadius()
			local inner = math.max(0, self.radius - cogHull - hull + self.buffer)
			local outer = self.radius + cogHull + hull
			local dir = dist > 1 and d:Normalized() or self:GetCaster():GetForwardVector()
			if dist <= self.radius and dist > inner then
				u:SetAbsOrigin(GetGroundPosition(c + dir * inner, u))
			elseif dist > self.radius and dist < outer then
				u:SetAbsOrigin(GetGroundPosition(c + dir * outer, u))
			end
		end
	end
end

function modifier_dota688_power_cogs_thinker:OnIntervalThink()
	local a, caster = self:GetAbility(), self:GetCaster()
	local now = GameRules:GetGameTime()
	for _, cog in ipairs(self.cogs) do
		local m = (not cog:IsNull() and cog:IsAlive()) and cog:FindModifierByName("modifier_dota688_power_cogs_cog")
		if m and m.charged then
			for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), cog:GetAbsOrigin(), nil, self.trigger, DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)) do
				local d = e:GetAbsOrigin() - self.center; d.z = 0
				local idx = e:entindex()
				-- doar inamicii din afara cercului; o singura impingere in curs pe unitate
				if d:Length2D() > self.radius + self.buffer and (self.lastHit[idx] == nil or now - self.lastHit[idx] >= self.pushDur) then
					self.lastHit[idx] = now
					self:Shock(cog, m, e, a, caster)
					break
				end
			end
		end
	end
end

function modifier_dota688_power_cogs_thinker:Shock(cog, m, e, a, caster)
	m:Discharge()
	local fx = ParticleManager:CreateParticle(P .. "rattletrap_cog_attack.vpcf", PATTACH_ABSORIGIN_FOLLOW, cog)
	ParticleManager:SetParticleControlEnt(fx, 0, cog, PATTACH_POINT_FOLLOW, "attach_hitloc", cog:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, e, PATTACH_POINT_FOLLOW, "attach_hitloc", e:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
	e:EmitSound("Hero_Rattletrap.Power_Cogs_Impact")
	local c = self.center
	e:AddNewModifier(caster, a, "modifier_knockback", { duration = self.pushDur, knockback_duration = self.pushDur,
		knockback_distance = self.pushLen, knockback_height = 0, should_stun = 0, center_x = c.x, center_y = c.y, center_z = c.z })
	if a and not a:IsNull() then e:Script_ReduceMana(self.drain, a) end
	ApplyDamage({ victim = e, attacker = caster, damage = self.drain, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
end

function modifier_dota688_power_cogs_thinker:OnDestroy()
	if not IsServer() then return end
	for _, cog in ipairs(self.cogs or {}) do
		if not cog:IsNull() then
			local m = cog:FindModifierByName("modifier_dota688_power_cogs_cog")
			if m then m:Destroy() end
		end
	end
	UTIL_Remove(self:GetParent())
end

--------------------------------------------------------------------------------------------------------------------------
-- o roata: viata = numarul de atacuri; fara daune din alte surse; un atac al lui Clockwerk o distruge
modifier_dota688_power_cogs_cog = class({})
function modifier_dota688_power_cogs_cog:IsHidden() return true end
function modifier_dota688_power_cogs_cog:IsPurgable() return false end
function modifier_dota688_power_cogs_cog:OnCreated()
	self.charged = true
	if not IsServer() then return end
	local p = self:GetParent()
	local hits = math.max(1, self:GetAbility():GetSpecialValueFor("attacks_to_destroy"))
	p:SetBaseMaxHealth(hits); p:SetMaxHealth(hits); p:SetHealth(hits)
	p:SetBaseHealthRegen(0)
	self.fx = ParticleManager:CreateParticle(P .. "rattletrap_cog_ambient.vpcf", PATTACH_ABSORIGIN_FOLLOW, p)
end
function modifier_dota688_power_cogs_cog:Discharge()
	self.charged = false
	if self.fx then ParticleManager:DestroyParticle(self.fx, false); ParticleManager:ReleaseParticleIndex(self.fx); self.fx = nil end
end
function modifier_dota688_power_cogs_cog:CheckState()
	return { [MODIFIER_STATE_SPECIALLY_DENIABLE] = true, [MODIFIER_STATE_NOT_ON_MINIMAP] = true, [MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_CANNOT_BE_MOTION_CONTROLLED] = true }
end
function modifier_dota688_power_cogs_cog:DeclareFunctions()
	return { MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL, MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL, MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE,
		MODIFIER_PROPERTY_DISABLE_HEALING, MODIFIER_PROPERTY_HEALTHBAR_PIPS, MODIFIER_EVENT_ON_ATTACK_LANDED }
end
function modifier_dota688_power_cogs_cog:GetAbsoluteNoDamagePhysical() return 1 end
function modifier_dota688_power_cogs_cog:GetAbsoluteNoDamageMagical() return 1 end
function modifier_dota688_power_cogs_cog:GetAbsoluteNoDamagePure() return 1 end
function modifier_dota688_power_cogs_cog:GetDisableHealing() return 1 end
function modifier_dota688_power_cogs_cog:GetModifierHealthBarPips() return Dota688Val(self, "attacks_to_destroy") end
function modifier_dota688_power_cogs_cog:OnAttackLanded(params)
	if not IsServer() then return end
	local p, att = self:GetParent(), params.attacker
	if params.target ~= p or not att or att:IsNull() or not p:IsAlive() then return end
	local hp
	if att == self:GetCaster() then
		hp = 0                                   -- Clockwerk: un singur atac
	elseif att:GetTeamNumber() ~= p:GetTeamNumber() then
		hp = p:GetHealth() - 1                   -- inamic: un atac = o "viata"
	else
		return                                   -- alti aliati nu strica rotile
	end
	if hp > 0 then p:SetHealth(hp); return end
	p:EmitSound("Hero_Rattletrap.Power_Cog.Destroy")
	self.killed = true
	p:Kill(nil, att)
	Dota688Timers:After(1, function() if not p:IsNull() then UTIL_Remove(p) end end)
end
function modifier_dota688_power_cogs_cog:OnDestroy()
	if not IsServer() then return end
	self:Discharge()
	local p = self:GetParent()
	if not self.killed and not p:IsNull() and p:IsAlive() then
		p:ForceKill(false)
		Dota688Timers:After(1, function() if not p:IsNull() then UTIL_Remove(p) end end)
	end
end

--------------------------------------------------------------------------------------------------------------------------
-- pe Clockwerk cat timp exista roti: anuleaza starea moderna care il lasa sa treaca prin ele
modifier_dota688_power_cogs_caster = class({})
function modifier_dota688_power_cogs_caster:IsHidden() return true end
function modifier_dota688_power_cogs_caster:IsPurgable() return false end
function modifier_dota688_power_cogs_caster:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end
function modifier_dota688_power_cogs_caster:CheckState()
	if MODIFIER_STATE_ALLOW_PATHING_THROUGH_POWER_COGS == nil then return {} end
	return { [MODIFIER_STATE_ALLOW_PATHING_THROUGH_POWER_COGS] = false }
end
