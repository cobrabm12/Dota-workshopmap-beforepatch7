-- Blur (6.88): 20/30/40/50% evaziune pasiva; cand niciun erou inamic nu e in raza 1600, PA dispare de pe minimap.
require("dota688/val")
LinkLuaModifier("modifier_dota688_phantom_assassin_blur", "abilities/heroes/dota688_phantom_assassin_blur", LUA_MODIFIER_MOTION_NONE)
dota688_phantom_assassin_blur = class({})
function dota688_phantom_assassin_blur:GetIntrinsicModifierName() return "modifier_dota688_phantom_assassin_blur" end

modifier_dota688_phantom_assassin_blur = class({})
function modifier_dota688_phantom_assassin_blur:IsHidden() return true end
function modifier_dota688_phantom_assassin_blur:IsPurgable() return false end
function modifier_dota688_phantom_assassin_blur:OnCreated()
	if IsServer() then self:StartIntervalThink(0.5) end
end
function modifier_dota688_phantom_assassin_blur:OnIntervalThink()
	local parent = self:GetParent()
	local enemies = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil, Dota688Val(self, "radius"),
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_ANY_ORDER, false)
	local hidden = (#enemies == 0) and not parent:PassivesDisabled()
	if hidden ~= (self:GetStackCount() == 1) then
		self:SetStackCount(hidden and 1 or 0)   -- stack-ul ajunge si la client, unde se evalueaza CheckState
	end
end
-- SetMinimapIconHidden nu mai exista: ascunderea de pe minimap se face prin stare (doar pentru inamici, ca in 6.88)
function modifier_dota688_phantom_assassin_blur:CheckState()
	return { [MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = self:GetStackCount() == 1 }
end
function modifier_dota688_phantom_assassin_blur:DeclareFunctions() return { MODIFIER_PROPERTY_EVASION_CONSTANT } end
function modifier_dota688_phantom_assassin_blur:GetModifierEvasion_Constant()
	if self:GetParent():PassivesDisabled() then return 0 end
	return Dota688Val(self, "bonus_evasion")
end
