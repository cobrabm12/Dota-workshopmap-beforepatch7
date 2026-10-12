-- Omnislash (6.88): 3/6/9 salturi la fiecare 0.4 s, 200-225 daune fizice fiecare, raza 425; invulnerabil pe durata.
-- Scepter: 6/9/12 salturi, cooldown 70.
require("dota688/val")
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_juggernaut_omni_slash", "abilities/heroes/dota688_juggernaut_omni_slash", LUA_MODIFIER_MOTION_NONE)
dota688_juggernaut_omni_slash = class({})
function dota688_juggernaut_omni_slash:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetSpecialValueFor("omni_slash_cooldown_scepter") end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_juggernaut_omni_slash:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	caster:EmitSound("Hero_Juggernaut.OmniSlash")
	local jumps = self:GetSpecialValueFor("omni_slash_jumps")
	if Dota688HasScepter(caster) then jumps = self:GetSpecialValueFor("omni_slash_jumps_scepter") end
	caster:AddNewModifier(caster, self, "modifier_dota688_juggernaut_omni_slash", { jumps = jumps, target = target:entindex() })
end
modifier_dota688_juggernaut_omni_slash = class({})
function modifier_dota688_juggernaut_omni_slash:IsPurgable() return false end
function modifier_dota688_juggernaut_omni_slash:OnCreated(kv)
	if not IsServer() then return end
	self.jumps = kv.jumps
	self.target = EntIndexToHScript(kv.target)
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_juggernaut/juggernaut_omni_slash_trail.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	self:Slash(self.target)
	self:StartIntervalThink(Dota688Val(self, "omni_slash_bounce_tick"))
end
function modifier_dota688_juggernaut_omni_slash:Slash(target)
	local parent, a = self:GetParent(), self:GetAbility()
	if not target or target:IsNull() or not target:IsAlive() then return false end
	local pos = target:GetAbsOrigin() + RandomVector(100)
	FindClearSpaceForUnit(parent, pos, false)
	parent:SetForwardVector((target:GetAbsOrigin() - parent:GetAbsOrigin()):Normalized())
	parent:StartGesture(ACT_DOTA_OVERRIDE_ABILITY_4)
	local dmg = RandomInt(a:GetSpecialValueFor("omni_slash_damage"), a:GetSpecialValueFor("omni_slash_damage") + 25)
	ApplyDamage({ victim = target, attacker = parent, damage = dmg, damage_type = DAMAGE_TYPE_PHYSICAL, ability = a })
	target:EmitSound("Hero_Juggernaut.OmniSlash.Damage")
	self.jumps = self.jumps - 1
	return true
end
function modifier_dota688_juggernaut_omni_slash:OnIntervalThink()
	if self.jumps <= 0 then self:Destroy() return end
	local parent, a = self:GetParent(), self:GetAbility()
	local enemies = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil, a:GetSpecialValueFor("omni_slash_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS, FIND_ANY_ORDER, false)
	if #enemies == 0 then self:Destroy() return end
	self:Slash(enemies[RandomInt(1, #enemies)])
end
function modifier_dota688_juggernaut_omni_slash:OnDestroy()
	if IsServer() then ParticleManager:DestroyParticle(self.fx, false); self:GetParent():RemoveGesture(ACT_DOTA_OVERRIDE_ABILITY_4) end
end
function modifier_dota688_juggernaut_omni_slash:CheckState() return { [MODIFIER_STATE_INVULNERABLE] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true, [MODIFIER_STATE_STUNNED] = true } end
