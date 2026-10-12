-- Battle Cry (6.88, doar in forma de urs, nivelul lui True Form): +70/100/130 daune si +10/15/20 armura pentru Lone Druid si
-- unitatile controlate de el (urs, iluzii, unitati dominate) din raza de 1000, 6 s; cooldown 60, 50 mana.
-- (KV-ul 6.88 are "DOTA_ABILITY_TYPE_ULTIMATE" in AbilityBehavior; comportamentul corect e dat de GetBehavior.)
require("dota688/val")
LinkLuaModifier("modifier_dota688_lone_druid_true_form_battle_cry", "abilities/heroes/dota688_lone_druid_true_form_battle_cry", LUA_MODIFIER_MOTION_NONE)
dota688_lone_druid_true_form_battle_cry = class({})
function dota688_lone_druid_true_form_battle_cry:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_HIDDEN + DOTA_ABILITY_BEHAVIOR_NOT_LEARNABLE
end
function dota688_lone_druid_true_form_battle_cry:OnSpellStart()
	local caster = self:GetCaster()
	local pid = caster:GetPlayerOwnerID()
	caster:EmitSound("Hero_LoneDruid.BattleCry")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/lone_druid_battle_cry_overhead.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("range"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if u == caster or u:GetPlayerOwnerID() == pid then
			u:AddNewModifier(caster, self, "modifier_dota688_lone_druid_true_form_battle_cry", { duration = self:GetSpecialValueFor("cry_duration") })
		end
	end
end

modifier_dota688_lone_druid_true_form_battle_cry = class({})
function modifier_dota688_lone_druid_true_form_battle_cry:IsPurgable() return true end
function modifier_dota688_lone_druid_true_form_battle_cry:GetEffectName() return "particles/units/heroes/hero_lone_druid/lone_druid_battle_cry_buff.vpcf" end
function modifier_dota688_lone_druid_true_form_battle_cry:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_lone_druid_true_form_battle_cry:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function modifier_dota688_lone_druid_true_form_battle_cry:GetModifierPreAttack_BonusDamage() return Dota688Val(self, "bonus_damage") end
function modifier_dota688_lone_druid_true_form_battle_cry:GetModifierPhysicalArmorBonus() return Dota688Val(self, "bonus_armor") end
