-- Enfeeble (6.88): -30/60/90/120 daune de atac pentru 20 s.
require("dota688/val")
LinkLuaModifier("modifier_dota688_bane_enfeeble", "abilities/heroes/dota688_bane_enfeeble", LUA_MODIFIER_MOTION_NONE)
dota688_bane_enfeeble = class({})
function dota688_bane_enfeeble:OnSpellStart()
	local t = self:GetCursorTarget()
	if t:TriggerSpellAbsorb(self) then return end
	t:AddNewModifier(self:GetCaster(), self, "modifier_dota688_bane_enfeeble", { duration = self:GetDuration() })
	t:EmitSound("Hero_Bane.Enfeeble")
end
modifier_dota688_bane_enfeeble = class({})
function modifier_dota688_bane_enfeeble:IsDebuff() return true end
function modifier_dota688_bane_enfeeble:IsPurgable() return false end   -- 6.88: "Enfeeble cannot be purged"
function modifier_dota688_bane_enfeeble:GetEffectName() return "particles/units/heroes/hero_bane/bane_enfeeble.vpcf" end
function modifier_dota688_bane_enfeeble:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE } end
function modifier_dota688_bane_enfeeble:GetModifierPreAttack_BonusDamage() return Dota688Val(self, "enfeeble_attack_reduction") end
