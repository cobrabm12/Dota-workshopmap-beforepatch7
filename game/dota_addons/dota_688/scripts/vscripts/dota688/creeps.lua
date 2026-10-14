-- Creepi 6.88f: experienta impartita, upgrade-urile creepilor de lane la 7:30 si valurile cu siege.
--
-- XP: motorul curent da tot XP-ul unui creep unui singur erou din apropiere (raza 1500, testat; motivul
-- DOTA_ModifyXP_CreepKill). In 6.88 XP-ul creepilor de lane, al neutralilor (si al celorlalte unitati non-erou) se
-- imparte egal intre eroii reali vii ai echipei care il primeste aflati la cel mult 1300 de creep: pentru creepii
-- echipelor = inamicii creep-ului (100 %; 50 % la deny; 35 % daca l-au omorat neutralii), pentru neutrali = echipa
-- ucigasului. XP-ul motorului (CreepKill/SummonKill) e blocat in ExperienceFilter cat timp nu il dam noi (awarding).
--
-- Upgrade-uri: la fiecare 7:30 de joc fiecare creep de lane (melee si ranged) primeste +12 HP si +2 aur bounty
-- (minim si maxim); XP-ul nu creste. La spawn: HP = StatusHealth KV + 12n, bounty = KV + 2n, XP = BountyXP KV,
-- n = floor(timp / 450). Siege: valorile KV (fara upgrade-uri). Daunele raman cum le pune motorul.
--
-- Valuri: 6.88 avea un creep siege la fiecare al 7-lea val (3.5 min) pe fiecare lane, 2 dupa 45:00; motorul curent
-- la fiecare al 10-lea. La fiecare val (grupat dupa echipa, lane si indexul valului) numaram ce a creat motorul si, dupa
-- WAVE_CHECK_DELAY, scoatem siege-urile in plus si cream pe cele lipsa la spawner-ul lane-ului, pe drumul valului.
Dota688Creeps = Dota688Creeps or {}
local M = Dota688Creeps

M.C = {
	XP_RADIUS              = 1300,     -- 7.07 -> 1500
	DENY_XP_FACTOR         = 0.5,      -- creep denied: 50 % pentru inamicii din raza
	NEUTRAL_KILL_XP_FACTOR = 0.35,     -- creep de lane omorat de neutrali: 35 %
	UPGRADE_INTERVAL       = 450,      -- 7:30
	UPGRADE_HP             = 12,
	UPGRADE_GOLD           = 2,
	WAVE_INTERVAL          = 30,
	WAVE_CHECK_DELAY       = 0.5,      -- secunde dupa primul creep al valului
	SIEGE_EVERY_WAVES      = 7,        -- valul 7, 14, 21... (3:30, 7:00, 10:30...); valul de la 0:00 are indexul 0
	LATE_GAME_TIME         = 2700,     -- 45:00: +1 siege, +1 ranged, (+1 melee si la 15:00 / 30:00)
	-- motorul pare sa aiba si el alta compozitie (60 de creepi la 0:43 = 5 pe val); cu true, melee/ranged sunt
	-- aduse si ele la valorile 6.88 (3+1, +1 melee la 15/30/45 min, +1 ranged la 45 min). Implicit doar siege-ul.
	ENFORCE_MELEE_RANGED   = false,
	SPAWNER_MAX_DIST       = 1000,
	-- pozitiile spawner-elor din harta 6.88 (docs/HARTA_ENTITATI.md), daca entitatile nu se gasesc
	SPAWNER_POS = {
		good_top = Vector(-6624, -4064, 480), good_mid = Vector(-5008, -4488, 480), good_bot = Vector(-3648, -6112, 480),
		bad_top = Vector(3168, 5792, 496), bad_mid = Vector(4096, 3584, 496), bad_bot = Vector(6272, 3648, 512),
	},
}
local C = M.C
local LANES = { "top", "mid", "bot" }
local KINDS = { "melee", "ranged", "siege" }

M.awarding = false     -- true cat timp dam noi XP-ul (ExperienceFilter lasa CreepKill sa treaca); refolosibil
M.kv = M.kv or {}
M.DEBUG_XP = false     -- true: scrie in consola fiecare eveniment de XP al motorului blocat

