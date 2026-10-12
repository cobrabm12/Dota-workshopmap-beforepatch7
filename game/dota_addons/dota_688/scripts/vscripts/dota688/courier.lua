-- Curierul 6.88: se cumpara (Animal Courier 100, apoi Flying Courier 150) si este al echipei, comun tuturor jucatorilor.
-- Motorul curent nu mai creeaza curierul din item (curierii sunt gratuiti din 7.23: item_courier folosit nu face
-- nimic, testat). Un curier creat pentru un jucator (PlayerController:SpawnCourierAtPosition) creste odata cu
-- eroul acelui jucator (nivelul curierului = nivelul eroului; de la nivelul 4 zboara), deci cream curierul fara
-- jucator proprietar: ramane la nivelul 1, motorul il numara ca al echipei si livreaza iteme jucatorului care ii da
-- ordinul (testat: take_stash_and_transfer_items).
Dota688Courier = Dota688Courier or {}
local M = Dota688Courier

M.FLYING_LEVEL = 4                       -- nivelul de la care curierul modern zboara (testat)
M.FLYING = { HP = 150, ARMOR = 10, VISION = 200 }   -- reference/6.88f/npc_units.txt: npc_dota_flying_courier
M.MODERN_ABILITIES = { "courier_autodeliver" }      -- 7.x
-- puse de motor pe orice curier (testat: de la creare, nu revin dupa ce le scoatem): imunitate la vraji si fara
-- coliziune (in 6.88 curierul putea fi omorat cu vraji si bloca unitati) si +10 viteza pe nivel peste 350
M.MODERN_MODIFIERS = { "modifier_magic_immune", "modifier_phased", "modifier_courier_passive_bonus" }
-- 6.88: curierul ucis revine (cu itemele) dupa 120 s, Flying Courier dupa 180 s
-- (reference/6.88f/dota_english.txt, dota_tip_beginner_46); vezi modifiers/modifier_dota688_courier_dead.lua
M.RESPAWN_GROUND = 120
M.RESPAWN_FLYING = 180
M.DEAD_MODIFIER = "modifier_dota688_courier_dead"
M.ABILITIES_688 = { "courier_return_to_base", "courier_go_to_secretshop", "courier_return_stash_items",
	"courier_take_stash_items", "courier_transfer_items", "courier_take_stash_and_transfer_items" }

