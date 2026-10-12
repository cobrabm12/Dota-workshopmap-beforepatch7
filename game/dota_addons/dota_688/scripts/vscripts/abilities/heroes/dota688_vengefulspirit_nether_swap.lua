-- Nether Swap (6.88): schimba pozitia cu un erou (aliat sau inamic), raza 700/950/1200, cooldown 45; trece prin imunitate.
-- Scepter: cooldown 10, poate schimba si unitati non-erou; cand Venge moare, apare o Vengeance Illusion (50% daune date, 150% primite) pana la respawn.
require("dota688/aghanim")
local F = "abilities/heroes/dota688_vengefulspirit_nether_swap"
LinkLuaModifier("modifier_dota688_nether_swap_passive", F, LUA_MODIFIER_MOTION_NONE)
dota688_vengefulspirit_nether_swap = class({})
function dota688_vengefulspirit_nether_swap:GetIntrinsicModifierName() return "modifier_dota688_nether_swap_passive" end
function dota688_vengefulspirit_nether_swap:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetSpecialValueFor("nether_swap_cooldown_scepter") end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_vengefulspirit_nether_swap:CastFilterResultTarget(target)
	local caster = self:GetCaster()
	if target == caster then return UF_FAIL_CUSTOM end
	if target:IsBuilding() or target:IsCourier() or target:IsOther() then return UF_FAIL_CUSTOM end
	if not target:IsHero() and not Dota688HasScepter(caster) then return UF_FAIL_CUSTOM end
	if target:IsInvulnerable() then return UF_FAIL_INVULNERABLE end
	return UF_SUCCESS
end
function dota688_vengefulspirit_nether_swap:GetCustomCastErrorTarget(target) return "#dota_hud_error_cant_cast_on_other" end
function dota688_vengefulspirit_nether_swap:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:GetTeamNumber() ~= caster:GetTeamNumber() and target:TriggerSpellAbsorb(self) then return end
	local a, b = caster:GetAbsOrigin(), target:GetAbsOrigin()
	caster:EmitSound("Hero_VengefulSpirit.NetherSwap")
	for _, pair in ipairs({ { caster, b }, { target, a } }) do
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_vengeful/vengeful_nether_swap.vpcf", PATTACH_ABSORIGIN, pair[1])
		ParticleManager:SetParticleControl(fx, 0, pair[1]:GetAbsOrigin()); ParticleManager:SetParticleControl(fx, 1, pair[2])
		ParticleManager:ReleaseParticleIndex(fx)
	end
	caster:Stop(); target:Stop()
	FindClearSpaceForUnit(caster, b, true)
	FindClearSpaceForUnit(target, a, true)
end
modifier_dota688_nether_swap_passive = class({})
function modifier_dota688_nether_swap_passive:IsHidden() return true end
function modifier_dota688_nether_swap_passive:IsPurgable() return false end
function modifier_dota688_nether_swap_passive:RemoveOnDeath() return false end
function modifier_dota688_nether_swap_passive:DeclareFunctions() return { MODIFIER_EVENT_ON_DEATH } end
function modifier_dota688_nether_swap_passive:OnDeath(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	local p, a = self:GetParent(), self:GetAbility()
	if not p:IsRealHero() or p:IsReincarnating() or not Dota688HasScepter(p) or a:GetLevel() < 1 then return end
	Dota688Timers:After(0.1, function()
		if p:IsNull() or p:IsAlive() then return end
		local dur = math.max(5, p:GetTimeUntilRespawn())
		local ill = CreateIllusions(p, p, { outgoing_damage = -a:GetSpecialValueFor("illusion_damage_out_pct_scepter"), incoming_damage = a:GetSpecialValueFor("illusion_damage_in_pct_scepter") - 100, duration = dur }, 1, 100, false, false)
		for _, u in ipairs(ill or {}) do FindClearSpaceForUnit(u, p:GetAbsOrigin(), true) end
	end)
end
