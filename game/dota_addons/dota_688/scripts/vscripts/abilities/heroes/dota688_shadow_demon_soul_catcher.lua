-- Soul Catcher (6.88): un erou inamic aleatoriu din zona (450) primeste +20/30/40/50% daune pentru 12 s.
require("dota688/val")
LinkLuaModifier("modifier_dota688_shadow_demon_soul_catcher", "abilities/heroes/dota688_shadow_demon_soul_catcher", LUA_MODIFIER_MOTION_NONE)
dota688_shadow_demon_soul_catcher = class({})
function dota688_shadow_demon_soul_catcher:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_shadow_demon_soul_catcher:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	caster:EmitSound("Hero_ShadowDemon.SoulCatcher.Cast")
	local heroes = FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_ANY_ORDER, false)
	local pool = heroes
	if #pool == 0 then
		pool = FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	end
	if #pool == 0 then return end
	local t = pool[RandomInt(1, #pool)]
	t:AddNewModifier(caster, self, "modifier_dota688_shadow_demon_soul_catcher", { duration = self:GetDuration() })
	t:EmitSound("Hero_ShadowDemon.SoulCatcher.Target")
end
modifier_dota688_shadow_demon_soul_catcher = class({})
function modifier_dota688_shadow_demon_soul_catcher:IsDebuff() return true end
function modifier_dota688_shadow_demon_soul_catcher:IsPurgable() return false end
function modifier_dota688_shadow_demon_soul_catcher:GetEffectName() return "particles/units/heroes/hero_shadow_demon/shadow_demon_soul_catcher_debuff.vpcf" end
function modifier_dota688_shadow_demon_soul_catcher:DeclareFunctions() return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_dota688_shadow_demon_soul_catcher:GetModifierIncomingDamage_Percentage() return Dota688Val(self, "bonus_damage_taken") end
