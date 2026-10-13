-- Surge (6.88): unitatea aliata tinta primeste viteza de miscare maxima (522, maximul din 6.88) timp de 3/4.5/6/7.5 s si nu
-- poate fi incetinita cat timp efectul e activ (doar scoaterea efectului, de ex. prin purge, o face din nou incetinibila).
-- Abilitatea curenta da in plus miscare fazata (trece prin unitati), pe care 6.88 nu o avea.
local F = "abilities/heroes/dota688_dark_seer_surge"
LinkLuaModifier("modifier_dota688_dark_seer_surge", F, LUA_MODIFIER_MOTION_NONE)

local SURGE_SPEED = 522   -- viteza maxima in 6.88

dota688_dark_seer_surge = class({})
function dota688_dark_seer_surge:GetCastAnimation() return ACT_DOTA_CAST_ABILITY_2 end
function dota688_dark_seer_surge:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if not target then return end
	target:EmitSound("Hero_Dark_Seer.Surge")
	target:AddNewModifier(caster, self, "modifier_dota688_dark_seer_surge", { duration = self:GetSpecialValueFor("duration") })
end

-- viteza fixata la 522 (incetinirile nu o scad); Hex-ul (viteza absoluta proprie) are prioritate, ca la runa Haste
modifier_dota688_dark_seer_surge = class({})
function modifier_dota688_dark_seer_surge:IsPurgable() return true end
function modifier_dota688_dark_seer_surge:GetEffectName() return "particles/units/heroes/hero_dark_seer/dark_seer_surge.vpcf" end
function modifier_dota688_dark_seer_surge:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_dark_seer_surge:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE } end
function modifier_dota688_dark_seer_surge:GetModifierMoveSpeed_Absolute()
	if self:GetParent():IsHexed() then return 0 end
	return SURGE_SPEED
end
