-- Poison Touch (6.88): proiectil; 10 s de daune fizice/s (14/20/26/36); incetinire in 3 trepte (33%/66%/100% dupa 1/2/3 s), la nivel 4 stun 1 s.
require("dota688/val")
LinkLuaModifier("modifier_dota688_dazzle_poison_touch", "abilities/heroes/dota688_dazzle_poison_touch", LUA_MODIFIER_MOTION_NONE)
dota688_dazzle_poison_touch = class({})
function dota688_dazzle_poison_touch:OnSpellStart()
	local target = self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	self:GetCaster():EmitSound("Hero_Dazzle.PoisonTouch")
	ProjectileManager:CreateTrackingProjectile({ Target = target, Source = self:GetCaster(), Ability = self,
		EffectName = "particles/units/heroes/hero_dazzle/dazzle_poison_touch.vpcf", iMoveSpeed = self:GetSpecialValueFor("projectile_speed"), bDodgeable = true })
end
function dota688_dazzle_poison_touch:OnProjectileHit(target, loc)
	if not target then return end
	target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_dazzle_poison_touch", { duration = self:GetDuration() })
	target:EmitSound("Hero_Dazzle.PoisonTouch.Target")
	return true
end
modifier_dota688_dazzle_poison_touch = class({})
function modifier_dota688_dazzle_poison_touch:IsDebuff() return true end
function modifier_dota688_dazzle_poison_touch:IsPurgable() return true end
function modifier_dota688_dazzle_poison_touch:GetEffectName() return "particles/units/heroes/hero_dazzle/dazzle_poison_debuff.vpcf" end
function modifier_dota688_dazzle_poison_touch:OnCreated()
	self.elapsed = 0
	if IsServer() then self:StartIntervalThink(1.0) end
end
function modifier_dota688_dazzle_poison_touch:OnIntervalThink()
	self.elapsed = self.elapsed + 1
	local a = self:GetAbility()
	if not a or a:IsNull() then self:Destroy(); return end   -- abilitatea/caster-ul au disparut (Rubick, iluzie moarta)
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = a:GetAbilityDamage(), damage_type = a:GetAbilityDamageType(), ability = a })
	self:SetStackCount(math.min(3, self.elapsed))
	if self.elapsed == a:GetSpecialValueFor("set_time") and a:GetSpecialValueFor("should_stun") == 1 then
		self:GetParent():AddNewModifier(self:GetCaster(), a, "modifier_stunned", { duration = a:GetSpecialValueFor("stun_duration") })
	end
end
function modifier_dota688_dazzle_poison_touch:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_dazzle_poison_touch:GetModifierMoveSpeedBonus_Percentage()
	local s = self:GetStackCount()
	if s <= 0 then return 0 end
	return Dota688Val(self, "slow_" .. math.min(3, s))
end
