-- Punctul de intrare al addon-ului "Dota 6.88 Classic".
require("dota688/constants")
require("dota688/util")
require("dota688/gamemode")

function Precache(context)
	-- Eroii si abilitatile built-in se precache-uiesc singure. Aici doar ce e specific addon-ului.
end

function Activate()
	GameRules.Dota688 = Dota688()
	GameRules.Dota688:Init()
end
