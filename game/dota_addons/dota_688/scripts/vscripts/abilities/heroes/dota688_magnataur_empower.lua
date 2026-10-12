-- Empower (6.88): +20/30/40/50% daune si cleave 20/30/40/50% in raza 240 (melee) pentru 40 s.
LinkLuaModifier("modifier_dota688_magnataur_empower", "abilities/heroes/dota688_magnataur_empower", LUA_MODIFIER_MOTION_NONE)
dota688_magnataur_empower = class({})
function dota688_magnataur_empower:OnSpellStart()
	local target = self:GetCursorTarget()
	target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_magnataur_empower", { duration = self:GetSpecialValueFor("empower_duration") })
	target:EmitSound("Hero_Magnataur.Empower.Cast")
end
modifier_dota688_magnataur_empower = class({})
function modifier_dota688_magnataur_empower:IsPurgable() return true end
function modifier_dota688_magnataur_empower:GetEffectName() return "particles/units/heroes/hero_magnataur/magnataur_empower.vpcf" end
function modifier_dota688_magnataur_empower:DeclareFunctions() return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_magnataur_empower:GetModifierBaseDamageOutgoing_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_damage_pct") end
function modifier_dota688_magnataur_empower:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() or self:GetParent():IsRangedAttacker() then return end
	local t = params.target
	if not t or t:IsBuilding() or t:IsOther() or t:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
	local a = self:GetAbility()
	DoCleaveAttack(self:GetParent(), t, a, params.damage * a:GetSpecialValueFor("cleave_damage_pct") / 100, 150, a:GetSpecialValueFor("cleave_radius"), 460, "particles/units/heroes/hero_magnataur/magnataur_empower_cleave_effect.vpcf")
end
