-- Nightmare (6.88): adoarme un erou/creep (aliat sau inamic, si pe Bane) 4/5/6/7 s; prima secunda tinta e invulnerabila;
-- ia 20 daune pure pe secunda (AbilityDamage; poate omori -> deny). Orice alta sursa de daune o trezeste. Cine o
-- ataca (atac fizic reusit, inclusiv Bane) o trezeste si primeste el Nightmare (durata intreaga). Cat timp exista un
-- Nightmare de-al lui Bane, in locul abilitatii apare Nightmare End (le termina pe toate).
require("dota688/val")
local F = "abilities/heroes/dota688_bane_nightmare"
LinkLuaModifier("modifier_dota688_bane_nightmare", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_bane_nightmare_invulnerable", F, LUA_MODIFIER_MOTION_NONE)
dota688_bane_nightmare = class({})

local END_NAME = "dota688_bane_nightmare_end"

function dota688_bane_nightmare:OnUpgrade()
	local e = self:GetCaster():FindAbilityByName(END_NAME)
	if e and e:GetLevel() < 1 then e:SetLevel(1) end
end

function dota688_bane_nightmare:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:GetTeamNumber() ~= caster:GetTeamNumber() and target:TriggerSpellAbsorb(self) then return end
	caster:EmitSound("Hero_Bane.Nightmare")
	self:ApplyNightmare(target, true)
end

-- folosit si de Fiend's Grip (scepter): invuln = false pentru Nightmare transferat
function dota688_bane_nightmare:ApplyNightmare(target, invuln)
	if not target or target:IsNull() or not target:IsAlive() then return end
	local caster = self:GetCaster()
	target:AddNewModifier(caster, self, "modifier_dota688_bane_nightmare", { duration = self:GetSpecialValueFor("duration") })
	if invuln then
		target:AddNewModifier(caster, self, "modifier_dota688_bane_nightmare_invulnerable", { duration = self:GetSpecialValueFor("nightmare_invuln_time") })
	end
end

-- evidenta Nightmare-urilor active (pentru Nightmare End)
function dota688_bane_nightmare:TrackNightmare(mod, on)
	self.active = self.active or {}
	self.active[mod] = on or nil
	for m, _ in pairs(self.active) do
		if m:IsNull() then self.active[m] = nil end
	end
	local any = next(self.active) ~= nil
	local caster = self:GetCaster()
	local e = caster:FindAbilityByName(END_NAME)
	if not e or self:IsNull() then return end
	if any and not self.swapped then
		self.swapped = true
		caster:SwapAbilities(self:GetAbilityName(), END_NAME, false, true)
	elseif not any and self.swapped then
		self.swapped = false
		caster:SwapAbilities(self:GetAbilityName(), END_NAME, true, false)
	end
end

function dota688_bane_nightmare:EndAll()
	local list = {}
	for mod, _ in pairs(self.active or {}) do table.insert(list, mod) end
	for _, mod in ipairs(list) do
		if not mod:IsNull() then mod:Destroy() end
	end
end

modifier_dota688_bane_nightmare = class({})
function modifier_dota688_bane_nightmare:IsDebuff() return true end
function modifier_dota688_bane_nightmare:IsPurgable() return true end
function modifier_dota688_bane_nightmare:GetEffectName() return "particles/units/heroes/hero_bane/bane_nightmare.vpcf" end
function modifier_dota688_bane_nightmare:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_dota688_bane_nightmare:OnCreated()
	self.rate = Dota688Val(self, "animation_rate")
	if not IsServer() then return end
	local a = self:GetAbility()
	self.damage = (a and a.GetAbilityDamage) and a:GetAbilityDamage() or 0
	if self.damage <= 0 then self.damage = 20 end
	self:GetParent():EmitSound("Hero_Bane.Nightmare.Loop")
	if a then a:TrackNightmare(self, true) end
	self:StartIntervalThink(Dota688Val(self, "nightmare_dot_interval"))
end
function modifier_dota688_bane_nightmare:OnRefresh()
	if not IsServer() then return end
	local a = self:GetAbility()
	if a and not a:IsNull() then a:TrackNightmare(self, true) end
end
function modifier_dota688_bane_nightmare:OnIntervalThink()
	local a = self:GetAbility()
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = self.damage, damage_type = DAMAGE_TYPE_PURE,
		ability = (a and not a:IsNull()) and a or nil })
end
function modifier_dota688_bane_nightmare:OnDestroy()
	if not IsServer() then return end
	self:GetParent():StopSound("Hero_Bane.Nightmare.Loop")
	self:GetParent():RemoveModifierByName("modifier_dota688_bane_nightmare_invulnerable")
	local a = self:GetAbility()
	if a and not a:IsNull() then a:TrackNightmare(self, false) end
end
function modifier_dota688_bane_nightmare:CheckState()
	return { [MODIFIER_STATE_NIGHTMARED] = true, [MODIFIER_STATE_STUNNED] = true }
end
function modifier_dota688_bane_nightmare:DeclareFunctions()
	return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_PROPERTY_OVERRIDE_ANIMATION_RATE, MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_EVENT_ON_TAKEDAMAGE }
end
function modifier_dota688_bane_nightmare:GetOverrideAnimation() return ACT_DOTA_DISABLED end
function modifier_dota688_bane_nightmare:GetOverrideAnimationRate() return self.rate or 0.2 end
-- atacul trezeste tinta si muta Nightmare pe atacator
function modifier_dota688_bane_nightmare:OnAttackLanded(params)
	if not IsServer() or params.target ~= self:GetParent() then return end
	local attacker = params.attacker
	local a = self:GetAbility()
	if attacker and not attacker:IsNull() and attacker ~= self:GetParent() and attacker:IsAlive() and not attacker:IsBuilding()
		and not attacker:IsMagicImmune() and not attacker:HasModifier("modifier_dota688_bane_nightmare") and a and not a:IsNull() then
		a:ApplyNightmare(attacker, false)
	end
	self:Destroy()
end
-- orice alte daune (in afara de Nightmare) trezesc tinta
function modifier_dota688_bane_nightmare:OnTakeDamage(params)
	if not IsServer() or params.unit ~= self:GetParent() or params.damage <= 0 then return end
	local a = self:GetAbility()
	if params.inflictor and a and params.inflictor == a then return end
	self:Destroy()
end

modifier_dota688_bane_nightmare_invulnerable = class({})
function modifier_dota688_bane_nightmare_invulnerable:IsHidden() return false end
function modifier_dota688_bane_nightmare_invulnerable:IsPurgable() return false end
function modifier_dota688_bane_nightmare_invulnerable:GetTexture() return "bane_nightmare" end
function modifier_dota688_bane_nightmare_invulnerable:CheckState() return { [MODIFIER_STATE_INVULNERABLE] = true } end
