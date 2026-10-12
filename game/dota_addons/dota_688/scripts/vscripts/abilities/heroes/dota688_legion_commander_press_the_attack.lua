-- Press the Attack (6.88): purge pe un aliat + 65/90/115/140 AS si 30/40/50/60 regenerare pentru 5 s.
LinkLuaModifier("modifier_dota688_legion_commander_press_the_attack", "abilities/heroes/dota688_legion_commander_press_the_attack", LUA_MODIFIER_MOTION_NONE)
dota688_legion_commander_press_the_attack = class({})
function dota688_legion_commander_press_the_attack:OnSpellStart()
	local target = self:GetCursorTarget()
	target:Purge(false, true, false, true, true)
	target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_legion_commander_press_the_attack", { duration = self:GetSpecialValueFor("duration") })
	target:EmitSound("Hero_LegionCommander.PressTheAttack")
end
modifier_dota688_legion_commander_press_the_attack = class({})
function modifier_dota688_legion_commander_press_the_attack:IsPurgable() return true end
function modifier_dota688_legion_commander_press_the_attack:GetEffectName() return "particles/units/heroes/hero_legion_commander/legion_commander_press.vpcf" end
function modifier_dota688_legion_commander_press_the_attack:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT } end
function modifier_dota688_legion_commander_press_the_attack:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("attack_speed") end
function modifier_dota688_legion_commander_press_the_attack:GetModifierConstantHealthRegen() return self:GetAbility():GetSpecialValueFor("hp_regen") end
