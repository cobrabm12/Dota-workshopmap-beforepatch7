-- Coup de Grace (6.88): 15% sansa de critic 230/340/450% direct pe atac (si pe atacul lui Stifling Dagger:
-- "Stifling Dagger shares the same critical strike chance"). Abilitatea curenta da in schimb buff-ul Deadly Focus
-- (indicatorul de deasupra eroului), care garanteaza critic la atacul urmator - mecanica de dupa 6.88.
require("dota688/val")
local F = "abilities/heroes/dota688_phantom_assassin_coup_de_grace"
LinkLuaModifier("modifier_dota688_phantom_assassin_coup_de_grace", F, LUA_MODIFIER_MOTION_NONE)

dota688_phantom_assassin_coup_de_grace = class({})
function dota688_phantom_assassin_coup_de_grace:GetIntrinsicModifierName() return "modifier_dota688_phantom_assassin_coup_de_grace" end

modifier_dota688_phantom_assassin_coup_de_grace = class({})
function modifier_dota688_phantom_assassin_coup_de_grace:IsHidden() return true end
function modifier_dota688_phantom_assassin_coup_de_grace:IsPurgable() return false end
function modifier_dota688_phantom_assassin_coup_de_grace:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE, MODIFIER_EVENT_ON_ATTACK_LANDED }
end
function modifier_dota688_phantom_assassin_coup_de_grace:GetModifierPreAttack_CriticalStrike(params)
	local parent = self:GetParent()
	if parent:PassivesDisabled() or not params.target or params.target:IsBuilding() or params.target:IsOther() then return nil end
	if params.target:GetTeamNumber() == parent:GetTeamNumber() then return nil end
	local prd = DOTA_PSEUDO_RANDOM_PHANTOMASSASSIN_CRIT or DOTA_PSEUDO_RANDOM_CUSTOM_GAME_1
	if RollPseudoRandomPercentage(Dota688Val(self, "crit_chance"), prd, parent) then
		self.procTarget = params.target
		return Dota688Val(self, "crit_bonus")
	end
	return nil
end
function modifier_dota688_phantom_assassin_coup_de_grace:OnAttackLanded(params)
	if not IsServer() then return end
	if params.attacker ~= self:GetParent() or params.target ~= self.procTarget then return end
	self.procTarget = nil
	local t = params.target
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_crit_impact.vpcf", PATTACH_CUSTOMORIGIN, t)
	ParticleManager:SetParticleControlEnt(fx, 0, t, PATTACH_POINT_FOLLOW, "attach_hitloc", t:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(fx, 1, t:GetAbsOrigin())
	ParticleManager:SetParticleControlForward(fx, 1, -self:GetParent():GetForwardVector())
	ParticleManager:ReleaseParticleIndex(fx)
	t:EmitSound("Hero_PhantomAssassin.CoupDeGrace")
end
