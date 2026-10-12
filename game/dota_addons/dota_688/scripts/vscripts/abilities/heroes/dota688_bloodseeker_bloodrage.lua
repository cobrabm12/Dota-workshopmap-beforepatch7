-- Bloodrage (6.88): tinta (aliat/inamic) da si primeste +25/30/35/40% daune (vraji si atacuri) 9-12 s; cand ucide o unitate se vindeca 19-25% din HP max al victimei.
require("dota688/val")
LinkLuaModifier("modifier_dota688_bloodseeker_bloodrage", "abilities/heroes/dota688_bloodseeker_bloodrage", LUA_MODIFIER_MOTION_NONE)
dota688_bloodseeker_bloodrage = class({})
function dota688_bloodseeker_bloodrage:OnSpellStart()
	local target = self:GetCursorTarget()
	target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_bloodseeker_bloodrage", { duration = self:GetSpecialValueFor("duration") })
	target:EmitSound("Hero_Bloodseeker.Bloodrage")
end
modifier_dota688_bloodseeker_bloodrage = class({})
function modifier_dota688_bloodseeker_bloodrage:IsPurgable() return true end
function modifier_dota688_bloodseeker_bloodrage:GetEffectName() return "particles/units/heroes/hero_bloodseeker/bloodseeker_bloodrage.vpcf" end
function modifier_dota688_bloodseeker_bloodrage:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_EVENT_ON_DEATH }
end
function modifier_dota688_bloodseeker_bloodrage:GetModifierTotalDamageOutgoing_Percentage() return Dota688Val(self, "damage_increase_pct") end
function modifier_dota688_bloodseeker_bloodrage:GetModifierIncomingDamage_Percentage() return Dota688Val(self, "damage_increase_pct") end
function modifier_dota688_bloodseeker_bloodrage:OnDeath(params)
	if not IsServer() or params.attacker ~= self:GetParent() then return end
	local unit = params.unit
	if not unit or unit:IsBuilding() or unit:IsOther() or unit:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
	local pct = unit:IsHero() and Dota688Val(self, "health_bonus_pct") or Dota688Val(self, "health_bonus_creep_pct")
	self:GetParent():Heal(unit:GetMaxHealth() * pct / 100, self:GetAbility())
end
