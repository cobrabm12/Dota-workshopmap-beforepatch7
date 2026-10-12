-- 6.88 nu avea backpack (adaugat in 7.00). Refuzam itemele care ar ajunge in sloturile 7-9.
Dota688Backpack = Dota688Backpack or {}
local M = Dota688Backpack

function M:ItemAddedToInventoryFilter(ev)
	local slot = ev.suggested_slot
	if slot ~= nil and slot >= DOTA_ITEM_SLOT_7 and slot <= DOTA_ITEM_SLOT_9 then
		-- itemul ramane pe jos / in stash in loc sa intre in backpack
		return false
	end
	return true
end
