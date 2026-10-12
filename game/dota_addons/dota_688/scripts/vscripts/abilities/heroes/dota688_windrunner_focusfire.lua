-- Focus Fire (6.88): 20 s, viteza de atac maxima (+500) pe tinta aleasa, cu -50/40/30% daune. Trece prin imunitate.
-- Scepter: cooldown 15, reducere -30/15/0%, atacurile pe tinta nu mai au penalizare la efectele itemelor/UAM.
require("dota688/val")
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_focusfire", "abilities/heroes/dota688_windrunner_focusfire", LUA_MODIFIER_MOTION_NONE)
dota688_windrunner_focusfire = class({})
function dota688_windrunner_focusfire:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetLevelSpecialValueFor("cooldown_scepter", level) end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_windrunner_focusfire:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	caster:EmitSound("Hero_Windrunner.FocusFire.Cast")
	caster:AddNewModifier(caster, self, "modifier_dota688_focusfire", { duration = self:GetDuration(), target = target:entindex() })
	caster:MoveToTargetToAttack(target)
end
modifier_dota688_focusfire = class({})
function modifier_dota688_focusfire:IsPurgable() return false end
function modifier_dota688_focusfire:GetEffectName() return "particles/units/heroes/hero_windrunner/windrunner_focusfire.vpcf" end
function modifier_dota688_focusfire:OnCreated(kv)
	if not IsServer() then return end
	self.target = EntIndexToHScript(kv.target)
	self:StartIntervalThink(0.1)
end
function modifier_dota688_focusfire:OnIntervalThink()
	local p = self:GetParent()
	if not self.target or self.target:IsNull() or not self.target:IsAlive() then self:Destroy() return end
	self:SetStackCount((p:GetAttackTarget() == self.target) and 1 or 0)
end
function modifier_dota688_focusfire:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE } end
function modifier_dota688_focusfire:GetModifierAttackSpeedBonus_Constant()
	if self:GetStackCount() == 1 then return Dota688Val(self, "bonus_attack_speed") end
	return 0
end
function modifier_dota688_focusfire:GetModifierDamageOutgoing_Percentage(params)
	if not params or params.inflictor ~= nil or not self.target or params.target ~= self.target then return 0 end
	local a = self:GetAbility()
	if not a or a:IsNull() then return 0 end
	if Dota688HasScepter(self:GetParent()) then return a:GetSpecialValueFor("focusfire_damage_reduction_scepter") end
	return a:GetSpecialValueFor("focusfire_damage_reduction")
end
