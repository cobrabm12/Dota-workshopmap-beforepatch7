-- Modifierii Lua ai runelor de putere 6.88 (modifiers/modifier_dota688_runes.lua). Trebuie legati si pe client
-- (require din dota688/modifiers_link.lua), altfel clientul nu are clasa modifier-ului: fara invizibilitate
-- randata, fara viteza/tooltip pe HUD.
for _, m in ipairs({ "modifier_dota688_rune_doubledamage", "modifier_dota688_rune_haste", "modifier_dota688_rune_invis",
	"modifier_dota688_rune_regen", "modifier_dota688_rune_arcane" }) do
	LinkLuaModifier(m, "modifiers/modifier_dota688_runes", LUA_MODIFIER_MOTION_NONE)
end
