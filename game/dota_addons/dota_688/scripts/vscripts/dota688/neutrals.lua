-- Neutrali (6.88): primul spawn la 0:30, apoi la fiecare minut. Motorul curent face primul spawn la 1:00.
-- Incercam sa fortam un spawn suplimentar la 0:30 prin input-ul entitatilor npc_dota_neutral_spawner.
Dota688Neutrals = Dota688Neutrals or {}
local M = Dota688Neutrals

function M:Init(gamemode)
	self.gamemode = gamemode
end

function M:OnHorn()
	Dota688Timers:After(30, function()
		local spawners = Entities:FindAllByClassname("npc_dota_neutral_spawner")
		local ok = 0
		for _, s in ipairs(spawners) do
			-- numele input-ului nu este documentat oficial; incercam variantele cunoscute
			for _, input in ipairs({ "SpawnNow", "ForceSpawn", "Spawn" }) do
				if pcall(DoEntFireByInstanceHandle, s, input, "", 0, nil, nil) then ok = ok + 1; break end
			end
		end
		print("[dota688] neutrali 0:30: " .. ok .. "/" .. #spawners .. " spawnere notificate")
	end)
end
