-- Compenseaza diferentele dintre bonusurile per punct de atribut din 6.88 si cele ale motorului curent.
-- (valorile in dota688/constants.lua: C.ATTR vs C.ATTR_NOW)
modifier_dota688_attributes = class({})
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
	}
end

local function Stats(self)
	local p = self:GetParent()
	if not p or p:IsNull() or not p.GetStrength then return 0, 0, 0 end
	return p:GetStrength(), p:GetAgility(), p:GetIntellect(true)
end

function modifier_dota688_attributes:GetModifierExtraHealthBonus()
	local str = Stats(self)
	return math.floor(str * (C.ATTR.HP_PER_STR - C.ATTR_NOW.HP_PER_STR))
end

function modifier_dota688_attributes:GetModifierExtraManaBonus()
	local _, _, int = Stats(self)
	return math.floor(int * (C.ATTR.MANA_PER_INT - C.ATTR_NOW.MANA_PER_INT))
end

function modifier_dota688_attributes:GetModifierConstantHealthRegen()
	local str = Stats(self)
	return str * (C.ATTR.HP_REGEN_PER_STR - C.ATTR_NOW.HP_REGEN_PER_STR)
end

function modifier_dota688_attributes:GetModifierConstantManaRegen()
	local _, _, int = Stats(self)
	return int * (C.ATTR.MANA_REGEN_PER_INT - C.ATTR_NOW.MANA_REGEN_PER_INT)
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
