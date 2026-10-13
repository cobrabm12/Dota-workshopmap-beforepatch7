-- Stasis Trap (6.88): capcana invizibila (2 s), armata dupa 1.5 s; cand un inamic intra in 450, explodeaza dupa 1.5 s si stun-eaza 2.5/3/3.5/4 s in 450. Durata 6 min.
require("abilities/heroes/dota688_techies_shared")
LinkLuaModifier("modifier_dota688_techies_stasis_trap", "abilities/heroes/dota688_techies_stasis_trap", LUA_MODIFIER_MOTION_NONE)
dota688_techies_stasis_trap = class({})
function dota688_techies_stasis_trap:GetAOERadius() return self:GetSpecialValueFor("activation_radius") end
function dota688_techies_stasis_trap:OnSpellStart()
	local pos = self:GetCursorPosition()
	Dota688Techies.Spawn("npc_dota688_techies_stasis_trap", self:GetCaster(), self, pos, "modifier_dota688_techies_stasis_trap", self:GetSpecialValueFor("duration"))
	EmitSoundOnLocationWithCaster(pos, "Hero_Techies.StasisTrap.Plant", self:GetCaster())
end
modifier_dota688_techies_stasis_trap = Dota688Techies.MineModifier("fade_time")
function modifier_dota688_techies_stasis_trap:OnIntervalThink()
	local a, mine, caster = self:GetAbility(), self:GetParent(), self:GetCaster()
	if self.exploding or GameRules:GetGameTime() - self.start < a:GetSpecialValueFor("activation_time") then return end
	local near = FindUnitsInRadius(caster:GetTeamNumber(), mine:GetAbsOrigin(), nil, a:GetSpecialValueFor("activation_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_ANY_ORDER, false)   -- 6.88: nu o declanseaza invizibilii
	if #near == 0 then return end
	self.exploding = true
	mine:EmitSound("Dota688.Techies.StasisTrap.Priming")
	Dota688Timers:After(a:GetSpecialValueFor("explode_delay"), function()
		if mine:IsNull() or not mine:IsAlive() then return end
		EmitSoundOnLocationWithCaster(mine:GetAbsOrigin(), "Dota688.Techies.StasisTrap.Stun", caster)
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_techies/techies_stasis_trap_explode.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(fx, 0, mine:GetAbsOrigin()); ParticleManager:ReleaseParticleIndex(fx)
		for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), mine:GetAbsOrigin(), nil, a:GetSpecialValueFor("stun_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
			e:AddNewModifier(caster, a, "modifier_stunned", { duration = a:GetSpecialValueFor("stun_duration") })
		end
		-- 6.88: "Stasis Traps destroy all other Stasis Traps in their area"
		for _, other in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), mine:GetAbsOrigin(), nil, a:GetSpecialValueFor("stun_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
			DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)) do
			if other ~= mine and other:HasModifier("modifier_dota688_techies_stasis_trap") then other:ForceKill(false) end
		end
		mine:ForceKill(false)
	end)
end
