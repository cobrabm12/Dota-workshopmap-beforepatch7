-- Nether Strike (6.88): Spirit Breaker apare langa tinta (raza 700) si o loveste cu 150/250/350 daune magice + un Greater Bash de nivelul curent.
-- Scepter: raza 850, cooldown 20, bash-ul loveste toti inamicii din 250 de tinta.
require("dota688/val")
require("dota688/aghanim")
require("dota688/stun")
LinkLuaModifier("modifier_dota688_nether_strike_haste", "abilities/heroes/dota688_spirit_breaker_nether_strike", LUA_MODIFIER_MOTION_NONE)
dota688_spirit_breaker_nether_strike = class({})
function dota688_spirit_breaker_nether_strike:GetCastRange(location, target)
	if Dota688HasScepter(self:GetCaster()) then return self:GetSpecialValueFor("cast_range_scepter") end
	return self.BaseClass.GetCastRange(self, location, target)
end
function dota688_spirit_breaker_nether_strike:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetLevelSpecialValueFor("cooldown_scepter", level) end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_spirit_breaker_nether_strike:Bash(target)
	local caster = self:GetCaster()
	local bash = caster:FindAbilityByName("spirit_breaker_greater_bash")
	if not bash or bash:GetLevel() < 1 or not target:IsAlive() then return end
	local dmg = caster:GetMoveSpeedModifier(caster:GetBaseMoveSpeed(), false) * bash:GetSpecialValueFor("damage") / 100
	ApplyDamage({ victim = target, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = bash })
	local dir = target:GetAbsOrigin() - caster:GetAbsOrigin(); dir.z = 0
	Dota688Knockback(target, caster, bash, dir:Normalized(), bash:GetSpecialValueFor("knockback_distance"), bash:GetSpecialValueFor("knockback_duration"))
	Dota688Stun(target, caster, bash, bash:GetSpecialValueFor("duration"))
	target:EmitSound("Hero_SpiritBreaker.GreaterBash")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_spirit_breaker/spirit_breaker_greater_bash.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:ReleaseParticleIndex(fx)
	caster:AddNewModifier(caster, bash, "modifier_dota688_nether_strike_haste", { duration = bash:GetSpecialValueFor("movespeed_duration") })
end
function dota688_spirit_breaker_nether_strike:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	local dir = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	caster:EmitSound("Hero_SpiritBreaker.NetherStrike.Begin")
	FindClearSpaceForUnit(caster, target:GetAbsOrigin() - dir * 80, true)
	caster:SetForwardVector(dir)
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_spirit_breaker/spirit_breaker_nether_strike_end.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	caster:EmitSound("Hero_SpiritBreaker.NetherStrike.End")
	ApplyDamage({ victim = target, attacker = caster, damage = self:GetSpecialValueFor("damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
	local targets = { target }
	if Dota688HasScepter(caster) then
		targets = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, self:GetSpecialValueFor("bash_radius_scepter"), DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		local has = false
		for _, u in ipairs(targets) do if u == target then has = true end end
		if not has then table.insert(targets, target) end
	end
	for _, u in ipairs(targets) do self:Bash(u) end
	caster:MoveToTargetToAttack(target)
end
modifier_dota688_nether_strike_haste = class({})
function modifier_dota688_nether_strike_haste:IsPurgable() return true end
function modifier_dota688_nether_strike_haste:GetTexture() return "spirit_breaker_greater_bash" end
function modifier_dota688_nether_strike_haste:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_nether_strike_haste:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "bonus_movespeed_pct") end
