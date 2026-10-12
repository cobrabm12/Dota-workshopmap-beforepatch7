-- Wall of Replica (6.88): zid de 1000 latime, 45 s; eroii inamici care il traverseaza iau 150 daune magice si li se creeaza o replica (controlata de Dark Seer),
-- cu -40/25/10% daune date si +300% daune primite, care dureaza cat zidul. Scepter: replicile dau 100/120/140% daune.
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_wall_of_replica", "abilities/heroes/dota688_dark_seer_wall_of_replica", LUA_MODIFIER_MOTION_NONE)
dota688_dark_seer_wall_of_replica = class({})
function dota688_dark_seer_wall_of_replica:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	local dir = pos - caster:GetAbsOrigin(); dir.z = 0
	if dir:Length2D() < 1 then dir = caster:GetForwardVector() end
	dir = dir:Normalized()
	caster:EmitSound("Hero_Dark_Seer.WallOfReplica")
	CreateModifierThinker(caster, self, "modifier_dota688_wall_of_replica", { duration = self:GetSpecialValueFor("duration"), dx = dir.x, dy = dir.y }, pos, caster:GetTeamNumber(), false)
end
modifier_dota688_wall_of_replica = class({})
function modifier_dota688_wall_of_replica:IsHidden() return true end
function modifier_dota688_wall_of_replica:OnCreated(kv)
	if not IsServer() then return end
	local a, pos = self:GetAbility(), self:GetParent():GetAbsOrigin()
	local perp = Vector(-kv.dy, kv.dx, 0)
	local half = a:GetSpecialValueFor("width") / 2
	self.p1, self.p2 = pos - perp * half, pos + perp * half
	self.replicas = {}
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_seer/dark_seer_wall_of_replica.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.fx, 0, self.p1); ParticleManager:SetParticleControl(self.fx, 1, self.p2)
	ParticleManager:SetParticleControl(self.fx, 2, Vector(self:GetDuration(), 0, 0))
	self:StartIntervalThink(0.1)
end
function modifier_dota688_wall_of_replica:OnIntervalThink()
	local a, caster = self:GetAbility(), self:GetCaster()
	for _, h in ipairs(FindUnitsInLine(caster:GetTeamNumber(), self.p1, self.p2, nil, 60, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS)) do
		local old = self.replicas[h:entindex()]
		if (not old or old:IsNull() or not old:IsAlive()) and not h:IsMagicImmune() then
			ApplyDamage({ victim = h, attacker = caster, damage = a:GetSpecialValueFor("damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
			local out = Dota688HasScepter(caster) and a:GetSpecialValueFor("replica_damage_outgoing_scepter") or a:GetSpecialValueFor("replica_damage_outgoing")
			local ill = CreateIllusions(caster, h, { outgoing_damage = out, incoming_damage = a:GetSpecialValueFor("replica_damage_incoming"), duration = self:GetRemainingTime() }, 1, 100, false, false)
			if ill and ill[1] then
				self.replicas[h:entindex()] = ill[1]
				local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_dark_seer/dark_seer_wall_of_replica_replicate.vpcf", PATTACH_ABSORIGIN_FOLLOW, ill[1])
				ParticleManager:ReleaseParticleIndex(fx)
			end
		end
	end
end
function modifier_dota688_wall_of_replica:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.fx, false)
	for _, r in pairs(self.replicas) do if not r:IsNull() and r:IsAlive() then r:ForceKill(false) end end
	UTIL_Remove(self:GetParent())
end
