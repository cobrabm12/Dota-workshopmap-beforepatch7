-- Thirst (6.88): pasiv global. Pentru fiecare erou inamic (nu iluzii) sub 75% viata, Bloodseeker primeste viteza de
-- miscare si daune, crescator liniar pana la maxim (16/24/32/40% MS si 16/24/32/40 daune) cand eroul e la 25% sau mai
-- putin; bonusurile se aduna pe eroi. Eroii inamici sub 25% viata sunt vizibili si fara invizibilitate pentru echipa lui.
require("dota688/val")
local F = "abilities/heroes/dota688_bloodseeker_thirst"
LinkLuaModifier("modifier_dota688_bloodseeker_thirst", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_bloodseeker_thirst_vision", F, LUA_MODIFIER_MOTION_NONE)
dota688_bloodseeker_thirst = class({})
function dota688_bloodseeker_thirst:GetIntrinsicModifierName() return "modifier_dota688_bloodseeker_thirst" end

-- stack = suma factorilor (0..1 pe erou) x 100
modifier_dota688_bloodseeker_thirst = class({})
function modifier_dota688_bloodseeker_thirst:IsHidden() return self:GetStackCount() == 0 end
function modifier_dota688_bloodseeker_thirst:IsPurgable() return false end
function modifier_dota688_bloodseeker_thirst:RemoveOnDeath() return false end
function modifier_dota688_bloodseeker_thirst:OnCreated()
	if IsServer() then self:StartIntervalThink(0.1) end
end
function modifier_dota688_bloodseeker_thirst:OnIntervalThink()
	local p, a = self:GetParent(), self:GetAbility()
	if not a or a:IsNull() or a:GetLevel() < 1 or p:PassivesDisabled() then
		self:SetStackCount(0)
		return
	end
	local minPct, maxPct = a:GetSpecialValueFor("min_bonus_pct"), a:GetSpecialValueFor("max_bonus_pct")
	local visPct = a:GetSpecialValueFor("visibility_threshold_pct")
	local sum = 0
	for _, h in ipairs(HeroList:GetAllHeroes()) do
		if h and not h:IsNull() and h:IsAlive() and h:IsRealHero() and h:GetTeamNumber() ~= p:GetTeamNumber() then
			local pct = h:GetHealth() / math.max(1, h:GetMaxHealth()) * 100
			if pct < minPct then
				sum = sum + math.min(1, (minPct - pct) / math.max(1, minPct - maxPct))
			end
			if pct < visPct and p:IsRealHero() and p:IsAlive() then
				h:AddNewModifier(p, a, "modifier_dota688_bloodseeker_thirst_vision", { duration = 0.25 })
			end
		end
	end
	self:SetStackCount(math.floor(sum * 100 + 0.5))
end
function modifier_dota688_bloodseeker_thirst:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end
function modifier_dota688_bloodseeker_thirst:GetModifierMoveSpeedBonus_Percentage()
	return Dota688Val(self, "bonus_movement_speed") * self:GetStackCount() / 100
end
function modifier_dota688_bloodseeker_thirst:GetModifierPreAttack_BonusDamage()
	return Dota688Val(self, "bonus_damage") * self:GetStackCount() / 100
end

-- pe eroul inamic sub 25%: viziune + True Sight pentru echipa lui Bloodseeker
modifier_dota688_bloodseeker_thirst_vision = class({})
function modifier_dota688_bloodseeker_thirst_vision:IsDebuff() return true end
function modifier_dota688_bloodseeker_thirst_vision:IsPurgable() return false end
function modifier_dota688_bloodseeker_thirst_vision:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end
function modifier_dota688_bloodseeker_thirst_vision:GetTexture() return "bloodseeker_thirst" end
function modifier_dota688_bloodseeker_thirst_vision:GetEffectName() return "particles/units/heroes/hero_bloodseeker/bloodseeker_vision.vpcf" end
function modifier_dota688_bloodseeker_thirst_vision:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_bloodseeker_thirst_vision:OnCreated() self:OnRefresh() end
function modifier_dota688_bloodseeker_thirst_vision:OnRefresh()
	if not IsServer() then return end
	local c = self:GetCaster()
	if c and not c:IsNull() then AddFOWViewer(c:GetTeamNumber(), self:GetParent():GetAbsOrigin(), 64, 0.15, false) end
end
function modifier_dota688_bloodseeker_thirst_vision:CheckState()
	return { [MODIFIER_STATE_INVISIBLE] = false, [MODIFIER_STATE_PROVIDES_VISION] = true }
end
