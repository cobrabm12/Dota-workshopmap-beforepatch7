-- Divided We Stand ca in 6.88: clonele lui Meepo au doar cizmele lui Meepo (si bonusurile lor).
-- 6.88: "the clones cannot wield any items but the boots that Meepo himself wears"; Note0: "Clones can't use Arcane
-- Boots or pick up runes." Atributele: 20% (100% cu scepter) din atributele bonus date de iteme lui Meepo
-- (modifier_dota688_meepo_share, dota688/aghanim_extras.lua).
-- Motorul curent pune pe clona modifierii tuturor itemelor lui Meepo (testat: Claymore +21, Desolator, Skadi):
--   A. ModifierGainedFilter: pe clona se refuza modifierii itemelor care nu sunt cizme (pasivul itemului sau pusi de clona);
--      efectele venite de la Meepo (aure, Mekansm) au caster = Meepo si raman.
--   B. modifier_dota688_meepo_clone_items: aceeasi regula la 0.1 s, pentru ce scapa de filtru.
--   C. OrderFilter: clona nu foloseste iteme (doar cizmele, fara Arcane Boots / Guardian Greaves), nu arunca / da / muta /
--      vinde / ridica iteme si nu ia rune.
-- Clona e marcata ca atare (IsClone) abia dupa npc_spawned, deci modifierii ei se pun in cadrul urmator (OnSpawned).
Dota688Meepo688 = Dota688Meepo688 or {}
local M = Dota688Meepo688
local F = "dota688/meepo_688"
local MOD = "modifier_dota688_meepo_clone_items"
LinkLuaModifier(MOD, F, LUA_MODIFIER_MOTION_NONE)

-- cizmele 6.88 (numele din addon + cele built-in, in caz ca apar)
M.BOOTS = {
	item_boots = true, item_arcane_boots = true,
	item_dota688_phase_boots = true, item_dota688_power_treads = true, item_dota688_tranquil_boots = true,
	item_dota688_travel_boots = true, item_dota688_travel_boots_2 = true, item_dota688_guardian_greaves = true,
	item_phase_boots = true, item_power_treads = true, item_tranquil_boots = true,
	item_travel_boots = true, item_travel_boots_2 = true, item_guardian_greaves = true,
}
-- cizme pe care clona le are (bonusurile) dar nu le poate folosi activ (6.88 Note0: Arcane Boots; Greaves = Arcane + Mekansm)
M.NO_ACTIVE = { item_arcane_boots = true, item_dota688_guardian_greaves = true, item_guardian_greaves = true }

function M.IsClone(u)
	return u ~= nil and not u:IsNull() and u.IsClone ~= nil and u:IsClone() and u:GetUnitName() == "npc_dota_hero_meepo"
end

local function IsItemAbility(a)
	return a ~= nil and not a:IsNull() and a.IsItem ~= nil and a:IsItem()
end

local function IntrinsicName(item)
	local ok, n = pcall(function() return item:GetIntrinsicModifierName() end)
	if ok and type(n) == "string" and n ~= "" then return n end
	return "modifier_" .. item:GetAbilityName()
end

-- true daca efectul itemului nu trebuie sa se aplice pe unitate (clona Meepo + item care nu e cizma)
function M.CloneIgnoresItem(unit, item)
	if not IsItemAbility(item) or not M.IsClone(unit) then return false end
	return not M.BOOTS[item:GetAbilityName()]
end

-- modifierul (nume, item, caster) de pe clona vine din pasivul unui item interzis?
local function Forbidden(clone, name, item, caster)
	if not IsItemAbility(item) or M.BOOTS[item:GetAbilityName()] then return false end
	if name == IntrinsicName(item) then return true end
	return caster == clone
end

------------------------------------------------------------------------------------------------
-- A. filtrul de modifieri (din Dota688:ModifierGainedFilter)
function M.ModifierGainedFilter(ev)
	local parent = ev.entindex_parent_const and EntIndexToHScript(ev.entindex_parent_const)
	if not M.IsClone(parent) then return true end
	local item = ev.entindex_ability_const and EntIndexToHScript(ev.entindex_ability_const)
	local caster = ev.entindex_caster_const and EntIndexToHScript(ev.entindex_caster_const)
	return not Forbidden(parent, ev.name_const, item, caster)
end

------------------------------------------------------------------------------------------------
-- B. modifier pe clona: scoate ce a scapat de filtru
modifier_dota688_meepo_clone_items = class({})
function modifier_dota688_meepo_clone_items:IsHidden() return true end
function modifier_dota688_meepo_clone_items:IsPurgable() return false end
function modifier_dota688_meepo_clone_items:RemoveOnDeath() return false end
function modifier_dota688_meepo_clone_items:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_dota688_meepo_clone_items:OnCreated()
	if not IsServer() then return end
	self.window, self.count = GameRules:GetGameTime(), 0
	self:OnIntervalThink()
	self:StartIntervalThink(0.1)
end
function modifier_dota688_meepo_clone_items:OnIntervalThink()
	local p = self:GetParent()
	if not M.IsClone(p) then return end
	local n = 0
	for _, m in ipairs(p:FindAllModifiers()) do
		if not m:IsNull() and m ~= self and Forbidden(p, m:GetName(), m:GetAbility(), m:GetCaster()) then
			m:Destroy()
			n = n + 1
		end
	end
	if n == 0 then return end
	p:CalculateStatBonus(true)
	-- daca motorul le pune la loc continuu (pasivele reaplicate in fiecare cadru), semnalam o data
	local now = GameRules:GetGameTime()
	if now - self.window > 10 then self.window, self.count = now, 0 end
	self.count = self.count + n
	if self.count > 100 and not self.warned then
		self.warned = true
		print("[dota688] meepo_688: motorul reaplica pasivele itemelor pe clona #" .. p:entindex() .. " (" .. self.count .. " in 10 s)")
	end
