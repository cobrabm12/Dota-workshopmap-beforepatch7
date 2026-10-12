-- Assassinate (6.88): Sniper ocheste tinta 2 s (crosshair vazut doar de aliatii lui, tinta ramane vizibila), apoi trage un
-- proiectil (viteza 2500) care da 320/485/650 daune magice si un mini-stun. Mini-stun-ul intrerupe canalizarile si pe tintele
-- imune la magie (acestea nu iau daune). Proiectilul poate fi evitat (blink/manta), invizibilitatea nu il opreste; Linken's il
-- blocheaza. Fara daunele de atac / refresh la kill / upgrade de scepter moderne (Sniper nu avea scepter in 6.88).
require("dota688/stun")
local F = "abilities/heroes/dota688_sniper_assassinate"
LinkLuaModifier("modifier_dota688_sniper_assassinate", F, LUA_MODIFIER_MOTION_NONE)
local MINISTUN = 0.1

dota688_sniper_assassinate = class({})
function dota688_sniper_assassinate:GetCastAnimation() return ACT_DOTA_CAST_ABILITY_4 end
function dota688_sniper_assassinate:OnAbilityPhaseStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	caster:EmitSound("Ability.AssassinateLoad")
	if target then
		-- durata acopera timpul de ochire; la lansare se prelungeste cu timpul de zbor al proiectilului
		self.aim = target:AddNewModifier(caster, self, "modifier_dota688_sniper_assassinate", { duration = self:GetCastPoint() + 1 })
	end
	return true
end
function dota688_sniper_assassinate:OnAbilityPhaseInterrupted()
	self:GetCaster():StopSound("Ability.AssassinateLoad")
	if self.aim and not self.aim:IsNull() then self.aim:Destroy() end
	self.aim = nil
end
function dota688_sniper_assassinate:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	local speed = self:GetSpecialValueFor("projectile_speed")
	caster:EmitSound("Ability.Assassinate")
	caster:EmitSound("Hero_Sniper.AssassinateProjectile")
	ProjectileManager:CreateTrackingProjectile({
		Target = target, Source = caster, Ability = self,
		EffectName = "particles/units/heroes/hero_sniper/sniper_assassinate.vpcf",
		iMoveSpeed = speed, iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1,
		bDodgeable = true, bProvidesVision = false,
	})
	-- crosshair-ul (si viziunea asupra tintei) raman pana la impact; daca proiectilul e evitat, expira singur
	local aim = self.aim
	self.aim = nil
	if (not aim or aim:IsNull()) and target and not target:IsNull() then
		aim = target:AddNewModifier(caster, self, "modifier_dota688_sniper_assassinate", {})
	end
	if aim and not aim:IsNull() and target and not target:IsNull() then
		local travel = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() / math.max(1, speed)
		aim:SetDuration(travel + 0.5, true)
	end
end
function dota688_sniper_assassinate:OnProjectileHit(target, location)
	if not target or target:IsNull() then return true end
	local caster = self:GetCaster()
	local aim = target:FindModifierByNameAndCaster("modifier_dota688_sniper_assassinate", caster)
	if aim then aim:Destroy() end
	if not target:IsAlive() then return true end
	if target:TriggerSpellAbsorb(self) then return true end
	target:EmitSound("Hero_Sniper.AssassinateDamage")
	if not target:IsMagicImmune() then
		ApplyDamage({ victim = target, attacker = caster, damage = self:GetAbilityDamage(), damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
	end
	-- mini-stun: intrerupe canalizarea, inclusiv pe unitatile imune la magie
	if target:IsAlive() then Dota688Stun(target, caster, self, MINISTUN) end
	return true
end

-- tinta ochita: crosshair vizibil doar echipei lui Sniper; tinta ramane vizibila pentru Sniper pana la impact
modifier_dota688_sniper_assassinate = class({})
function modifier_dota688_sniper_assassinate:IsDebuff() return true end
function modifier_dota688_sniper_assassinate:IsPurgable() return false end
function modifier_dota688_sniper_assassinate:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_dota688_sniper_assassinate:OnCreated()
	if not IsServer() then return end
	self.fx = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_sniper/sniper_crosshair.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent(), self:GetCaster():GetTeamNumber())
end
function modifier_dota688_sniper_assassinate:OnDestroy()
	if not IsServer() or not self.fx then return end
	ParticleManager:DestroyParticle(self.fx, false)
	ParticleManager:ReleaseParticleIndex(self.fx)
	self.fx = nil
end
function modifier_dota688_sniper_assassinate:CheckState() return { [MODIFIER_STATE_PROVIDES_VISION] = true } end
