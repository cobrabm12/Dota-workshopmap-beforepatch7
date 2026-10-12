-- Battle Trance (6.88): Troll si toti eroii aliati (global, fara iluzii) primesc +60/120/180 viteza de atac 5 s.
-- (Varianta 7.x - doar Troll, atac fortat, nu poate muri, lifesteal - nu exista in 6.88.)
require("dota688/val")
LinkLuaModifier("modifier_dota688_troll_warlord_battle_trance", "abilities/heroes/dota688_troll_warlord_battle_trance", LUA_MODIFIER_MOTION_NONE)
dota688_troll_warlord_battle_trance = class({})
function dota688_troll_warlord_battle_trance:OnSpellStart()
	local caster = self:GetCaster()
	local dur = self:GetSpecialValueFor("trance_duration")
	caster:EmitSound("Hero_TrollWarlord.BattleTrance.Cast")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_troll_warlord/troll_warlord_battletrance_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	for _, h in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)) do
		h:AddNewModifier(caster, self, "modifier_dota688_troll_warlord_battle_trance", { duration = dur })
	end
end

modifier_dota688_troll_warlord_battle_trance = class({})
function modifier_dota688_troll_warlord_battle_trance:IsPurgable() return true end
function modifier_dota688_troll_warlord_battle_trance:GetTexture() return "troll_warlord_battle_trance" end
function modifier_dota688_troll_warlord_battle_trance:GetEffectName() return "particles/units/heroes/hero_troll_warlord/troll_warlord_battletrance_buff.vpcf" end
function modifier_dota688_troll_warlord_battle_trance:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_troll_warlord_battle_trance:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_troll_warlord_battle_trance:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "attack_speed") end