end

-- 4. din Dota688:OnNPCSpawned (si la respawn: modifierul e permanent, nu se dubleaza)
function M.OnSpawned(unit)
	if not unit or unit:IsNull() or unit:GetUnitName() ~= "npc_dota_hero_meepo" then return end
	Dota688Timers:After(0.1, function()
		if not M.IsClone(unit) then return end
		if not unit:HasModifier(MOD) then unit:AddNewModifier(unit, nil, MOD, {}) end
		if not unit:HasModifier("modifier_dota688_meepo_share") then unit:AddNewModifier(unit, nil, "modifier_dota688_meepo_share", {}) end
	end)
end

------------------------------------------------------------------------------------------------
-- C. filtrul de ordine (din Dota688:OrderFilter)
local function OrderSet(names)
	local s = {}
	for _, n in ipairs(names) do if _G[n] then s[_G[n]] = true end end
	return s
end
local CAST_ORDERS = OrderSet({ "DOTA_UNIT_ORDER_CAST_POSITION", "DOTA_UNIT_ORDER_CAST_TARGET", "DOTA_UNIT_ORDER_CAST_TARGET_TREE",
	"DOTA_UNIT_ORDER_CAST_NO_TARGET", "DOTA_UNIT_ORDER_CAST_TOGGLE", "DOTA_UNIT_ORDER_CAST_TOGGLE_AUTO", "DOTA_UNIT_ORDER_CAST_RUNE",
	"DOTA_UNIT_ORDER_CAST_TOGGLE_ALT" })
-- 6.88: clona nu are inventar propriu si nu ia rune
local ITEM_ORDERS = OrderSet({ "DOTA_UNIT_ORDER_DROP_ITEM", "DOTA_UNIT_ORDER_GIVE_ITEM", "DOTA_UNIT_ORDER_PICKUP_ITEM",
	"DOTA_UNIT_ORDER_PICKUP_RUNE", "DOTA_UNIT_ORDER_SELL_ITEM", "DOTA_UNIT_ORDER_DISASSEMBLE_ITEM", "DOTA_UNIT_ORDER_MOVE_ITEM",
	"DOTA_UNIT_ORDER_EJECT_ITEM_FROM_STASH" })
function M.OrderFilter(ev)
	local unit = ev.units and ev.units["0"] and EntIndexToHScript(ev.units["0"])
	if not M.IsClone(unit) then return true end
	if ITEM_ORDERS[ev.order_type] then return false end
	if CAST_ORDERS[ev.order_type] and ev.entindex_ability and ev.entindex_ability > 0 then
		local a = EntIndexToHScript(ev.entindex_ability)
		if IsItemAbility(a) then
			local name = a:GetAbilityName()
			if not M.BOOTS[name] or M.NO_ACTIVE[name] then return false end
		end
	end
	return true
end

------------------------------------------------------------------------------------------------
-- 6. (optional) atributele date de cizme (Power Treads) - pentru modifier_dota688_meepo_share
function M.BootAttributes(unit)
	local s, a, i = 0, 0, 0
	if not unit or unit:IsNull() then return s, a, i end
	for _, m in ipairs(unit:FindAllModifiers()) do
		local item = m:GetAbility()
		if IsItemAbility(item) and M.BOOTS[item:GetAbilityName()] and m:GetName() == IntrinsicName(item) then
			if m.GetModifierBonusStats_Strength then s = s + (m:GetModifierBonusStats_Strength() or 0) end
			if m.GetModifierBonusStats_Agility then a = a + (m:GetModifierBonusStats_Agility() or 0) end
			if m.GetModifierBonusStats_Intellect then i = i + (m:GetModifierBonusStats_Intellect() or 0) end
		end
	end
	return s, a, i
end

------------------------------------------------------------------------------------------------
-- Diagnostic: ce primesc clonele de la motor (rulat din consola cu "script Dota688Meepo688.Dump()")
function M.Dump()
	for _, u in ipairs(Entities:FindAllByClassname("npc_dota_hero_meepo")) do
		if M.IsClone(u) then
			local main = u:GetCloneSource()
			print(string.format("[meepo_688] clona #%d (Meepo #%d)", u:entindex(), main and main:entindex() or -1))
			for s = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
				local it = u:GetItemInSlot(s)
				local mit = main and main:GetItemInSlot(s)
				if it or mit then
					print(string.format("  slot %d: clona %s #%d | Meepo %s #%d | aceeasi entitate: %s", s,
						it and it:GetAbilityName() or "-", it and it:entindex() or -1,
						mit and mit:GetAbilityName() or "-", mit and mit:entindex() or -1, tostring(it ~= nil and it == mit)))
				end
			end
			for _, m in ipairs(u:FindAllModifiers()) do
				local a, c = m:GetAbility(), m:GetCaster()
				if IsItemAbility(a) then
					print(string.format("  %s <- %s (intrinsec %s), caster %s #%d, interzis: %s", m:GetName(), a:GetAbilityName(),
						IntrinsicName(a), c and c:GetUnitName() or "-", c and c:entindex() or -1, tostring(Forbidden(u, m:GetName(), a, c))))
				end
			end
		end
	end
end
