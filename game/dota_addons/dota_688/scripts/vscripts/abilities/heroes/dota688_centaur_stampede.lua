-- Stampede (6.88): toate unitatile aliate (global) primesc viteza maxima 4 s; inamicii atinsi (105) iau 1/2/3 x STR-ul lui Centaur daune magice si sunt incetiniti 100% 1.8 s (o data per unitate).
-- Scepter: eroii afectati iau cu 60% mai putine daune si trec prin copaci/dealuri.
require("dota688/val")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_centaur_stampede"
LinkLuaModifier("modifier_dota688_stampede", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_stampede_slow", F, LUA_MODIFIER_MOTION_NONE)
dota688_centaur_stampede = class({})
function dota688_centaur_stampede:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_Centaur.Stampede.Cast")
	self.hit = {}
	for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		u:AddNewModifier(caster, self, "modifier_dota688_stampede", { duration = self:GetSpecialValueFor("duration") })
	end
end
modifier_dota688_stampede = class({})
function modifier_dota688_stampede:IsPurgable() return false end
function modifier_dota688_stampede:GetEffectName() return "particles/units/heroes/hero_centaur/centaur_stampede_haste_npc.vpcf" end
function modifier_dota688_stampede:OnCreated() if IsServer() then self:StartIntervalThink(0.1) end end
function modifier_dota688_stampede:OnIntervalThink()
	local p, a, caster = self:GetParent(), self:GetAbility(), self:GetCaster()
	if not caster or caster:IsNull() then return end
	a.hit = a.hit or {}
	for _, e in ipairs(FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, a:GetSpecialValueFor("radius") + p:GetHullRadius(), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if not a.hit[e:entindex()] then
			a.hit[e:entindex()] = true
			e:EmitSound("Hero_Centaur.Stampede.Impact")
			ApplyDamage({ victim = e, attacker = caster, damage = a:GetSpecialValueFor("base_damage") + caster:GetStrength() * a:GetSpecialValueFor("strength_damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
			e:AddNewModifier(caster, a, "modifier_dota688_stampede_slow", { duration = a:GetSpecialValueFor("slow_duration") })
		end
	end
end
function modifier_dota688_stampede:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_dota688_stampede:GetModifierMoveSpeed_AbsoluteMin() return 522 end
function modifier_dota688_stampede:GetModifierIncomingDamage_Percentage()
	if self:GetParent():IsHero() and Dota688HasScepter(self:GetCaster()) then return -Dota688Val(self, "damage_reduction") end
	return 0
end
function modifier_dota688_stampede:CheckState()
	if self:GetParent():IsHero() and Dota688HasScepter(self:GetCaster()) then return { [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true } end
	return {}
end
modifier_dota688_stampede_slow = class({})
function modifier_dota688_stampede_slow:IsDebuff() return true end
function modifier_dota688_stampede_slow:IsPurgable() return true end
function modifier_dota688_stampede_slow:GetTexture() return "centaur_stampede" end
function modifier_dota688_stampede_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_stampede_slow:GetModifierMoveSpeedBonus_Percentage() return -Dota688Val(self, "slow_movement_speed") end
