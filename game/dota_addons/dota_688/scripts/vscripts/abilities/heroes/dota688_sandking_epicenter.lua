-- Epicenter (6.88): canalizare 2 s (cast point 0); daca Sand King e intrerupt, mana si cooldown-ul sunt consumate si nu
-- urmeaza nimic. Dupa canalizare: 6/8/10 pulsuri in 3 s, centrate pe Sand King (il urmeaza), cu raza crescatoare
-- 275 / 325 / 375 / 425 / 475 / 525 / 575 / 650 / 675 / 700; fiecare puls da 110 daune magice si -30% MS / -30 AS 3 s.
-- Motorul curent nu mai are canalizare (asteapta 2 s de cast point si nu se mai poate intrerupe dupa ce porneste).
require("dota688/val")
local F = "abilities/heroes/dota688_sandking_epicenter"
LinkLuaModifier("modifier_dota688_sandking_epicenter", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_sandking_epicenter_slow", F, LUA_MODIFIER_MOTION_NONE)

dota688_sandking_epicenter = class({})
function dota688_sandking_epicenter:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Ability.SandKing_Epicenter.spell")
	self.tell = ParticleManager:CreateParticle("particles/units/heroes/hero_sandking/sandking_epicenter_tell.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(self.tell, 1, caster, PATTACH_POINT_FOLLOW, "attach_tail", caster:GetAbsOrigin(), true)
end
function dota688_sandking_epicenter:OnChannelFinish(interrupted)
	local caster = self:GetCaster()
	if self.tell then ParticleManager:DestroyParticle(self.tell, interrupted); ParticleManager:ReleaseParticleIndex(self.tell); self.tell = nil end
	if interrupted then caster:StopSound("Ability.SandKing_Epicenter.spell"); return end
	caster:AddNewModifier(caster, self, "modifier_dota688_sandking_epicenter", { duration = self:GetDuration() + 0.1 })
end

-- pulsurile (pe Sand King)
modifier_dota688_sandking_epicenter = class({})
function modifier_dota688_sandking_epicenter:IsPurgable() return false end
function modifier_dota688_sandking_epicenter:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_dota688_sandking_epicenter:OnCreated()
	if not IsServer() then return end
	local a = self:GetAbility()
	self.pulses = a:GetSpecialValueFor("epicenter_pulses")
	self.done = 0
	self:GetParent():EmitSound("Ability.SandKing_Epicenter")
	self:Pulse()
	if self.pulses > 1 then self:StartIntervalThink(a:GetDuration() / self.pulses) end
end
function modifier_dota688_sandking_epicenter:OnIntervalThink() self:Pulse() end
function modifier_dota688_sandking_epicenter:Pulse()
	local a, p = self:GetAbility(), self:GetParent()
	if not a or a:IsNull() or self.done >= self.pulses then self:StartIntervalThink(-1); return end
	self.done = self.done + 1
	-- raza puls-ului k = valoarea k din lista epicenter_radius (10 valori, indiferent de nivel)
	local radius = a:GetLevelSpecialValueFor("epicenter_radius", math.min(self.done, 10) - 1)
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_sandking/sandking_epicenter.vpcf", PATTACH_ABSORIGIN_FOLLOW, p)
	ParticleManager:SetParticleControl(fx, 1, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(fx)
	for _, e in ipairs(FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		ApplyDamage({ victim = e, attacker = p, damage = a:GetSpecialValueFor("epicenter_damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
		e:AddNewModifier(p, a, "modifier_dota688_sandking_epicenter_slow", { duration = a:GetSpecialValueFor("epicenter_slow_duration_tooltip") })
	end
	if self.done >= self.pulses then self:StartIntervalThink(-1) end
end
function modifier_dota688_sandking_epicenter:OnDestroy()
	if IsServer() then self:GetParent():StopSound("Ability.SandKing_Epicenter") end
end

modifier_dota688_sandking_epicenter_slow = class({})
function modifier_dota688_sandking_epicenter_slow:IsDebuff() return true end
function modifier_dota688_sandking_epicenter_slow:IsPurgable() return true end
function modifier_dota688_sandking_epicenter_slow:GetTexture() return "sandking_epicenter" end
function modifier_dota688_sandking_epicenter_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_sandking_epicenter_slow:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "epicenter_slow") end
function modifier_dota688_sandking_epicenter_slow:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "epicenter_slow_as") end