local function TeamTag(team) return team == DOTA_TEAM_GOODGUYS and "good" or "bad" end
local function TeamName(team) return team == DOTA_TEAM_GOODGUYS and "goodguys" or "badguys" end

local function OtherTeam(team)
	if team == DOTA_TEAM_GOODGUYS then return DOTA_TEAM_BADGUYS end
	if team == DOTA_TEAM_BADGUYS then return DOTA_TEAM_GOODGUYS end
	return nil
end

local function UnitKV(name)
	local kv = M.kv[name]
	if kv == nil then
		local t = GetUnitKeyValuesByName(name)
		kv = false
		if t then
			kv = { hp = tonumber(t.StatusHealth), gmin = tonumber(t.BountyGoldMin), gmax = tonumber(t.BountyGoldMax),
				xp = tonumber(t.BountyXP) }
		end
		M.kv[name] = kv
	end
	return kv or nil
end

local function IsLaneCreep(unit)
	local cls = unit:GetClassname()
	if cls ~= "npc_dota_creep_lane" and cls ~= "npc_dota_creep_siege" then return false end
	local team = unit:GetTeamNumber()
	if team ~= DOTA_TEAM_GOODGUYS and team ~= DOTA_TEAM_BADGUYS then return false end
	return not string.find(unit:GetUnitName(), "diretide", 1, true)
end

local function KindOf(unit)
	local name = unit:GetUnitName()
	if unit:GetClassname() == "npc_dota_creep_siege" or string.find(name, "_siege", 1, true) then return "siege" end
	if string.find(name, "_ranged", 1, true) then return "ranged" end
	return "melee"   -- melee si flagbearer (devenit creep melee 6.88 in KV)
end

local function Suffix(name)
	if string.find(name, "_upgraded_mega$") then return "_upgraded_mega" end
	if string.find(name, "_upgraded$") then return "_upgraded" end
	return ""
end

-- ruleaza fn cu filtrul de XP deschis; awarding revine pe false si la eroare
function M:Award(fn)
	self.awarding = true
	local ok, err = pcall(fn)
	self.awarding = false
	if not ok then print("[dota688] eroare la XP-ul creepilor: " .. tostring(err)) end
end

-- pentru codul care da XP cu DOTA_ModifyXP_CreepKill in afara acestui modul (Hand of Midas, Dark Ritual)
function M:GiveXP(hero, xp)
	if not hero or hero:IsNull() or not xp or xp <= 0 then return end
	self:Award(function() hero:AddExperience(xp, DOTA_ModifyXP_CreepKill, false, true) end)
end

function M:Init(gamemode)
	self.gamemode = gamemode
	self.awarding = false
	self.waves = {}
	self.spawners = {}
	for _, team in ipairs({ DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS }) do
		self.spawners[team] = {}
		for _, lane in ipairs(LANES) do
			local key = TeamTag(team) .. "_" .. lane
			local e = Entities:FindAllByClassname("npc_dota_spawner_" .. key)[1]
			self.spawners[team][lane] = e and e:GetAbsOrigin() or C.SPAWNER_POS[key]
			if not e then print("[dota688] spawner npc_dota_spawner_" .. key .. " negasit: pozitia din harta 6.88") end
		end
	end
end

-- Upgrade-uri ----------------------------------------------------------------------------------------------------
function M:UpgradeCount()
	local t = GameRules:GetDOTATime(false, false)
	return math.max(0, math.floor((t + 1) / C.UPGRADE_INTERVAL))
end

function M:ApplyLaneStats(unit, kind)
	local kv = UnitKV(unit:GetUnitName())
	if not kv or not kv.hp then return end
	local n = (kind == "siege") and 0 or self:UpgradeCount()
	local hp = kv.hp + C.UPGRADE_HP * n
	-- HP adaugat de modifieri la spawn (eventualele upgrade-uri ale motorului) e compensat in HP-ul de baza
	local bonus = math.max(0, unit:GetMaxHealth() - unit:GetBaseMaxHealth())
	local base = math.max(1, hp - bonus)
	if unit:GetBaseMaxHealth() ~= base or unit:GetMaxHealth() ~= hp then
		local full = unit:GetHealth() >= unit:GetMaxHealth()
		local pct = unit:GetHealth() / math.max(1, unit:GetMaxHealth())
		unit:SetBaseMaxHealth(base)
		unit:SetMaxHealth(hp)
		unit:SetHealth(full and hp or math.max(1, math.floor(hp * pct + 0.5)))
	end
	if kv.gmin then unit:SetMinimumGoldBounty(kv.gmin + C.UPGRADE_GOLD * n) end
	if kv.gmax then unit:SetMaximumGoldBounty(kv.gmax + C.UPGRADE_GOLD * n) end
	if kv.xp then unit:SetDeathXP(kv.xp) end
