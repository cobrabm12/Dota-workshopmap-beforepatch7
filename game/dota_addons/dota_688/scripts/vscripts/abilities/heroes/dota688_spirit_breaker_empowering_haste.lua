-- Empowering Haste (6.88): aura 900: +6/10/14/18% MS; activ (cd 12): +3/5/7/9% in plus pentru 6 s, apoi aura e redusa la jumatate cat dureaza cooldown-ul... (simplificat: bonusul extra 6 s).
local F = "abilities/heroes/dota688_spirit_breaker_empowering_haste"
LinkLuaModifier("modifier_dota688_spirit_breaker_empowering_haste", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_spirit_breaker_empowering_haste_effect", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_spirit_breaker_empowering_haste_active", F, LUA_MODIFIER_MOTION_NONE)
dota688_spirit_breaker_empowering_haste = class({})
function dota688_spirit_breaker_empowering_haste:GetIntrinsicModifierName() return "modifier_dota688_spirit_breaker_empowering_haste" end
function dota688_spirit_breaker_empowering_haste:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_dota688_spirit_breaker_empowering_haste_active", { duration = self:GetSpecialValueFor("duration") })
	self:GetCaster():EmitSound("Hero_SpiritBreaker.EmpoweringHaste")
end
modifier_dota688_spirit_breaker_empowering_haste_active = class({})
function modifier_dota688_spirit_breaker_empowering_haste_active:IsPurgable() return false end

modifier_dota688_spirit_breaker_empowering_haste = class({})
function modifier_dota688_spirit_breaker_empowering_haste:IsHidden() return true end
function modifier_dota688_spirit_breaker_empowering_haste:IsPurgable() return false end
function modifier_dota688_spirit_breaker_empowering_haste:IsAura() return not self:GetParent():PassivesDisabled() end
function modifier_dota688_spirit_breaker_empowering_haste:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("aura_radius") end
function modifier_dota688_spirit_breaker_empowering_haste:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_spirit_breaker_empowering_haste:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_spirit_breaker_empowering_haste:GetModifierAura() return "modifier_dota688_spirit_breaker_empowering_haste_effect" end
modifier_dota688_spirit_breaker_empowering_haste_effect = class({})
function modifier_dota688_spirit_breaker_empowering_haste_effect:IsPurgable() return false end
function modifier_dota688_spirit_breaker_empowering_haste_effect:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_spirit_breaker_empowering_haste_effect:GetModifierMoveSpeedBonus_Percentage()
	local a = self:GetAbility()
	if not a or a:IsNull() then return 0 end
	local v = a:GetSpecialValueFor("bonus_movespeed_pct")
	if self:GetCaster():HasModifier("modifier_dota688_spirit_breaker_empowering_haste_active") then v = v + a:GetSpecialValueFor("bonus_movespeed_pct_extra") end
	return v
end
