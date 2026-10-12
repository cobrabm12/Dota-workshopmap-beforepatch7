-- Druid Form (6.88): Lone Druid revine din forma de urs in forma de druid (1.933 s, 25 mana). Apare pe slotul lui True Form doar
-- in forma de urs; are mereu nivelul lui True Form (invatat aici in forma de urs, ridica si True Form / Battle Cry).
-- Logica: dota688_lone_druid_true_form.lua.
require("abilities/heroes/dota688_lone_druid_true_form")
dota688_lone_druid_true_form_druid = class({})
function dota688_lone_druid_true_form_druid:IsStealable() return false end
function dota688_lone_druid_true_form_druid:OnUpgrade() Dota688LoneDruidSyncLevels(self:GetCaster(), self:GetLevel()) end
function dota688_lone_druid_true_form_druid:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_LoneDruid.TrueForm.Recast")
	Dota688LoneDruidTransform(caster, self, false)
end
