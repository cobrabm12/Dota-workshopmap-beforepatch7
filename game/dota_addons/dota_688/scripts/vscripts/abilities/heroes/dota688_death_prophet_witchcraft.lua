-- NOTA: in 6.88f Death Prophet are Spirit Siphon in locul lui Witchcraft (reference/6.88f/npc_heroes.txt), deci abilitatea asta nu e in
-- sloturile eroului; ramane doar ca referinta.
-- Witchcraft (6.87): pasiv: +5/10/15/20 MS; -10..-25 mana si -1..-4 s cooldown la Carrion Swarm si Silence; +3/4/5/6 spirite la Exorcism.
-- (Silence, fiind in Lua, isi aplica singur reducerile; pe Carrion Swarm built-in merg prin proprietatile de cooldown/mana cu params.ability.)
require("dota688/val")
LinkLuaModifier("modifier_dota688_death_prophet_witchcraft", "abilities/heroes/dota688_death_prophet_witchcraft", LUA_MODIFIER_MOTION_NONE)
dota688_death_prophet_witchcraft = class({})
function dota688_death_prophet_witchcraft:GetIntrinsicModifierName() return "modifier_dota688_death_prophet_witchcraft" end
modifier_dota688_death_prophet_witchcraft = class({})
function modifier_dota688_death_prophet_witchcraft:IsHidden() return true end
function modifier_dota688_death_prophet_witchcraft:IsPurgable() return false end
function modifier_dota688_death_prophet_witchcraft:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_COOLDOWN_REDUCTION_CONSTANT, MODIFIER_PROPERTY_MANACOST_REDUCTION_CONSTANT }
end
-- Carrion Swarm (built-in): -1/2/3/4 s cooldown si -10/15/20/25 mana (Silence, fiind in Lua, le aplica singur)
local function IsSwarm(params) return params and params.ability and not params.ability:IsNull() and params.ability:GetAbilityName() == "death_prophet_carrion_swarm" end
function modifier_dota688_death_prophet_witchcraft:GetModifierCooldownReduction_Constant(params)
	if not IsSwarm(params) or self:GetParent():PassivesDisabled() then return 0 end
	return -Dota688Val(self, "carrion_swarm_cooldown_adjust")
end
function modifier_dota688_death_prophet_witchcraft:GetModifierConstantManaReduction(params)
	if not IsSwarm(params) or self:GetParent():PassivesDisabled() then return 0 end
	return -Dota688Val(self, "carrion_swarm_mana_cost_adjust")
end
function modifier_dota688_death_prophet_witchcraft:GetModifierMoveSpeedBonus_Constant() return Dota688Val(self, "bonus_movement_speed") end
