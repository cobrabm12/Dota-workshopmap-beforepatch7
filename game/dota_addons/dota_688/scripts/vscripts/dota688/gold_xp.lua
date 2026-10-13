-- Aur si experienta pentru uciderea eroilor, dupa formulele 6.88.
local C = DOTA688
Dota688GoldXP = Dota688GoldXP or {}
LinkLuaModifier("modifier_dota688_illusion_bounty", "modifiers/modifier_dota688_illusion_bounty", LUA_MODIFIER_MOTION_NONE)
local M = Dota688GoldXP

function M:Init(gamemode)
	self.gamemode = gamemode
	self.awarding = false            -- true cat timp dam noi aur/XP (filtrele lasa valorile sa treaca)
	self.streak = {}                 -- playerID -> kill streak curent
	self.penaltyUntil = {}           -- playerID -> GameTime pana la care se aplica penalizarea de buyback
	self.penaltyCarry = {}           -- playerID -> restul fractionar al aurului redus de penalizare
end

local function OwnerPlayerID(unit)
	if not unit or not unit.GetPlayerOwnerID then return -1 end
	local pid = unit:GetPlayerOwnerID()
	if pid == nil or pid < 0 then return -1 end
	return pid
end

local function HeroesInRadius(team, pos, radius)
	local units = FindUnitsInRadius(team, pos, nil, radius,
		DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
	local out = {}
	for _, u in ipairs(units) do
		if u:IsRealHero() and not u:IsClone() and u:IsAlive() then table.insert(out, u) end
	end
	return out
end

-- XP-ul de kill (6.88): HERO_KILL_XP impartit intre eroii care primesc XP + componenta AoE pe nivel (n = eroii din raza
-- care primesc aurul AoE, maxim 5; 0 daca nu e nimeni in raza)
local function KillXP(level, receivers, n)
	if #receivers == 0 then return 0 end
	local killXP = C.HERO_KILL_XP[math.min(level, #C.HERO_KILL_XP)] or 0
	local aoe = (n > 0) and (C.AOE_XP_PER_LEVEL[n] * level) or 0
	return math.floor(killXP / #receivers + aoe)
end

-- net worth-ul unei echipe (suma jucatorilor)
local function TeamNetWorth(team)
	local nw = 0
	for pid = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PlayerResource:IsValidPlayerID(pid) and PlayerResource:GetTeam(pid) == team then
			nw = nw + (PlayerResource:GetNetWorth(pid) or 0)
		end
	end
	return nw
end

-- componenta "comeback" a aurului AoE (6.82-6.88), doar pentru echipa cu net worth mai mic (vezi C.AOE_COMEBACK)
local function ComebackGold(n, killerTeam, victimTeam, victimPID)
	local allied, enemy = TeamNetWorth(killerTeam), TeamNetWorth(victimTeam)
	if allied <= 0 or enemy <= allied then return 0 end
	local nwFactor = math.min(1, enemy / allied - 1)
	local disadvantage = math.min(1, (enemy - allied) / C.AOE_COMEBACK_NW_CAP)
	local dyingNW = (victimPID >= 0) and (PlayerResource:GetNetWorth(victimPID) or 0) or 0
	local c = C.AOE_COMEBACK[n]
	return c[1] * dyingNW * nwFactor + c[2] * disadvantage
end

function M:OnHeroKilled(victim, attacker)
	local victimPID = OwnerPlayerID(victim)
	local level = victim:GetLevel()
	local victimTeam = victim:GetTeamNumber()

	-- pierdere de aur: 30 x nivel, doar din aurul nesigur. GoldFilter blocheaza DOTA_ModifyGold_Death negativ cat
	-- timp awarding e false (pierderea moderna a motorului), deci pierderea noastra trece doar cu awarding = true.
	if victimPID >= 0 then
		local loss = math.min(C.DEATH_GOLD_PER_LEVEL * level, PlayerResource:GetUnreliableGold(victimPID))
		if loss > 0 then
			self.awarding = true
			local ok, err = pcall(function() PlayerResource:ModifyGold(victimPID, -loss, false, DOTA_ModifyGold_Death) end)
			self.awarding = false
			if not ok then print("[dota688] pierderea de aur la moarte: " .. tostring(err)) end
		end
	end

	local killerTeam = attacker and attacker:GetTeamNumber() or nil
	local enemyTeam = (victimTeam == DOTA_TEAM_GOODGUYS and DOTA_TEAM_BADGUYS) or (victimTeam == DOTA_TEAM_BADGUYS and DOTA_TEAM_GOODGUYS) or nil
	if not attacker or killerTeam == victimTeam or (killerTeam ~= DOTA_TEAM_GOODGUYS and killerTeam ~= DOTA_TEAM_BADGUYS) then
		-- deny / sinucidere / neutrali (6.88): nimeni nu primeste aur, streak-ul victimei se reseteaza (al denierului nu
		-- creste), iar eroii inamici din raza impart XP-ul normal de kill; daca nu e nimeni in raza, XP-ul se pierde
		if victimPID >= 0 then self.streak[victimPID] = 0 end
		if enemyTeam then
			local receivers = HeroesInRadius(enemyTeam, victim:GetAbsOrigin(), C.KILL_RADIUS)
			local xpEach = KillXP(level, receivers, math.min(#receivers, 5))
			if xpEach > 0 then
				self.awarding = true
				for _, hero in ipairs(receivers) do hero:AddExperience(xpEach, DOTA_ModifyXP_HeroKill, false, true) end
				self.awarding = false
			end
		end
		return
	end

	-- aurul direct merge jucatorului care detine unitatea cu last hit-ul (oricat de departe ar fi eroul lui)
	local killerPID = OwnerPlayerID(attacker)
	local killerHero = (killerPID >= 0) and PlayerResource:GetSelectedHeroEntity(killerPID) or nil
	-- aur AoE: doar eroii reali vii din raza (ucigasul doar daca eroul lui e el insusi in raza)
	local nearby = HeroesInRadius(killerTeam, victim:GetAbsOrigin(), C.KILL_RADIUS)
	local n = math.min(#nearby, 5)
	-- XP: eroii din raza; eroul care a dat el insusi last hit-ul primeste XP si din afara razei. Daca last hit-ul e al
	-- unui creep / iluzii / turn / summon, owner-ul din afara razei nu primeste XP.
	local xpReceivers = {}
	for _, u in ipairs(nearby) do table.insert(xpReceivers, u) end
	if killerHero and attacker == killerHero then
		local present = false
		for _, u in ipairs(xpReceivers) do if u == killerHero then present = true end end
		if not present then table.insert(xpReceivers, killerHero) end
	end

	-- streak-ul victimei (bonus pentru cel care o opreste)
	local victimStreak = (victimPID >= 0) and (self.streak[victimPID] or 0) or 0
	local streakGold = C.KILL_STREAK_GOLD[math.min(victimStreak, 10)] or 0
	if victimPID >= 0 then self.streak[victimPID] = 0 end
	if killerPID >= 0 then self.streak[killerPID] = (self.streak[killerPID] or 0) + 1 end

	self.awarding = true
	-- aur direct pentru ucigas (daca e un jucator)
	if killerPID >= 0 then
		local direct = math.floor(C.KILL_GOLD_BASE + streakGold + C.KILL_GOLD_PER_LEVEL * level)
		Dota688GiveGold(killerPID, direct, true, DOTA_ModifyGold_HeroKill)
		-- First Blood: o singura data pe meci, jucatorului care primeste aurul direct al primului kill erou-vs-erou
		-- (deny-ul si neutralii nu ajung aici, deci nu il consuma)
		if not self.firstBloodGiven then
			self.firstBloodGiven = true
			Dota688GiveGold(killerPID, C.FIRST_BLOOD_GOLD, true, DOTA_ModifyGold_HeroKill)
		end
	end
	-- aur AoE pentru eroii din raza
	if n > 0 then
		local aoe = C.AOE_GOLD[n]
		local aoeGold = math.floor(aoe[1] + aoe[2] * level + ComebackGold(n, killerTeam, victimTeam, victimPID))
		for _, hero in ipairs(nearby) do
			local pid = OwnerPlayerID(hero)
			if pid >= 0 then Dota688GiveGold(pid, aoeGold, true, DOTA_ModifyGold_HeroKill) end
		end
	end
	-- XP
	local xpEach = KillXP(level, xpReceivers, n)
	for _, hero in ipairs(xpReceivers) do
		hero:AddExperience(xpEach, DOTA_ModifyXP_HeroKill, false, true)
	end
	self.awarding = false
end

-- Iluziile (6.88): fara aur si fara XP la moarte (7.00 a adaugat bounty pentru iluzii). Apelat la npc_spawned; iluzia
-- e marcata ca atare abia dupa eveniment, deci verificam in cadrul urmator. Motorul ignora bounty-ul / XP-ul setat
-- (testat), deci moartea fara aur o asigura modifier_dota688_illusion_bounty.
function M:OnUnitSpawned(unit)
	if C.ILLUSION_BOUNTY or not unit or unit:IsNull() or not unit.IsHero or not unit:IsHero() then return end
	Dota688Timers:After(0, function()
		if unit:IsNull() or not unit:IsIllusion() then return end
		unit:SetMinimumGoldBounty(0)
		unit:SetMaximumGoldBounty(0)
		unit:SetDeathXP(0)
		unit:AddNewModifier(unit, nil, "modifier_dota688_illusion_bounty", {})
	end)
end

-- Filtru de aur: blocheaza aurul de kill calculat de motor (il dam noi) si aplica penalizarea de buyback.
-- Aur pasiv 6.88: 1 aur (nesigur) la 0.6 s, de la horn. Il dam din Lua: aurul pasiv al motorului nu trece prin filtru
-- (nu poate fi redus de penalizarea de buyback), deci e oprit in gamemode.lua (SetGoldPerTick(0)).
function M:OnHorn()
	Dota688Timers:Every(C.GOLD_TICK_TIME, function()
		if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then return false end
		self.awarding = true
		self.penaltyDone = true
		for pid = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
			if PlayerResource:IsValidPlayerID(pid) and PlayerResource:HasSelectedHero(pid) then
				local team = PlayerResource:GetTeam(pid)
				local gold = self:Penalize(pid, C.GOLD_PER_TICK, DOTA_ModifyGold_GameTick)
				if (team == DOTA_TEAM_GOODGUYS or team == DOTA_TEAM_BADGUYS) and gold > 0 then
					PlayerResource:ModifyGold(pid, gold, false, DOTA_ModifyGold_GameTick)
				end
			end
		end
		self.penaltyDone = false
		self.awarding = false
	end)
end

-- Penalizarea de buyback (6.84-6.88): tot aurul castigat (si cel pasiv) e taiat cu 60% pana la respawn-ul initial;
-- exceptii: vanzarea de iteme si redistribuirea de la abandon. Folosita de GoldFilter (aurul dat de motor) si de aurul
-- dat din Lua (Dota688GiveGold, OnHorn), care nu trece prin filtru.
function M:Penalize(pid, gold, reason)
	local until_ = pid and self.penaltyUntil[pid]
	if not until_ or GameRules:GetGameTime() >= until_ or gold <= 0
		or reason == DOTA_ModifyGold_SellItem or reason == DOTA_ModifyGold_AbandonedRedistribute then
		return gold
	end
	-- restul fractionar se pastreaza pe jucator: aurul pasiv vine cate 1, iar 40% din 1 rotunjit in jos ar fi 0
	self.penaltyCarry[pid] = (self.penaltyCarry[pid] or 0) + gold * (1 - C.BUYBACK_GOLD_PENALTY)
	local out = math.floor(self.penaltyCarry[pid])
	self.penaltyCarry[pid] = self.penaltyCarry[pid] - out
	return out
end

function M:GoldFilter(ev)
	local reason = ev.reason_const
	if reason == DOTA_ModifyGold_GameTick and not self.awarding then
		return false   -- aurul pasiv il dam noi (OnHorn); evitam dublarea daca motorul l-ar da si el
	end
	if reason == DOTA_ModifyGold_HeroKill and not self.awarding then
		return false
	end
	if reason == DOTA_ModifyGold_Death and not self.awarding then
		-- motorul nu ar trebui sa scada aur (SetLoseGoldOnDeath false); daca totusi o face, blocam
		if ev.gold < 0 then return false end
	end
	-- penalizarea de buyback (daca aurul vine din Lua, a fost deja aplicata de Dota688GiveGold / OnHorn)
	if not self.penaltyDone then ev.gold = self:Penalize(ev.player_id_const, ev.gold, reason) end
	return true
end

function M:ExperienceFilter(ev)
	if ev.reason_const == DOTA_ModifyXP_HeroKill and not self.awarding then
		return false
	end
	-- XP de recuperare pentru eroii in urma si XP de la outpost-uri: aparute dupa 6.88
	if ev.reason_const == DOTA_ModifyXP_CatchUp or ev.reason_const == DOTA_ModifyXP_Outpost then
		return false
	end
	return true
end

function M:SetBuybackPenalty(pid, seconds)
	self.penaltyUntil[pid] = GameRules:GetGameTime() + seconds
end
