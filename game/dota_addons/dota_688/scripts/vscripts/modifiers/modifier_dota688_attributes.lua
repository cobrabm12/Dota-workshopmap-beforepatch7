-- Compenseaza diferentele dintre bonusurile per punct de atribut din 6.88 si cele ale motorului curent.
-- (valorile in dota688/constants.lua: C.ATTR vs C.ATTR_NOW)
modifier_dota688_attributes = class({})
require("dota688/constants")   -- si pe client (proprietatile modifier-ului se evalueaza si acolo)
local C = DOTA688

function modifier_dota688_attributes:IsHidden() return true end
function modifier_dota688_attributes:IsPurgable() return false end
function modifier_dota688_attributes:IsPermanent() return true end
function modifier_dota688_attributes:RemoveOnDeath() return false end
function modifier_dota688_attributes:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_dota688_attributes:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_EXTRA_MANA_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
	}
end

-- Daca motorul ignora StatusHealth/StatusMana din npc_heroes_custom.txt (baza moderna: 120 HP / 75 mana), compensam diferenta.
function modifier_dota688_attributes:OnCreated()
	if not IsServer() then return end
	local p = self:GetParent()
	if not p or not p.GetStrength then return end
	local flags = 0
	local expectHpModern = C.ATTR_NOW.BASE_HP_ENGINE + p:GetStrength() * C.ATTR_NOW.HP_PER_STR
	if math.abs(p:GetMaxHealth() - expectHpModern) < 2 then flags = flags + 1 end
	local expectManaModern = C.ATTR_NOW.BASE_MANA_ENGINE + p:GetIntellect(true) * C.ATTR_NOW.MANA_PER_INT
	if math.abs(p:GetMaxMana() - expectManaModern) < 2 then flags = flags + 2 end
	self.flags = flags
	self:SetStackCount(flags)
	self:StartIntervalThink(0.25)
	if flags > 0 then print("[dota688] " .. p:GetUnitName() .. ": StatusHealth/StatusMana din KV ignorate (flags=" .. flags .. "), compensez in Lua") end
end

-- Iteme cu regenerare de mana procentuala in 6.88 (% din regenerarea de baza 0.01 + 0.04 x INT). In motorul curent cheia
-- lor e o valoare fixa (6.88 scria 50..250 -> +50..250 mana/s), deci e pusa pe 0 in tools/manual_overrides.json si
-- procentul il dam aici. Suma procentelor (calculata pe server) ajunge pe client in stack count: flags + 4 x procent.
function modifier_dota688_attributes:OnIntervalThink()
	local p = self:GetParent()
	local pct = 0
	for slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
		local it = p:GetItemInSlot(slot)
		if it then pct = pct + (C.MANA_REGEN_PCT_ITEMS[it:GetAbilityName()] or 0) end
	end
	local stack = (self.flags or 0) + 4 * pct
	if stack ~= self:GetStackCount() then self:SetStackCount(stack) end
end

local function Stats(self)
	local p = self:GetParent()
	if not p or p:IsNull() or not p.GetStrength then return 0, 0, 0 end
	return p:GetStrength(), p:GetAgility(), p:GetIntellect(true)
end

function modifier_dota688_attributes:GetModifierExtraHealthBonus()
	local str = Stats(self)
	local base = (self:GetStackCount() % 4 % 2 == 1) and (C.ATTR.BASE_HP - C.ATTR_NOW.BASE_HP_ENGINE) or 0
	return math.floor(str * (C.ATTR.HP_PER_STR - C.ATTR_NOW.HP_PER_STR)) + base
end

function modifier_dota688_attributes:GetModifierExtraManaBonus()
	local _, _, int = Stats(self)
	local base = (self:GetStackCount() % 4 >= 2) and (C.ATTR.BASE_MANA - C.ATTR_NOW.BASE_MANA_ENGINE) or 0
	return math.floor(int * (C.ATTR.MANA_PER_INT - C.ATTR_NOW.MANA_PER_INT)) + base
end

function modifier_dota688_attributes:GetModifierConstantHealthRegen()
	local str = Stats(self)
	return str * (C.ATTR.HP_REGEN_PER_STR - C.ATTR_NOW.HP_REGEN_PER_STR)
end

function modifier_dota688_attributes:GetModifierConstantManaRegen()
	local _, _, int = Stats(self)
	local pct = math.floor(self:GetStackCount() / 4)
	return int * (C.ATTR.MANA_REGEN_PER_INT - C.ATTR_NOW.MANA_REGEN_PER_INT) + (0.01 + 0.04 * int) * pct / 100
end

function modifier_dota688_attributes:GetModifierPhysicalArmorBonus()
	local _, agi = Stats(self)
	return agi * (C.ATTR.ARMOR_PER_AGI - C.ATTR_NOW.ARMOR_PER_AGI)
end

function modifier_dota688_attributes:GetModifierAttackSpeedBonus_Constant()
	local _, agi = Stats(self)
	return agi * (C.ATTR.AS_PER_AGI - C.ATTR_NOW.AS_PER_AGI)
end

function modifier_dota688_attributes:GetModifierSpellAmplify_Percentage()
	local _, _, int = Stats(self)
	return int * (C.ATTR.SPELL_AMP_PER_INT - C.ATTR_NOW.SPELL_AMP_PER_INT)
end

-- Motorul curent aduna 0.1% rezistenta la magie pe punct de INT la baza (Techies 22 INT: 27.2% in loc de 25%).
-- Bonusurile de rezistenta se combina multiplicativ, deci calculam bonusul negativ exact care readuce baza 6.88.
function modifier_dota688_attributes:GetModifierMagicalResistanceBonus()
	local _, _, int = Stats(self)
	local extra = int * (C.ATTR_NOW.MAGIC_RES_PER_INT - C.ATTR.MAGIC_RES_PER_INT)
	if extra <= 0 then return 0 end
	local base = C.ATTR.BASE_MAGIC_RES
	return 100 * (1 - (1 - base / 100) / (1 - (base + extra) / 100))
end
