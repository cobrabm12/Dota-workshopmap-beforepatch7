-- Vampiric Aura (6.88): aura de 900; unitatile aliate melee fura 15/20/25/30% din daunele atacurilor.
-- Toggle: activat = toate unitatile melee aliate; dezactivat = doar eroii (si Wraith King).
LinkLuaModifier("modifier_dota688_skeleton_king_vampiric_aura", "abilities/heroes/dota688_skeleton_king_vampiric_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_skeleton_king_vampiric_aura_effect", "abilities/heroes/dota688_skeleton_king_vampiric_aura", LUA_MODIFIER_MOTION_NONE)

dota688_skeleton_king_vampiric_aura = class({})
function dota688_skeleton_king_vampiric_aura:GetIntrinsicModifierName() return "modifier_dota688_skeleton_king_vampiric_aura" end
function dota688_skeleton_king_vampiric_aura:OnToggle() end

modifier_dota688_skeleton_king_vampiric_aura = class({})
function modifier_dota688_skeleton_king_vampiric_aura:IsHidden() return true end
function modifier_dota688_skeleton_king_vampiric_aura:IsPurgable() return false end
function modifier_dota688_skeleton_king_vampiric_aura:IsAura() return true end
function modifier_dota688_skeleton_king_vampiric_aura:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("vampiric_aura_radius") end
function modifier_dota688_skeleton_king_vampiric_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_skeleton_king_vampiric_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_skeleton_king_vampiric_aura:GetModifierAura() return "modifier_dota688_skeleton_king_vampiric_aura_effect" end
function modifier_dota688_skeleton_king_vampiric_aura:GetAuraEntityReject(unit)
	if unit:IsRangedAttacker() then return true end
	if self:GetAbility():GetToggleState() then return false end
	return not (unit:IsHero() or unit == self:GetParent())
end

modifier_dota688_skeleton_king_vampiric_aura_effect = class({})
function modifier_dota688_skeleton_king_vampiric_aura_effect:IsPurgable() return false end
function modifier_dota688_skeleton_king_vampiric_aura_effect:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_skeleton_king_vampiric_aura_effect:OnAttackLanded(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	if params.attacker ~= parent or parent:IsRangedAttacker() then return end
	local target = params.target
	if not target or target:IsBuilding() or target:IsOther() or target:GetTeamNumber() == parent:GetTeamNumber() then return end
	local pct = self:GetAbility():GetSpecialValueFor("vampiric_aura")
	local heal = params.damage * pct / 100
	if heal > 0 then
		parent:Heal(heal, self:GetAbility())
		local fx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:ReleaseParticleIndex(fx)
	end
end
