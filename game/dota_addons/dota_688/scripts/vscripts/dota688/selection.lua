-- Selectia jucatorilor (trimisa de HUD, hud_688.js): cu mai multe Remote Mines selectate, clientul trimite ordinul de
-- detonare doar pentru unitatea principala (testat: units = 1 mina). In 6.88 se detonau toate minele selectate.
Dota688Selection = Dota688Selection or {}
local M = Dota688Selection
M.byPlayer = M.byPlayer or {}

local MULTI_CAST = { dota688_techies_remote_mine_detonate = true }

function M:Init()
	CustomGameEventManager:RegisterListener("dota688_selection", function(_, ev) M:OnSelection(ev) end)
end

function M:OnSelection(ev)
	local pid = ev.PlayerID
	if pid == nil then return end
	local list = {}
	for _, idx in pairs(ev.units or {}) do
		local n = tonumber(idx)
		if n then list[#list + 1] = n end
	end
	self.byPlayer[pid] = list
end

-- ordinul de cast al unei unitati selectate -> aceeasi abilitate pe celelalte unitati selectate ale jucatorului
function M:OrderFilter(ev)
	if ev.order_type ~= DOTA_UNIT_ORDER_CAST_NO_TARGET or not ev.entindex_ability then return end
	local ability = EntIndexToHScript(ev.entindex_ability)
	if not ability or not MULTI_CAST[ability:GetAbilityName()] then return end
	local pid = ev.issuer_player_id_const
	local caster = ability:GetCaster()
	for _, idx in ipairs(self.byPlayer[pid] or {}) do
		local u = EntIndexToHScript(idx)
		if u and not u:IsNull() and u ~= caster and u:IsAlive() and u:GetPlayerOwnerID() == pid then
			local a = u:FindAbilityByName(ability:GetAbilityName())
			if a and a:IsActivated() and a:IsFullyCastable() then
				u:CastAbilityNoTarget(a, pid)
			end
		end
	end
end
