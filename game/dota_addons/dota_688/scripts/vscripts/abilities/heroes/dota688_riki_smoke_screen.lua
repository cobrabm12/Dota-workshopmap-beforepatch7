-- Smoke Screen (6.88): nor de fum 250-325 raza, 6 s: inamicii sunt silence, rateaza 40/50/60/70% si sunt incetiniti 13/17/21/25%.
local F = "abilities/heroes/dota688_riki_smoke_screen"
LinkLuaModifier("modifier_dota688_riki_smoke_screen_thinker", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_riki_smoke_screen", F, LUA_MODIFIER_MOTION_NONE)
dota688_riki_smoke_screen = class({})
function dota688_riki_smoke_screen:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_riki_smoke_screen:OnSpellStart()
	local pos = self:GetCursorPosition()
	CreateModifierThinker(self:GetCaster(), self, "modifier_dota688_riki_smoke_screen_thinker", { duration = self:GetSpecialValueFor("duration") }, pos, self:GetCaster():GetTeamNumber(), false)
	EmitSoundOnLocationWithCaster(pos, "Hero_Riki.Smoke_Screen", self:GetCaster())
end

modifier_dota688_riki_smoke_screen_thinker = class({})
function modifier_dota688_riki_smoke_screen_thinker:IsAura() return true end
function modifier_dota688_riki_smoke_screen_thinker:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_dota688_riki_smoke_screen_thinker:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_dota688_riki_smoke_screen_thinker:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_riki_smoke_screen_thinker:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NOT_MAGIC_IMMUNE_ALLIES end
function modifier_dota688_riki_smoke_screen_thinker:GetModifierAura() return "modifier_dota688_riki_smoke_screen" end
function modifier_dota688_riki_smoke_screen_thinker:OnCreated()
	if not IsServer() then return end
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_smokebomb.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	local r = self:GetAbility():GetSpecialValueFor("radius")
	ParticleManager:SetParticleControl(self.fx, 0, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.fx, 1, Vector(r, r, r))
end
function modifier_dota688_riki_smoke_screen_thinker:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle(self.fx, false)
		UTIL_Remove(self:GetParent())
	end
end

modifier_dota688_riki_smoke_screen = class({})
function modifier_dota688_riki_smoke_screen:IsDebuff() return true end
function modifier_dota688_riki_smoke_screen:IsPurgable() return false end
function modifier_dota688_riki_smoke_screen:CheckState() return { [MODIFIER_STATE_SILENCED] = true } end
function modifier_dota688_riki_smoke_screen:DeclareFunctions() return { MODIFIER_PROPERTY_MISS_PERCENTAGE, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_riki_smoke_screen:GetModifierMiss_Percentage() return self:GetAbility():GetSpecialValueFor("miss_rate") end
function modifier_dota688_riki_smoke_screen:GetModifierMoveSpeedBonus_Percentage() return -self:GetAbility():GetSpecialValueFor("movement_speed_reduction") end
