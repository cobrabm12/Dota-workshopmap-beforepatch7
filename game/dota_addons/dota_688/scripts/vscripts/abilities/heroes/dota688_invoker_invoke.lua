-- Invoke (6.88): ultimate cu 4 niveluri (invatat la nivelurile 1/6/11/16), cooldown 22/17/12/5, mana 20/40/60/80.
-- Combina cele 3 instante active (ordinea nu conteaza) intr-un spell care intra pe slotul D; spell-ul de pe D trece pe F, cel de pe F
-- dispare (maxim 2 spell-uri invocate). Daca spell-ul e deja pe D/F doar se schimba pozitiile, fara cooldown si fara mana.
-- Scepter: cooldown 16/8/4/2, fara mana (+1 nivel la orbe pentru spell-uri: dota688/aghanim_extras.lua).
-- (Varianta moderna: innata, nivel unic, cooldown redus per nivel de orb, puncte bonus la orbe - nu exista in 6.88.)
require("dota688/aghanim")
dota688_invoker_invoke = class({})

-- numarul de instante Quas, Wex, Exort -> spell
local SPELLS = {
	["3 0 0"] = "invoker_cold_snap",  ["2 1 0"] = "invoker_ghost_walk",   ["2 0 1"] = "invoker_ice_wall",
	["0 3 0"] = "invoker_emp",        ["1 2 0"] = "invoker_tornado",      ["0 2 1"] = "invoker_alacrity",
	["0 0 3"] = "invoker_sun_strike", ["1 0 2"] = "invoker_forge_spirit", ["0 1 2"] = "invoker_chaos_meteor",
	["1 1 1"] = "invoker_deafening_blast",
}
-- ce poate sta pe sloturile D/F (index 3 si 4)
local SLOT_OK = { invoker_empty1 = true, invoker_empty2 = true }
for _, n in pairs(SPELLS) do SLOT_OK[n] = true end

function dota688_invoker_invoke:IsStealable() return false end
function dota688_invoker_invoke:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetLevelSpecialValueFor("cooldown_scepter", level) end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_invoker_invoke:GetManaCost(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetLevelSpecialValueFor("mana_cost_scepter", level) end
	return self.BaseClass.GetManaCost(self, level)
end

-- fara efect sau doar schimb de pozitii: fara cooldown si fara mana
function dota688_invoker_invoke:Refund()
	self:EndCooldown()
	self:RefundManaCost()
end

function dota688_invoker_invoke:OnSpellStart()
	local caster = self:GetCaster()
	local q = #caster:FindAllModifiersByName("modifier_invoker_quas_instance")
	local w = #caster:FindAllModifiersByName("modifier_invoker_wex_instance")
	local e = #caster:FindAllModifiersByName("modifier_invoker_exort_instance")
	local name = SPELLS[q .. " " .. w .. " " .. e]
	local spell = name and caster:FindAbilityByName(name)
	local d, f = caster:GetAbilityByIndex(3), caster:GetAbilityByIndex(4)
	if not spell or not d or not f or not SLOT_OK[d:GetAbilityName()] or not SLOT_OK[f:GetAbilityName()] then
		self:Refund()   -- mai putin de 3 instante sau erou fara sloturile lui Invoker (ex. Rubick)
		return
	end
	if spell == d then self:Refund() return end
	if spell == f then
		caster:SwapAbilities(d:GetAbilityName(), f:GetAbilityName(), true, true)
		self:Refund()
		return
	end
	local fName, dName = f:GetAbilityName(), d:GetAbilityName()
	caster:SwapAbilities(fName, name, false, true)   -- spell-ul nou ia slotul F, vechiul F se ascunde in slotul lui
	caster:SwapAbilities(dName, name, true, true)    -- spell-ul nou trece pe D, vechiul D pe F
	if spell:GetLevel() < 1 then spell:SetLevel(1) end
	caster:EmitSound("Hero_Invoker.Invoke")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_invoker/invoker_invoke.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
end
