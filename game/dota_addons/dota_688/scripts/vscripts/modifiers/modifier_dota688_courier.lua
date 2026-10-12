-- Pasivul curierului 6.88 (pus de Dota688Courier la deploy si dupa respawn). Aura moderna a fantanii da curierilor
-- 550 viteza (testat; eroilor nimic), in 6.88 nu exista: in fantana curierul ramane la viteza lui (350), in afara de
-- Speed Burst (modifier_dota688_courier_burst; IGNORE_MOVESPEED_LIMIT nu trece peste limita asta, testat).
local ENGINE_FOUNTAIN_BUFF = "modifier_fountain_aura_buff"
local BURST = "modifier_dota688_courier_burst"

modifier_dota688_courier = class({})

function modifier_dota688_courier:IsHidden() return true end
function modifier_dota688_courier:IsPurgable() return false end
function modifier_dota688_courier:RemoveOnDeath() return false end
function modifier_dota688_courier:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end

function modifier_dota688_courier:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_LIMIT }
end

function modifier_dota688_courier:GetModifierMoveSpeed_Limit()
	local parent = self:GetParent()
	if not parent:HasModifier(ENGINE_FOUNTAIN_BUFF) or parent:HasModifier(BURST) then return 5000 end   -- fara efect
	return parent:GetBaseMoveSpeed()
end
