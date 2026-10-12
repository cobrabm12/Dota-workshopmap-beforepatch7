-- Chilling Touch (6.88): aliatii din 525 primesc 3/4/5/6 atacuri cu +50/60/70/80 daune magice, dar -20% AS, pentru 30 s.
require("dota688/val")
LinkLuaModifier("modifier_dota688_aa_chilling_touch", "abilities/heroes/dota688_ancient_apparition_chilling_touch", LUA_MODIFIER_MOTION_NONE)
dota688_ancient_apparition_chilling_touch = class({})
function dota688_ancient_apparition_chilling_touch:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_ancient_apparition_chilling_touch:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	caster:EmitSound("Hero_Ancient_Apparition.ChillingTouch.Cast")
	caster:AddNewModifier(caster, self, "modifier_dota688_aa_chilling_touch", { duration = self:GetDuration() })   -- "always receives the buff"
	for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if u ~= caster then u:AddNewModifier(caster, self, "modifier_dota688_aa_chilling_touch", { duration = self:GetDuration() }) end
	end
end
modifier_dota688_aa_chilling_touch = class({})
function modifier_dota688_aa_chilling_touch:IsPurgable() return true end
function modifier_dota688_aa_chilling_touch:GetEffectName() return "particles/units/heroes/hero_ancient_apparition/ancient_apparition_chilling_touch_buff.vpcf" end
function modifier_dota688_aa_chilling_touch:OnCreated() self:SetStackCount(Dota688Val(self, "max_attacks")) end
function modifier_dota688_aa_chilling_touch:OnRefresh() self:OnCreated() end
function modifier_dota688_aa_chilling_touch:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL, MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_aa_chilling_touch:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "attack_speed_pct") end
function modifier_dota688_aa_chilling_touch:GetModifierProcAttack_BonusDamage_Magical(params)
	if params.target and not params.target:IsBuilding() and not params.target:IsOther() and self:GetStackCount() > 0 then return Dota688Val(self, "bonus_damage") end
	return 0
end
function modifier_dota688_aa_chilling_touch:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() or not params.target or params.target:IsBuilding() or params.target:IsOther() then return end
	self:DecrementStackCount()
	if self:GetStackCount() <= 0 then self:Destroy() end
end
