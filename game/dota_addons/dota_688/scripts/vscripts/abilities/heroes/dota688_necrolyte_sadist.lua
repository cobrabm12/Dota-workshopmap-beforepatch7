-- Sadist (6.88): la fiecare unitate ucisa, +1/2/3/6 HP si +2/4/6/12 mana pe secunda pentru 6 s (x10 pentru eroi). Se stacheaza.
require("dota688/val")
local F = "abilities/heroes/dota688_necrolyte_sadist"
LinkLuaModifier("modifier_dota688_necrolyte_sadist", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_necrolyte_sadist_regen", F, LUA_MODIFIER_MOTION_NONE)
dota688_necrolyte_sadist = class({})
function dota688_necrolyte_sadist:GetIntrinsicModifierName() return "modifier_dota688_necrolyte_sadist" end

modifier_dota688_necrolyte_sadist = class({})
function modifier_dota688_necrolyte_sadist:IsHidden() return true end
function modifier_dota688_necrolyte_sadist:IsPurgable() return false end
function modifier_dota688_necrolyte_sadist:DeclareFunctions() return { MODIFIER_EVENT_ON_DEATH } end
function modifier_dota688_necrolyte_sadist:OnDeath(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	if params.attacker ~= parent or parent:PassivesDisabled() then return end
	local unit = params.unit
	if not unit or unit:IsBuilding() or unit:IsOther() or unit:GetTeamNumber() == parent:GetTeamNumber() then return end
	local a = self:GetAbility()
	if not a or a:IsNull() then return end
	local mult = (unit:IsRealHero() and not unit:IsIllusion()) and a:GetSpecialValueFor("hero_multiplier") or 1
	parent:AddNewModifier(parent, a, "modifier_dota688_necrolyte_sadist_regen", { duration = a:GetSpecialValueFor("regen_duration"), mult = mult })
end

modifier_dota688_necrolyte_sadist_regen = class({})
function modifier_dota688_necrolyte_sadist_regen:IsPurgable() return false end
function modifier_dota688_necrolyte_sadist_regen:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_dota688_necrolyte_sadist_regen:OnCreated(kv) self.mult = kv.mult or 1 end
function modifier_dota688_necrolyte_sadist_regen:DeclareFunctions() return { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, MODIFIER_PROPERTY_MANA_REGEN_CONSTANT } end
function modifier_dota688_necrolyte_sadist_regen:GetModifierConstantHealthRegen() return Dota688Val(self, "health_regen") * self.mult end
function modifier_dota688_necrolyte_sadist_regen:GetModifierConstantManaRegen() return Dota688Val(self, "mana_regen") * self.mult end