end

-- diagnostic: ce valori pune motorul unui creep melee normal, o data pentru fiecare treapta de upgrade
function M:LogEngineStats(unit, kind)
	if kind ~= "melee" or Suffix(unit:GetUnitName()) ~= "" or string.find(unit:GetUnitName(), "flagbearer", 1, true) then return end
	local n = self:UpgradeCount()
	if self.loggedUpgrade == n then return end
	self.loggedUpgrade = n
	local kv = UnitKV(unit:GetUnitName()) or {}
	print(string.format("[dota688] creep %s la %.0f s (upgrade %d): motor HP %d/%d (baza %d), daune %d-%d, aur %d-%d, XP %d; "
		.. "6.88: HP %d, aur %d-%d, XP %d", unit:GetUnitName(), GameRules:GetDOTATime(false, false), n, unit:GetHealth(),
		unit:GetMaxHealth(), unit:GetBaseMaxHealth(), unit:GetBaseDamageMin(), unit:GetBaseDamageMax(), unit:GetMinimumGoldBounty(),
		unit:GetMaximumGoldBounty(), unit:GetDeathXP(), (kv.hp or 0) + C.UPGRADE_HP * n, (kv.gmin or 0) + C.UPGRADE_GOLD * n,
		(kv.gmax or 0) + C.UPGRADE_GOLD * n, kv.xp or 0))
end

-- apelat pentru fiecare unitate din OnNPCSpawned
function M:OnNPCSpawned(unit)
	if unit.dota688_creep_setup or not IsLaneCreep(unit) then return end
	unit.dota688_creep_setup = true
	local kind = KindOf(unit)
	self:LogEngineStats(unit, kind)
	self:ApplyLaneStats(unit, kind)
	-- a doua oara dupa spawn, daca motorul isi aplica valorile dupa evenimentul npc_spawned
	Dota688Timers:After(0.1, function()
		if not unit:IsNull() and unit:IsAlive() then self:ApplyLaneStats(unit, kind) end
	end)
	self:TrackWave(unit, kind)
end

-- Valuri ---------------------------------------------------------------------------------------------------------
-- cate unitati de tipul dat trebuie sa aiba valul (6.88); nil = cum decide motorul
function M:WantedCount(kind, index)
	local t = index * C.WAVE_INTERVAL
	local late = (t >= C.LATE_GAME_TIME) and 1 or 0
	if kind == "siege" then
		if index <= 0 or index % C.SIEGE_EVERY_WAVES ~= 0 then return 0 end
		return 1 + late
	end
	if not C.ENFORCE_MELEE_RANGED then return nil end
	if kind == "melee" then
		return 3 + ((t >= 900) and 1 or 0) + ((t >= 1800) and 1 or 0) + late
	end
	return 1 + late
end

function M:LaneOf(unit, team)
	local pos = unit:GetAbsOrigin()
	local best, bestD
	for lane, sp in pairs(self.spawners and self.spawners[team] or {}) do
		local d = (pos - sp):Length2D()
		if not bestD or d < bestD then best, bestD = lane, d end
	end
	if best and bestD <= C.SPAWNER_MAX_DIST then return best end
	-- rezerva: numele primului path_corner (lane_<lane>_pathcorner_<echipa>_N)
	local goal = unit:GetInitialGoalEntity()
	local name = goal and goal:GetName() or ""
	return string.match(name, "^lane_(%a+)_pathcorner")
end

