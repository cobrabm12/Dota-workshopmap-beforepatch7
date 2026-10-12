-- Timere simple pe baza GetGameTime (se opresc cand jocul e pe pauza).
Dota688Timers = Dota688Timers or { list = {}, nextId = 1, started = false }

function Dota688Timers:Start()
	if self.started then return end
	self.started = true
	GameRules:GetGameModeEntity():SetContextThink("Dota688Timers", function() return self:Think() end, 0)
end

function Dota688Timers:Think()
	local now = GameRules:GetGameTime()
	for id, t in pairs(self.list) do
		if now >= t.at then
			local ok, ret = pcall(t.fn)
			if not ok then
				print("[dota688] eroare in timer " .. tostring(id) .. ": " .. tostring(ret))
				self.list[id] = nil
			elseif type(ret) == "number" then
				-- cadenta fixa (fara deriva de pana la 0.05 s pe tick): aurul pasiv la 0.6 s ramane 100/min
				t.at = math.max(t.at + ret, now)
			else
				self.list[id] = nil
			end
		end
	end
	return 0.05
end

-- fn poate returna un numar (secunde pana la urmatoarea rulare) ca sa se repete
function Dota688Timers:After(delay, fn)
	local id = self.nextId
	self.nextId = id + 1
	self.list[id] = { at = GameRules:GetGameTime() + (delay or 0), fn = fn }
	return id
end

function Dota688Timers:Every(interval, fn)
	return self:After(interval, function()
		if fn() == false then return nil end
		return interval
	end)
end

function Dota688Timers:Stop(id)
	if id then self.list[id] = nil end
end

-- Apel sigur al unei metode a GameMode-ului care poate lipsi in versiuni mai vechi/noi ale API-ului.
function Dota688SafeCall(obj, method, ...)
	local f = obj and obj[method]
	if type(f) ~= "function" then
		print("[dota688] API lipsa: " .. tostring(method))
		return nil
	end
	local ok, err = pcall(f, obj, ...)
	if not ok then print("[dota688] eroare " .. tostring(method) .. ": " .. tostring(err)) end
	return ok
end

function Dota688GameMinutes()
	return math.max(0, math.floor(GameRules:GetDOTATime(false, false) / 60))
end

-- UTIL_Remove pe o unitate inghetata intr-un Chronosphere activ face motorul sa cada (testat in testul de fum, Workshop
-- Tools). Unitatea e ascunsa si facuta invulnerabila imediat, iar UTIL_Remove vine dupa ce se termina Chronosphere-ul.
local function in_chronosphere(u)
	for _, m in ipairs(u:FindAllModifiers()) do
		if string.find(m:GetName(), "chronosphere", 1, true) then return true end
	end
	return false
end

function Dota688SafeRemove(u)
	if u == nil or u:IsNull() then return end
	if not in_chronosphere(u) then UTIL_Remove(u); return end
	u:AddNoDraw()
	u:AddNewModifier(u, nil, "modifier_invulnerable", {})
	Dota688Timers:Every(0.5, function()
		if u:IsNull() then return false end
		if in_chronosphere(u) then return true end
		UTIL_Remove(u)
		return false
	end)
end
