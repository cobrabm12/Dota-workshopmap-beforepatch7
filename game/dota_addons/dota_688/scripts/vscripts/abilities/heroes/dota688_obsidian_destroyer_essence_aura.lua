-- Essence Aura (6.88): OD are +125/200/275/350 mana (doar el, "passively gains a bonus to its base mana pool"); eroii aliati din 900
-- si OD au 40% sansa la fiecare vraja sa restaureze 10/15/20/25% din mana maxima (nu la toggle-uri si vraji fara cooldown, in afara
-- de Arcane Orb).
require("dota688/val")
local F = "abilities/heroes/dota688_obsidian_destroyer_essence_aura"
LinkLuaModifier("modifier_dota688_od_essence_aura", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_od_essence_aura_effect", F, LUA_MODIFIER_MOTION_NONE)
dota688_obsidian_destroyer_essence_aura = class({})
function dota688_obsidian_destroyer_essence_aura:GetIntrinsicModifierName() return "modifier_dota688_od_essence_aura" end
modifier_dota688_od_essence_aura = class({})
function modifier_dota688_od_essence_aura:IsHidden() return true end
function modifier_dota688_od_essence_aura:IsPurgable() return false end
function modifier_dota688_od_essence_aura:IsAura() return not self:GetParent():PassivesDisabled() end
function modifier_dota688_od_essence_aura:GetAuraRadius() return Dota688Val(self, "radius") end
function modifier_dota688_od_essence_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_od_essence_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_dota688_od_essence_aura:GetModifierAura() return "modifier_dota688_od_essence_aura_effect" end
modifier_dota688_od_essence_aura_effect = class({})
function modifier_dota688_od_essence_aura_effect:IsPurgable() return false end
function modifier_dota688_od_essence_aura_effect:DeclareFunctions() return { MODIFIER_PROPERTY_MANA_BONUS, MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
function modifier_dota688_od_essence_aura_effect:GetModifierManaBonus()
	if self:GetParent() ~= self:GetCaster() then return 0 end
	return Dota688Val(self, "bonus_mana")
end
function modifier_dota688_od_essence_aura_effect:OnAbilityExecuted(params)
	if not IsServer() or params.unit ~= self:GetParent() or not params.ability or params.ability:IsItem() then return end
	local a = self:GetAbility()
	if not a or a:IsNull() then return end
	local cast = params.ability
	if cast:GetAbilityName() ~= "dota688_obsidian_destroyer_arcane_orb" and (cast:IsToggle() or cast:GetCooldown(cast:GetLevel()) <= 0) then return end
	if RollPseudoRandomPercentage(a:GetSpecialValueFor("restore_chance"), DOTA_PSEUDO_RANDOM_NONE, self:GetParent()) then
		self:GetParent():GiveMana(self:GetParent():GetMaxMana() * a:GetSpecialValueFor("restore_amount") / 100)
		local fx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
		ParticleManager:ReleaseParticleIndex(fx)
	end
end
