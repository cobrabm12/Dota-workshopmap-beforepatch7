-- Fantana 6.88: +14 mana pe secunda (constant) peste cele 4 % ale motorului. SetFountainConstantManaRegen nu mai are
-- efect in motorul curent (masurat: doar 4 % din mana maxima + regenerarea proprie), deci partea constanta o da aura
-- asta, pusa pe fiecare fantana. Efectul conteaza doar cat unitatea are si aura motorului (modifier_fountain_aura_buff),
-- ca zona sa fie exact cea a fantanii; raza auri noastre e doar mai mare, ca sa o acopere.
local RADIUS = 2000
local EFFECT = "modifier_dota688_fountain_effect"
local ENGINE_BUFF = "modifier_fountain_aura_buff"

-- Pe fantana -------------------------------------------------------------------------------------------------------
modifier_dota688_fountain = class({})

function modifier_dota688_fountain:IsHidden() return true end
function modifier_dota688_fountain:IsPurgable() return false end
function modifier_dota688_fountain:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_dota688_fountain:IsAura() return true end
function modifier_dota688_fountain:GetAuraRadius() return RADIUS end
function modifier_dota688_fountain:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_fountain:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + (DOTA_UNIT_TARGET_COURIER or 0) end
function modifier_dota688_fountain:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_dota688_fountain:GetModifierAura() return EFFECT end
function modifier_dota688_fountain:GetAuraDuration() return 0 end

-- Pe unitate -------------------------------------------------------------------------------------------------------
-- stack count = mana constanta (pusa pe server din constants.lua, ajunge si pe client pentru afisaj)
modifier_dota688_fountain_effect = class({})

function modifier_dota688_fountain_effect:IsHidden() return true end
function modifier_dota688_fountain_effect:IsPurgable() return false end
function modifier_dota688_fountain_effect:IsDebuff() return false end

function modifier_dota688_fountain_effect:OnCreated()
	if not IsServer() then return end
	self:SetStackCount(DOTA688.FOUNTAIN_MANA_REGEN_CONST)
end

function modifier_dota688_fountain_effect:DeclareFunctions()
	return { MODIFIER_PROPERTY_MANA_REGEN_CONSTANT }
end

function modifier_dota688_fountain_effect:GetModifierConstantManaRegen()
	if not self:GetParent():HasModifier(ENGINE_BUFF) then return 0 end
	return self:GetStackCount()
end
