-- Inner Beast (6.88): aura pasiva (4 niveluri), raza 900: aliatii (eroi si unitati) primesc +15/25/35/45 viteza de atac.
require("dota688/val")
local F = "abilities/heroes/dota688_beastmaster_inner_beast"
LinkLuaModifier("modifier_dota688_beastmaster_inner_beast", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_beastmaster_inner_beast_effect", F, LUA_MODIFIER_MOTION_NONE)
dota688_beastmaster_inner_beast = class({})
function dota688_beastmaster_inner_beast:GetIntrinsicModifierName() return "modifier_dota688_beastmaster_inner_beast" end

modifier_dota688_beastmaster_inner_beast = class({})
function modifier_dota688_beastmaster_inner_beast:IsHidden() return true end
function modifier_dota688_beastmaster_inner_beast:IsPurgable() return false end
function modifier_dota688_beastmaster_inner_beast:IsAura()
	local a = self:GetAbility()
	return a ~= nil and a:GetLevel() > 0 and not self:GetParent():PassivesDisabled()
end
function modifier_dota688_beastmaster_inner_beast:GetAuraRadius() return Dota688Val(self, "radius") end
function modifier_dota688_beastmaster_inner_beast:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_beastmaster_inner_beast:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_beastmaster_inner_beast:GetModifierAura() return "modifier_dota688_beastmaster_inner_beast_effect" end

modifier_dota688_beastmaster_inner_beast_effect = class({})
function modifier_dota688_beastmaster_inner_beast_effect:IsPurgable() return false end
function modifier_dota688_beastmaster_inner_beast_effect:GetTexture() return "beastmaster_inner_beast" end
function modifier_dota688_beastmaster_inner_beast_effect:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_beastmaster_inner_beast_effect:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "bonus_attack_speed") end
