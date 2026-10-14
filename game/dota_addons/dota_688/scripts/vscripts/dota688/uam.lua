-- Unique Attack Modifiers (orb effects) dupa regulile 6.88 (Dota 2 Wiki, "Unique Attack Modifier", noiembrie 2016):
--  * pe un atac se aplica un singur UAM; prioritate:
--      1. conditionale: Maelstrom / Mjollnir, doar cand Chain Lightning se declanseaza pe acel atac;
--      2. abilitatile eroului: Mana Break, Frost Arrows, Liquid Fire, Arcane Orb, Caustic Finale;
--      3. itemele: cel mai vechi din inventar (iluziile: primul slot in ordinea citirii);
--  * exceptii: Eye of Skadi + lifesteal se aplica impreuna; Liquid Fire + Eye of Skadi la fel;
--  * daca tinta e imuna la UAM-ul prioritar (ex. cladire pentru Skadi / lifesteal), se foloseste urmatorul care o afecteaza.
-- Sursele item (Lua) nu aplica efectul direct: il trimit aici (Queue) in OnAttackLanded, iar in cadrul urmator se alege
-- ce se aplica pentru acel atac. Asa sunt vazute si sursele motorului din acelasi cadru (Chain Lightning, Frost Arrows).
Dota688UAM = Dota688UAM or { pending = {} }
local M = Dota688UAM

-- itemele Lua care sunt UAM: tipul efectului
M.ITEM_KIND = {
	item_dota688_lifesteal = "lifesteal", item_dota688_mask_of_madness = "lifesteal", item_dota688_satanic = "lifesteal",
	item_dota688_helm_of_the_dominator = "lifesteal",
	item_dota688_skadi = "skadi",
	item_dota688_desolator = "corruption", item_dota688_blight_stone = "corruption",
	item_dota688_diffusal_blade = "feedback", item_dota688_diffusal_blade_2 = "feedback",
	item_dota688_orb_of_venom = "venom",
}
-- debuff-urile puse de orb-urile built-in ale eroilor (arata daca orb-ul s-a aplicat pe atac)
M.ORB_DEBUFF = {
	drow_ranger_frost_arrows = "modifier_drow_ranger_frost_arrows_slow",
	jakiro_liquid_fire = "modifier_jakiro_liquid_fire_burn",
}
M.CHAIN_ITEMS = { item_maelstrom = true, item_mjollnir = true }

-- tinta poate fi afectata de un item de tipul dat? (Skadi si lifesteal nu merg pe cladiri, Corruption da)
local function Affects(kind, target)
	if target:IsBuilding() or target:IsOther() then return kind == "corruption" end
	return true
end

-- Chain Lightning (din DamageFilter): atacatorul a declansat un UAM conditional in acest cadru
function M:OnDamage(ev)
	local inflictor = ev.entindex_inflictor_const and EntIndexToHScript(ev.entindex_inflictor_const)
	local attacker = ev.entindex_attacker_const and EntIndexToHScript(ev.entindex_attacker_const)
	if inflictor and attacker and inflictor.GetAbilityName and self.CHAIN_ITEMS[inflictor:GetAbilityName()] then
		attacker.dota688_chain_time = GameRules:GetGameTime()
	end
end

-- Arcane Orb (Lua) anunta ca s-a aplicat pe atacul curent
function M:MarkAbilityOrb(attacker)
	attacker.dota688_orb_time = GameRules:GetGameTime()
end

local function JustApplied(target, modName, caster)
	for _, m in ipairs(target:FindAllModifiersByName(modName)) do
		if (not caster or m:GetCaster() == caster) and m:GetDuration() > 0 and m:GetDuration() - m:GetRemainingTime() < 0.1 then return true end
	end
	return false
end

-- UAM-ul unei abilitati a eroului s-a aplicat pe acest atac? Intoarce numele abilitatii (sau nil).
function M:AbilityOrb(attacker, target, t)
	if attacker.dota688_orb_time and math.abs(attacker.dota688_orb_time - t) < 0.06 then return "arcane_orb" end
	for name, mod in pairs(self.ORB_DEBUFF) do
		local a = attacker:FindAbilityByName(name)
		if a and a:GetLevel() > 0 and JustApplied(target, mod, attacker) then return name end
	end
	if not attacker:PassivesDisabled() and not target:IsBuilding() and not target:IsOther() then
		local mb = attacker:FindAbilityByName("antimage_mana_break")
		if mb and mb:GetLevel() > 0 and target:GetMaxMana() > 0 and not target:IsMagicImmune() then return "antimage_mana_break" end
		local cf = attacker:FindAbilityByName("dota688_sandking_caustic_finale")
		if cf and cf:GetLevel() > 0 and not target:IsMagicImmune() and target:GetTeamNumber() ~= attacker:GetTeamNumber() then return "caustic_finale" end
	end
	return nil
end

-- itemele UAM din inventar, in ordinea prioritatii (cel mai vechi primul; iluziile: ordinea sloturilor)
function M:Items(unit)
	local list = {}
	for s = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
		local it = unit:GetItemInSlot(s)
		if it and self.ITEM_KIND[it:GetAbilityName()] then list[#list + 1] = { item = it, slot = s, t = it:GetPurchaseTime() } end
	end
	if not unit:IsIllusion() then
		table.sort(list, function(a, b) if a.t ~= b.t then return a.t < b.t end return a.slot < b.slot end)
	end
	return list
end

-- multimea itemelor (entindex -> true) ale caror efecte se aplica pe acest atac
function M:Decide(attacker, target, t)
	local allowed = {}
	if attacker.dota688_chain_time and math.abs(attacker.dota688_chain_time - t) < 0.06 then return allowed end
	local orb = self:AbilityOrb(attacker, target, t)
	local first
	for _, e in ipairs(self:Items(attacker)) do
		local kind = self.ITEM_KIND[e.item:GetAbilityName()]
		if Affects(kind, target) then
			if orb then
				-- Liquid Fire se combina cu Eye of Skadi
				if orb == "jakiro_liquid_fire" and kind == "skadi" then allowed[e.item:entindex()] = true; break end
			elseif not first then
				first = kind
				allowed[e.item:entindex()] = true
			elseif (first == "lifesteal" and kind == "skadi") or (first == "skadi" and kind == "lifesteal") then
				-- exceptia 6.88: Skadi + lifesteal
				allowed[e.item:entindex()] = true
				first = "both"
			end
		end
	end
	return allowed, orb
end

-- item: itemul sursa; fn(): efectul de aplicat daca itemul castiga atacul
function M:Queue(attacker, target, item, fn)
	if not IsServer() then return end
	local t = GameRules:GetGameTime()
	local key = attacker:entindex() .. ":" .. target:entindex() .. ":" .. t
	local p = self.pending[key]
	if not p then
		p = { list = {} }
		self.pending[key] = p
		Dota688Timers:After(0, function()
			self.pending[key] = nil
			if attacker:IsNull() or target:IsNull() then return end
			local allowed = self:Decide(attacker, target, t)
			for _, e in ipairs(p.list) do
				if not e.item:IsNull() and allowed[e.item:entindex()] then
					local ok, err = pcall(e.fn)
					if not ok then print("[dota688] UAM: eroare la " .. e.item:GetAbilityName() .. ": " .. tostring(err)) end
				end
			end
		end)
	end
	table.insert(p.list, { item = item, fn = fn })
end
