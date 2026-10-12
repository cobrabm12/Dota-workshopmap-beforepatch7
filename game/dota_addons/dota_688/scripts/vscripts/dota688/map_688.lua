-- Entitatile pe care motorul curent le cere si care lipsesc din harta 6.88.
-- Harta folosita este maps/dota_688.vpk din clientul curent (harta 6.88 recompilata de Valve pentru motorul actual,
-- cu trigger-ele de shop / no-wards / camp-uri intacte), copiata in addon ca maps/dota.vpk de tools/import_harta_688.py.
-- Ea are entitatile din 2016, deci aici se adauga (o singura data, la Activate):
--   * info_courier_spawn_radiant_1..5 / dire_1..5: motorul curent pune cate un curier pe jucator si cade la PRE_GAME
--     fara ele (testat); toate in punctul de curier al echipei;
--   * info_player_start_dota "roshan_location_1/2": pozitiile intre care Roshan se muta din 7.33; ambele in groapa
--     6.88, ca Roshan sa ramana pe loc;
--   * info_target "dota688_rune_top/bot": punctele de rune 6.88 (dota_item_rune_spawner din 2016 nu mai exista ca
--     clasa), cautate de runes.lua.
Dota688Map = Dota688Map or {}
local M = Dota688Map

-- coordonatele din harta 6.88 (entitatile dota_item_rune_spawner si npc_dota_roshan_spawner)
M.RUNE_SPOTS = {
	dota688_rune_top = "-2237.414307 1620.966675 176",
	dota688_rune_bot = "2812.585693 -2241.033203 176",
}
M.ROSHAN_PIT = "4320 -1824 168"

local function vec_str(v)
	return string.format("%f %f %f", v.x, v.y, v.z)
end

function M:Ensure()
	local added = 0
	for name, origin in pairs(self.RUNE_SPOTS) do
		if Entities:FindByName(nil, name) == nil then
			SpawnEntityFromTableSynchronous("info_target", { targetname = name, origin = origin })
			added = added + 1
		end
	end
	for _, team in ipairs({ "radiant", "dire" }) do
		local base = Entities:FindByClassname(nil, "info_courier_spawn_" .. team)
		for i = 1, 5 do
			local cls = "info_courier_spawn_" .. team .. "_" .. i
			if base ~= nil and Entities:FindByClassname(nil, cls) == nil then
				SpawnEntityFromTableSynchronous(cls, { origin = vec_str(base:GetAbsOrigin()) })
				added = added + 1
			end
		end
	end
	for i = 1, 2 do
		local name = "roshan_location_" .. i
		if Entities:FindByName(nil, name) == nil then
			SpawnEntityFromTableSynchronous("info_player_start_dota", { targetname = name, origin = self.ROSHAN_PIT })
			added = added + 1
		end
	end
	print(string.format("[dota688] harta %s: %d entitati adaugate (curieri, pozitii Roshan, puncte de rune)", GetMapName(), added))
end
