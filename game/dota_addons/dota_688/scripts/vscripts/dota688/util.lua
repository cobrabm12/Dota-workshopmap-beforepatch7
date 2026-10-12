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
				t.at = now + ret
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
