-- Neutrali (6.88): primul spawn la 0:30, apoi verificare la fiecare minut (x:00); un camp reapare doar daca volumul
-- lui (trigger_multiple neutralcamp_*, din harta) e gol. Motorul curent face primul spawn la 1:00:
-- GameRules:SetNeutralInitialSpawnOffset muta doar primul spawn.
local C = DOTA688
Dota688Neutrals = Dota688Neutrals or {}
local M = Dota688Neutrals

function M:Init(gamemode)
	self.gamemode = gamemode
	Dota688SafeCall(GameRules, "SetNeutralInitialSpawnOffset", C.NEUTRAL_FIRST_SPAWN_OFFSET)
end

function M:OnHorn()
	-- verificare in consola: cati neutrali exista dupa primul spawn
	Dota688Timers:After(31, function()
		local n = #Entities:FindAllByClassname("npc_dota_creep_neutral")
		print(string.format("[dota688] neutrali la 0:31: %d (spawnere: %d)", n, #Entities:FindAllByClassname("npc_dota_neutral_spawner")))
	end)
end
