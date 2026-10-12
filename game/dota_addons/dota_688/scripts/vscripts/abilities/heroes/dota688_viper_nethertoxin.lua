-- Nethertoxin (6.88): daune fizice bonus in functie de viata lipsa a tintei: 2.5/5/7.5/10 la 0-20%, dublate la fiecare 20% (max x16); 50% pe non-eroi.
require("dota688/val")
LinkLuaModifier("modifier_dota688_viper_nethertoxin", "abilities/heroes/dota688_viper_nethertoxin", LUA_MODIFIER_MOTION_NONE)
dota688_viper_nethertoxin = class({})
function dota688_viper_nethertoxin:GetIntrinsicModifierName() return "modifier_dota688_viper_nethertoxin" end
modifier_dota688_viper_nethertoxin = class({})
function modifier_dota688_viper_nethertoxin:IsHidden() return true end
function modifier_dota688_viper_nethertoxin:IsPurgable() return false end
function modifier_dota688_viper_nethertoxin:DeclareFunctions() return { MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL } end
function modifier_dota688_viper_nethertoxin:GetModifierProcAttack_BonusDamage_Physical(params)
	local parent = self:GetParent()
	local target = params.target
	if parent:PassivesDisabled() or not target or target:IsBuilding() or target:IsOther() then return 0 end
	local missing = 1 - target:GetHealth() / math.max(1, target:GetMaxHealth())
	local step = math.min(4, math.floor(missing / 0.2))
	local dmg = Dota688Val(self, "bonus_damage") * (2 ^ step)
	if not target:IsHero() then dmg = dmg * Dota688Val(self, "non_hero_damage_pct") / 100 end
	return dmg
end
