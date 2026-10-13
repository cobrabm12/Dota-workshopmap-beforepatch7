-- Time Dilation (6.88): inamicii din raza 725 sunt prinsi 6/8/10/12 s: cooldown-urile abilitatilor aflate in cooldown
-- la aplicare sunt inghetate, iar tinta pierde 10% viteza de miscare si 10 viteza de atac pentru fiecare cooldown inghetat.
-- Fara daune. Nu afecteaza itemele. Nu trece prin imunitate.
require("dota688/val")
LinkLuaModifier("modifier_dota688_time_dilation", "abilities/heroes/dota688_faceless_void_time_dilation", LUA_MODIFIER_MOTION_NONE)
dota688_faceless_void_time_dilation = class({})
function dota688_faceless_void_time_dilation:GetCastRange() return self:GetSpecialValueFor("radius") end
function dota688_faceless_void_time_dilation:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	caster:EmitSound("Hero_FacelessVoid.TimeDilation.Cast")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_faceless_void/faceless_void_timedialate.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(fx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(fx, 1, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(fx)
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		e:AddNewModifier(caster, self, "modifier_dota688_time_dilation", { duration = self:GetSpecialValueFor("duration") })
	end
end

-- SetFrozenCooldown e apelat protejat: daca motorul nu-l accepta, OnIntervalThink tine oricum cooldown-ul pe loc
local function set_frozen(ab, frozen)
	if ab and not ab:IsNull() and ab.SetFrozenCooldown then pcall(ab.SetFrozenCooldown, ab, frozen) end
end

modifier_dota688_time_dilation = class({})
function modifier_dota688_time_dilation:IsDebuff() return true end
function modifier_dota688_time_dilation:IsPurgable() return true end
function modifier_dota688_time_dilation:GetEffectName() return "particles/units/heroes/hero_faceless_void/faceless_void_dialatedebuf.vpcf" end
function modifier_dota688_time_dilation:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_time_dilation:OnCreated()
	self.slow = Dota688Val(self, "slow")
	if not IsServer() then return end
	self.frozen = {}
	self:Freeze()
	self:StartIntervalThink(0.1)
end
function modifier_dota688_time_dilation:OnRefresh()
	self.slow = Dota688Val(self, "slow")
	if IsServer() then self:Freeze() end
end
-- ingheata abilitatile (nu itemele) aflate acum in cooldown
function modifier_dota688_time_dilation:Freeze()
	local p = self:GetParent()
	for i = 0, p:GetAbilityCount() - 1 do
		local ab = p:GetAbilityByIndex(i)
		if ab and not ab:IsNull() and ab:GetLevel() > 0 and not ab:IsHidden() and not ab:IsCooldownReady() and not self.frozen[ab] then
			self.frozen[ab] = ab:GetCooldownTimeRemaining()
			set_frozen(ab, true)
		end
	end
	self:Recount()
end
function modifier_dota688_time_dilation:Recount()
	local n = 0
	for _ in pairs(self.frozen) do n = n + 1 end
	self:SetStackCount(n)
end
function modifier_dota688_time_dilation:OnIntervalThink()
	local changed = false
	for ab, rem in pairs(self.frozen) do
		if ab:IsNull() then
			self.frozen[ab] = nil; changed = true
		elseif ab:IsCooldownReady() then
			-- cooldown resetat (Refresher etc.): nu mai e inghetat
			set_frozen(ab, false)
			self.frozen[ab] = nil; changed = true
		elseif ab:GetCooldownTimeRemaining() < rem - 0.05 then
			ab:EndCooldown()
			ab:StartCooldown(rem)
		end
	end
	if changed then self:Recount() end
end
function modifier_dota688_time_dilation:OnDestroy()
	if not IsServer() then return end
	for ab, _ in pairs(self.frozen) do set_frozen(ab, false) end
	self.frozen = {}
end
function modifier_dota688_time_dilation:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_dota688_time_dilation:GetModifierMoveSpeedBonus_Percentage() return -(self.slow or 0) * self:GetStackCount() end
function modifier_dota688_time_dilation:GetModifierAttackSpeedBonus_Constant() return -(self.slow or 0) * self:GetStackCount() end
