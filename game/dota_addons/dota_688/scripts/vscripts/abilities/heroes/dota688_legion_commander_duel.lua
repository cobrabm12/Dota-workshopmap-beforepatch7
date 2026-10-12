-- Duel (6.88): Legion si tinta sunt fortati sa se atace 4/4.75/5.5 s, fara abilitati/iteme; trece prin imunitate.
-- Daca unul moare, castigatorul primeste permanent +10/14/18 daune. Scepter: 6/7/8 s si cei doi iau daune doar unul de la celalalt.
require("dota688/val")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_legion_commander_duel"
LinkLuaModifier("modifier_dota688_duel", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_duel_damage", F, LUA_MODIFIER_MOTION_NONE)
dota688_legion_commander_duel = class({})
function dota688_legion_commander_duel:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	local scepter = Dota688HasScepter(caster)
	local dur = scepter and self:GetSpecialValueFor("duration_scepter") or self:GetSpecialValueFor("duration")
	caster:EmitSound("Hero_LegionCommander.Duel.Cast")
	target:EmitSound("Hero_LegionCommander.Duel")
	caster:AddNewModifier(caster, self, "modifier_dota688_duel", { duration = dur, other = target:entindex(), scepter = scepter and 1 or 0 })
	target:AddNewModifier(caster, self, "modifier_dota688_duel", { duration = dur, other = caster:entindex(), scepter = scepter and 1 or 0 })
end
modifier_dota688_duel = class({})
function modifier_dota688_duel:IsPurgable() return false end
function modifier_dota688_duel:IsDebuff() return self:GetParent() ~= self:GetCaster() end
function modifier_dota688_duel:GetTexture() return "legion_commander_duel" end
function modifier_dota688_duel:GetEffectName() return "particles/units/heroes/hero_legion_commander/legion_commander_duel_buff.vpcf" end
function modifier_dota688_duel:OnCreated(kv)
	if not IsServer() then return end
	self.other = EntIndexToHScript(kv.other)
	self.scepter = kv.scepter == 1
	self:StartIntervalThink(0.1)
end
function modifier_dota688_duel:OnIntervalThink()
	local p = self:GetParent()
	if not self.other or self.other:IsNull() or not self.other:IsAlive() then self:Destroy() return end
	if p:GetAttackTarget() ~= self.other then p:MoveToTargetToAttack(self.other) end
end
function modifier_dota688_duel:CheckState() return { [MODIFIER_STATE_SILENCED] = true, [MODIFIER_STATE_MUTED] = true, [MODIFIER_STATE_COMMAND_RESTRICTED] = true } end
function modifier_dota688_duel:DeclareFunctions() return { MODIFIER_EVENT_ON_DEATH, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_dota688_duel:GetModifierIncomingDamage_Percentage(params)
	if self.scepter and params and params.attacker and params.attacker ~= self.other and params.attacker ~= self:GetParent() then return -100 end
	return 0
end
function modifier_dota688_duel:OnDeath(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	local winner = self.other
	if winner and not winner:IsNull() and winner:IsAlive() and winner:HasModifier("modifier_dota688_duel") then
		local m = winner:FindModifierByName("modifier_dota688_duel_damage")
		if not m then m = winner:AddNewModifier(winner, self:GetAbility(), "modifier_dota688_duel_damage", {}) end
		if m then m:SetStackCount(m:GetStackCount() + Dota688Val(self, "reward_damage")) end
		winner:EmitSound("Hero_LegionCommander.Duel.Victory")
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_legion_commander/legion_commander_duel_victory.vpcf", PATTACH_OVERHEAD_FOLLOW, winner)
		ParticleManager:ReleaseParticleIndex(fx)
		winner:RemoveModifierByName("modifier_dota688_duel")
	end
end
modifier_dota688_duel_damage = class({})
function modifier_dota688_duel_damage:IsPurgable() return false end
function modifier_dota688_duel_damage:RemoveOnDeath() return false end
function modifier_dota688_duel_damage:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_dota688_duel_damage:GetTexture() return "legion_commander_duel" end
function modifier_dota688_duel_damage:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE } end
function modifier_dota688_duel_damage:GetModifierPreAttack_BonusDamage() return self:GetStackCount() end
