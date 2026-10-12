-- Bloodrage (6.88): tinta (aliat/inamic) da si primeste +25/30/35/40% daune (vraji si atacuri) 9-12 s; cand ucide o unitate se vindeca 19-25% din HP max al victimei.
require("dota688/val")
LinkLuaModifier("modifier_dota688_bloodseeker_bloodrage", "abilities/heroes/dota688_bloodseeker_bloodrage", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_bloodrage_tracker", "abilities/heroes/dota688_bloodseeker_bloodrage", LUA_MODIFIER_MOTION_NONE)
dota688_bloodseeker_bloodrage = class({})
function dota688_bloodseeker_bloodrage:GetIntrinsicModifierName() return "modifier_dota688_bloodrage_tracker" end
function dota688_bloodseeker_bloodrage:OnSpellStart()
	local target = self:GetCursorTarget()
	if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() and target:TriggerSpellAbsorb(self) then return end
	target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_bloodseeker_bloodrage", { duration = self:GetSpecialValueFor("duration") })
	-- evidenta tintelor, pentru vindecarea ucigasului (modifier-ul unitatii care moare e scos inainte de OnDeath / OnTakeDamage, testat)
	self.raged = self.raged or {}
	self.raged[target:entindex()] = GameRules:GetGameTime() + self:GetSpecialValueFor("duration")
	target:EmitSound("Hero_Bloodseeker.Bloodrage")
end
-- pe Bloodseeker: 6.88 "Units affected by Bloodrage when killed will heal a percentage of their max health to their killer"
modifier_dota688_bloodrage_tracker = class({})
function modifier_dota688_bloodrage_tracker:IsHidden() return true end
function modifier_dota688_bloodrage_tracker:IsPurgable() return false end
function modifier_dota688_bloodrage_tracker:RemoveOnDeath() return false end
function modifier_dota688_bloodrage_tracker:DeclareFunctions() return { MODIFIER_EVENT_ON_DEATH } end
function modifier_dota688_bloodrage_tracker:OnDeath(params)
	if not IsServer() then return end
	local a, unit, killer = self:GetAbility(), params.unit, params.attacker
	if not a or a:IsNull() or not a.raged or not unit then return end
	local until_ = a.raged[unit:entindex()]
	if not until_ then return end
	a.raged[unit:entindex()] = nil
	if GameRules:GetGameTime() > until_ or not unit:HasModifier("modifier_dota688_bloodseeker_bloodrage") and GameRules:GetGameTime() > until_ then return end
	if not killer or killer:IsNull() or killer == unit or killer:GetTeamNumber() == unit:GetTeamNumber() then return end
	local pct = unit:IsHero() and a:GetSpecialValueFor("health_bonus_pct") or a:GetSpecialValueFor("health_bonus_creep_pct")
	killer:Heal(unit:GetMaxHealth() * pct / 100, a)
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
	if not IsServer() then return end
	local parent = self:GetParent()
	if params.attacker ~= parent then return end
	local unit = params.unit
	if not unit or unit:IsBuilding() or unit:IsOther() or unit:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
	local pct = unit:IsHero() and Dota688Val(self, "health_bonus_pct") or Dota688Val(self, "health_bonus_creep_pct")
	self:GetParent():Heal(unit:GetMaxHealth() * pct / 100, self:GetAbility())
end
