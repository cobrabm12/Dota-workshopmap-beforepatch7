-- Shadow Dance (6.88): 4 s invizibilitate care nu se rupe la atac/cast; pasiv: cand nu e vazut de inamici, +30/35/40% MS si 3/5/7% HP regen/s.
local F = "abilities/heroes/dota688_slark_shadow_dance"
LinkLuaModifier("modifier_dota688_slark_shadow_dance", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_slark_shadow_dance_passive", F, LUA_MODIFIER_MOTION_NONE)
dota688_slark_shadow_dance = class({})
function dota688_slark_shadow_dance:GetIntrinsicModifierName() return "modifier_dota688_slark_shadow_dance_passive" end
function dota688_slark_shadow_dance:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_dota688_slark_shadow_dance", { duration = self:GetSpecialValueFor("duration") })
	self:GetCaster():EmitSound("Hero_Slark.ShadowDance")
end
modifier_dota688_slark_shadow_dance = class({})
function modifier_dota688_slark_shadow_dance:IsPurgable() return false end
function modifier_dota688_slark_shadow_dance:GetEffectName() return "particles/units/heroes/hero_slark/slark_shadow_dance.vpcf" end
function modifier_dota688_slark_shadow_dance:CheckState() return { [MODIFIER_STATE_INVISIBLE] = true, [MODIFIER_STATE_TRUESIGHT_IMMUNE] = true } end
function modifier_dota688_slark_shadow_dance:DeclareFunctions() return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL } end
function modifier_dota688_slark_shadow_dance:GetModifierInvisibilityLevel() return 1 end
modifier_dota688_slark_shadow_dance_passive = class({})
function modifier_dota688_slark_shadow_dance_passive:IsHidden() return self:GetStackCount() == 0 end
function modifier_dota688_slark_shadow_dance_passive:IsPurgable() return false end
function modifier_dota688_slark_shadow_dance_passive:OnCreated() if IsServer() then self:StartIntervalThink(0.5) end end
function modifier_dota688_slark_shadow_dance_passive:OnIntervalThink()
	local p = self:GetParent()
	local enemyTeam = (p:GetTeamNumber() == DOTA_TEAM_GOODGUYS) and DOTA_TEAM_BADGUYS or DOTA_TEAM_GOODGUYS
	local seen = p:IsInvisible() and false or (IsLocationVisible(enemyTeam, p:GetAbsOrigin()) and not p:IsInvisible())
	-- aproximare: "vazut" = pozitia e vizibila pentru echipa inamica (nu include true sight pe invizibil)
	self:SetStackCount((seen or p:PassivesDisabled()) and 0 or 1)
end
function modifier_dota688_slark_shadow_dance_passive:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE } end
function modifier_dota688_slark_shadow_dance_passive:GetModifierMoveSpeedBonus_Percentage() return self:GetStackCount() == 1 and self:GetAbility():GetSpecialValueFor("bonus_movement_speed") or 0 end
function modifier_dota688_slark_shadow_dance_passive:GetModifierHealthRegenPercentage() return self:GetStackCount() == 1 and self:GetAbility():GetSpecialValueFor("bonus_regen_pct") or 0 end
