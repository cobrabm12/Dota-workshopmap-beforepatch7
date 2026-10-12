require("items/dota688_item_base")
require("dota688/courier")
-- Animal Courier (6.88): Use: Deploy Courier - curierul echipei (vezi dota688/courier.lua).
Dota688DefineItem("item_dota688_courier", "items/item_dota688_courier", {
	item = {
		OnSpellStart = function(self) Dota688Courier:Deploy(self) end,
	},
})
