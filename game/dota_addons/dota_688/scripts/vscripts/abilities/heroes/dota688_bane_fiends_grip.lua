-- Fiend's Grip (6.88): canalizare 5 s: tinta e dezactivata, ia 100/155/215 daune magice/s si pierde 5% din mana maxima/s; trece prin imunitate.
-- Scepter: 7 s, 155/215/270 daune/s, 10% mana/s; cine ataca Bane in timpul canalizarii primeste Nightmare (nivelul curent).
require("dota688/aghanim")
local F = "abilities/heroes/dota688_bane_fiends_grip"
LinkLuaModifier("modifier_dota688_fiends_grip", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_fiends_grip_caster", F, LUA_MODIFIER_MOTION_NONE)
dota688_bane_fiends_grip = class({})
function dota688_bane_fiends_grip:GetChannelTime()
	if Dota688HasScepter(self:GetCaster()) then return self:GetSpecialValueFor("fiend_grip_duration_scepter") end
	return self:GetSpecialValueFor("fiend_grip_duration")
end
function dota688_bane_fiends_grip:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then self:EndChannel(true) return end
	caster:EmitSound("Hero_Bane.FiendsGrip.Cast")
	target:EmitSound("Hero_Bane.FiendsGrip")
	local dur = self:GetChannelTime()
	self.mod = target:AddNewModifier(caster, self, "modifier_dota688_fiends_grip", { duration = dur })
	self.selfmod = caster:AddNewModifier(caster, self, "modifier_dota688_fiends_grip_caster", { duration = dur })
end
function dota688_bane_fiends_grip:OnChannelFinish(interrupted)
	local caster = self:GetCaster()
	caster:StopSound("Hero_Bane.FiendsGrip.Cast")
	if self.mod and not self.mod:IsNull() then self.mod:GetParent():StopSound("Hero_Bane.FiendsGrip"); self.mod:Destroy() end
	if self.selfmod and not self.selfmod:IsNull() then self.selfmod:Destroy() end
	self.mod, self.selfmod = nil, nil
end
modifier_dota688_fiends_grip = class({})
function modifier_dota688_fiends_grip:IsDebuff() return true end
function modifier_dota688_fiends_grip:IsPurgable() return false end
function modifier_dota688_fiends_grip:IsStunDebuff() return true end
function modifier_dota688_fiends_grip:GetEffectName() return "particles/units/heroes/hero_bane/bane_fiends_grip.vpcf" end
function modifier_dota688_fiends_grip:GetOverrideAnimation() return ACT_DOTA_FLAIL end
function modifier_dota688_fiends_grip:OnCreated()
	if not IsServer() then return end
	local a, scepter = self:GetAbility(), Dota688HasScepter(self:GetCaster())
	self.dmg = scepter and a:GetSpecialValueFor("fiend_grip_damage_scepter") or a:GetSpecialValueFor("fiend_grip_damage")
	self.mana = scepter and a:GetSpecialValueFor("fiend_grip_mana_drain_scepter") or a:GetSpecialValueFor("fiend_grip_mana_drain")
	self:StartIntervalThink(a:GetSpecialValueFor("fiend_grip_tick_interval"))
end
function modifier_dota688_fiends_grip:OnIntervalThink()
	local p, caster = self:GetParent(), self:GetCaster()
	ApplyDamage({ victim = p, attacker = caster, damage = self.dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = self:GetAbility() })
	local mana = p:GetMaxMana() * self.mana / 100
	p:ReduceMana(mana)
	caster:GiveMana(mana)
end
function modifier_dota688_fiends_grip:CheckState() return { [MODIFIER_STATE_STUNNED] = true } end
-- pe Bane: cine il ataca primeste Nightmare (scepter)
modifier_dota688_fiends_grip_caster = class({})
function modifier_dota688_fiends_grip_caster:IsHidden() return true end
function modifier_dota688_fiends_grip_caster:IsPurgable() return false end
function modifier_dota688_fiends_grip_caster:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_fiends_grip_caster:OnAttackLanded(params)
	if not IsServer() or params.target ~= self:GetParent() or not Dota688HasScepter(self:GetParent()) then return end
	local attacker = params.attacker
	local nightmare = self:GetParent():FindAbilityByName("bane_nightmare")
	if not attacker or not nightmare or nightmare:GetLevel() < 1 or attacker:IsMagicImmune() or attacker:HasModifier("modifier_bane_nightmare") then return end
	attacker:AddNewModifier(self:GetParent(), nightmare, "modifier_bane_nightmare", { duration = nightmare:GetSpecialValueFor("duration") })
end
