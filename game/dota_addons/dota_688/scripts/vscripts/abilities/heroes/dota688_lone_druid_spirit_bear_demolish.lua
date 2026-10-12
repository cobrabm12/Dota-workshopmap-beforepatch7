-- Demolish (6.88, ursul de nivel 4): +33% rezistenta la magie si +40% daune (din atacuri) la cladiri.
-- (Varianta moderna: +20% la cladiri, fara rezistenta la magie - nu exista in 6.88.)
require("dota688/val")
LinkLuaModifier("modifier_dota688_lone_druid_spirit_bear_demolish", "abilities/heroes/dota688_lone_druid_spirit_bear_demolish", LUA_MODIFIER_MOTION_NONE)
dota688_lone_druid_spirit_bear_demolish = class({})
function dota688_lone_druid_spirit_bear_demolish:GetIntrinsicModifierName() return "modifier_dota688_lone_druid_spirit_bear_demolish" end

modifier_dota688_lone_druid_spirit_bear_demolish = class({})
function modifier_dota688_lone_druid_spirit_bear_demolish:IsHidden() return true end
function modifier_dota688_lone_druid_spirit_bear_demolish:IsPurgable() return false end
function modifier_dota688_lone_druid_spirit_bear_demolish:DeclareFunctions()
	return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE }
end
function modifier_dota688_lone_druid_spirit_bear_demolish:GetModifierMagicalResistanceBonus()
	if self:GetParent():PassivesDisabled() then return 0 end
	return Dota688Val(self, "spell_resistance")
end
function modifier_dota688_lone_druid_spirit_bear_demolish:GetModifierDamageOutgoing_Percentage(params)
	if self:GetParent():PassivesDisabled() then return 0 end
	if params and params.target and params.target:IsBuilding() and params.inflictor == nil then
		return Dota688Val(self, "bonus_building_damage")
	end
	return 0
end
