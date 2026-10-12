-- Rune dupa regulile 6.82-6.88:
--  * doua rune in rau (sus si jos), la fiecare 2 minute, incepand cu 0:00
--  * la 0:00 ambele sunt Bounty (100 aur, 0 XP); apoi una e mereu Bounty, cealalta o runa de putere aleatoare
--  * runele neluate sunt inlocuite la urmatorul spawn
-- Pozitiile vin din harta: entitati "info_target" numite "dota688_rune_top" / "dota688_rune_bot",
-- sau, daca lipsesc, spawner-ele standard Valve (dota_item_rune_spawner_powerup).
local C = DOTA688
Dota688Runes = Dota688Runes or {}
local M = Dota688Runes

function M:Init(gamemode)
	self.gamemode = gamemode
	self.spots = {}
	self.runes = {}
	self.spawnCount = 0
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

-- Valorile runei Bounty: 100 aur la 0:00; apoi 50 + 2/min aur si 50 + 5/min XP.
function M:BountyRuneFilter(ev)
	local minutes = Dota688GameMinutes()
	if self.spawnCount <= 1 then
		ev.gold_bounty = C.RUNE_INITIAL_BOUNTY_GOLD
		ev.xp_bounty = 0
	else
		ev.gold_bounty = C.RUNE_BOUNTY_GOLD_BASE + C.RUNE_BOUNTY_GOLD_PER_MIN * minutes
		ev.xp_bounty = C.RUNE_BOUNTY_XP_BASE + C.RUNE_BOUNTY_XP_PER_MIN * minutes
	end
	return true
end
