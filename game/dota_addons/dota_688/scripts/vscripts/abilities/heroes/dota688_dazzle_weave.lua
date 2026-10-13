-- Weave (6.88): zona de 575 timp de 24 s; aliatii castiga, inamicii pierd 0.75/1/1.25 armura pe secunda (cumulativ).
-- Scepter: raza 775, 1.25/1.5/1.75 armura pe secunda.
require("dota688/val")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_dazzle_weave"
LinkLuaModifier("modifier_dota688_weave_thinker", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_weave_buff", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_weave_debuff", F, LUA_MODIFIER_MOTION_NONE)
dota688_dazzle_weave = class({})
function dota688_dazzle_weave:Radius()
	return Dota688HasScepter(self:GetCaster()) and self:GetSpecialValueFor("radius_scepter") or self:GetSpecialValueFor("radius")
end
function dota688_dazzle_weave:GetAOERadius() return self:Radius() end
function dota688_dazzle_weave:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	caster:EmitSound("Hero_Dazzle.Weave")
	local dur = Dota688HasScepter(caster) and self:GetSpecialValueFor("duration_scepter") or self:GetSpecialValueFor("duration")
	CreateModifierThinker(caster, self, "modifier_dota688_weave_thinker", { duration = dur }, pos, caster:GetTeamNumber(), false)
	AddFOWViewer(caster:GetTeamNumber(), pos, self:GetSpecialValueFor("vision"), dur, false)
end
modifier_dota688_weave_thinker = class({})
function modifier_dota688_weave_thinker:IsHidden() return true end
function modifier_dota688_weave_thinker:OnCreated()
	if not IsServer() then return end
	local a = self:GetAbility()
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_dazzle/dazzle_weave.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:SetParticleControl(self.fx, 0, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.fx, 1, Vector(a:Radius(), a:Radius(), a:Radius()))
	self:StartIntervalThink(0.5)
end
function modifier_dota688_weave_thinker:OnIntervalThink()
	local a, caster = self:GetAbility(), self:GetCaster()
	if not a or a:IsNull() or not caster or caster:IsNull() then self:Destroy(); return end   -- abilitatea/caster-ul au disparut (Rubick, iluzie moarta)
	if self.applied then return end   -- 6.88: "entering or leaving the area after the cast has no effect"
	self.applied = true
	local remaining = self:GetRemainingTime()
	for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, a:Radius(), DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)) do
		local name = (u:GetTeamNumber() == caster:GetTeamNumber()) and "modifier_dota688_weave_buff" or "modifier_dota688_weave_debuff"
		if not u:HasModifier(name) then
			u:AddNewModifier(caster, a, name, { duration = remaining })
		end
	end
end
function modifier_dota688_weave_thinker:OnDestroy() if IsServer() then ParticleManager:DestroyParticle(self.fx, false); UTIL_Remove(self:GetParent()) end end
local function weave_mod(m, sign)
	function m:IsPurgable() return sign < 0 end
	function m:IsDebuff() return sign < 0 end
	function m:GetTexture() return "dazzle_weave" end
	function m:OnCreated()
		if not IsServer() then return end
		self.per = Dota688HasScepter(self:GetCaster()) and Dota688Val(self, "armor_per_second_scepter") or Dota688Val(self, "armor_per_second")
		self:StartIntervalThink(1.0)
	end
	function m:OnIntervalThink() self:SetStackCount(self:GetStackCount() + 1) end
	function m:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
	function m:GetModifierPhysicalArmorBonus()
		local per = self.per or Dota688Val(self, "armor_per_second")
		return sign * per * self:GetStackCount()
	end
end
modifier_dota688_weave_buff = class({})
weave_mod(modifier_dota688_weave_buff, 1)
modifier_dota688_weave_debuff = class({})
weave_mod(modifier_dota688_weave_debuff, -1)
