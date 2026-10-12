-- Crestere Roshan ca in 6.88 (+700 HP / +10 dmg / +0.7 armura la fiecare 4 min), compensand cresterea moderna pe minut.
modifier_dota688_roshan = class({})
require("dota688/constants")   -- si pe client (proprietatile modifier-ului se evalueaza si acolo)
local C = DOTA688

function modifier_dota688_roshan:IsHidden() return true end
function modifier_dota688_roshan:IsPurgable() return false end
function modifier_dota688_roshan:RemoveOnDeath() return false end
function modifier_dota688_roshan:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_dota688_roshan:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
	}
end

function modifier_dota688_roshan:OnCreated()
	self:Recalc()
	if IsServer() then self:StartIntervalThink(5.0) end
end

function modifier_dota688_roshan:OnIntervalThink()
	self:Recalc()
end

function modifier_dota688_roshan:Recalc()
	local t = math.max(0, GameRules:GetDOTATime(false, false))
	local old = math.floor(t / C.ROSHAN_GROWTH_INTERVAL)
	local now = math.floor(t / C.ROSHAN_GROWTH_NOW_INTERVAL)
	self.hp = C.ROSHAN_GROWTH.HP * old - C.ROSHAN_GROWTH_NOW.HP * now
	self.armor = C.ROSHAN_GROWTH.ARMOR * old - C.ROSHAN_GROWTH_NOW.ARMOR * now
	self.damage = C.ROSHAN_GROWTH.DAMAGE * old - C.ROSHAN_GROWTH_NOW.DAMAGE * now
end

function modifier_dota688_roshan:GetModifierExtraHealthBonus() return self.hp or 0 end
function modifier_dota688_roshan:GetModifierPhysicalArmorBonus() return self.armor or 0 end
function modifier_dota688_roshan:GetModifierPreAttack_BonusDamage() return self.damage or 0 end
