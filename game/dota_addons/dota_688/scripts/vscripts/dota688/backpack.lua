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

-- Item built-in care are o reimplementare 6.88 (item_dota688_*): in mod normal nu se mai poate obtine (shop-ul si
-- retetele dau versiunea Lua), dar daca ajunge totusi in inventar (combinare, drop) il inlocuim cu versiunea 6.88.
local function lua_version(name)
	if string.sub(name, 1, 5) ~= "item_" or string.find(name, "item_dota688_", 1, true) == 1
		or string.find(name, "item_recipe_", 1, true) == 1 then return nil end
	local custom = "item_dota688_" .. string.sub(name, 6)
	if GetAbilityKeyValuesByName(custom) == nil then return nil end
	return custom
end

local function replace_with_lua(unit, item, custom)
	if unit:IsNull() or item:IsNull() then return end
	for s = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
		if unit:GetItemInSlot(s) == item then
			local purchaser, charges, old = item:GetPurchaser(), item:GetCurrentCharges(), item:GetAbilityName()
			unit:RemoveItem(item)
			local new = CreateItem(custom, purchaser, purchaser)
			if charges > 0 then new:SetCurrentCharges(charges) end
			unit:AddItem(new)
			for t = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
				if unit:GetItemInSlot(t) == new then
					if t ~= s then unit:SwapItems(t, s) end
					break
				end
			end
			print("[dota688] " .. old .. " (built-in) inlocuit cu " .. custom)
			return
		end
	end
end

function M:ItemAddedToInventoryFilter(ev)
	local item = ev.item_entindex_const and EntIndexToHScript(ev.item_entindex_const)
	local unit = ev.inventory_parent_entindex_const and EntIndexToHScript(ev.inventory_parent_entindex_const)
	if item and unit and unit.GetItemInSlot then
		local custom = lua_version(item:GetAbilityName())
		if custom then Dota688Timers:After(0, function() replace_with_lua(unit, item, custom) end) end
	end
	local slot = ev.suggested_slot
	if slot == nil then return true end
	-- cumparaturile vin fara slot sugerat (-1): cu sloturile 1-6 pline motorul le-ar pune in backpack (ascuns de HUD, deci
	-- "itemul dispare" - raportat din joc, 2026-10-17); le tratam ca pe cele cu slot de backpack sugerat
	if slot < 0 and unit and unit.IsRealHero and unit:IsRealHero() and free_slot(unit, DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6) == nil then
		slot = DOTA_ITEM_SLOT_7
	end
	if slot >= DOTA_ITEM_SLOT_7 and slot <= DOTA_ITEM_SLOT_9 then
		-- 6.88: fara backpack. Un item ridicat de pe jos / adus de curier cu inventarul plin ramane unde era (refuzat); un item
		-- cumparat cu inventarul plin merge in stash; daca si stash-ul e plin, cumpararea e refuzata (aurul se intoarce)
		local fromElsewhere = ev.item_parent_entindex_const and ev.inventory_parent_entindex_const
			and ev.item_parent_entindex_const ~= ev.inventory_parent_entindex_const
		if fromElsewhere or not unit or not unit.IsRealHero or not unit:IsRealHero() then return false end
		local s = free_slot(unit, DOTA_STASH_SLOT_1, DOTA_STASH_SLOT_6)
		if s ~= nil then
			ev.suggested_slot = s
			return true
		end
		return false   -- motorul anuleaza cumparatura si da singur aurul inapoi (testat: o rambursare in plus dubla aurul)
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
				if hero and not hero:IsNull() then M:MoveTPScroll(hero); M:EmptyBackpack(hero) end
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

-- plasa de siguranta: un item ajuns totusi in sloturile de backpack (6.88 nu le are, HUD-ul le ascunde) e mutat intr-un slot
-- liber al inventarului sau al stash-ului; daca nu e loc nicaieri, e aruncat pe jos langa erou
function M:EmptyBackpack(hero)
	for s = DOTA_ITEM_SLOT_7, DOTA_ITEM_SLOT_9 do
		local it = hero:GetItemInSlot(s)
		if it then
			local free = free_slot(hero, DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6) or free_slot(hero, DOTA_STASH_SLOT_1, DOTA_STASH_SLOT_6)
			if free ~= nil then
				hero:SwapItems(s, free)
			elseif hero:IsAlive() then
				hero:DropItemAtPositionImmediate(it, hero:GetAbsOrigin() + RandomVector(100))
			end
		end
	end
end

-- TP-ul cu care motorul curent porneste eroii (slotul dedicat): in 6.88 eroii pornesc fara TP
function M:OnHeroFirstSpawn(hero)
	for s = DOTA_ITEM_SLOT_1, DOTA_ITEM_TP_SCROLL do
		local it = hero:GetItemInSlot(s)
		if it and it:GetAbilityName() == "item_tpscroll" then hero:RemoveItem(it) end
	end
end
