-- Aur si experienta pentru uciderea eroilor, dupa formulele 6.88.
local C = DOTA688
Dota688GoldXP = Dota688GoldXP or {}
local M = Dota688GoldXP

function M:Init(gamemode)
	self.gamemode = gamemode
	self.awarding = false            -- true cat timp dam noi aur/XP (filtrele lasa valorile sa treaca)
	self.streak = {}                 -- playerID -> kill streak curent
	self.penaltyUntil = {}           -- playerID -> GameTime pana la care se aplica penalizarea de buyback
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

function M:OnHeroKilled(victim, attacker)
	local victimPID = OwnerPlayerID(victim)
	local level = victim:GetLevel()

	-- pierdere de aur: 30 x nivel, doar din aurul nesigur
	if victimPID >= 0 then
		local loss = math.min(C.DEATH_GOLD_PER_LEVEL * level, PlayerResource:GetUnreliableGold(victimPID))
		if loss > 0 then
			PlayerResource:ModifyGold(victimPID, -loss, false, DOTA_ModifyGold_Death)
		end
	end

	if not attacker then return end
	local killerTeam = attacker:GetTeamNumber()
	if killerTeam == victim:GetTeamNumber() then
		-- deny / sinucidere: nimeni nu primeste nimic, dar streak-ul victimei se reseteaza
		if victimPID >= 0 then self.streak[victimPID] = 0 end
		return
	end
	if killerTeam ~= DOTA_TEAM_GOODGUYS and killerTeam ~= DOTA_TEAM_BADGUYS then
		-- ucis de neutrali: fara aur de kill, dar XP se imparte eroilor inamici din raza (ca in 6.88)
		if victimPID >= 0 then self.streak[victimPID] = 0 end
		return
	end

	local killerPID = OwnerPlayerID(attacker)
	local killerHero = (killerPID >= 0) and PlayerResource:GetSelectedHeroEntity(killerPID) or nil
	local nearby = HeroesInRadius(killerTeam, victim:GetAbsOrigin(), C.KILL_RADIUS)
	if killerHero then
		local present = false
		for _, u in ipairs(nearby) do if u == killerHero then present = true end end
		if not present then table.insert(nearby, killerHero) end
	end
	local n = math.max(1, math.min(#nearby, 5))

	-- streak-ul victimei (bonus pentru cel care o opreste)
	local victimStreak = (victimPID >= 0) and (self.streak[victimPID] or 0) or 0
	local streakGold = C.KILL_STREAK_GOLD[math.min(victimStreak, 10)] or 0
	if victimPID >= 0 then self.streak[victimPID] = 0 end
	if killerPID >= 0 then self.streak[killerPID] = (self.streak[killerPID] or 0) + 1 end

	self.awarding = true
	-- aur direct pentru ucigas (daca e un jucator)
	if killerPID >= 0 then
		local direct = math.floor(C.KILL_GOLD_BASE + streakGold + C.KILL_GOLD_PER_LEVEL * level)
		PlayerResource:ModifyGold(killerPID, direct, true, DOTA_ModifyGold_HeroKill)
	end
	-- aur si XP "AoE" pentru fiecare erou din raza (inclusiv ucigasul)
	local aoe = C.AOE_GOLD[n]
	local aoeGold = math.floor(aoe[1] + aoe[2] * level)
	local killXP = C.HERO_KILL_XP[math.min(level, #C.HERO_KILL_XP)] or 0
	local xpEach = math.floor(killXP / #nearby + C.AOE_XP_PER_LEVEL[n] * level)
	for _, hero in ipairs(nearby) do
		local pid = OwnerPlayerID(hero)
		if pid >= 0 then
			PlayerResource:ModifyGold(pid, aoeGold, true, DOTA_ModifyGold_HeroKill)
		end
		hero:AddExperience(xpEach, DOTA_ModifyXP_HeroKill, false, true)
	end
	self.awarding = false
end

-- Filtru de aur: blocheaza aurul de kill calculat de motor (il dam noi) si aplica penalizarea de buyback.
-- Aur pasiv 6.88: 1 aur (nesigur) la 0.6 s, de la horn. GameRules:SetGoldPerTick/SetGoldTickTime nu mai au efect
-- in motorul curent (testat: 0 aur pasiv, cu sau fara filtru), deci il dam din Lua.
function M:OnHorn()
	Dota688Timers:Every(C.GOLD_TICK_TIME, function()
		if GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME then return false end
		self.awarding = true
		for pid = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
			if PlayerResource:IsValidPlayerID(pid) and PlayerResource:HasSelectedHero(pid) then
				local team = PlayerResource:GetTeam(pid)
				if team == DOTA_TEAM_GOODGUYS or team == DOTA_TEAM_BADGUYS then
					PlayerResource:ModifyGold(pid, C.GOLD_PER_TICK, false, DOTA_ModifyGold_GameTick)
				end
			end
		end
		self.awarding = false
	end)
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
	local pid = ev.player_id_const
	local until_ = pid and self.penaltyUntil[pid]
	if until_ and GameRules:GetGameTime() < until_ and ev.gold > 0 and reason ~= DOTA_ModifyGold_GameTick
		and reason ~= DOTA_ModifyGold_SellItem and reason ~= DOTA_ModifyGold_AbandonedRedistribute then
		ev.gold = math.floor(ev.gold * (1 - C.BUYBACK_GOLD_PENALTY))
	end
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
