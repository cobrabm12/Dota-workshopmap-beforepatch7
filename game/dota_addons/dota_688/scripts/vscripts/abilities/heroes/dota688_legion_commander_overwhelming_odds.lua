-- Overwhelming Odds (6.88): tintit pe un punct (raza de cast 1000), zona de 330: fiecare inamic primeste 40/80/120/160 daune magice
-- + 14/16/18/20 pentru fiecare unitate (non-erou) si + 20/40/60/80 pentru fiecare erou din zona; iluziile si unitatile invocate primesc
-- in plus 25% din viata lor curenta. Legion primeste +3% viteza de miscare pentru fiecare unitate si +9% pentru fiecare erou atins, 7 s.
-- (Varianta moderna: centrata pe Legion, viteza de atac, incetinire - nu exista in 6.88.)
local F = "abilities/heroes/dota688_legion_commander_overwhelming_odds"
LinkLuaModifier("modifier_dota688_legion_commander_overwhelming_odds", F, LUA_MODIFIER_MOTION_NONE)

dota688_legion_commander_overwhelming_odds = class({})
function dota688_legion_commander_overwhelming_odds:GetAOERadius() return self:GetSpecialValueFor("radius") end

function dota688_legion_commander_overwhelming_odds:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local radius = self:GetSpecialValueFor("radius")
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	local heroes, units = 0, 0
	for _, e in ipairs(enemies) do
		if e:IsHero() then heroes = heroes + 1 else units = units + 1 end   -- iluziile conteaza ca eroi
	end
	local damage = self:GetSpecialValueFor("damage") + units * self:GetSpecialValueFor("damage_per_unit") + heroes * self:GetSpecialValueFor("damage_per_hero")
	local pct = self:GetSpecialValueFor("illusion_dmg_pct")

	caster:EmitSound("Hero_LegionCommander.Overwhelming.Cast")
	EmitSoundOnLocationWithCaster(point, "Hero_LegionCommander.Overwhelming.Location", caster)
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_legion_commander/legion_commander_odds.vpcf", PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(fx, 0, point)
	ParticleManager:SetParticleControl(fx, 1, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(fx, 2, point)
	ParticleManager:SetParticleControl(fx, 3, point)
	ParticleManager:SetParticleControl(fx, 4, Vector(radius, radius, radius))
	ParticleManager:SetParticleControl(fx, 6, point)
	ParticleManager:ReleaseParticleIndex(fx)

	for _, e in ipairs(enemies) do
		local d = damage
		if e:IsIllusion() or e:IsSummoned() then d = d + e:GetHealth() * pct / 100 end
		local hit = ParticleManager:CreateParticle("particles/units/heroes/hero_legion_commander/legion_commander_odds_dmga.vpcf", PATTACH_ABSORIGIN_FOLLOW, e)
		ParticleManager:SetParticleControl(hit, 1, e:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(hit)
		e:EmitSound(e:IsHero() and "Hero_LegionCommander.Overwhelming.Hero" or "Hero_LegionCommander.Overwhelming.Creep")
		ApplyDamage({ victim = e, attacker = caster, damage = d, damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
	end

	local speed = units * self:GetSpecialValueFor("bonus_speed_creeps") + heroes * self:GetSpecialValueFor("bonus_speed_heroes")
	if speed > 0 then
		caster:RemoveModifierByName("modifier_dota688_legion_commander_overwhelming_odds")
		local m = caster:AddNewModifier(caster, self, "modifier_dota688_legion_commander_overwhelming_odds", { duration = self:GetSpecialValueFor("duration") })
		if m then m:SetStackCount(speed) end
		caster:EmitSound("Hero_LegionCommander.Overwhelming.Buff")
	end
end

-- +% viteza de miscare (stack count = procentul, calculat la lansare)
modifier_dota688_legion_commander_overwhelming_odds = class({})
function modifier_dota688_legion_commander_overwhelming_odds:IsPurgable() return true end
function modifier_dota688_legion_commander_overwhelming_odds:GetEffectName() return "particles/units/heroes/hero_legion_commander/legion_commander_odds_buff.vpcf" end
function modifier_dota688_legion_commander_overwhelming_odds:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_legion_commander_overwhelming_odds:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_legion_commander_overwhelming_odds:GetModifierMoveSpeedBonus_Percentage() return self:GetStackCount() end
