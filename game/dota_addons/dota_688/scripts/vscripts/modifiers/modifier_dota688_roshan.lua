-- Roshan ca in 6.88: 8000 HP, 5 armura, 65 daune, +700 HP / +0.7 armura / +10 daune la fiecare 4 minute.
-- Abilitatea moderna roshan_inherent_buffs impune HP 6000 + 130/min la fiecare frame (ignora KV-ul si orice
-- modifier) si adauga cresterea moderna; generatorul o scoate de pe Roshan (in 6.88 era un pasiv fara valori).
-- Pe server, la fiecare secunda: HP-ul de baza se seteaza la valoarea 6.88 (pastrand procentul de viata), iar
-- armura si daunele primesc bonusul = tinta 6.88 - ce da motorul (masurat, nu presupus).
-- Testat in joc: la 6:58 motorul dadea 6780 HP / 7.8 armura / 107 daune in loc de 8700 / 5.7 / 75.
modifier_dota688_roshan = class({})
require("dota688/constants")   -- si pe client (proprietatile modifier-ului se evalueaza si acolo)
local C = DOTA688

function modifier_dota688_roshan:IsHidden() return true end
function modifier_dota688_roshan:IsPurgable() return false end
function modifier_dota688_roshan:RemoveOnDeath() return false end
function modifier_dota688_roshan:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_dota688_roshan:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_dota688_roshan:OnCreated()
	self.armor, self.damage = 0, 0
	if IsServer() then
		self:OnIntervalThink()
		self:StartIntervalThink(1.0)
	end
end

local function Target688()
	local t = math.max(0, GameRules:GetDOTATime(false, false))
	local k = math.floor(t / C.ROSHAN_GROWTH_INTERVAL)
	return C.ROSHAN_BASE.HP + C.ROSHAN_GROWTH.HP * k, C.ROSHAN_BASE.ARMOR + C.ROSHAN_GROWTH.ARMOR * k,
		C.ROSHAN_BASE.DAMAGE + C.ROSHAN_GROWTH.DAMAGE * k
end

function modifier_dota688_roshan:OnIntervalThink()
	local r = self:GetParent()
	if r:IsNull() or not r:IsAlive() then return end
	local hp, armor, damage = Target688()
	if r:GetBaseMaxHealth() ~= hp then
		local pct = r:GetHealth() / math.max(1, r:GetMaxHealth())
		r:SetBaseMaxHealth(hp)
		r:SetMaxHealth(hp)
		r:SetHealth(math.max(1, math.floor(hp * pct + 0.5)))
	end
	-- valorile motorului fara bonusul nostru de acum, apoi bonusul care duce la tinta 6.88
	local engineArmor = r:GetPhysicalArmorValue(false) - self.armor
	local engineDamage = r:GetAverageTrueAttackDamage(nil) - self.damage
	self.armor = armor - engineArmor
	self.damage = damage - engineDamage
end

function modifier_dota688_roshan:GetModifierPhysicalArmorBonus() return self.armor or 0 end
function modifier_dota688_roshan:GetModifierPreAttack_BonusDamage() return self.damage or 0 end
