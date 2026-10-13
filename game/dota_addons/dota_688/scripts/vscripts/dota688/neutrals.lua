-- Neutrali (6.88): primul spawn la 0:30, apoi verificare la fiecare minut (x:00); un camp reapare doar daca volumul
-- lui (trigger_multiple neutralcamp_*, din harta) e gol. Motorul curent face primul spawn la 1:00:
-- GameRules:SetNeutralInitialSpawnOffset muta doar primul spawn.
local C = DOTA688
Dota688Neutrals = Dota688Neutrals or {}
local M = Dota688Neutrals

function M:Init(gamemode)
	self.gamemode = gamemode
	Dota688SafeCall(GameRules, "SetNeutralInitialSpawnOffset", C.NEUTRAL_FIRST_SPAWN_OFFSET)
	-- InitCamps() (inlocuirea camp-urilor moderne) e oprita: neutrii creati cu CreateUnitByName nu au AI-ul de camp
	-- (testat 13.10.2026: nu riposteaza cand sunt atacati). De reluat cu o metoda care pastreaza AI-ul motorului.
end

function M:OnHorn()
	-- verificare in consola: cati neutrali exista dupa primul spawn
	Dota688Timers:After(31, function()
		local n = #Entities:FindAllByClassname("npc_dota_creep_neutral")
		print(string.format("[dota688] neutrali la 0:31: %d (spawnere: %d)", n, #Entities:FindAllByClassname("npc_dota_neutral_spawner")))
	end)
end

-- Camp-uri 6.88 --------------------------------------------------------------
-- Motorul curent alege la fiecare spawn un camp aleator de nivelul spawner-ului, inclusiv tipuri aparute dupa 6.88
-- (Warpine Raiders, broaste, Prowlers, Ice Shaman + Frostbitten Golems la ancient). Un astfel de camp e sters in
-- cadrul urmator si inlocuit cu un camp 6.88 de acelasi nivel (nivelurile vin din spawner-ele hartii 6.88).
M.MODERN = {
	npc_dota_neutral_warpine_raider = true, npc_dota_neutral_prowler_acolyte = true, npc_dota_neutral_prowler_shaman = true,
	npc_dota_neutral_ice_shaman = true, npc_dota_neutral_frostbitten_golem = true,
	npc_dota_neutral_ancient_frog = true, npc_dota_neutral_ancient_frog_mage = true, npc_dota_neutral_grown_frog = true,
	npc_dota_neutral_grown_frog_mage = true, npc_dota_neutral_froglet = true, npc_dota_neutral_froglet_mage = true,
	npc_dota_neutral_tadpole = true, npc_dota_neutral_default = true,
}
-- npc_dota_neutral_spawner din harta 6.88 (docs/HARTA_ENTITATI.md): pozitie, nivel (0 mic, 1 mediu, 2 mare, 3 ancient)
M.SPAWNERS = {
	{ Vector(-1644, -4408, 384), 2 }, { Vector(-1648, 2512, 265), 1 }, { Vector(-256, -3324, 265), 1 },
	{ Vector(-288, 3616, 393), 1 }, { Vector(-3104, 4448, 393), 0 }, { Vector(-3136, 0, 393), 3 },
	{ Vector(-3598, 778, 392), 2 }, { Vector(-4608, 3456, 393), 2 }, { Vector(1216, 3232, 393), 2 },
	{ Vector(1600, -3520, 393), 1 }, { Vector(2972, -4576, 393), 0 }, { Vector(4143, -641, 288), 3 },
	{ Vector(4272, 556, 392), 2 }, { Vector(4504, -3472, 552), 2 },
}
local function camp(...) return { ... } end
local N = "npc_dota_neutral_"
-- componenta camp-urilor 6.88 (6.86-6.88) pe niveluri
M.CAMPS_688 = {
	[0] = {
		camp(N .. "kobold", N .. "kobold", N .. "kobold", N .. "kobold_tunneler", N .. "kobold_taskmaster"),
		camp(N .. "forest_troll_berserker", N .. "forest_troll_berserker", N .. "kobold_taskmaster"),
		camp(N .. "forest_troll_berserker", N .. "forest_troll_berserker", N .. "forest_troll_high_priest"),
		camp(N .. "gnoll_assassin", N .. "gnoll_assassin", N .. "gnoll_assassin"),
		camp(N .. "ghost", N .. "fel_beast", N .. "fel_beast"),
	},
	[1] = {
		camp(N .. "centaur_outrunner", N .. "centaur_khan"),
		camp(N .. "giant_wolf", N .. "giant_wolf", N .. "alpha_wolf"),
		camp(N .. "satyr_trickster", N .. "satyr_trickster", N .. "satyr_soulstealer", N .. "satyr_soulstealer"),
		camp(N .. "ogre_mauler", N .. "ogre_mauler", N .. "ogre_magi"),
		camp(N .. "mud_golem", N .. "mud_golem"),
		camp(N .. "harpy_scout", N .. "harpy_scout", N .. "harpy_storm"),
	},
	[2] = {
		camp(N .. "centaur_khan", N .. "centaur_outrunner", N .. "centaur_outrunner"),
		camp(N .. "satyr_hellcaller", N .. "satyr_soulstealer", N .. "satyr_trickster"),
		camp(N .. "polar_furbolg_champion", N .. "polar_furbolg_ursa_warrior", N .. "polar_furbolg_ursa_warrior"),
		camp(N .. "enraged_wildkin", N .. "wildkin", N .. "wildkin"),
		camp(N .. "dark_troll_warlord", N .. "dark_troll", N .. "dark_troll"),
	},
	[3] = {
		camp(N .. "black_dragon", N .. "black_drake", N .. "black_drake"),
		camp(N .. "granite_golem", N .. "rock_golem", N .. "rock_golem"),
		camp(N .. "big_thunder_lizard", N .. "small_thunder_lizard", N .. "small_thunder_lizard"),
	},
}
M.CAMP_RADIUS = 900   -- un spawn modern apartine celui mai apropiat spawner din aceasta raza

function M:InitCamps()
	self.pending = {}
	if self.spawnListener then StopListeningToGameEvent(self.spawnListener) end
	self.spawnListener = ListenToGameEvent("npc_spawned", Dynamic_Wrap(Dota688Neutrals, "OnNPCSpawned"), self)
end

function M:OnNPCSpawned(ev)
	local u = ev.entindex and EntIndexToHScript(ev.entindex)
	if not u or u:IsNull() or u.dota688_camp_688 or not self.MODERN[u:GetUnitName()] then return end
	if u:GetTeamNumber() ~= DOTA_TEAM_NEUTRALS or u:GetPlayerOwnerID() >= 0 then return end   -- dominat / creat de un jucator
	table.insert(self.pending, u)
	if not self.replaceQueued then
		self.replaceQueued = true
		Dota688Timers:After(0, function() M:ReplaceModernCamps() end)
	end
end

function M:NearestSpawner(pos)
	local best, bestD
	for _, s in ipairs(self.SPAWNERS) do
		local d = (s[1] - pos):Length2D()
		if d < self.CAMP_RADIUS and (not bestD or d < bestD) then best, bestD = s, d end
	end
	return best
end

function M:ReplaceModernCamps()
	self.replaceQueued = false
	local groups = {}
	for _, u in ipairs(self.pending) do
		if not u:IsNull() and u:IsAlive() then
			local s = self:NearestSpawner(u:GetAbsOrigin())
			if s then
				groups[s] = groups[s] or {}
				table.insert(groups[s], u)
			else
				print("[dota688] neutral modern fara spawner 6.88 in apropiere: " .. u:GetUnitName())
			end
		end
	end
	self.pending = {}
	for s, units in pairs(groups) do
		local names = {}
		for _, u in ipairs(units) do names[#names + 1] = u:GetUnitName(); UTIL_Remove(u) end
		local list = self.CAMPS_688[s[2]]
		local pick = list[RandomInt(1, #list)]
		for _, name in ipairs(pick) do
			local c = CreateUnitByName(name, s[1] + RandomVector(RandomFloat(0, 150)), true, nil, nil, DOTA_TEAM_NEUTRALS)
			if c then c.dota688_camp_688 = true end
		end
		print(string.format("[dota688] camp modern (%s) inlocuit cu camp 6.88 de nivel %d: %s", table.concat(names, ","), s[2], table.concat(pick, ",")))
	end
end
