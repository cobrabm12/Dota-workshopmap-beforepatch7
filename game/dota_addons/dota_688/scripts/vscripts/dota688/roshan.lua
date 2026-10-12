-- Roshan 6.88: statistici prin npc_units_custom.txt; crestere la 4 minute si drop-uri gestionate aici.
local C = DOTA688
Dota688Roshan = Dota688Roshan or {}
local M = Dota688Roshan

function M:Init(gamemode)
	self.gamemode = gamemode
	self.deaths = 0
end

function M:OnRoshanSpawned(roshan)
	if not roshan:HasModifier("modifier_dota688_roshan") then
		roshan:AddNewModifier(roshan, nil, "modifier_dota688_roshan", {})
	end
end

function M:OnRoshanKilled(roshan, attacker)
	self.deaths = self.deaths + 1
	local deaths = self.deaths
	local pos = roshan:GetAbsOrigin()
	-- motorul lasa pe jos drop-urile moderne; le scoatem pe cele care nu existau in 6.88
	Dota688Timers:After(0.1, function()
		local drops = Entities:FindAllByClassnameWithin("dota_item_drop", pos, 600)
		for _, drop in ipairs(drops) do
			local item = drop:GetContainedItem()
			if item then
				local name = item:GetAbilityName()
				local remove = false
				for _, bad in ipairs(C.ROSHAN_EXTRA_DROPS) do
					if name == bad then remove = true end
				end
				if name == "item_cheese" and deaths < C.ROSHAN_CHEESE_FROM_DEATH then remove = true end
				if remove then
					UTIL_Remove(item)
					UTIL_Remove(drop)
				end
			end
		end
	end)
end
