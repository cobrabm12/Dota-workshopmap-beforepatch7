-- Inventarul 6.88: 6 sloturi + stash. Fara backpack (7.00), fara slotul dedicat de TP (7.07) si fara sloturile
-- de iteme neutre (7.23).
Dota688Backpack = Dota688Backpack or {}
local M = Dota688Backpack

local function free_slot(unit, first, last)
	for s = first, last do
		if unit:GetItemInSlot(s) == nil then return s end
	end
	return nil
end

function M:ItemAddedToInventoryFilter(ev)
	local slot = ev.suggested_slot
	if slot == nil then return true end
	if slot >= DOTA_ITEM_SLOT_7 and slot <= DOTA_ITEM_SLOT_9 then
		-- itemul ramane pe jos / in stash in loc sa intre in backpack
		return false
	end
	if slot == DOTA_ITEM_NEUTRAL_ACTIVE_SLOT or slot == DOTA_ITEM_NEUTRAL_PASSIVE_SLOT then
		return false
	end
	return true
end

-- Slotul dedicat de TP: motorul pune acolo orice TP (cumparat, adus de curier, AddItemByName), fara sa treaca mereu
-- prin filtru (testat), iar HUD-ul il ascunde. Il mutam intr-un slot normal (apoi stash), adunat cu TP-urile existente.
function M:Init()
	Dota688Timers:Every(0.2, function()
		for pid = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
			if PlayerResource:IsValidPlayerID(pid) then
				local hero = PlayerResource:GetSelectedHeroEntity(pid)
				if hero and not hero:IsNull() then M:MoveTPScroll(hero) end
			end
		end
	end)
end

function M:MoveTPScroll(hero)
	local tp = hero:GetItemInSlot(DOTA_ITEM_TP_SCROLL)
	if tp == nil then return end
	for s = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
		local it = hero:GetItemInSlot(s)
		if it and it:GetAbilityName() == tp:GetAbilityName() and (s <= DOTA_ITEM_SLOT_6 or s >= DOTA_STASH_SLOT_1) then
			it:SetCurrentCharges(it:GetCurrentCharges() + tp:GetCurrentCharges())
			hero:RemoveItem(tp)
			return
		end
	end
	local s = free_slot(hero, DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6) or free_slot(hero, DOTA_STASH_SLOT_1, DOTA_STASH_SLOT_6)
	if s ~= nil then hero:SwapItems(DOTA_ITEM_TP_SCROLL, s) end
end

-- TP-ul cu care motorul curent porneste eroii (slotul dedicat): in 6.88 eroii pornesc fara TP
function M:OnHeroFirstSpawn(hero)
	for s = DOTA_ITEM_SLOT_1, DOTA_ITEM_TP_SCROLL do
		local it = hero:GetItemInSlot(s)
		if it and it:GetAbilityName() == "item_tpscroll" then hero:RemoveItem(it) end
	end
end