local function team_players(team)
	local list = {}
	for pid = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PlayerResource:IsValidPlayerID(pid) and PlayerResource:GetTeam(pid) == team then list[#list + 1] = pid end
	end
	return list
end

function M:TeamCouriers(team)
	local list = {}
	for _, c in ipairs(Entities:FindAllByClassname("npc_dota_courier")) do
		if not c:IsNull() and c:IsAlive() and c:GetTeamNumber() == team and not c:HasModifier(self.DEAD_MODIFIER) then
			list[#list + 1] = c
		end
	end
	return list
end

function M:StripModern(c)
	for _, name in ipairs(self.MODERN_MODIFIERS) do
		if c:HasModifier(name) then c:RemoveModifierByName(name) end
	end
	if not c:HasModifier("modifier_dota688_courier") then c:AddNewModifier(c, nil, "modifier_dota688_courier", {}) end
end

-- curierul reinviat (dupa moarte) primeste din nou modifier-ele motorului; daca motorul l-a reinviat inainte de
-- timpul 6.88, sta ascuns pana atunci
function M:OnNPCSpawned(unit)
	if not (unit.IsCourier and unit:IsCourier()) then return end
	Dota688Timers:After(0, function()
		if unit:IsNull() or not unit:IsAlive() then return end
		self:StripModern(unit)
		local left = unit.dota688_respawn_at and (unit.dota688_respawn_at - GameRules:GetGameTime()) or 0
		if left > 0.1 then unit:AddNewModifier(unit, nil, self.DEAD_MODIFIER, { duration = left }) end
	end)
end

-- item_dota688_courier: "Deploy Courier"
function M:Deploy(item)
	local caster = item:GetCaster()
	local team = caster:GetTeamNumber()
	local c = CreateUnitByName("npc_dota_courier", caster:GetAbsOrigin() + caster:GetForwardVector() * 100, true, nil, nil, team)
	if not c then return end
	if caster:IsRealHero() then c:SetOwner(caster) end
	for _, pid in ipairs(team_players(team)) do c:SetControllableByPlayer(pid, true) end
	for _, name in ipairs(self.MODERN_ABILITIES) do
		local a = c:FindAbilityByName(name)
		if a then c:RemoveAbilityByHandle(a) end
	end
	for _, name in ipairs(self.ABILITIES_688) do
		local a = c:FindAbilityByName(name)
		if a then
			if a:GetLevel() < 1 then a:SetLevel(1) end
			a:SetHidden(false)
		end
	end
	local burst = c:FindAbilityByName("courier_burst")
	if burst then burst:SetLevel(0) end   -- doar curierul zburator are burst
	self:StripModern(c)
	caster:RemoveItem(item)
end

-- Proprietarul curierului echipei = jucatorul care ii da ultima comanda. Fara proprietar, clientul nu vede itemele
-- cumparate prin curier (ex. la secret shop) ca fiind ale jucatorului, iar quickbuy-ul ("mark for buy") le cumpara
-- in bucla (testat: 6 Point Booster). SetOwner nu leaga nivelul curierului de erou (testat: ramane la nivelul 1).
-- Intoarce false cand ordinul a fost preluat de comenzile 6.88 ale curierului (nu mai ajunge la motor).
function M:OrderFilter(ev)
	if self.issuing then return true end
	local pid = ev.issuer_player_id_const
	if pid == nil or pid < 0 then return true end
	local hero = PlayerResource:GetSelectedHeroEntity(pid)
	if not hero then return true end
	local ability = ev.entindex_ability and ev.entindex_ability > 0 and EntIndexToHScript(ev.entindex_ability) or nil
	local command = ability and not ability:IsNull() and ability.GetAbilityName and self.COMMANDS[ability:GetAbilityName()] and ability:GetAbilityName()
	local handled = false
	for _, idx in pairs(ev.units or {}) do
		local u = EntIndexToHScript(idx)
		if u and not u:IsNull() and u.IsCourier and u:IsCourier() and u:GetTeamNumber() == hero:GetTeamNumber() then
			if u:GetOwner() ~= hero then u:SetOwner(hero) end
			-- butonul "Deliver Items" trimite take_stash_and_transfer ca CAST_TARGET (tinta = eroul), restul fara tinta
			if command and (ev.order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET or ev.order_type == DOTA_UNIT_ORDER_CAST_TARGET) then
				self:Command(u, command, pid)
				handled = true
			elseif ev.order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET and ability and not ability:IsNull() and ability.GetAbilityName
				and ability:GetAbilityName() == "courier_burst" then
				self:Burst(u)
				handled = true
			else
				u.dota688_task = nil   -- alt ordin (miscare, stop, cumparare...) anuleaza comanda in curs
			end
		end
	end
	return not handled
end

-- item_dota688_flying_courier (pasiv in 6.88): transforma Animal Courier-ul echipei in Flying Courier
function M:TryUpgrade(item)
	if not item or item:IsNull() then return true end
	local caster = item:GetCaster()
	for _, c in ipairs(self:TeamCouriers(caster:GetTeamNumber())) do
		if not c:HasFlyMovementCapability() then
			for _ = 1, self.FLYING_LEVEL do
				if c:HasFlyMovementCapability() then break end
				c:UpgradeCourier(c:GetLevel() + 1)
			end
			local pct = c:GetHealthPercent() / 100
			c:SetBaseMaxHealth(self.FLYING.HP)
			c:SetMaxHealth(self.FLYING.HP)
			c:SetHealth(math.max(1, self.FLYING.HP * pct))
			c:SetPhysicalArmorBaseValue(self.FLYING.ARMOR)
			c:SetDayTimeVisionRange(self.FLYING.VISION)
			c:SetNightTimeVisionRange(self.FLYING.VISION)
			local burst = c:FindAbilityByName("courier_burst")
			if burst then burst:SetLevel(1); burst:SetHidden(false) end
			self:StripModern(c)
			-- itemul se scoate dupa think-ul modifier-ului lui
			Dota688Timers:After(0, function() if not item:IsNull() then caster:RemoveItem(item) end end)
			return true
		end
	end
	return false   -- "Requires a deployed Animal Courier": itemul ramane pana exista un curier de sol
end

-- Comenzile curierului 6.88. Abilitatile moderne ale curierului isi iau "baza" din spawn-ul curierului personal al
-- jucatorului (7.23+): pentru curierul echipei "Return to Base" il trimitea in centrul hartii (0, 0), iar "Go to Secret
-- Shop" la secret shop-ul celeilalte echipe (testat). Ordinele catre ele (butoanele din HUD, hotkey-urile) sunt
-- interceptate in OrderFilter si executate aici:
--   return_to_base         -> fantana echipei
--   go_to_secretshop       -> secret shop-ul echipei ("Sends the courier to your team's secret shop")
--   take_stash_items       -> la fantana, ia itemele din stash-ul jucatorului care a dat ordinul
--   return_stash_items     -> la fantana, pune in stash itemele acelui jucator
--   transfer_items         -> merge la eroul jucatorului si ii da itemele lui (raman pe curier daca nu e loc)
--   take_stash_and_transfer_items -> take_stash_items, apoi transfer_items
-- Dupa livrare curierul ramane pe loc (6.88; intoarcerea automata la baza e din 7.x).
M.COMMANDS = {
	courier_return_to_base = { "base" },
	courier_go_to_secretshop = { "secret" },
	courier_take_stash_items = { "take" },
	courier_return_stash_items = { "return" },
	courier_transfer_items = { "deliver" },
	courier_take_stash_and_transfer_items = { "take", "deliver" },
}
M.ARRIVE = 250          -- distanta la care se considera ajuns la fantana / secret shop
M.DELIVER_RANGE = 225   -- distanta de la care curierul da itemele eroului

local function team_point(team, cls, shopType)
	local fountain
	for _, f in ipairs(Entities:FindAllByClassname("ent_dota_fountain")) do
		if f:GetTeamNumber() == team then fountain = f:GetAbsOrigin() end
	end
	if cls == "fountain" then return fountain end
	-- secret shop-ul echipei = cel mai apropiat de fantana ei
	local best, bestd
	for _, s in ipairs(Entities:FindAllByClassname("ent_dota_shop")) do
		if s.GetShopType and s:GetShopType() == shopType then
			local d = fountain and (s:GetAbsOrigin() - fountain):Length2D() or 0
			if not bestd or d < bestd then best, bestd = s:GetAbsOrigin(), d end
		end
	end
	return best
end

function M:OnKilled(c)
	if not (c.IsCourier and c:IsCourier()) then return end
	c.dota688_task = nil
	local delay = c:HasFlyMovementCapability() and self.RESPAWN_FLYING or self.RESPAWN_GROUND
	local at = GameRules:GetGameTime() + delay
	c.dota688_respawn_at = at
	Dota688Timers:After(delay, function()
		if c:IsNull() or c.dota688_respawn_at ~= at then return end
		c.dota688_respawn_at = nil
		if c:IsAlive() then
			c:RemoveModifierByName(self.DEAD_MODIFIER)
		else
			-- formula motorului creste cu nivelul eroului si poate depasi timpul 6.88: il reinviem noi, in fantana
			c:RespawnUnit()
			local f = team_point(c:GetTeamNumber(), "fountain")
			if f then FindClearSpaceForUnit(c, f, true) end
		end
	end)
end

local function free_slot(unit, first, last)
	for s = first, last do
		if unit:GetItemInSlot(s) == nil then return s end
	end
	return nil
end

-- ordinele date curierului din Lua trec si ele prin OrderFilter: nu trebuie sa anuleze comanda in curs
local function own_order(fn)
	M.issuing = true
	local ok, err = pcall(fn)
	M.issuing = false
	if not ok then print("[dota688] curier: " .. tostring(err)) end
end

local function move_item(from, item, to, first, last)
	local s = free_slot(to, first, last)
	if not s then return false end
	from:TakeItem(item)
	to:AddItem(item)
	-- AddItem pune itemul in primul slot liber (0-8); il mutam in intervalul cerut (ex. stash)
	for t = DOTA_ITEM_SLOT_1, DOTA_STASH_SLOT_6 do
		if to:GetItemInSlot(t) == item then
			if t < first or t > last then to:SwapItems(t, s) end
			break
		end
	end
	return true
end

function M:Command(c, name, pid)
	local hero = PlayerResource:GetSelectedHeroEntity(pid)
	if not hero then return end
	local steps = {}
	for _, s in ipairs(self.COMMANDS[name]) do steps[#steps + 1] = s end
	c.dota688_task = { steps = steps, pid = pid, hero = hero, issued = 0 }
	own_order(function() c:Stop() end)
	self:StartThink()
end

-- Butoanele curierului din panoul shop-ului (livrare, burst, meniul de click dreapta: fantana / secret shop) si
-- hotkey-urile lor cauta curierul personal al jucatorului (7.23+, creat cu SpawnCourierAtPosition): pentru curierul
-- echipei clientul nu trimite niciun ordin (testat: "Deliver Items" si F3 nu faceau nimic). hud_688.js le trimite
-- aici (evenimentul dota688_courier_command) si comanda ajunge la curierul echipei, de la orice jucator al ei.
function M:Init()
	CustomGameEventManager:RegisterListener("dota688_courier_command", function(_, ev) M:OnHudCommand(ev) end)
end

-- curierul echipei e al tuturor jucatorilor ei: si cei care primesc erou dupa ce a fost cumparat (pick tarziu,
-- reconectare) il pot controla
function M:GrantControl(hero)
	local pid = hero:GetPlayerOwnerID()
	if pid == nil or pid < 0 then return end
	for _, c in ipairs(self:TeamCouriers(hero:GetTeamNumber())) do c:SetControllableByPlayer(pid, true) end
end

function M:OnHudCommand(ev)
	local pid, name = ev.PlayerID, ev.cmd
	if pid == nil or type(name) ~= "string" then return end
	local hero = PlayerResource:GetSelectedHeroEntity(pid)
	if not hero then return end
	local c = self:TeamCouriers(hero:GetTeamNumber())[1]
	if not c then return end
	if c:GetOwner() ~= hero then c:SetOwner(hero) end
	c:SetControllableByPlayer(pid, true)
	if self.COMMANDS[name] then
		self:Command(c, name, pid)
	elseif name == "courier_burst" then
		self:Burst(c)
	end
end

-- Speed Burst 6.88 (vezi modifiers/modifier_dota688_courier_burst.lua): cooldown-ul ramane pe abilitatea motorului,
-- ca butonul si bara de abilitati sa-l afiseze
function M:Burst(c)
	local burst = c:FindAbilityByName("courier_burst")
	if not burst or burst:GetLevel() < 1 or not burst:IsCooldownReady() then return end
	burst:StartCooldown(burst:GetCooldown(burst:GetLevel()))
	c:AddNewModifier(c, burst, "modifier_dota688_courier_burst", { duration = burst:GetSpecialValueFor("duration") })
end

function M:StartThink()
	if self.thinking then return end
	self.thinking = true
	Dota688Timers:Every(0.2, function()
		local any = false
		for _, c in ipairs(Entities:FindAllByClassname("npc_dota_courier")) do
			if not c:IsNull() and c.dota688_task then
				if c:IsAlive() then self:Step(c, c.dota688_task); any = true else c.dota688_task = nil end
			end
		end
		if not any then self.thinking = false; return false end
	end)
end

function M:GoTo(c, task, pos)
	if (c:GetAbsOrigin() - pos):Length2D() <= self.ARRIVE then return true end
	local now = GameRules:GetGameTime()
	if now - task.issued > 1.0 or not c:IsMoving() then
		own_order(function() c:MoveToPosition(pos) end)
		task.issued = now
	end
	return false
end

function M:Step(c, task)
	local step = task.steps[1]
	if not step then c.dota688_task = nil; return end
	local team, hero = c:GetTeamNumber(), task.hero
	if step == "base" or step == "take" or step == "return" then
		local f = team_point(team, "fountain")
		if not f or not self:GoTo(c, task, f) then return end
		if step == "take" and hero and not hero:IsNull() then
			for s = DOTA_STASH_SLOT_1, DOTA_STASH_SLOT_6 do
				local it = hero:GetItemInSlot(s)
				if it and not move_item(hero, it, c, DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6) then break end
			end
		elseif step == "return" and hero and not hero:IsNull() then
			for s = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
				local it = c:GetItemInSlot(s)
				if it and it:GetPurchaser() == hero then move_item(c, it, hero, DOTA_STASH_SLOT_1, DOTA_STASH_SLOT_6) end
			end
		end
		table.remove(task.steps, 1); task.issued = 0
	elseif step == "secret" then
		local p = team_point(team, "shop", DOTA_SHOP_SECRET)
		if not p or self:GoTo(c, task, p) then table.remove(task.steps, 1); task.issued = 0 end
	elseif step == "deliver" then
		if not hero or hero:IsNull() or not hero:IsAlive() then own_order(function() c:Stop() end); c.dota688_task = nil; return end
		if (c:GetAbsOrigin() - hero:GetAbsOrigin()):Length2D() > self.DELIVER_RANGE then
			local now = GameRules:GetGameTime()
			if now - task.issued > 0.5 then own_order(function() c:MoveToNPC(hero) end); task.issued = now end
			return
		end
		for s = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
			local it = c:GetItemInSlot(s)
			if it and it:GetPurchaser() == hero then move_item(c, it, hero, DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6) end
		end
		own_order(function() c:Stop() end)
		table.remove(task.steps, 1)
	end
end
