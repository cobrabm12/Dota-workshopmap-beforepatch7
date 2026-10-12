-- Poison Attack (6.88, orb): 10/16/22/28 daune magice/s, -10/20/30/40% MS si AS, 2 s.
LinkLuaModifier("modifier_dota688_viper_poison_attack", "abilities/heroes/dota688_viper_poison_attack", LUA_MODIFIER_MOTION_NONE)
dota688_viper_poison_attack = class({})
function dota688_viper_poison_attack:GetProjectileName() return "particles/units/heroes/hero_viper/viper_poison_attack.vpcf" end
function dota688_viper_poison_attack:OnOrbImpact(params)
	local target = params.target
	if not target or target:IsBuilding() or target:IsOther() or target:IsMagicImmune() then return end
	target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_viper_poison_attack", { duration = self:GetSpecialValueFor("duration") })
end
-- fallback cand motorul nu apeleaza OnOrbImpact (ability ATTACK fara suport orb): tratam ca atac normal cu efect la impact
function dota688_viper_poison_attack:OnSpellStart()
	local target = self:GetCursorTarget()
	if target then self:OnOrbImpact({ target = target }) end
end
modifier_dota688_viper_poison_attack = class({})
function modifier_dota688_viper_poison_attack:IsDebuff() return true end
function modifier_dota688_viper_poison_attack:IsPurgable() return true end
function modifier_dota688_viper_poison_attack:GetEffectName() return "particles/units/heroes/hero_viper/viper_poison_debuff.vpcf" end
function modifier_dota688_viper_poison_attack:OnCreated()
	self.tick = 1.0
	if IsServer() then self:StartIntervalThink(self.tick) end
end
function modifier_dota688_viper_poison_attack:OnRefresh() end
function modifier_dota688_viper_poison_attack:OnIntervalThink()
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = self:GetAbility():GetSpecialValueFor("damage") * self.tick,
		damage_type = DAMAGE_TYPE_MAGICAL, ability = self:GetAbility() })
end
function modifier_dota688_viper_poison_attack:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_viper_poison_attack:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("bonus_movement_speed") end
function modifier_dota688_viper_poison_attack:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("bonus_attack_speed") end
