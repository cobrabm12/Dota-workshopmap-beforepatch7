-- Eye of the Storm (6.88): 30 s, la fiecare 0.7/0.6/0.5 s loveste inamicul cu cel mai putin HP din 500: 40/55/70 daune fizice si -1 armura (cumulativ).
-- Scepter: 0.6/0.5/0.4 s si loveste si cladiri (turnuri, baraci, Ancient).
require("dota688/val")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_razor_eye_of_the_storm"
LinkLuaModifier("modifier_dota688_eye_of_the_storm", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_eye_of_the_storm_armor", F, LUA_MODIFIER_MOTION_NONE)
dota688_razor_eye_of_the_storm = class({})
function dota688_razor_eye_of_the_storm:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_Razor.Storm.Start")
	caster:AddNewModifier(caster, self, "modifier_dota688_eye_of_the_storm", { duration = self:GetSpecialValueFor("duration") })
end
modifier_dota688_eye_of_the_storm = class({})
function modifier_dota688_eye_of_the_storm:IsPurgable() return false end
function modifier_dota688_eye_of_the_storm:GetEffectName() return "particles/units/heroes/hero_razor/razor_rain_storm.vpcf" end
function modifier_dota688_eye_of_the_storm:OnCreated()
	if not IsServer() then return end
	local a = self:GetAbility()
	self.scepter = Dota688HasScepter(self:GetParent())
	self:GetParent():EmitSound("Hero_Razor.Storm.Loop")
	self:StartIntervalThink(self.scepter and a:GetSpecialValueFor("strike_interval_scepter") or a:GetSpecialValueFor("strike_interval"))
end
function modifier_dota688_eye_of_the_storm:OnIntervalThink()
	local p, a = self:GetParent(), self:GetAbility()
	local radius = a:GetSpecialValueFor("radius")
	local units = FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	local target, best = nil, math.huge
	for _, u in ipairs(units) do if u:GetHealth() < best then target, best = u, u:GetHealth() end end
	if not target and self.scepter then
		for _, b in ipairs(FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
			local n = b:GetUnitName()
			if (n:find("tower", 1, true) or n:find("rax", 1, true) or n:find("fort", 1, true)) and b:GetHealth() < best then target, best = b, b:GetHealth() end
		end
	end
	if not target then return end
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_razor/razor_storm_lightning_strike.vpcf", PATTACH_CUSTOMORIGIN, p)
	ParticleManager:SetParticleControlEnt(fx, 0, p, PATTACH_POINT_FOLLOW, "attach_hitloc", p:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
	target:EmitSound("Hero_Razor.Storm.Strike")
	ApplyDamage({ victim = target, attacker = p, damage = a:GetSpecialValueFor("damage"), damage_type = DAMAGE_TYPE_PHYSICAL, ability = a })
	if not target:IsBuilding() then
		local m = target:FindModifierByName("modifier_dota688_eye_of_the_storm_armor")
		if not m then m = target:AddNewModifier(p, a, "modifier_dota688_eye_of_the_storm_armor", { duration = self:GetRemainingTime() }) end
		if m then m:SetStackCount(m:GetStackCount() + 1); m:SetDuration(self:GetRemainingTime(), true) end
	end
end
function modifier_dota688_eye_of_the_storm:OnDestroy() if IsServer() then self:GetParent():StopSound("Hero_Razor.Storm.Loop"); self:GetParent():EmitSound("Hero_Razor.Storm.End") end end
modifier_dota688_eye_of_the_storm_armor = class({})
function modifier_dota688_eye_of_the_storm_armor:IsDebuff() return true end
function modifier_dota688_eye_of_the_storm_armor:IsPurgable() return true end
function modifier_dota688_eye_of_the_storm_armor:GetTexture() return "razor_eye_of_the_storm" end
function modifier_dota688_eye_of_the_storm_armor:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function modifier_dota688_eye_of_the_storm_armor:GetModifierPhysicalArmorBonus() return -Dota688Val(self, "armor_reduction") * self:GetStackCount() end
