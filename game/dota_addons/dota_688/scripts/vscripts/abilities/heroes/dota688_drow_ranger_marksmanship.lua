-- Marksmanship (6.88): +40/60/80 agilitate cat timp nu e niciun erou inamic la mai putin de 400 unitati.
-- Scepter: atacurile se "despica" si lovesc pana la 2 unitati din 375 de tinta cu atacuri normale la 50% daune.
require("dota688/val")
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_drow_ranger_marksmanship", "abilities/heroes/dota688_drow_ranger_marksmanship", LUA_MODIFIER_MOTION_NONE)
dota688_drow_ranger_marksmanship = class({})
function dota688_drow_ranger_marksmanship:GetIntrinsicModifierName() return "modifier_dota688_drow_ranger_marksmanship" end

modifier_dota688_drow_ranger_marksmanship = class({})
function modifier_dota688_drow_ranger_marksmanship:IsHidden() return false end
function modifier_dota688_drow_ranger_marksmanship:IsPurgable() return false end
function modifier_dota688_drow_ranger_marksmanship:OnCreated()
	self.active = true
	if IsServer() then self:SetStackCount(1); self:StartIntervalThink(0.25) end
end
function modifier_dota688_drow_ranger_marksmanship:OnIntervalThink()
	local parent = self:GetParent()
	local enemies = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil, Dota688Val(self, "radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_ANY_ORDER, false)
	local active = (#enemies == 0) and not parent:PassivesDisabled()
	if active ~= self.active then
		self.active = active
		self:SetStackCount(active and 1 or 0)
	end
end
function modifier_dota688_drow_ranger_marksmanship:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_AGILITY_BONUS, MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE }
end
function modifier_dota688_drow_ranger_marksmanship:GetModifierBonusStats_Agility()
	if self:GetStackCount() == 0 then return 0 end
	return Dota688Val(self, "marksmanship_agility_bonus")
end
-- Scepter: split shot
function modifier_dota688_drow_ranger_marksmanship:OnAttackLanded(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	if params.attacker ~= parent or self.splitting or parent:PassivesDisabled() or not Dota688HasScepter(parent) then return end
	local target = params.target
	if not target or target:IsBuilding() or target:IsOther() or target:GetTeamNumber() == parent:GetTeamNumber() then return end
	local a = self:GetAbility()
	if not a or a:IsNull() then return end
	local extra = FindUnitsInRadius(parent:GetTeamNumber(), target:GetAbsOrigin(), nil, a:GetSpecialValueFor("scepter_range"),
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
	local n = 0
	self.splitting = true
	for _, u in ipairs(extra) do
		if u ~= target and n < a:GetSpecialValueFor("split_count_scepter") then
			parent:PerformAttack(u, true, true, true, false, false, false, false)
			n = n + 1
		end
	end
	self.splitting = false
end
function modifier_dota688_drow_ranger_marksmanship:GetModifierDamageOutgoing_Percentage()
	if self.splitting then return -Dota688Val(self, "damage_reduction_scepter") end
	return 0
end
function modifier_dota688_drow_ranger_marksmanship:GetEffectName() return "particles/units/heroes/hero_drow/drow_marksmanship.vpcf" end
