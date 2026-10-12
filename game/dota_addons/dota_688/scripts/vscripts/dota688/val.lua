-- Valoare speciala citita dintr-un modifier: live cat timp abilitatea/itemul exista, altfel ultima valoare citita.
-- Efectele raman si dupa ce sursa dispare (item vandut/combinat, iluzie moarta, spell furat de Rubick inlocuit),
-- iar 6.88 le pastra pana la expirare; fara asta, self:GetAbility() era nil -> "attempt to index a nil value".
function Dota688Val(mod, key)
	local a = mod:GetAbility()
	if a ~= nil and not a:IsNull() then
		local v = a:GetSpecialValueFor(key)
		mod.dota688_vals = mod.dota688_vals or {}
		mod.dota688_vals[key] = v
		return v
	end
	return (mod.dota688_vals and mod.dota688_vals[key]) or 0
end
