-- Marksmanship (6.88): +40/60/80 agilitate cat timp nu e niciun erou inamic la mai putin de 400 unitati.
LinkLuaModifier("modifier_dota688_drow_ranger_marksmanship", "abilities/heroes/dota688_drow_ranger_marksmanship", LUA_MODIFIER_MOTION_NONE)
dota688_drow_ranger_marksmanship = class({})
function dota688_drow_ranger_marksmanship:GetIntrinsicModifierName() return "modifier_dota688_drow_ranger_marksmanship" end

modifier_dota688_drow_ranger_marksmanship = class({})
function modifier_dota688_drow_ranger_marksmanship:IsHidden() return false end
function modifier_dota688_drow_ranger_marksmanship:IsPurgable() return false end
function modifier_dota688_drow_ranger_marksmanship:OnCreated()
	self.active = true
	if IsServer() then self:StartIntervalThink(0.25) end
end
function modifier_dota688_drow_ranger_marksmanship:OnIntervalThink()
	local parent = self:GetParent()
	local enemies = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil, self:GetAbility():GetSpecialValueFor("radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_ANY_ORDER, false)
	local active = (#enemies == 0) and not parent:PassivesDisabled()
	if active ~= self.active then
		self.active = active
		self:SetStackCount(active and 1 or 0)
	end
end
function modifier_dota688_drow_ranger_marksmanship:DeclareFunctions() return { MODIFIER_PROPERTY_STATS_AGILITY_BONUS } end
function modifier_dota688_drow_ranger_marksmanship:GetModifierBonusStats_Agility()
	if self:GetStackCount() == 0 then return 0 end
	return self:GetAbility():GetSpecialValueFor("marksmanship_agility_bonus")
end
function modifier_dota688_drow_ranger_marksmanship:GetEffectName() return "particles/units/heroes/hero_drow/drow_marksmanship.vpcf" end
