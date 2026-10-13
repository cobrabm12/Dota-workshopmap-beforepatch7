-- Decrepify (6.88): tinta devine eterica 3.5 s: inamic -30/40/50/60% MS si +30..60% daune magice primite; aliat: -25% daune magice primite.
require("dota688/val")
LinkLuaModifier("modifier_dota688_pugna_decrepify", "abilities/heroes/dota688_pugna_decrepify", LUA_MODIFIER_MOTION_NONE)
dota688_pugna_decrepify = class({})
function dota688_pugna_decrepify:CastFilterResultTarget(target)
	if target:IsBuilding() or target:IsOther() then return UF_FAIL_CUSTOM end
	if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() and target:IsMagicImmune() then return UF_FAIL_MAGIC_IMMUNE_ENEMY end
	return UF_SUCCESS
end
function dota688_pugna_decrepify:OnSpellStart()
	local target = self:GetCursorTarget()
	local enemy = target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber()
	if enemy and target:TriggerSpellAbsorb(self) then return end
	target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_pugna_decrepify", { duration = self:GetDuration() })
	target:EmitSound("Hero_Pugna.Decrepify")
end
modifier_dota688_pugna_decrepify = class({})
function modifier_dota688_pugna_decrepify:IsPurgable() return true end
function modifier_dota688_pugna_decrepify:IsDebuff() return self:GetParent():GetTeamNumber() ~= self:GetCaster():GetTeamNumber() end
function modifier_dota688_pugna_decrepify:GetStatusEffectName() return "particles/status_fx/status_effect_ghost.vpcf" end
function modifier_dota688_pugna_decrepify:CheckState() return { [MODIFIER_STATE_DISARMED] = true, [MODIFIER_STATE_ATTACK_IMMUNE] = true } end
function modifier_dota688_pugna_decrepify:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS } end
function modifier_dota688_pugna_decrepify:GetModifierMoveSpeedBonus_Percentage()
	if not self:IsDebuff() then return Dota688Val(self, "bonus_movement_speed_allies") end
	return Dota688Val(self, "bonus_movement_speed")
end
function modifier_dota688_pugna_decrepify:GetModifierMagicalResistanceBonus()
	if not self:IsDebuff() then return -Dota688Val(self, "bonus_spell_damage_pct_allies") end
	return Dota688Val(self, "bonus_spell_damage_pct")
end
