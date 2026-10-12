-- Cladiri 6.88f: aurul turnurilor/baracilor/fillerelor (de echipa + last hit), aurul lui Roshan, Glyph of
-- Fortification (5 s, doar cladiri, cooldown 300 s, reimprospatat la caderea unui turn Tier 1) si Tower Protection.
--
-- Motorul curent (testat): la distrugerea unui turn T1 de catre un erou dau doar evenimente de aur cu motivul
-- DOTA_ModifyGold_Building (0 si 216, sigur) = last hit, fara aur de echipa; Roshan da 135 aur nesigur echipei
-- (DOTA_ModifyGold_RoshanKill). Le blocam pe toate in GoldFilter (cat timp nu dam noi aurul) si dam valorile 6.88.
-- Bounty-ul KV al cladirilor si al lui Roshan e pus pe 0 pe unitate (pastrat din KV aici), ca motorul sa nu dea
-- last hit-ul KV si pe alt motiv decat cele blocate.
LinkLuaModifier("modifier_dota688_glyph", "modifiers/modifier_dota688_glyph", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_tower_aura", "modifiers/modifier_dota688_tower_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_tower_aura_effect", "modifiers/modifier_dota688_tower_aura", LUA_MODIFIER_MOTION_NONE)

Dota688Buildings = Dota688Buildings or {}
local M = Dota688Buildings

-- Valori 6.88f ----------------------------------------------------------------------------------------------------
M.C = {
	TOWER_TEAM_GOLD     = { 160, 200, 240, 280 },   -- T1..T4, fiecarui jucator al echipei care distruge, sigur
	TOWER_LASTHIT_GOLD  = { 150, 250 },             -- doar daca KV-ul turnului are 0 (in KV-ul 6.88 aurul e 0: era in C++)
	RAX_TEAM_GOLD       = { melee = 275, range = 225 },
	RAX_LASTHIT_GOLD    = { 100, 150 },             -- idem, daca KV-ul baracii are 0
	DENY_TEAM_GOLD      = 0.5,                      -- turn (si baraca) distrus de propria echipa: inamicii primesc 50 %
	ROSHAN_TEAM_GOLD    = 200,                      -- fiecarui jucator al echipei care il omoara, sigur (+ last hit KV 150-400)
	GLYPH_DURATION      = 5,
	GLYPH_COOLDOWN      = 300,
	-- aura moderna a turnurilor (Tower Protection 7.x: +3/5/5/5 armura si regenerare), inlocuita de modifier_dota688_tower_aura
	ENGINE_TOWER_MODIFIERS = { modifier_tower_aura = true, modifier_tower_aura_bonus = true },
	BUILDING_CLASSES    = { "npc_dota_tower", "npc_dota_barracks", "npc_dota_fort", "npc_dota_filler", "npc_dota_building" },
}
local C = M.C

M.awarding = false     -- true cat timp dam noi aurul (GoldFilter lasa sa treaca)
M.readyAt = M.readyAt or {}
M.kv = M.kv or {}

local function OtherTeam(team)
	if team == DOTA_TEAM_GOODGUYS then return DOTA_TEAM_BADGUYS end
	if team == DOTA_TEAM_BADGUYS then return DOTA_TEAM_GOODGUYS end
	return nil
end

local function IsPlayingTeam(team)
	return team == DOTA_TEAM_GOODGUYS or team == DOTA_TEAM_BADGUYS
end

-- "tower", tier | "rax", "melee"/"range" | "fort" | "filler"
local function Kind(unit)
	local name = unit:GetUnitName()
	local tier = tonumber(string.match(name, "tower(%d)"))
	if tier then return "tower", tier end
	if string.find(name, "melee_rax", 1, true) then return "rax", "melee" end
	if string.find(name, "range_rax", 1, true) then return "rax", "range" end
	if unit:IsFort() or string.find(name, "_fort", 1, true) then return "fort" end
	return "filler"
end

-- bounty-ul din KV (unitatea are 0 dupa Setup)
function M:KVBounty(name)
	local kv = self.kv[name]
	if kv == nil then
		local t = GetUnitKeyValuesByName(name)
		kv = { tonumber(t and t.BountyGoldMin) or 0, tonumber(t and t.BountyGoldMax) or 0 }
		self.kv[name] = kv
	end
	return kv[1], kv[2]
end

function M:LastHitRange(unit, kind)
	local lo, hi = self:KVBounty(unit:GetUnitName())
	if hi <= 0 then
		if kind == "tower" then lo, hi = C.TOWER_LASTHIT_GOLD[1], C.TOWER_LASTHIT_GOLD[2]
		elseif kind == "rax" then lo, hi = C.RAX_LASTHIT_GOLD[1], C.RAX_LASTHIT_GOLD[2] end
	end
	return lo, math.max(lo, hi)
end

-- ruleaza fn cu filtrul de aur deschis; awarding revine pe false si la eroare
function M:Award(fn)
	self.awarding = true
	local ok, err = pcall(fn)
	self.awarding = false
	if not ok then print("[dota688] eroare la aurul cladirilor: " .. tostring(err)) end
end

function M:GiveTeam(team, amount, reason)
	if not IsPlayingTeam(team) or amount <= 0 then return end
	for pid = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PlayerResource:IsValidPlayerID(pid) and PlayerResource:GetTeam(pid) == team and PlayerResource:HasSelectedHero(pid) then
			Dota688GiveGold(pid, amount, true, reason)
		end
	end
end

-- jucatorul care primeste last hit-ul: doar eroi / unitati ale unui jucator (iluzii, summon-uri), nu creepi/turnuri
local function LastHitPlayer(attacker, enemyTeam)
	if not attacker or attacker:IsNull() or attacker:GetTeamNumber() ~= enemyTeam then return -1 end
	if attacker:IsBuilding() then return -1 end
	local pid = attacker.GetPlayerOwnerID and attacker:GetPlayerOwnerID() or -1
	if pid == nil or pid < 0 then return -1 end
	return pid
end

-- Cladiri --------------------------------------------------------------------------------------------------------
-- turn / baraca / Ancient / filler (nu warduri sau alte unitati marcate ca cladiri)
local BUILDING_CLASS_SET = {}
for _, cls in ipairs(C.BUILDING_CLASSES) do BUILDING_CLASS_SET[cls] = true end
local function IsStructure(unit)
	return BUILDING_CLASS_SET[unit:GetClassname()] == true and unit:IsBuilding()
end

function M:AllBuildings(team)
	local list, seen = {}, {}
	for _, cls in ipairs(C.BUILDING_CLASSES) do
		for _, b in ipairs(Entities:FindAllByClassname(cls)) do
			if not b:IsNull() and b.IsBuilding and b:IsBuilding() and not seen[b:GetEntityIndex()]
				and (team == nil or b:GetTeamNumber() == team) then
				seen[b:GetEntityIndex()] = true
				list[#list + 1] = b
			end
		end
	end
	return list
end

-- bounty 0 pe unitate (aurul il dam noi), aura 6.88 pe turnuri in locul celei moderne
function M:SetupBuilding(b)
	if b:IsNull() or not b:IsAlive() then return end
	local lo, hi = self:KVBounty(b:GetUnitName())   -- citit din KV inainte de a pune 0 pe unitate
	if b:IsTower() and not self.loggedTowerBounty then
		self.loggedTowerBounty = true   -- diagnostic: ce bounty pune motorul pe un turn
		print(string.format("[dota688] bounty motor %s: %d-%d (KV %d-%d)", b:GetUnitName(), b:GetMinimumGoldBounty(),
			b:GetMaximumGoldBounty(), lo, hi))
	end
	b:SetMinimumGoldBounty(0)
	b:SetMaximumGoldBounty(0)
	if b:IsTower() then
		for name in pairs(C.ENGINE_TOWER_MODIFIERS) do
			if b:HasModifier(name) then b:RemoveModifierByName(name) end
		end
		if not b:HasModifier("modifier_dota688_tower_aura") then
			b:AddNewModifier(b, nil, "modifier_dota688_tower_aura", {})
		end
	end
end

function M:SetupAll()
	local all = self:AllBuildings(nil)
	for _, b in ipairs(all) do self:SetupBuilding(b) end
	return #all
end

function M:Init(gamemode)
	self.gamemode = gamemode
	self.awarding = false
	self.readyAt = {}            -- echipa -> GameTime de la care glyph-ul e gata (nil = inainte de horn)
	local gm = GameRules:GetGameModeEntity()
	Dota688SafeCall(gm, "SetCustomGlyphCooldown", C.GLYPH_COOLDOWN)
	local n = self:SetupAll()
	print(string.format("[dota688] cladiri: %d (aur 6.88, Tower Protection 6.88, glyph 6.88)", n))
	Dota688Timers:After(1, function() self:SetupAll() end)   -- daca motorul pune aura moderna dupa Init
	Dota688Timers:Every(1, function() self:SyncGlyph() end)
end

function M:OnHorn()
	local now = GameRules:GetGameTime()
	self.readyAt[DOTA_TEAM_GOODGUYS] = now
	self.readyAt[DOTA_TEAM_BADGUYS] = now
	self:SetupAll()
	self:SyncGlyph()
end

-- apelat pentru fiecare unitate din OnNPCSpawned
function M:OnNPCSpawned(unit)
	if unit:GetUnitName() == "npc_dota_roshan" then
		-- last hit-ul il dam noi (OnRoshanKilled), ca sa nu-l dea motorul pe un motiv neblocat
		unit:SetMinimumGoldBounty(0)
		unit:SetMaximumGoldBounty(0)
	elseif IsStructure(unit) then
		self:SetupBuilding(unit)
	end
end

-- apelat din OnEntityKilled pentru orice cladire (killed:IsBuilding())
function M:OnBuildingKilled(building, attacker)
	if building.dota688_paid or not IsStructure(building) then return end
	building.dota688_paid = true
	local team = building:GetTeamNumber()
	local enemy = OtherTeam(team)
	local kind, sub = Kind(building)
	if kind == "tower" and sub == 1 then self:RefreshGlyph(team) end
	if kind == "fort" or not enemy then return end   -- Ancient: fara aur
	local atkTeam = (attacker and not attacker:IsNull()) and attacker:GetTeamNumber() or nil
	local teamGold = 0
	if kind == "tower" then teamGold = C.TOWER_TEAM_GOLD[sub] or 0
	elseif kind == "rax" then teamGold = C.RAX_TEAM_GOLD[sub] or 0 end
	local each, lastHit, lastPid = 0, 0, -1
	if atkTeam == team then
		each = math.floor(teamGold * C.DENY_TEAM_GOLD + 0.5)   -- deny: inamicii primesc jumatate, echipa proprie nimic
	else
		each = teamGold                                        -- distrus de inamici (sau de neutrali): aur de echipa
		lastPid = LastHitPlayer(attacker, enemy)
		if lastPid >= 0 then
			local lo, hi = self:LastHitRange(building, kind)
			if hi > 0 then lastHit = RandomInt(lo, hi) end
		end
	end
	self:Award(function()
		self:GiveTeam(enemy, each, DOTA_ModifyGold_Building)
		if lastHit > 0 then Dota688GiveGold(lastPid, lastHit, true, DOTA_ModifyGold_Building) end
	end)
	print(string.format("[dota688] %s distrus (echipa atacatorului %s): %d aur/jucator echipei %d, last hit %d (jucator %d)",
		building:GetUnitName(), tostring(atkTeam), each, enemy, lastHit, lastPid))
end

-- Roshan: apelat din OnEntityKilled (ramura npc_dota_roshan), pe langa Dota688Roshan:OnRoshanKilled
function M:OnRoshanKilled(roshan, attacker)
	if roshan.dota688_paid then return end
	roshan.dota688_paid = true
	if not attacker or attacker:IsNull() then return end
	local team = attacker:GetTeamNumber()
	if not IsPlayingTeam(team) then return end
	local pid = LastHitPlayer(attacker, team)
	local lastHit = 0
	if pid >= 0 then
		local lo, hi = self:KVBounty(roshan:GetUnitName())
		if hi > 0 then lastHit = RandomInt(lo, math.max(lo, hi)) end
	end
	self:Award(function()
		self:GiveTeam(team, C.ROSHAN_TEAM_GOLD, DOTA_ModifyGold_RoshanKill)
		if lastHit > 0 then Dota688GiveGold(pid, lastHit, true, DOTA_ModifyGold_RoshanKill) end
	end)
	print(string.format("[dota688] Roshan ucis de echipa %d: %d aur/jucator, last hit %d (jucator %d)", team,
		C.ROSHAN_TEAM_GOLD, lastHit, pid))
end

-- Glyph ----------------------------------------------------------------------------------------------------------
function M:GlyphRemaining(team)
	local at = self.readyAt[team]
	if at == nil then
		-- inainte de horn: gata la 0:00
		return math.max(0, -GameRules:GetDOTATime(false, true))
	end
	return math.max(0, at - GameRules:GetGameTime())
end

function M:SyncGlyph()
	local state = GameRules:State_Get()
	if state < DOTA_GAMERULES_STATE_PRE_GAME then return end
	if state >= DOTA_GAMERULES_STATE_POST_GAME then return false end
	for _, team in ipairs({ DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS }) do
		GameRules:SetGlyphCooldown(team, self:GlyphRemaining(team))
	end
end

function M:RefreshGlyph(team)
	if not IsPlayingTeam(team) or self.readyAt[team] == nil then return end
	self.readyAt[team] = GameRules:GetGameTime()
	GameRules:SetGlyphCooldown(team, 0)
end

function M:UseGlyph(team)
	local buildings = self:AllBuildings(team)
	for _, b in ipairs(buildings) do
		if b:IsAlive() then
			b:AddNewModifier(b, nil, "modifier_dota688_glyph", { duration = C.GLYPH_DURATION })
		end
	end
	self.readyAt[team] = GameRules:GetGameTime() + C.GLYPH_COOLDOWN
	GameRules:SetGlyphCooldown(team, C.GLYPH_COOLDOWN)
	-- semnalul de pe minimap al glyph-ului (ca la glyph-ul motorului), pe Ancient-ul echipei
	for _, b in ipairs(buildings) do
		if b:IsFort() then
			local pos = b:GetAbsOrigin()
			pcall(MinimapEvent, team, b, pos.x, pos.y, DOTA_MINIMAP_EVENT_BASE_GLYPHED, C.GLYPH_DURATION)
			break
		end
	end
end

-- Filtre ---------------------------------------------------------------------------------------------------------
-- ordinul de glyph: efectul 6.88 in locul celui al motorului; intoarce false pentru a opri ordinul
function M:OrderFilter(ev)
	if ev.order_type ~= DOTA_UNIT_ORDER_GLYPH then return true end
	local pid = ev.issuer_player_id_const
	local team = (pid ~= nil and pid >= 0) and PlayerResource:GetTeam(pid) or nil
	if IsPlayingTeam(team) and self.readyAt[team] ~= nil and self:GlyphRemaining(team) <= 0 then
		self:UseGlyph(team)
	end
	return false
end

function M:GoldFilter(ev)
	if self.awarding then return true end
	local reason = ev.reason_const
	if reason == DOTA_ModifyGold_Building or reason == DOTA_ModifyGold_RoshanKill then
		return false
	end
	return true
end

-- aura moderna a turnurilor nu se mai aplica (inlocuita de modifier_dota688_tower_aura)
function M:ModifierGainedFilter(ev)
	if C.ENGINE_TOWER_MODIFIERS[ev.name_const] then return false end
	return true
end
