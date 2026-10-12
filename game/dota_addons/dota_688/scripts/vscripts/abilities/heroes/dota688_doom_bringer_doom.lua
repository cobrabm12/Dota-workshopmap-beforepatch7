-- Doom (6.88): 15 s: 20/35/50 daune pure/s, tinta nu poate folosi abilitati sau iteme (silence + mute); trece prin imunitate; eroul poate fi deniat sub 25%.
-- Scepter: 16 s; durata nu scade cat timp tinta e la mai putin de 900 de Doom; la cast scoate buff-urile; dezactiveaza pasivele (break).
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_doom", "abilities/heroes/dota688_doom_bringer_doom", LUA_MODIFIER_MOTION_NONE)
dota688_doom_bringer_doom = class({})
function dota688_doom_bringer_doom:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	local scepter = Dota688HasScepter(caster)
	caster:EmitSound("Hero_DoomBringer.Doom")
	if scepter then target:Purge(true, false, false, false, false) end
	local dur = scepter and self:GetSpecialValueFor("duration_scepter") or self:GetSpecialValueFor("duration")
	target:AddNewModifier(caster, self, "modifier_dota688_doom", { total = dur, scepter = scepter and 1 or 0 })
end
modifier_dota688_doom = class({})
function modifier_dota688_doom:IsDebuff() return true end
function modifier_dota688_doom:IsPurgable() return false end
function modifier_dota688_doom:GetEffectName() return "particles/units/heroes/hero_doom_bringer/doom_bringer_doom.vpcf" end
function modifier_dota688_doom:OnCreated(kv)
	if not IsServer() then return end
	self.left = kv.total
	self.scepter = kv.scepter == 1
	self.dmg = Dota688HasScepter(self:GetCaster()) and self:GetAbility():GetSpecialValueFor("damage_scepter") or self:GetAbility():GetSpecialValueFor("damage")
	self.acc = 0
	self:StartIntervalThink(0.1)
end
function modifier_dota688_doom:OnIntervalThink()
	local p, caster = self:GetParent(), self:GetCaster()
	self.acc = self.acc + 0.1
	if self.acc >= 1 then
		self.acc = self.acc - 1
		ApplyDamage({ victim = p, attacker = caster, damage = self.dmg, damage_type = DAMAGE_TYPE_PURE, ability = self:GetAbility() })
	end
	local near = self.scepter and caster and not caster:IsNull() and caster:IsAlive() and (caster:GetAbsOrigin() - p:GetAbsOrigin()):Length2D() <= 900
	if not near then self.left = self.left - 0.1 end
	if self.left <= 0 then self:Destroy() end
end
function modifier_dota688_doom:CheckState()
	return { [MODIFIER_STATE_SILENCED] = true, [MODIFIER_STATE_MUTED] = true, [MODIFIER_STATE_PASSIVES_DISABLED] = self.scepter == true, [MODIFIER_STATE_SPECIALLY_DENIABLE] = true }
end
