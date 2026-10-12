-- Enrage (6.88): 4 s: 80% reducere a daunelor primite si Fury Swipes x1.5/1.75/2 (multiplicatorul se aplica ca daune bonus la atac, echivalent cu stack-urile built-in).
-- Scepter: cooldown 30/24/18; poate fi folosit si cand Ursa e dezactivat (stun/hex) – prin filtrul de ordine din dota688/aghanim_extras.lua.
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_ursa_enrage", "abilities/heroes/dota688_ursa_enrage", LUA_MODIFIER_MOTION_NONE)
dota688_ursa_enrage = class({})
function dota688_ursa_enrage:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetSpecialValueFor("cooldown_scepter") end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_ursa_enrage:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_dota688_ursa_enrage", { duration = self:GetSpecialValueFor("duration") })
	self:GetCaster():EmitSound("Hero_Ursa.Enrage")
end
modifier_dota688_ursa_enrage = class({})
function modifier_dota688_ursa_enrage:IsPurgable() return false end
function modifier_dota688_ursa_enrage:GetEffectName() return "particles/units/heroes/hero_ursa/ursa_enrage_buff.vpcf" end
function modifier_dota688_ursa_enrage:DeclareFunctions() return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL } end
function modifier_dota688_ursa_enrage:GetModifierIncomingDamage_Percentage() return -self:GetAbility():GetSpecialValueFor("damage_reduction") end
function modifier_dota688_ursa_enrage:GetModifierProcAttack_BonusDamage_Physical(params)
	-- Fury Swipes built-in: daunele per stack * stack-uri pe tinta; adaugam (mult - 1) x acea valoare
	local parent = self:GetParent()
	local target = params.target
	local swipes = parent:FindAbilityByName("ursa_fury_swipes")
	if not swipes or not target then return 0 end
	local m = target:FindModifierByNameAndCaster("modifier_ursa_fury_swipes_damage_increase", parent)
	if not m then return 0 end
	local per = swipes:GetSpecialValueFor("damage_per_stack")
	return per * m:GetStackCount() * (self:GetAbility():GetSpecialValueFor("enrage_multiplier") - 1)
end
