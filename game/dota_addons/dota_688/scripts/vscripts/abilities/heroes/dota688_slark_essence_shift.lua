-- Essence Shift (6.88): pasiv, 4 niveluri; fiecare atac al lui Slark pe un erou inamic (nu iluzie) ii da lui Slark +3 agilitate,
-- iar tinta pierde 1 din fiecare atribut, pentru 15/30/60/120 s. Fiecare lovitura expira separat (pe Slark si pe tinta
-- independent), atributele tintei nu scad sub 1, iar totul revine la moarte. Trece prin imunitatea la magie.
-- Fara furtul permanent la kill, raza de furt si scalarea cu nivelul eroului (adaugate dupa 6.88).
require("dota688/val")
local F = "abilities/heroes/dota688_slark_essence_shift"
LinkLuaModifier("modifier_dota688_slark_essence_shift_passive", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_slark_essence_shift", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_slark_essence_shift_debuff_counter", F, LUA_MODIFIER_MOTION_NONE)

dota688_slark_essence_shift = class({})
function dota688_slark_essence_shift:GetIntrinsicModifierName() return "modifier_dota688_slark_essence_shift_passive" end

modifier_dota688_slark_essence_shift_passive = class({})
function modifier_dota688_slark_essence_shift_passive:IsHidden() return true end
function modifier_dota688_slark_essence_shift_passive:IsPurgable() return false end
function modifier_dota688_slark_essence_shift_passive:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_slark_essence_shift_passive:OnAttackLanded(params)
	if not IsServer() then return end
	local p, t = self:GetParent(), params.target
	if params.attacker ~= p or not t or t:IsNull() then return end
	if p:IsIllusion() or p:PassivesDisabled() then return end
	if t:GetTeamNumber() == p:GetTeamNumber() or not t:IsRealHero() then return end
	local a = self:GetAbility()
	if not a or a:IsNull() or a:GetLevel() < 1 then return end
	local dur = a:GetSpecialValueFor("duration")
	local debuff = t:FindModifierByNameAndCaster("modifier_dota688_slark_essence_shift_debuff_counter", p)
		or t:AddNewModifier(p, a, "modifier_dota688_slark_essence_shift_debuff_counter", { duration = dur })
	if debuff and debuff.AddInstance then debuff:AddInstance(dur, a:GetSpecialValueFor("stat_loss")) end
	local buff = p:FindModifierByName("modifier_dota688_slark_essence_shift")
		or p:AddNewModifier(p, a, "modifier_dota688_slark_essence_shift", { duration = dur })
	if buff and buff.AddInstance then buff:AddInstance(dur) end
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_slark/slark_essence_shift.vpcf", PATTACH_ABSORIGIN_FOLLOW, t)
	ParticleManager:SetParticleControl(fx, 1, p:GetAbsOrigin() + Vector(0, 0, 64))
	ParticleManager:ReleaseParticleIndex(fx)
end

-- liste de lovituri: fiecare intrare expira la momentul ei (GameTime)
local function prune(list)
	local now, changed = GameRules:GetGameTime(), false
	for k = #list, 1, -1 do
		if list[k].t <= now then table.remove(list, k); changed = true end
	end
	return changed
end

-- buff pe Slark: +agi_gain agilitate pentru fiecare lovitura activa
modifier_dota688_slark_essence_shift = class({})
function modifier_dota688_slark_essence_shift:IsPurgable() return false end
function modifier_dota688_slark_essence_shift:OnCreated()
	if not IsServer() then return end
	self.list = {}
	self:StartIntervalThink(0.1)
end
function modifier_dota688_slark_essence_shift:AddInstance(dur)
	table.insert(self.list, { t = GameRules:GetGameTime() + dur })
	if self:GetRemainingTime() < dur then self:SetDuration(dur, true) end
	self:SetStackCount(#self.list)
	self:GetParent():CalculateStatBonus(true)
end
function modifier_dota688_slark_essence_shift:OnIntervalThink()
	if not prune(self.list) then return end
	if #self.list == 0 then self:Destroy(); return end
	self:SetStackCount(#self.list)
	self:GetParent():CalculateStatBonus(true)
end
function modifier_dota688_slark_essence_shift:DeclareFunctions() return { MODIFIER_PROPERTY_STATS_AGILITY_BONUS } end
function modifier_dota688_slark_essence_shift:GetModifierBonusStats_Agility() return self:GetStackCount() * Dota688Val(self, "agi_gain") end

-- debuff pe tinta: -stat_loss la fiecare atribut pentru fiecare lovitura activa (fara sa coboare atributul total sub 1).
-- Pierderile efective se calculeaza pe server la fiecare lovitura si se trimit clientului (custom transmitter data).
modifier_dota688_slark_essence_shift_debuff_counter = class({})
function modifier_dota688_slark_essence_shift_debuff_counter:IsDebuff() return true end
function modifier_dota688_slark_essence_shift_debuff_counter:IsPurgable() return false end
function modifier_dota688_slark_essence_shift_debuff_counter:OnCreated()
	self.s, self.a, self.i = 0, 0, 0
	if not IsServer() then return end
	self.list = {}
	self:SetHasCustomTransmitterData(true)
	self:StartIntervalThink(0.1)
end
function modifier_dota688_slark_essence_shift_debuff_counter:AddCustomTransmitterData() return { s = self.s, a = self.a, i = self.i } end
function modifier_dota688_slark_essence_shift_debuff_counter:HandleCustomTransmitterData(data)
	self.s, self.a, self.i = data.s or 0, data.a or 0, data.i or 0
end
function modifier_dota688_slark_essence_shift_debuff_counter:AddInstance(dur, loss)
	local t = self:GetParent()
	local function take(cur) return math.max(0, math.min(loss, math.floor(cur) - 1)) end
	table.insert(self.list, { t = GameRules:GetGameTime() + dur, s = take(t:GetStrength()), a = take(t:GetAgility()), i = take(t:GetIntellect(true)) })
	if self:GetRemainingTime() < dur then self:SetDuration(dur, true) end
	self:Update()
end
function modifier_dota688_slark_essence_shift_debuff_counter:Update()
	local s, a, i = 0, 0, 0
	for _, e in ipairs(self.list) do s, a, i = s + e.s, a + e.a, i + e.i end
	self:SetStackCount(#self.list)
	if s ~= self.s or a ~= self.a or i ~= self.i then
		self.s, self.a, self.i = s, a, i
		self:SendBuffRefreshToClients()
		self:GetParent():CalculateStatBonus(true)
	end
end
function modifier_dota688_slark_essence_shift_debuff_counter:OnIntervalThink()
	if not prune(self.list) then return end
	if #self.list == 0 then self:Destroy(); return end
	self:Update()
end
function modifier_dota688_slark_essence_shift_debuff_counter:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, MODIFIER_PROPERTY_STATS_AGILITY_BONUS, MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, MODIFIER_PROPERTY_TOOLTIP }
end
function modifier_dota688_slark_essence_shift_debuff_counter:GetModifierBonusStats_Strength() return -(self.s or 0) end
function modifier_dota688_slark_essence_shift_debuff_counter:GetModifierBonusStats_Agility() return -(self.a or 0) end
function modifier_dota688_slark_essence_shift_debuff_counter:GetModifierBonusStats_Intellect() return -(self.i or 0) end
function modifier_dota688_slark_essence_shift_debuff_counter:OnTooltip() return math.max(self.s or 0, self.a or 0, self.i or 0) end
