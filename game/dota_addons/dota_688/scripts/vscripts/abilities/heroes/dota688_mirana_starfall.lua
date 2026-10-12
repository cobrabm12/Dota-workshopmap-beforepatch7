-- Starstorm (6.88): 75/150/225/300 daune magice tuturor inamicilor din 650; dupa 0.5 s, un inamic aleator din 425 e lovit din nou.
-- Scepter: se declanseaza pasiv la fiecare 10 s (doar daca Mirana e vizibila pentru inamici si are un inamic in raza).
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_starfall_passive", "abilities/heroes/dota688_mirana_starfall", LUA_MODIFIER_MOTION_NONE)
dota688_mirana_starfall = class({})
function dota688_mirana_starfall:GetIntrinsicModifierName() return "modifier_dota688_starfall_passive" end
function dota688_mirana_starfall:Strike(target)
	local caster = self:GetCaster()
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_mirana/mirana_starfall_attack.vpcf", PATTACH_CUSTOMORIGIN, target)
	ParticleManager:SetParticleControlEnt(fx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
	target:EmitSound("Hero_Mirana.Starstorm.Impact")
	ApplyDamage({ victim = target, attacker = caster, damage = self:GetAbilityDamage(), damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
end
function dota688_mirana_starfall:Storm()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_Mirana.Starstorm.Cast")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_mirana/mirana_starfall_circle.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("starfall_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, e in ipairs(enemies) do self:Strike(e) end
	Dota688Timers:After(0.5, function()
		if caster:IsNull() then return end
		local near = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("starfall_secondary_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		if #near > 0 then self:Strike(near[RandomInt(1, #near)]) end
	end)
	return #enemies
end
function dota688_mirana_starfall:OnSpellStart() self:Storm() end
modifier_dota688_starfall_passive = class({})
function modifier_dota688_starfall_passive:IsHidden() return true end
function modifier_dota688_starfall_passive:IsPurgable() return false end
function modifier_dota688_starfall_passive:RemoveOnDeath() return false end
function modifier_dota688_starfall_passive:OnCreated() if IsServer() then self:StartIntervalThink(self:GetAbility():GetSpecialValueFor("interval_scepter")) end end
function modifier_dota688_starfall_passive:OnIntervalThink()
	local p, a = self:GetParent(), self:GetAbility()
	if not p:IsAlive() or a:GetLevel() < 1 or not Dota688HasScepter(p) or p:PassivesDisabled() or p:IsInvisible() then return end
	local enemies = FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, a:GetSpecialValueFor("starfall_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	if #enemies == 0 then return end
	a:Storm()
end
