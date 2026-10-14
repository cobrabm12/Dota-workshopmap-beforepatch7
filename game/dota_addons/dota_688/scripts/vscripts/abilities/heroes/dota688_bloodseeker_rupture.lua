-- Rupture (6.88): 12 s; tinta ia 30/45/60% din distanta parcursa ca daune pure (max 200 la fiecare 0.25 s); trece prin imunitate.
-- Scepter: 2 incarcaturi care se refac la 40 s.
require("dota688/val")
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_rupture", "abilities/heroes/dota688_bloodseeker_rupture", LUA_MODIFIER_MOTION_NONE)
dota688_bloodseeker_rupture = class({})
function dota688_bloodseeker_rupture:Charges()
	if self.charges == nil then self.charges = self:GetSpecialValueFor("max_charges_scepter") end
	return self.charges
end
function dota688_bloodseeker_rupture:RestoreLater()
	Dota688Timers:After(self:GetSpecialValueFor("charge_restore_time_scepter"), function()
		if self:IsNull() then return end
		self.charges = math.min(self:GetSpecialValueFor("max_charges_scepter"), (self.charges or 0) + 1)
		if self.charges < self:GetSpecialValueFor("max_charges_scepter") then self:RestoreLater() end
		if Dota688HasScepter(self:GetCaster()) then self:EndCooldown() end
		if self.SetCurrentAbilityCharges then self:SetCurrentAbilityCharges(self.charges) end
	end)
end
function dota688_bloodseeker_rupture:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	target:EmitSound("Hero_Bloodseeker.Rupture.Cast")
	target:AddNewModifier(caster, self, "modifier_dota688_rupture", { duration = self:GetSpecialValueFor("duration") })
	if Dota688HasScepter(caster) then
		local full = self:Charges() >= self:GetSpecialValueFor("max_charges_scepter")
		self.charges = math.max(0, self:Charges() - 1)
		if full then self:RestoreLater() end
		if self.charges > 0 then Dota688Timers:After(0, function() if not self:IsNull() then self:EndCooldown() end end) end
		if self.SetCurrentAbilityCharges then self:SetCurrentAbilityCharges(self.charges) end
	end
end
modifier_dota688_rupture = class({})
function modifier_dota688_rupture:IsDebuff() return true end
function modifier_dota688_rupture:IsPurgable() return false end
function modifier_dota688_rupture:GetTexture() return "bloodseeker_rupture" end
function modifier_dota688_rupture:GetEffectName() return "particles/units/heroes/hero_bloodseeker/bloodseeker_rupture.vpcf" end
function modifier_dota688_rupture:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_rupture:OnCreated()
	if not IsServer() then return end
	self.last = self:GetParent():GetAbsOrigin()
	self.interval = Dota688Val(self, "damage_cap_interval")
	self:StartIntervalThink(self.interval)
end
function modifier_dota688_rupture:OnIntervalThink()
	local p, a = self:GetParent(), self:GetAbility()
	local pos = p:GetAbsOrigin()
	local d = (pos - self.last):Length2D()
	self.last = pos
	if d <= 1 then return end
	local dmg = math.min(Dota688Val(self, "damage_cap_amount"), d * Dota688Val(self, "movement_damage_pct") / 100)
	if d > 1300 then return end   -- teleport/blink: fara daune (6.88)
	ApplyDamage({ victim = p, attacker = self:GetCaster(), damage = dmg, damage_type = DAMAGE_TYPE_PURE, ability = a })
end
