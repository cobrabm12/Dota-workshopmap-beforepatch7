-- Rune dupa regulile 6.82-6.88:
--  * doua rune in rau (sus si jos), la fiecare 2 minute, incepand cu 0:00
--  * la 0:00 ambele sunt Bounty (100 aur, 0 XP); apoi una e mereu Bounty, cealalta o runa de putere aleatoare
--  * runele neluate sunt inlocuite la urmatorul spawn
-- Pozitiile vin din harta: entitati "info_target" numite "dota688_rune_top" / "dota688_rune_bot",
-- sau, daca lipsesc, spawner-ele standard Valve (dota_item_rune_spawner_powerup).
--
-- Efectele runelor, ca in 6.88f (valorile in modifiers/modifier_dota688_runes.lua):
--  * runele de putere: la activare motorul aplica modifierii moderni modifier_rune_* (valori 7.x).
--    ModifierGainedFilter ii blocheaza si pune in loc modifierii Lua 6.88; evenimentul dota_rune_activated_server
--    e rezerva (inlocuieste modifier-ul modern daca filtrul nu l-a prins).
--  * Illusion: iluziile create de motor sunt sterse si recreate cu CreateIllusions (35% daune, 200%/300% daune
--    primite, 75 s, fara bounty).
--  * Bounty: aur nesigur si XP doar pentru cel care o ia (7.x da aur sigur intregii echipe -> blocat:
--    gold_bounty = 0 in filtrul motorului, iar GoldFilter refuza aurul de bounty pe care nu il dam noi).
local C = DOTA688
require("dota688/runes_link")
require("modifiers/modifier_dota688_runes")
local R = DOTA688_RUNES
Dota688Runes = Dota688Runes or {}
local M = Dota688Runes

-- modifierul modern -> { modifierul 6.88, durata 6.88 }
M.REPLACE = {
	modifier_rune_doubledamage = { "modifier_dota688_rune_doubledamage", R.DD_DURATION },
	modifier_rune_haste        = { "modifier_dota688_rune_haste", R.HASTE_DURATION },
	modifier_rune_invis        = { "modifier_dota688_rune_invis", R.INVIS_DURATION },
	modifier_rune_regen        = { "modifier_dota688_rune_regen", R.REGEN_DURATION },
	modifier_rune_arcane       = { "modifier_dota688_rune_arcane", R.ARCANE_DURATION },
}
M.RUNE_MODIFIER = {
	[DOTA_RUNE_DOUBLEDAMAGE] = "modifier_rune_doubledamage",
	[DOTA_RUNE_HASTE]        = "modifier_rune_haste",
	[DOTA_RUNE_INVISIBILITY] = "modifier_rune_invis",
	[DOTA_RUNE_REGENERATION] = "modifier_rune_regen",
	[DOTA_RUNE_ARCANE]       = "modifier_rune_arcane",
}

function M:Init(gamemode)
	self.gamemode = gamemode
	self.spots = {}
	self.runes = {}
	self.spawnCount = 0
	self.awarding = false          -- true cat timp dam noi aurul de bounty (GoldFilter il lasa sa treaca)
	self.bountyBatch = nil         -- apelurile filtrului de bounty din acelasi cadru
	self.bountyActivators = {}     -- { pid, time } din dota_rune_activated_server (rune Bounty)
	for _, id in ipairs(self.listeners or {}) do StopListeningToGameEvent(id) end
	self.listeners = {
		ListenToGameEvent("dota_rune_activated_server", Dynamic_Wrap(Dota688Runes, "OnRuneActivated"), self),
		ListenToGameEvent("npc_spawned", Dynamic_Wrap(Dota688Runes, "OnNPCSpawned"), self),
	}
end

function M:FindSpots()
	local spots = {}
	for _, name in ipairs({ "dota688_rune_top", "dota688_rune_bot" }) do
		local e = Entities:FindByName(nil, name)
		if e then table.insert(spots, e:GetAbsOrigin()) end
	end
	if #spots < 2 then
		spots = {}
		local spawners = Entities:FindAllByClassname("dota_item_rune_spawner_powerup")
		for _, s in ipairs(spawners) do table.insert(spots, s:GetAbsOrigin()) end
	end
	if #spots < 2 then
		print("[dota688] AVERTISMENT: nu am gasit 2 puncte de rune pe harta (dota688_rune_top/bot). Runele nu vor aparea.")
	end
	self.spots = spots
end

function M:OnHorn()
	self:FindSpots()
	if #self.spots < 2 then return end
	self:Spawn()
	Dota688Timers:Every(C.RUNE_INTERVAL, function() M:Spawn() end)
end

function M:ClearOld()
	for _, r in ipairs(self.runes) do
		if r and not r:IsNull() then UTIL_Remove(r) end
	end
	self.runes = {}
	-- rune ramase de la alte surse (de siguranta)
	for _, r in ipairs(Entities:FindAllByClassname("dota_item_rune")) do
		if r and not r:IsNull() then UTIL_Remove(r) end
	end
