-- Punctul de intrare al addon-ului "Dota 6.88 Classic".
require("dota688/constants")
require("dota688/util")
require("dota688/gamemode")

function Precache(context)
	-- Eroii si abilitatile built-in se precache-uiesc singure. Aici doar ce e specific addon-ului.
	-- sunete 6.88 al caror eveniment nu mai exista in clientul curent (content/.../soundevents/dota688_sounds.vsndevts)
	PrecacheResource("soundfile", "soundevents/dota688_sounds.vsndevts", context)
end

function Activate()
	GameRules.Dota688 = Dota688()
	GameRules.Dota688:Init()
end
