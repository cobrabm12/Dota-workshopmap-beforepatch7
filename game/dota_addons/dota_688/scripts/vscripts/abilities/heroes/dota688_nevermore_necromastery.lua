-- Necromastery (6.88): +2 daune pentru fiecare suflet; +1 suflet la fiecare unitate omorata (si deny-uri, si neutrali), +12 (1 + 11)
-- la erou; max 18/24/30/36; la moarte pierde jumatate (dupa Requiem-ul de moarte, care foloseste numarul dinainte).
-- Scepter: max 22/30/38/46.
require("dota688/val")
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_necromastery", "abilities/heroes/dota688_nevermore_necromastery", LUA_MODIFIER_MOTION_NONE)
dota688_nevermore_necromastery = class({})
function dota688_nevermore_necromastery:GetIntrinsicModifierName() return "modifier_dota688_necromastery" end
function dota688_nevermore_necromastery:MaxSouls()
	if self:GetLevel() < 1 then return 0 end
	if Dota688HasScepter(self:GetCaster()) then return self:GetSpecialValueFor("necromastery_max_souls_scepter") end
	return self:GetSpecialValueFor("necromastery_max_souls")
end
modifier_dota688_necromastery = class({})
function modifier_dota688_necromastery:IsHidden() return self:GetStackCount() == 0 end
function modifier_dota688_necromastery:IsPurgable() return false end
function modifier_dota688_necromastery:RemoveOnDeath() return false end
function modifier_dota688_necromastery:GetTexture() return "nevermore_necromastery" end
function modifier_dota688_necromastery:OnCreated()
	if not IsServer() then return end
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_necro_souls.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	self:StartIntervalThink(0.5)
end
function modifier_dota688_necromastery:OnIntervalThink()
	local max = self:GetAbility():MaxSouls()
	if self:GetStackCount() > max then self:SetStackCount(max) end
	ParticleManager:SetParticleControl(self.fx, 1, Vector(self:GetStackCount(), 0, 0))
end
function modifier_dota688_necromastery:OnDestroy() if IsServer() then ParticleManager:DestroyParticle(self.fx, false) end end
function modifier_dota688_necromastery:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_EVENT_ON_DEATH } end
function modifier_dota688_necromastery:GetModifierPreAttack_BonusDamage()
	if self:GetParent():PassivesDisabled() then return 0 end
	return self:GetStackCount() * Dota688Val(self, "necromastery_damage_per_soul")
end
function modifier_dota688_necromastery:OnDeath(params)
	if not IsServer() then return end
	local p, a = self:GetParent(), self:GetAbility()
	if params.unit == p then
		if not p:IsReincarnating() then
			-- dupa Requiem-ul pasiv (acelasi eveniment), ca liniile sa se calculeze din sufletele de dinainte
			local souls = self:GetStackCount()
			Dota688Timers:After(0, function()
				if not self:IsNull() then self:SetStackCount(math.floor(souls * a:GetSpecialValueFor("necromastery_soul_release"))) end
			end)
		end
		return
	end
	if params.attacker ~= p or p:PassivesDisabled() or a:GetLevel() < 1 then return end
	local u = params.unit
	if not u or u:IsBuilding() or u:IsOther() or u:IsIllusion() then return end   -- si deny-urile (6.88)
	local gain = 1
	if u:IsRealHero() then gain = gain + a:GetSpecialValueFor("necromastery_souls_hero_bonus") end
	self:SetStackCount(math.min(a:MaxSouls(), self:GetStackCount() + gain))
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_necro_souls_hero.vpcf", PATTACH_CUSTOMORIGIN, u)
	ParticleManager:SetParticleControl(fx, 0, u:GetAbsOrigin()); ParticleManager:SetParticleControlEnt(fx, 1, p, PATTACH_POINT_FOLLOW, "attach_hitloc", p:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
end
