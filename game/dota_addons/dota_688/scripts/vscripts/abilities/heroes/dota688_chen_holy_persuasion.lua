-- Holy Persuasion (6.88): Chen preia controlul unui creep inamic/neutru (max 1/2/3/4; cel mai vechi moare cand se depaseste limita);
-- daca viata de baza e sub 700/800/900/1000, e ridicata la minim. Scepter: poate convinge si creepi Ancient (max = nivelul Hand of God).
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_holy_persuasion", "abilities/heroes/dota688_chen_holy_persuasion", LUA_MODIFIER_MOTION_NONE)
dota688_chen_holy_persuasion = class({})
function dota688_chen_holy_persuasion:Units()
	self.units = self.units or {}
	local alive = {}
	for _, u in ipairs(self.units) do if not u:IsNull() and u:IsAlive() then table.insert(alive, u) end end
	self.units = alive
	return alive
end
function dota688_chen_holy_persuasion:CastFilterResultTarget(target)
	local caster = self:GetCaster()
	if target:IsHero() or target:IsBuilding() or target:IsCourier() or target:IsOther() or target:IsConsideredHero() then return UF_FAIL_CUSTOM end
	if target:GetTeamNumber() == caster:GetTeamNumber() then return UF_FAIL_FRIENDLY end
	if target:IsAncient() then
		if not Dota688HasScepter(caster) then self.err = "#dota_hud_error_cant_cast_on_ancient" return UF_FAIL_CUSTOM end
		local hog = caster:FindAbilityByName("chen_hand_of_god")
		local max = hog and hog:GetLevel() or 0
		local n = 0
		for _, u in ipairs(self:Units()) do if u:IsAncient() then n = n + 1 end end
		if n >= max then self.err = "#dota688_chen_too_many_ancients" return UF_FAIL_CUSTOM end
	end
	if target:IsMagicImmune() then return UF_FAIL_MAGIC_IMMUNE_ENEMY end
	self.err = nil
	return UF_SUCCESS
end
function dota688_chen_holy_persuasion:GetCustomCastErrorTarget(target) return self.err or "#dota_hud_error_cant_cast_on_other" end
function dota688_chen_holy_persuasion:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	caster:EmitSound("Hero_Chen.HolyPersuasionCast")
	if target:TriggerSpellAbsorb(self) then return end
	local units = self:Units()
	while #units >= self:GetSpecialValueFor("max_units") do
		local old = table.remove(units, 1)
		old:ForceKill(false)
	end
	target:EmitSound("Hero_Chen.HolyPersuasion")
	target:SetTeam(caster:GetTeamNumber())
	target:SetOwner(caster)
	target:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
	target:Stop()
	local min = self:GetSpecialValueFor("health_min")
	if target:GetBaseMaxHealth() < min then
		target:SetBaseMaxHealth(min)
		target:SetMaxHealth(min)
	end
	target:AddNewModifier(caster, self, "modifier_dota688_holy_persuasion", {})
	table.insert(units, target)
	self.units = units
end
modifier_dota688_holy_persuasion = class({})
function modifier_dota688_holy_persuasion:IsPurgable() return false end
function modifier_dota688_holy_persuasion:RemoveOnDeath() return false end
function modifier_dota688_holy_persuasion:GetTexture() return "chen_holy_persuasion" end
function modifier_dota688_holy_persuasion:GetEffectName() return "particles/units/heroes/hero_chen/chen_holy_persuasion.vpcf" end
function modifier_dota688_holy_persuasion:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
