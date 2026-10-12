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
		if not c:IsNull() and c:IsAlive() and c:GetTeamNumber() == team then list[#list + 1] = c end
	end
	return list
end

-- item_dota688_courier: "Deploy Courier"
function M:Deploy(item)
	local caster = item:GetCaster()
	local team = caster:GetTeamNumber()
	local c = CreateUnitByName("npc_dota_courier", caster:GetAbsOrigin() + caster:GetForwardVector() * 100, true, nil, nil, team)
	if not c then return end
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
	caster:RemoveItem(item)
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
			-- itemul se scoate dupa think-ul modifier-ului lui
			Dota688Timers:After(0, function() if not item:IsNull() then caster:RemoveItem(item) end end)
			return true
		end
	end
	return false   -- "Requires a deployed Animal Courier": itemul ramane pana exista un curier de sol
end
