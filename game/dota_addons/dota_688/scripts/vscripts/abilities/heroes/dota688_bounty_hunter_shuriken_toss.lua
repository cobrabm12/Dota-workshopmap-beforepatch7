-- Shuriken Toss (6.88): shuriken (proiectil 1000, poate fi evitat) pe un inamic: 150/225/300/375 daune magice si
-- mini-stun 0.1 s (intrerupe canalizarile). Apoi sare, pe rand, la unitatile cu Track aflate la cel mult 1200
-- de ultima lovita (fiecare lovita o singura data).
dota688_bounty_hunter_shuriken_toss = class({})
local MINI_STUN = 0.1
local TRACK = "modifier_dota688_bounty_hunter_track"

function dota688_bounty_hunter_shuriken_toss:Throw(source, target, id)
	ProjectileManager:CreateTrackingProjectile({
		Target = target, Source = source, Ability = self,
		EffectName = "particles/units/heroes/hero_bounty_hunter/bounty_hunter_suriken_toss.vpcf",
		iMoveSpeed = self:GetSpecialValueFor("speed"), vSourceLoc = source:GetAbsOrigin(), bDodgeable = true, bProvidesVision = false,
		iSourceAttachment = (source == self:GetCaster()) and DOTA_PROJECTILE_ATTACHMENT_ATTACK_1 or nil,
		ExtraData = { id = id },
	})
end
function dota688_bounty_hunter_shuriken_toss:OnSpellStart()
	local caster = self:GetCaster()
	self.casts = self.casts or {}
	self.nextId = (self.nextId or 0) + 1
	self.casts[self.nextId] = { first = true, hit = {} }
	caster:EmitSound("Hero_BountyHunter.Shuriken")
	self:Throw(caster, self:GetCursorTarget(), self.nextId)
end
function dota688_bounty_hunter_shuriken_toss:OnProjectileHit_ExtraData(target, location, data)
	local cast = self.casts and self.casts[data.id]
	if not cast then return true end
	if not target or target:IsNull() then self.casts[data.id] = nil return true end
	local caster = self:GetCaster()
	local first = cast.first
	cast.first = false
	cast.hit[target:entindex()] = true
	if not (first and target:TriggerSpellAbsorb(self)) then
		if not target:IsMagicImmune() and not target:IsInvulnerable() then
			target:EmitSound("Hero_BountyHunter.Shuriken.Impact")
			ApplyDamage({ victim = target, attacker = caster, damage = self:GetSpecialValueFor("bonus_damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
			target:AddNewModifier(caster, self, "modifier_stunned", { duration = MINI_STUN })
		end
	end
	-- urmatoarea unitate cu Track (cea mai apropiata, nelovita inca)
	for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, self:GetSpecialValueFor("bounce_aoe"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)) do
		if not cast.hit[u:entindex()] and u:HasModifier(TRACK) then
			self:Throw(target, u, data.id)
			return true
		end
	end
	self.casts[data.id] = nil
	return true
end
