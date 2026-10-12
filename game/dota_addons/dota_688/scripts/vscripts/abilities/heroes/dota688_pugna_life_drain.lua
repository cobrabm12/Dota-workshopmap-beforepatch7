-- Life Drain (6.88): canalizare 10 s; ia 150/200/250 HP/s de la inamic si vindeca Pugna (daca Pugna are HP maxim, primeste mana);
-- pe aliat, transfera HP de la Pugna la aliat. Se intrerupe daca tinta iese din raza. Scepter: 180/240/300 HP/s, fara cooldown.
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_life_drain", "abilities/heroes/dota688_pugna_life_drain", LUA_MODIFIER_MOTION_NONE)
dota688_pugna_life_drain = class({})
function dota688_pugna_life_drain:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return 0 end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_pugna_life_drain:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:GetTeamNumber() ~= caster:GetTeamNumber() and target:TriggerSpellAbsorb(self) then self:EndChannel(true) return end
	self.target = target
	caster:EmitSound("Hero_Pugna.LifeDrain.Target")
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_pugna/pugna_life_drain.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(self.fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(self.fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	self.mod = target:AddNewModifier(caster, self, "modifier_dota688_life_drain", { duration = self:GetChannelTime() })
end
function dota688_pugna_life_drain:OnChannelFinish(interrupted)
	local caster = self:GetCaster()
	caster:StopSound("Hero_Pugna.LifeDrain.Target")
	if self.fx then ParticleManager:DestroyParticle(self.fx, false); self.fx = nil end
	if self.mod and not self.mod:IsNull() then self.mod:Destroy() end
	self.mod = nil
end
modifier_dota688_life_drain = class({})
function modifier_dota688_life_drain:IsHidden() return false end
function modifier_dota688_life_drain:IsPurgable() return false end
function modifier_dota688_life_drain:IsDebuff() return self:GetParent():GetTeamNumber() ~= self:GetCaster():GetTeamNumber() end
function modifier_dota688_life_drain:GetTexture() return "pugna_life_drain" end
function modifier_dota688_life_drain:OnCreated()
	if not IsServer() then return end
	local a = self:GetAbility()
	self.tick = a:GetSpecialValueFor("tick_rate")
	self.drain = (Dota688HasScepter(self:GetCaster()) and a:GetSpecialValueFor("health_drain_scepter") or a:GetSpecialValueFor("health_drain")) * self.tick
	self:StartIntervalThink(self.tick)
end
function modifier_dota688_life_drain:OnIntervalThink()
	local p, caster, a = self:GetParent(), self:GetCaster(), self:GetAbility()
	if not caster:IsAlive() or not p:IsAlive() or (caster:GetAbsOrigin() - p:GetAbsOrigin()):Length2D() > a:GetCastRange(caster:GetAbsOrigin(), p) + 150 then
		a:EndChannel(true)
		return
	end
	if p:GetTeamNumber() == caster:GetTeamNumber() then
		local amt = math.min(self.drain, math.max(0, caster:GetHealth() - 1))
		if amt > 0 then
			ApplyDamage({ victim = caster, attacker = caster, damage = amt, damage_type = DAMAGE_TYPE_PURE, ability = a, damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_HPLOSS })
			p:Heal(amt, a)
		end
	else
		if p:IsMagicImmune() then return end
		local before = p:GetHealth()
		ApplyDamage({ victim = p, attacker = caster, damage = self.drain, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
		local dealt = before - p:GetHealth()
		if caster:GetHealth() >= caster:GetMaxHealth() then caster:GiveMana(dealt) else caster:Heal(dealt, a) end
	end
end
