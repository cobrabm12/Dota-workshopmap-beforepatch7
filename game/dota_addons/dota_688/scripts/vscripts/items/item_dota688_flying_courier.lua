require("items/dota688_item_base")
require("dota688/courier")
-- Flying Courier (6.88, pasiv): transforma Animal Courier-ul echipei in Flying Courier; necesita un curier de sol.
Dota688DefineItem("item_dota688_flying_courier", "items/item_dota688_flying_courier", {
	onCreated = function(self)
		if IsServer() then self:StartIntervalThink(0.1) end
	end,
	modifier = {
		OnIntervalThink = function(self)
			if Dota688Courier:TryUpgrade(self:GetAbility()) then self:StartIntervalThink(-1) else self:StartIntervalThink(1.0) end
		end,
	},
})
