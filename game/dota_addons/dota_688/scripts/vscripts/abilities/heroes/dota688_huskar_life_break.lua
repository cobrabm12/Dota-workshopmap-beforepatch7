-- Life Break (6.88): Huskar sare spre tinta (1000), pierde 35% din HP-ul curent si ia tintei 35% din HP-ul curent (magic); tinta e incetinita 40/50/60% 4/5/6 s.
-- Scepter: 65% din HP-ul tintei, cooldown 4.
require("dota688/val")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_huskar_life_break"
LinkLuaModifier("modifier_dota688_life_break_charge", F, LUA_MODIFIER_MOTION_HORIZONTAL)
LinkLuaModifier("modifier_dota688_life_break_slow", F, LUA_MODIFIER_MOTION_NONE)
dota688_huskar_life_break = class({})
function dota688_huskar_life_break:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetLevelSpecialValueFor("cooldown_scepter", level) end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_huskar_life_break:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	caster:EmitSound("Hero_Huskar.Life_Break")
	caster:AddNewModifier(caster, self, "modifier_dota688_life_break_charge", { target = target:entindex() })
end
modifier_dota688_life_break_charge = class({})
function modifier_dota688_life_break_charge:IsHidden() return true end
function modifier_dota688_life_break_charge:IsPurgable() return false end
function modifier_dota688_life_break_charge:GetEffectName() return "particles/units/heroes/hero_huskar/huskar_life_break.vpcf" end
function modifier_dota688_life_break_charge:OnCreated(kv)
	if not IsServer() then return end
	self.target = EntIndexToHScript(kv.target)
	self.speed = Dota688Val(self, "charge_speed")
	if self:ApplyHorizontalMotionController() == false then self:Destroy() end
end
function modifier_dota688_life_break_charge:UpdateHorizontalMotion(me, dt)
	local t = self.target
	if not t or t:IsNull() or not t:IsAlive() then self:Destroy() return end
	local to = t:GetAbsOrigin() - me:GetAbsOrigin(); to.z = 0
	local d = to:Length2D()
	if d <= 100 then self:Impact() self:Destroy() return end
	me:SetAbsOrigin(me:GetAbsOrigin() + to:Normalized() * math.min(d, self.speed * dt))
	me:SetForwardVector(to:Normalized())
end
function modifier_dota688_life_break_charge:OnHorizontalMotionInterrupted() self:Destroy() end
function modifier_dota688_life_break_charge:Impact()
	local me, t, a = self:GetParent(), self.target, self:GetAbility()
	if t:TriggerSpellAbsorb(a) then return end
	local scepter = Dota688HasScepter(me)
	local pct = scepter and a:GetSpecialValueFor("health_damage_scepter") or a:GetSpecialValueFor("health_damage")
	t:EmitSound("Hero_Huskar.Life_Break.Impact")
	ApplyDamage({ victim = t, attacker = me, damage = t:GetHealth() * pct, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
	ApplyDamage({ victim = me, attacker = me, damage = me:GetHealth() * a:GetSpecialValueFor("health_cost_percent"), damage_type = DAMAGE_TYPE_MAGICAL, ability = a, damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_HPLOSS })
	t:AddNewModifier(me, a, "modifier_dota688_life_break_slow", { duration = a:GetDuration() })
	me:MoveToTargetToAttack(t)
end
function modifier_dota688_life_break_charge:OnDestroy()
	if IsServer() then self:GetParent():RemoveHorizontalMotionController(self); FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), false) end
end
function modifier_dota688_life_break_charge:CheckState() return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true } end
modifier_dota688_life_break_slow = class({})
function modifier_dota688_life_break_slow:IsDebuff() return true end
function modifier_dota688_life_break_slow:IsPurgable() return true end
function modifier_dota688_life_break_slow:GetTexture() return "huskar_life_break" end
function modifier_dota688_life_break_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_life_break_slow:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "movespeed") end
