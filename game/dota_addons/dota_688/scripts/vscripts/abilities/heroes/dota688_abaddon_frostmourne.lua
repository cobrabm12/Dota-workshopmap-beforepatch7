-- Frostmourne / Curse of Avernus (6.88): atacurile lui Abaddon incetinesc tinta (-15% MS, -8/12/16/20 AS, 2.5 s);
-- aliatii care ataca tinta blestemata primesc +15% MS si +10/20/30/40 AS pentru 4.5 s.
require("dota688/val")
local F = "abilities/heroes/dota688_abaddon_frostmourne"
LinkLuaModifier("modifier_dota688_abaddon_frostmourne", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_abaddon_frostmourne_debuff", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_abaddon_frostmourne_buff", F, LUA_MODIFIER_MOTION_NONE)

dota688_abaddon_frostmourne = class({})
function dota688_abaddon_frostmourne:GetIntrinsicModifierName() return "modifier_dota688_abaddon_frostmourne" end

modifier_dota688_abaddon_frostmourne = class({})
function modifier_dota688_abaddon_frostmourne:IsHidden() return true end
function modifier_dota688_abaddon_frostmourne:IsPurgable() return false end
function modifier_dota688_abaddon_frostmourne:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_abaddon_frostmourne:OnAttackLanded(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	if params.attacker ~= parent or parent:PassivesDisabled() then return end
	local target = params.target
	if not target or target:IsBuilding() or target:IsOther() or target:GetTeamNumber() == parent:GetTeamNumber() then return end
	target:AddNewModifier(parent, self:GetAbility(), "modifier_dota688_abaddon_frostmourne_debuff", { duration = Dota688Val(self, "debuff_duration") })
end

modifier_dota688_abaddon_frostmourne_debuff = class({})
function modifier_dota688_abaddon_frostmourne_debuff:IsDebuff() return true end
function modifier_dota688_abaddon_frostmourne_debuff:IsPurgable() return true end
function modifier_dota688_abaddon_frostmourne_debuff:GetEffectName() return "particles/units/heroes/hero_abaddon/abaddon_frost_slow.vpcf" end
function modifier_dota688_abaddon_frostmourne_debuff:OnCreated()
	local a = self:GetAbility()
	self.ms = -a:GetSpecialValueFor("slow_pct")              -- "%MOVEMENT SLOW" 8/12/16/20 (move_speed_pct e bonusul aliatilor)
	self.as = -a:GetSpecialValueFor("attack_slow_tooltip")   -- 8/12/16/20
end
function modifier_dota688_abaddon_frostmourne_debuff:OnRefresh() self:OnCreated() end
function modifier_dota688_abaddon_frostmourne_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_EVENT_ON_ATTACK_LANDED }
end
function modifier_dota688_abaddon_frostmourne_debuff:GetModifierMoveSpeedBonus_Percentage() return self.ms end
function modifier_dota688_abaddon_frostmourne_debuff:GetModifierAttackSpeedBonus_Constant() return self.as end
function modifier_dota688_abaddon_frostmourne_debuff:OnAttackLanded(params)
	if not IsServer() then return end
	if params.target ~= self:GetParent() then return end
	local attacker = params.attacker
	if not attacker or attacker:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then return end
	attacker:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_dota688_abaddon_frostmourne_buff", { duration = Dota688Val(self, "buff_duration") })
end

modifier_dota688_abaddon_frostmourne_buff = class({})
function modifier_dota688_abaddon_frostmourne_buff:IsPurgable() return true end
function modifier_dota688_abaddon_frostmourne_buff:GetEffectName() return "particles/units/heroes/hero_abaddon/abaddon_frost_buff.vpcf" end
function modifier_dota688_abaddon_frostmourne_buff:OnCreated()
	local a = self:GetAbility()
	self.ms = a:GetSpecialValueFor("move_speed_pct")
	self.as = a:GetSpecialValueFor("attack_speed")
end
function modifier_dota688_abaddon_frostmourne_buff:OnRefresh() self:OnCreated() end
function modifier_dota688_abaddon_frostmourne_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_dota688_abaddon_frostmourne_buff:GetModifierMoveSpeedBonus_Percentage() return self.ms end
function modifier_dota688_abaddon_frostmourne_buff:GetModifierAttackSpeedBonus_Constant() return self.as end
