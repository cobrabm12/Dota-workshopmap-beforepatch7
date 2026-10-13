-- Arcane Orb (6.88, orb): daune pure egale cu 6/7/8/9% din mana curenta; iluziile iau 100-400 in plus; fura 1/2/3/4 INT pentru 80 s de la eroi.
local F = "abilities/heroes/dota688_obsidian_destroyer_arcane_orb"
LinkLuaModifier("modifier_dota688_od_int_steal", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_od_int_loss", F, LUA_MODIFIER_MOTION_NONE)
dota688_obsidian_destroyer_arcane_orb = class({})
function dota688_obsidian_destroyer_arcane_orb:GetProjectileName() return "particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_base_attack.vpcf" end
function dota688_obsidian_destroyer_arcane_orb:OnOrbImpact(params)
	local caster, target = self:GetCaster(), params.target
	if not target or target:IsBuilding() or target:IsOther() then return end
	local dmg = caster:GetMana() * self:GetSpecialValueFor("mana_pool_damage_pct") / 100
	if target:IsIllusion() or target:IsSummoned() then dmg = dmg + self:GetSpecialValueFor("illusion_damage") end   -- "bonus damage to summoned units and illusions"
	ApplyDamage({ victim = target, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_PURE, ability = self })
	if target:IsRealHero() then
		local n = self:GetSpecialValueFor("int_steal")
		local d = self:GetSpecialValueFor("int_steal_duration")
		local m = caster:AddNewModifier(caster, self, "modifier_dota688_od_int_steal", { duration = d })
		local l = target:AddNewModifier(caster, self, "modifier_dota688_od_int_loss", { duration = d })
		for i = 1, n do m:IncrementStackCount(); l:IncrementStackCount() end
	end
end
function dota688_obsidian_destroyer_arcane_orb:OnSpellStart()
	local t = self:GetCursorTarget(); if t then self:OnOrbImpact({ target = t }) end
end
modifier_dota688_od_int_steal = class({})
function modifier_dota688_od_int_steal:IsPurgable() return false end
function modifier_dota688_od_int_steal:DeclareFunctions() return { MODIFIER_PROPERTY_STATS_INTELLECT_BONUS } end
function modifier_dota688_od_int_steal:GetModifierBonusStats_Intellect() return self:GetStackCount() end
modifier_dota688_od_int_loss = class({})
function modifier_dota688_od_int_loss:IsDebuff() return true end
function modifier_dota688_od_int_loss:IsPurgable() return false end
function modifier_dota688_od_int_loss:DeclareFunctions() return { MODIFIER_PROPERTY_STATS_INTELLECT_BONUS } end
function modifier_dota688_od_int_loss:GetModifierBonusStats_Intellect() return -self:GetStackCount() end