local function Alive(list)
	local out = {}
	for _, u in ipairs(list) do
		if not u:IsNull() and u:IsAlive() then out[#out + 1] = u end
	end
	return out
end

function M:TrackWave(unit, kind)
	if self.spawningWave or unit.dota688_wave_spawned or not self.waves then return end
	local team = unit:GetTeamNumber()
	local lane = self:LaneOf(unit, team)
	if not lane then return end
	local index = math.floor(GameRules:GetDOTATime(false, false) / C.WAVE_INTERVAL + 0.5)
	local key = team .. ":" .. lane .. ":" .. index
	local w = self.waves[key]
	if not w then
		w = { team = team, lane = lane, index = index, checked = false, adjusted = {},
			units = { melee = {}, ranged = {}, siege = {} }, engine = { melee = 0, ranged = 0, siege = 0 }, suffix = {} }
		self.waves[key] = w
		Dota688Timers:After(C.WAVE_CHECK_DELAY, function() self:CheckWave(w) end)
	end
	w.engine[kind] = w.engine[kind] + 1
	w.sample = w.sample or unit
	w.suffix[kind] = w.suffix[kind] or Suffix(unit:GetUnitName())
	if w.checked then
		-- creep al motorului aparut dupa verificare: il pastram doar daca valul mai are loc pentru el
		local want = self:WantedCount(kind, index)
		if want and #Alive(w.units[kind]) >= want then
			Dota688Timers:After(0, function() if not unit:IsNull() then UTIL_Remove(unit) end end)
			return
		end
	end
	table.insert(w.units[kind], unit)
end

function M:LaneGoal(w)
	local s = w.sample
	if s and not s:IsNull() then
		local g = s:GetInitialGoalEntity()
		if g then return g end
	end
	return Entities:FindByName(nil, string.format("lane_%s_pathcorner_%s_1", w.lane, TeamName(w.team)))
end

function M:SpawnLaneCreep(w, kind)
	-- upgrade-ul (super/mega) dupa creepii valului: siege-ul urmeaza creepii melee
	local name
	if kind == "siege" then
		local suffix = w.suffix.melee or w.suffix.siege or w.suffix.ranged or ""
		name = "npc_dota_" .. TeamName(w.team) .. "_siege" .. suffix
	else
		local suffix = w.suffix[kind] or w.suffix.melee or ""
		name = "npc_dota_creep_" .. TeamName(w.team) .. "_" .. kind .. suffix
	end
	local pos = self.spawners[w.team][w.lane]
	if not pos and w.sample and not w.sample:IsNull() then pos = w.sample:GetAbsOrigin() end
	if not pos then return end
	self.spawningWave = true
	local ok, u = pcall(CreateUnitByName, name, pos, true, nil, nil, w.team)
	self.spawningWave = false
	if not ok or not u then
		print("[dota688] nu am putut crea " .. name .. ": " .. tostring(u))
		return
	end
	u.dota688_wave_spawned = true
	local goal = self:LaneGoal(w)
	if goal then
		u:SetInitialGoalEntity(goal)
		u:SetMustReachEachGoalEntity(true)
	else
		print("[dota688] fara path_corner pentru lane-ul " .. w.lane .. ": " .. name .. " ramane la spawner")
	end
	table.insert(w.units[kind], u)
end

function M:CheckWave(w)
	w.checked = true
	for _, kind in ipairs(KINDS) do
		local want = self:WantedCount(kind, w.index)
		if want then
			local alive = Alive(w.units[kind])
			if #alive > want then
				-- scoatem intai flagbearer-ii (unitate 7.32), apoi ultimii aparuti
				table.sort(alive, function(a, b)
					local fa = string.find(a:GetUnitName(), "flagbearer", 1, true) and 1 or 0
					local fb = string.find(b:GetUnitName(), "flagbearer", 1, true) and 1 or 0
					if fa ~= fb then return fa > fb end
					return a:GetEntityIndex() > b:GetEntityIndex()
				end)
				local keep = {}
				for i = #alive - want + 1, #alive do keep[#keep + 1] = alive[i] end
				for i = 1, #alive - want do UTIL_Remove(alive[i]) end
				w.adjusted[kind] = want - #alive
				w.units[kind] = keep
			elseif #alive < want then
				for _ = 1, want - #alive do self:SpawnLaneCreep(w, kind) end
				w.adjusted[kind] = want - #alive
			end
		end
	end
	-- diagnostic: compozitia valurilor motorului pe mid Radiant (primele valuri, la schimbari si la ajustari)
	if w.team == DOTA_TEAM_GOODGUYS and w.lane == "mid" then
		local sig = string.format("%d melee, %d ranged, %d siege", w.engine.melee, w.engine.ranged, w.engine.siege)
		local adj = {}
		for _, kind in ipairs(KINDS) do
			if w.adjusted[kind] then adj[#adj + 1] = string.format("%s %+d", kind, w.adjusted[kind]) end
		end
		if w.index < 3 or sig ~= self.lastSig or #adj > 0 then
			print(string.format("[dota688] valul %d (%d:%02d) mid Radiant: motorul %s; ajustat: %s", w.index,
				math.floor(w.index * C.WAVE_INTERVAL / 60), (w.index * C.WAVE_INTERVAL) % 60, sig,
				#adj > 0 and table.concat(adj, ", ") or "nimic"))
		end
		self.lastSig = sig
	end
	for k, other in pairs(self.waves) do
		if other.index < w.index - 2 then self.waves[k] = nil end
	end
end

-- XP -------------------------------------------------------------------------------------------------------------
-- eroii reali vii ai echipei din raza; clonele Meepo si Tempest Double conteaza pentru eroul jucatorului (o data)
local function HeroesNear(team, pos, radius)
	local units = FindUnitsInRadius(team, pos, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS,
		FIND_ANY_ORDER, false)
	local out, seen = {}, {}
	for _, u in ipairs(units) do
		if u:IsRealHero() and u:IsAlive() and u:GetTeamNumber() == team and not u.dota688_copy then
			local hero = u
			if u:IsClone() or u:IsTempestDouble() then
				local pid = u:GetPlayerOwnerID()
				hero = (pid ~= nil and pid >= 0) and PlayerResource:GetSelectedHeroEntity(pid) or u
			end
			if hero and not seen[hero:GetEntityIndex()] then
				seen[hero:GetEntityIndex()] = true
				out[#out + 1] = hero
			end
		end
	end
	return out
end

-- apelat din OnEntityKilled pentru orice unitate care nu e erou
function M:OnUnitKilled(killed, attacker)
	if killed:IsHero() or killed:IsBuilding() or killed:IsIllusion() or killed:IsCourier() then return end
	if killed:GetUnitName() == "npc_dota_roshan" then return end   -- XP-ul lui Roshan ramane la motor (RoshanKill)
	local xp = killed:GetDeathXP()
	if not xp or xp <= 0 then return end
	-- fara ucigas sau ucis de el insusi (expirare, ForceKill, explozia minelor): fara XP
	if not attacker or attacker:IsNull() or attacker == killed then return end
	local creepTeam = killed:GetTeamNumber()
	local atkTeam = attacker:GetTeamNumber()
	local team, factor
	if creepTeam == DOTA_TEAM_NEUTRALS then
		team, factor = atkTeam, 1
	else
		team = OtherTeam(creepTeam)
		if atkTeam == creepTeam then factor = C.DENY_XP_FACTOR
		elseif atkTeam == DOTA_TEAM_NEUTRALS then factor = C.NEUTRAL_KILL_XP_FACTOR
		else factor = 1 end
	end
	if team ~= DOTA_TEAM_GOODGUYS and team ~= DOTA_TEAM_BADGUYS then return end
	local heroes = HeroesNear(team, killed:GetAbsOrigin(), C.XP_RADIUS)
	if #heroes == 0 then return end
	local each = xp * factor / #heroes
	self:Award(function()
		for _, hero in ipairs(heroes) do
			hero:AddExperience(each, DOTA_ModifyXP_CreepKill, false, true)
		end
	end)
end

function M:ExperienceFilter(ev)
	if self.awarding then return true end
	local reason = ev.reason_const
	if reason == DOTA_ModifyXP_CreepKill or reason == DOTA_ModifyXP_SummonKill then
		if self.DEBUG_XP then
			print(string.format("[dota688] XP motor blocat: jucator %s, %s XP, motiv %s", tostring(ev.player_id_const),
				tostring(ev.experience), tostring(reason)))
		end
		return false
	end
	return true
end
