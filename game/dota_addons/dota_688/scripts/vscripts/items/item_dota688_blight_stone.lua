require("items/dota688_item_base")
require("items/item_dota688_desolator")
-- Blight Stone (6.88): Corruption -2 armura 8 s (Unique Attack Modifier, vezi dota688/uam.lua).
Dota688DefineItem("item_dota688_blight_stone", "items/item_dota688_blight_stone", { onAttackLanded = Dota688Corruption })
