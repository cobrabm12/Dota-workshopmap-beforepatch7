-- Rage (6.88): imunitate la magie + 50/60/70/80 AS pentru 3/4/5/6 s; purge la activare.
require("dota688/val")
LinkLuaModifier("modifier_dota688_life_stealer_rage", "abilities/heroes/dota688_life_stealer_rage", LUA_MODIFIER_MOTION_NONE)
dota688_life_stealer_rage = class({})
function dota688_life_stealer_rage:OnSpellStart()
	local caster = self:GetCaster()
	caster:Purge(false, true, false, true, true)
	caster:AddNewModifier(caster, self, "modifier_dota688_life_stealer_rage", { duration = self:GetSpecialValueFor("duration") })
	caster:EmitSound("Hero_LifeStealer.Rage")
end
modifier_dota688_life_stealer_rage = class({})
function modifier_dota688_life_stealer_rage:IsPurgable() return false end
function modifier_dota688_life_stealer_rage:GetEffectName() return "particles/units/heroes/hero_life_stealer/life_stealer_rage.vpcf" end
function modifier_dota688_life_stealer_rage:CheckState() return { [MODIFIER_STATE_MAGIC_IMMUNE] = true } end
function modifier_dota688_life_stealer_rage:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_life_stealer_rage:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "attack_speed_bonus") end
