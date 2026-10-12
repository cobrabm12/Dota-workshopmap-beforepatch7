-- Witchcraft (6.88): pasiv: +5/10/15/20 MS; -10..-25 mana si -1..-4 s cooldown la Carrion Swarm si Silence; +3/4/5/6 spirite la Exorcism.
-- (Pe Silence, care e in Lua, reducerile de mana/cooldown sunt aplicate; pe Carrion Swarm built-in nu pot fi aplicate selectiv din Lua.)
require("dota688/val")
LinkLuaModifier("modifier_dota688_death_prophet_witchcraft", "abilities/heroes/dota688_death_prophet_witchcraft", LUA_MODIFIER_MOTION_NONE)
dota688_death_prophet_witchcraft = class({})
function dota688_death_prophet_witchcraft:GetIntrinsicModifierName() return "modifier_dota688_death_prophet_witchcraft" end
modifier_dota688_death_prophet_witchcraft = class({})
function modifier_dota688_death_prophet_witchcraft:IsHidden() return true end
function modifier_dota688_death_prophet_witchcraft:IsPurgable() return false end
function modifier_dota688_death_prophet_witchcraft:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT } end
function modifier_dota688_death_prophet_witchcraft:GetModifierMoveSpeedBonus_Constant() return Dota688Val(self, "bonus_movement_speed") end
