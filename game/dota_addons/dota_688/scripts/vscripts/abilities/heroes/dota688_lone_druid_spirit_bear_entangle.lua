-- Entangling Claws (6.88, ursul de nivel 3+): 20% sansa (PRD) la atac sa imobilizeze tinta 3 s (erou) / 9 s (creep), cu 60 daune
-- fizice pe secunda; cooldown 5 s. Tinta prinsa nu poate folosi Blink si e vizibila daca e invizibila. Afecteaza unitatile imune la magie.
-- (Varianta moderna: contor de 5 lovituri, daune magice - nu exista in 6.88.)
require("dota688/val")
local F = "abilities/heroes/dota688_lone_druid_spirit_bear_entangle"
LinkLuaModifier("modifier_dota688_lone_druid_spirit_bear_entangle", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_lone_druid_spirit_bear_entangle_effect", F, LUA_MODIFIER_MOTION_NONE)
dota688_lone_druid_spirit_bear_entangle = class({})
function dota688_lone_druid_spirit_bear_entangle:GetIntrinsicModifierName() return "modifier_dota688_lone_druid_spirit_bear_entangle" end

modifier_dota688_lone_druid_spirit_bear_entangle = class({})
function modifier_dota688_lone_druid_spirit_bear_entangle:IsHidden() return true end
function modifier_dota688_lone_druid_spirit_bear_entangle:IsPurgable() return false end
function modifier_dota688_lone_druid_spirit_bear_entangle:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_lone_druid_spirit_bear_entangle:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() then return end
	local parent, t, a = self:GetParent(), params.target, self:GetAbility()
	if not a or a:IsNull() or parent:PassivesDisabled() or parent:IsIllusion() or not a:IsCooldownReady() then return end
	if not t or t:IsNull() or not t:IsAlive() or t:IsBuilding() or t:IsOther() or t:GetTeamNumber() == parent:GetTeamNumber() then return end
	if not RollPseudoRandomPercentage(a:GetSpecialValueFor("entangle_chance"), DOTA_PSEUDO_RANDOM_LONE_DRUID_ENTANGLE, parent) then return end
	a:StartCooldown(a:GetCooldown(a:GetLevel() - 1))
	local duration = (t:IsHero() or t:IsConsideredHero()) and a:GetSpecialValueFor("hero_duration") or a:GetSpecialValueFor("creep_duration")
	t:AddNewModifier(parent, a, "modifier_dota688_lone_druid_spirit_bear_entangle_effect", { duration = duration })
	t:EmitSound("LoneDruid_SpiritBear.Entangle")
end

-- pe tinta: imobilizata, vizibila, 60 daune fizice pe secunda
modifier_dota688_lone_druid_spirit_bear_entangle_effect = class({})
function modifier_dota688_lone_druid_spirit_bear_entangle_effect:IsDebuff() return true end
function modifier_dota688_lone_druid_spirit_bear_entangle_effect:IsPurgable() return true end
function modifier_dota688_lone_druid_spirit_bear_entangle_effect:GetEffectName() return "particles/units/heroes/hero_lone_druid/lone_druid_bear_entangle.vpcf" end
function modifier_dota688_lone_druid_spirit_bear_entangle_effect:GetEffectAttachType() return PATTACH_ABSORIGIN end
function modifier_dota688_lone_druid_spirit_bear_entangle_effect:GetPriority() return MODIFIER_PRIORITY_HIGH end
function modifier_dota688_lone_druid_spirit_bear_entangle_effect:CheckState()
	return { [MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_INVISIBLE] = false }
end
function modifier_dota688_lone_druid_spirit_bear_entangle_effect:OnCreated()
	if not IsServer() then return end
	local a = self:GetAbility()
	self.damage = (a and not a:IsNull()) and a:GetAbilityDamage() or 60
	self.ticks = 0
	self.maxTicks = math.floor(self:GetDuration() + 0.01)
	self:StartIntervalThink(1.0)
end
function modifier_dota688_lone_druid_spirit_bear_entangle_effect:Tick()
	if self.ticks >= self.maxTicks then return end
	self.ticks = self.ticks + 1
	local caster, a = self:GetCaster(), self:GetAbility()
	if not caster or caster:IsNull() then return end
	ApplyDamage({ victim = self:GetParent(), attacker = caster, damage = self.damage, damage_type = DAMAGE_TYPE_PHYSICAL,
		ability = (a and not a:IsNull()) and a or nil })
end
function modifier_dota688_lone_druid_spirit_bear_entangle_effect:OnIntervalThink() self:Tick() end
function modifier_dota688_lone_druid_spirit_bear_entangle_effect:OnDestroy()
	-- ultima secunda poate cadea in acelasi cadru cu expirarea
	if IsServer() and self:GetRemainingTime() <= 0.05 and self:GetParent():IsAlive() then self:Tick() end
end