end

function M:Spawn()
	self:ClearOld()
	self.spawnCount = self.spawnCount + 1
	local first = (self.spawnCount == 1)
	local bountyIndex = RandomInt(1, 2)
	for i = 1, 2 do
		local pos = self.spots[i]
		local runeType
		if first or i == bountyIndex then
			runeType = DOTA_RUNE_BOUNTY
		else
			runeType = _G[C.POWER_RUNES[RandomInt(1, #C.POWER_RUNES)]]
		end
		local rune = CreateRune(pos, runeType)
		if rune then table.insert(self.runes, rune) end
	end
end

-- Runele de putere ------------------------------------------------------------

function M:ApplyPower(unit, engineName)
	local r = self.REPLACE[engineName]
	if not r or not unit or unit:IsNull() or not unit:IsAlive() then return end
	unit:AddNewModifier(unit, nil, r[1], { duration = r[2] })
end

-- Filtrul de modifieri (SetModifierGainedFilter, conectat din gamemode.lua): blocheaza modifierii moderni ai
-- runelor (si cei din Bottle) si pune modifierul 6.88 in cadrul urmator (nu adaugam modifieri din interiorul filtrului).
function M:ModifierGainedFilter(ev)
	local name = ev.name_const
	if self.REPLACE[name] then
		local parent = ev.entindex_parent_const and EntIndexToHScript(ev.entindex_parent_const)
		if not parent then return true end
		Dota688Timers:After(0, function() M:ApplyPower(parent, name) end)
		return false
	end
	if name == "modifier_illusion" or name == "modifier_rune_illusion" then
		-- marcam iluziile noi: ReplaceIllusions recunoaste astfel iluziile create de motor pentru runa Illusion
		local parent = ev.entindex_parent_const and EntIndexToHScript(ev.entindex_parent_const)
		if parent then parent.dota688_illusion_time = GameRules:GetGameTime() end
	end
	return true
end

function M:OnNPCSpawned(ev)
	local u = ev.entindex and EntIndexToHScript(ev.entindex)
	if u and u.IsHero and u:IsHero() then u.dota688_spawn_time = GameRules:GetGameTime() end
end

-- dota_rune_activated_server: { PlayerID, rune } (si pentru runele din Bottle)
function M:OnRuneActivated(ev)
	local pid, rune = ev.PlayerID, ev.rune
	local now = GameRules:GetGameTime()
	if rune == DOTA_RUNE_BOUNTY then
		table.insert(self.bountyActivators, { pid = pid, time = now })
		return
	end
	if pid == nil or pid < 0 or not PlayerResource:HasSelectedHero(pid) then return end
	local hero = PlayerResource:GetSelectedHeroEntity(pid)
	if not hero then return end
	if rune == DOTA_RUNE_ILLUSION then
		Dota688Timers:After(0, function() M:ReplaceIllusions(hero, pid, now) end)
		return
	end
	local engineName = self.RUNE_MODIFIER[rune]
	if engineName then
		-- rezerva: daca filtrul de modifieri nu e conectat sau nu a prins modifierul modern
		Dota688Timers:After(0, function()
			if not hero:IsNull() and hero:HasModifier(engineName) then
				hero:RemoveModifierByName(engineName)
				M:ApplyPower(hero, engineName)
			end
		end)
	end
end

-- Runa Illusion ---------------------------------------------------------------

function M:CreateRuneIllusions(hero)
	local keys = {
		outgoing_damage = R.ILLUSION_OUTGOING,
		incoming_damage = hero:IsRangedAttacker() and R.ILLUSION_INCOMING_RANGED or R.ILLUSION_INCOMING_MELEE,
		duration = R.ILLUSION_DURATION,
	}
	if not C.ILLUSION_BOUNTY then
		keys.bounty_base = 0     -- 6.88: iluziile nu dau aur
		keys.bounty_growth = 0
	end
	local list = CreateIllusions(hero, hero, keys, R.ILLUSION_COUNT, 108, false, true)
	for _, il in ipairs(list or {}) do il.dota688_rune_illusion = true end
	return list
end

-- iluzie creata in jurul momentului t0 (activarea runei)? Mai multe semnale, oricare ajunge.
local function IsNewIllusion(u, t0, now)
	local from = t0 - 0.25
	if (u.dota688_spawn_time or -1) >= from or (u.dota688_illusion_time or -1) >= from then return true end
	if u:HasModifier("modifier_rune_illusion") then return true end
	local ct = u.GetCreationTime and u:GetCreationTime()
	return ct ~= nil and ct >= from and ct <= now + 0.05
end

-- sterge iluziile runei create de motor (valori 7.x) si le recreeaza cu valorile 6.88
function M:ReplaceIllusions(hero, pid, t0)
	if hero:IsNull() then return end
	local now = GameRules:GetGameTime()
	local name = hero:GetUnitName()
	local units = FindUnitsInRadius(hero:GetTeamNumber(), hero:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
	local removed = 0
	for _, u in ipairs(units) do
		if u ~= hero and u:IsIllusion() and not u.dota688_rune_illusion and u:GetPlayerOwnerID() == pid
			and u:GetUnitName() == name and IsNewIllusion(u, t0, now) then
			UTIL_Remove(u)
			removed = removed + 1
		end
	end
	if removed == 0 then
		-- nu cream iluzii in plus peste cele (eventual nerecunoscute) ale motorului
		print("[dota688] runa Illusion: iluziile motorului nu au fost gasite; raman cele moderne")
		return
	end
	if hero:IsAlive() then self:CreateRuneIllusions(hero) end
end

-- Runa Bounty -----------------------------------------------------------------

-- 100 aur si 0 XP la 0:00; apoi 50 + 2/min aur si 50 + 5/min XP
function M:BountyValues()
	if self.spawnCount <= 1 then return C.RUNE_INITIAL_BOUNTY_GOLD, 0 end
	local minutes = Dota688GameMinutes()
	return C.RUNE_BOUNTY_GOLD_BASE + C.RUNE_BOUNTY_GOLD_PER_MIN * minutes,
		C.RUNE_BOUNTY_XP_BASE + C.RUNE_BOUNTY_XP_PER_MIN * minutes
end

-- Filtrul motorului (SetBountyRunePickupFilter): motorul nu mai da nimic (nici echipei); platim noi in cadrul
-- urmator, doar jucatorului care a activat runa.
function M:BountyRuneFilter(ev)
	local now = GameRules:GetGameTime()
	local b = self.bountyBatch
	if not b or b.time ~= now then
		b = { time = now, pids = {} }
		self.bountyBatch = b
		Dota688Timers:After(0, function() M:PayBounty(b) end)
	end
	local pid = ev.player_id_const
	if pid ~= nil and pid >= 0 then table.insert(b.pids, pid) end
	ev.gold_bounty = 0
	ev.xp_bounty = 0
	return true
end

-- Cine a luat runa: jucatorul din dota_rune_activated_server din acelasi cadru; altfel primul jucator cu care
-- a fost apelat filtrul (daca motorul apeleaza filtrul pentru fiecare coechipier, primul e cel care a luat-o).
function M:PayBounty(b)
	local now = GameRules:GetGameTime()
	local payees, keep = {}, {}
	for _, a in ipairs(self.bountyActivators) do
		if math.abs(a.time - b.time) < 0.001 then
			table.insert(payees, a.pid)
		elseif now - a.time < 1 then
			table.insert(keep, a)
		end
	end
	self.bountyActivators = keep
	if #payees == 0 and b.pids[1] then
		if #b.pids > 1 then
			print("[dota688] runa Bounty: filtrul apelat pentru " .. #b.pids .. " jucatori fara eveniment de activare; platesc doar jucatorul " .. b.pids[1])
		end
		payees[1] = b.pids[1]
	end
	for _, pid in ipairs(payees) do self:AwardBounty(pid) end
end

function M:AwardBounty(pid)
	if pid == nil or pid < 0 or not PlayerResource:IsValidPlayerID(pid) then return end
	local gold, xp = self:BountyValues()
	local hero = PlayerResource:HasSelectedHero(pid) and PlayerResource:GetSelectedHeroEntity(pid) or nil
	-- Greevil's Greed (Alchemist, 6.88): runele Bounty valoreaza x3/4/5/6
	local greed = hero and hero:FindAbilityByName("dota688_alchemist_goblins_greed")
	if greed and greed:GetLevel() > 0 then gold = gold * (2 + greed:GetLevel()) end
	self.awarding = true
	local ok, err = pcall(function() PlayerResource:ModifyGold(pid, gold, false, DOTA_ModifyGold_BountyRune) end)
	self.awarding = false
	if not ok then print("[dota688] runa Bounty: eroare la aur: " .. tostring(err)) end
	if hero then
		if xp > 0 then hero:AddExperience(xp, DOTA_ModifyXP_Unspecified, false, true) end
		local player = PlayerResource:GetPlayer(pid)
		if player then SendOverheadEventMessage(player, OVERHEAD_ALERT_GOLD, hero, gold, nil) end
	end
end

-- De apelat din Dota688:GoldFilter (inainte de Dota688GoldXP:GoldFilter): aurul de bounty dat de motor
-- (partea echipei din 7.x, sau orice rest daca motorul ignora gold_bounty = 0) e refuzat; trece doar ce dam noi.
function M:GoldFilter(ev)
	if self.awarding then return true end
	local reason = ev.reason_const
	if reason == DOTA_ModifyGold_BountyRune then return false end
	if reason == DOTA_ModifyGold_SharedGold and self.bountyBatch and GameRules:GetGameTime() - self.bountyBatch.time < 0.25 then
		return false
	end
	return true
end
