-- Ciclu zi/noapte de 4 + 4 minute (6.79-7.19). Motorul are 5 + 5; emulam prin SetTimeOfDay.
local C = DOTA688
Dota688DayNight = Dota688DayNight or {}
local M = Dota688DayNight

function M:Init(gamemode)
	self.gamemode = gamemode
end

function M:OnHorn()
	if not C.EMULATE_DAY_NIGHT then return end
	local full = C.DAY_NIGHT_HALF_CYCLE * 2
	Dota688Timers:Every(0.5, function()
		if GameRules:IsNightstalkerNight() then return end   -- noaptea fortata de abilitati are prioritate
		local t = GameRules:GetDOTATime(false, false)
		-- 0.25 = rasarit; 0:00 este primul rasarit
		local tod = (0.25 + (t % full) / full) % 1.0
		GameRules:SetTimeOfDay(tod)
	end)
end
