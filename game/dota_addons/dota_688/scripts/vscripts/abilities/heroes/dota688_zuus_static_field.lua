-- Static Field (6.88): pasiv; de fiecare data cand Zeus foloseste o abilitate (itemele nu declanseaza), toti inamicii din 1200
-- (eroi si creepi, fara sa fie nevoie sa fie vizibili) pierd 4/6/8/10% din HP-ul curent ca daune magice, inaintea daunelor
-- spell-ului. Nu afecteaza unitatile imune la magie. Fara declansarea moderna la atac / la lovirea cu abilitati.
local F = "abilities/heroes/dota688_zuus_static_field"
LinkLuaModifier("modifier_dota688_zuus_static_field", F, LUA_MODIFIER_MOTION_NONE)

dota688_zuus_static_field = class({})
function dota688_zuus_static_field:GetIntrinsicModifierName() return "modifier_dota688_zuus_static_field" end

modifier_dota688_zuus_static_field = class({})
function modifier_dota688_zuus_static_field:IsHidden() return true end
function modifier_dota688_zuus_static_field:IsPurgable() return false end
function modifier_dota688_zuus_static_field:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
function modifier_dota688_zuus_static_field:OnAbilityExecuted(params)
	if not IsServer() then return end
	local p = self:GetParent()
	if params.unit ~= p or not params.ability or params.ability:IsNull() or params.ability:IsItem() then return end
	if p:IsIllusion() or p:PassivesDisabled() then return end
	local a = self:GetAbility()
	if not a or a:IsNull() or a:GetLevel() < 1 then return end
	local pct = a:GetSpecialValueFor("damage_health_pct") / 100
	for _, e in ipairs(FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, a:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if not e:IsMagicImmune() then
			local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_static_field.vpcf", PATTACH_ABSORIGIN_FOLLOW, e)
			ParticleManager:ReleaseParticleIndex(fx)
			e:EmitSound("Hero_Zuus.StaticField")
			ApplyDamage({ victim = e, attacker = p, damage = e:GetHealth() * pct, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
		end
	end
end
