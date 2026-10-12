-- Curierul "inca mort" (6.88: revine dupa 120 s, Flying Courier dupa 180 s, cu itemele). Motorul il reinvie dupa
-- formula 7.x (testat: 50-66 s) si nu poate fi amanat (SetUnitCanRespawn si MODIFIER_PROPERTY_RESPAWNTIME nu au efect
-- la curieri), deci pana la timpul 6.88 curierul reinviat sta ascuns in fantana, fara sa poata fi folosit sau lovit.
-- Pus si scos de Dota688Courier (dota688/courier.lua).
modifier_dota688_courier_dead = class({})

function modifier_dota688_courier_dead:IsHidden() return true end
function modifier_dota688_courier_dead:IsPurgable() return false end
function modifier_dota688_courier_dead:RemoveOnDeath() return true end
function modifier_dota688_courier_dead:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_dota688_courier_dead:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_UNTARGETABLE] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_STUNNED] = true,
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
	}
end

function modifier_dota688_courier_dead:OnCreated()
	if not IsServer() then return end
	self:GetParent():AddNoDraw()
end

function modifier_dota688_courier_dead:OnDestroy()
	if not IsServer() then return end
	local c = self:GetParent()
	if c:IsNull() then return end
	c:RemoveNoDraw()
	c:SetHealth(c:GetMaxHealth())
end
