-- Warcry (6.88): Sven si aliatii din 900 primesc +12% MS si +5/10/15/20 armura pentru 8 s.
require("dota688/val")
LinkLuaModifier("modifier_dota688_sven_warcry", "abilities/heroes/dota688_sven_warcry", LUA_MODIFIER_MOTION_NONE)
dota688_sven_warcry = class({})
function dota688_sven_warcry:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_Sven.WarCry")
	local units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("warcry_radius"),
		DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, u in ipairs(units) do
		u:AddNewModifier(caster, self, "modifier_dota688_sven_warcry", { duration = self:GetDuration() })
	end
end
modifier_dota688_sven_warcry = class({})
function modifier_dota688_sven_warcry:IsPurgable() return true end
function modifier_dota688_sven_warcry:GetEffectName() return "particles/units/heroes/hero_sven/sven_warcry_buff.vpcf" end
function modifier_dota688_sven_warcry:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function modifier_dota688_sven_warcry:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "warcry_movespeed") end
function modifier_dota688_sven_warcry:GetModifierPhysicalArmorBonus() return Dota688Val(self, "warcry_armor") end
