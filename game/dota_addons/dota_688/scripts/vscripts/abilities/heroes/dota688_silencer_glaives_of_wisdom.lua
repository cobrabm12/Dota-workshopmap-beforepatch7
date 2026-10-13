-- Glaives of Wisdom (6.88, orb): +35/50/65/80% din INT ca daune pure; Silencer fura permanent 2 INT cand un erou inamic moare in raza 925 (sau e ucis de el).
require("dota688/val")
local F = "abilities/heroes/dota688_silencer_glaives_of_wisdom"
LinkLuaModifier("modifier_dota688_silencer_glaives_of_wisdom", F, LUA_MODIFIER_MOTION_NONE)
dota688_silencer_glaives_of_wisdom = class({})
function dota688_silencer_glaives_of_wisdom:GetIntrinsicModifierName() return "modifier_dota688_silencer_glaives_of_wisdom" end
function dota688_silencer_glaives_of_wisdom:GetProjectileName() return "particles/units/heroes/hero_silencer/silencer_glaives_of_wisdom.vpcf" end
function dota688_silencer_glaives_of_wisdom:OnOrbImpact(params)
	local target = params.target
	local caster = self:GetCaster()
	if not target or target:IsBuilding() or target:IsOther() then return end
	local dmg = caster:GetIntellect(true) * self:GetSpecialValueFor("intellect_damage_pct") / 100
	ApplyDamage({ victim = target, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_PURE, ability = self })
end
function dota688_silencer_glaives_of_wisdom:OnSpellStart()
	local target = self:GetCursorTarget()
	if target then self:OnOrbImpact({ target = target }) end
end
modifier_dota688_silencer_glaives_of_wisdom = class({})
function modifier_dota688_silencer_glaives_of_wisdom:IsHidden() return true end
function modifier_dota688_silencer_glaives_of_wisdom:IsPurgable() return false end
function modifier_dota688_silencer_glaives_of_wisdom:RemoveOnDeath() return false end
function modifier_dota688_silencer_glaives_of_wisdom:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_dota688_silencer_glaives_of_wisdom:DeclareFunctions() return { MODIFIER_EVENT_ON_DEATH, MODIFIER_PROPERTY_STATS_INTELLECT_BONUS } end
function modifier_dota688_silencer_glaives_of_wisdom:OnDeath(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	local unit = params.unit
	if not unit or not unit:IsRealHero() or unit:IsIllusion() or unit:GetTeamNumber() == parent:GetTeamNumber() then return end
	local near = (unit:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D() <= Dota688Val(self, "steal_range")
	if near or params.attacker == parent then
		self:IncrementStackCount()
		unit:ModifyIntellect(-2)  -- permanent, ca in 6.88 (tinta pierde 2 INT)
	end
end
function modifier_dota688_silencer_glaives_of_wisdom:GetModifierBonusStats_Intellect() return self:GetStackCount() * 2 end
