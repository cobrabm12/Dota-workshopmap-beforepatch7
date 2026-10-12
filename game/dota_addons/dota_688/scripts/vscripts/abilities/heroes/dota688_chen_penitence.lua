-- Penitence (6.88): tinta e incetinita 15/20/25/30% si primeste +15/20/25/30% daune, 8 s.
require("dota688/val")
LinkLuaModifier("modifier_dota688_chen_penitence", "abilities/heroes/dota688_chen_penitence", LUA_MODIFIER_MOTION_NONE)
dota688_chen_penitence = class({})
function dota688_chen_penitence:OnSpellStart()
	local t = self:GetCursorTarget()
	if t:TriggerSpellAbsorb(self) then return end
	t:AddNewModifier(self:GetCaster(), self, "modifier_dota688_chen_penitence", { duration = self:GetSpecialValueFor("duration") })
	t:EmitSound("Hero_Chen.PenitenceCast")
end
modifier_dota688_chen_penitence = class({})
function modifier_dota688_chen_penitence:IsDebuff() return true end
function modifier_dota688_chen_penitence:IsPurgable() return true end
function modifier_dota688_chen_penitence:GetEffectName() return "particles/units/heroes/hero_chen/chen_penitence.vpcf" end
function modifier_dota688_chen_penitence:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_dota688_chen_penitence:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "bonus_movement_speed") end
function modifier_dota688_chen_penitence:GetModifierIncomingDamage_Percentage() return Dota688Val(self, "bonus_damage_taken") end
