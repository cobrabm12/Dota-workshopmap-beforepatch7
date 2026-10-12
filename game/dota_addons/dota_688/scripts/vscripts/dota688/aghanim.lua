-- Aghanim's Scepter dupa 6.88.
--
-- Scepter-ul este un item propriu (item_dota688_ultimate_scepter, +10 toate atributele, +175 HP, +175 mana);
-- itemul built-in nu mai e cumparabil, deci C++-ul nu mai vede niciun "HasScepter()" de la sine.
-- Cat timp eroul tine itemul (sau a primit un scepter de la Alchemist), are modifier_dota688_scepter, care:
--   * BUILTIN  – la eroii la care upgrade-ul C++ actual este (aproape) identic cu cel din 6.88, adauga
--                modifier_item_ultimate_scepter_consumed, ca sa se activeze upgrade-ul built-in;
--   * GRANT    – deblocheaza abilitatile care in 6.88 erau oferite de scepter (Assimilate, Hybrid, Chakram 2...);
--   * HOOKS    – pentru abilitatile C++ la care 6.88 schimba doar cooldown / mana / cast range / attack range,
--                aplica aceste valori din Lua (dupa cast, respectiv prin bonus de cast range pe abilitate);
--   * abilitatile reimplementate in Lua verifica singure Dota688HasScepter(caster) (Omnislash, Grow, Marksmanship...).
-- Lista completa, pe eroi: docs/AGHANIM.md

Dota688Aghanim = Dota688Aghanim or {}
local AG = Dota688Aghanim
AG.ITEM = "item_dota688_ultimate_scepter"
AG.MODIFIER = "modifier_dota688_scepter"
AG.CONSUMED = "modifier_item_ultimate_scepter_consumed"

-- eroi la care upgrade-ul C++ actual = 6.88 (restul ultimate-urilor cu scepter sunt rescrise in Lua; vezi docs/AGHANIM.md)
AG.BUILTIN = {
	npc_dota_hero_earthshaker = true,     -- Enchant Totem: saritura de 900
	npc_dota_hero_witch_doctor = true,    -- Death Ward: atacurile sar intre inamici
	npc_dota_hero_tidehunter = true,      -- Gush in linie, cooldown redus
	npc_dota_hero_weaver = true,          -- Time Lapse pe aliat (cooldown 16 prin HOOKS)
	npc_dota_hero_batrider = true,        -- Lasso prinde si cel mai apropiat erou aliat
	npc_dota_hero_undying = true,         -- Decay fura mai mult STR
	npc_dota_hero_phoenix = true,         -- Supernova pe aliat, mai multe atacuri necesare
	npc_dota_hero_winter_wyvern = true,   -- Arctic Burn toggle
	npc_dota_hero_silencer = true,        -- Global Silence aplica Arcane Curse
	npc_dota_hero_shadow_demon = true,    -- Demonic Purge: 3 incarcaturi + break
	npc_dota_hero_nyx_assassin = true,    -- Burrow (abilitate oferita de scepter)
	npc_dota_hero_earth_spirit = true,    -- Enchant Remnant (abilitate oferita de scepter)
}

-- abilitati oferite de scepter in 6.88, deblocate din Lua (fara efecte secundare moderne)
AG.GRANT = {
	npc_dota_hero_life_stealer = { "life_stealer_assimilate" },
	npc_dota_hero_ogre_magi = { "ogre_magi_unrefined_fireblast" },
	npc_dota_hero_tusk = { "tusk_walrus_kick" },
	npc_dota_hero_treant = { "dota688_treant_eyes_in_the_forest" },
	npc_dota_hero_shredder = { "shredder_chakram_2" },
	npc_dota_hero_morphling = { "morphling_hybrid" },
}

-- abilitati C++ la care scepter-ul 6.88 schimba cooldown-ul / mana / cast range / attack range
-- (valorile din reference/6.88f/npc_abilities.txt, pe nivel; cast_range = bonus fata de raza de baza)
AG.HOOKS = {
	beastmaster_primal_roar      = { cooldown = { 45, 45, 45 }, cast_range = { 350, 350, 350 } },  -- 600 -> 950
	faceless_void_chronosphere   = { cooldown = { 60, 60, 60 } },
	rattletrap_hookshot          = { cooldown = { 12, 12, 12 } },
	weaver_time_lapse            = { cooldown = { 16, 16, 16 } },
	rubick_spell_steal           = { cooldown = { 2, 2, 2 }, cast_range = { 400, 400, 400 } },     -- 1000 -> 1400
	viper_viper_strike           = { cooldown = { 10, 10, 10 }, mana = { 125, 125, 125 }, cast_range = { 400, 400, 400 } },  -- 500 -> 900
	enchantress_impetus          = { attack_range = 190, cast_range = { 190, 190, 190 } },
	invoker_invoke               = { cooldown = { 16, 8, 4, 2 }, mana = { 0, 0, 0, 0 } },
}

local function level_value(tbl, level)
	if type(tbl) ~= "table" then return tbl end
	return tbl[math.max(1, math.min(level, #tbl))]
end

function Dota688HasScepter(unit)
	return unit ~= nil and not unit:IsNull() and unit:HasModifier(AG.MODIFIER)
end

-- are eroul vreun scepter (item in inventarul activ sau unul primit de la Alchemist)?
function AG.ShouldHave(unit)
	if unit.dota688_scepter_granted then return true end
	return unit:HasModifier("modifier_" .. AG.ITEM)
end

function AG.Refresh(unit)
	if not unit or unit:IsNull() or not unit:IsRealHero() then return end
	local want = AG.ShouldHave(unit)
	local has = unit:HasModifier(AG.MODIFIER)
	if want and not has then
		unit:AddNewModifier(unit, nil, AG.MODIFIER, {})
	elseif has and not want then
		unit:RemoveModifierByName(AG.MODIFIER)
	end
	local m = unit:FindModifierByName(AG.MODIFIER)
	if m then m:SetStackCount(unit.dota688_scepter_granted and 1 or 0) end
end

-- scepter permanent (Alchemist l-a "topit" pentru aliat)
function AG.GrantPermanent(unit)
	if not unit or unit:IsNull() then return end
	unit.dota688_scepter_granted = true
	AG.Refresh(unit)
end

-- apelat de modifierul itemului la creare / distrugere (distrugerea se verifica pe tick-ul urmator)
function AG.OnItemChanged(unit)
	if not unit or unit:IsNull() then return end
	AG.Refresh(unit)
	Dota688Timers:After(0, function() AG.Refresh(unit) end)
end

------------------------------------------------------------------------------------------------
modifier_dota688_scepter = class({})
local M = modifier_dota688_scepter
function M:IsHidden() return self:GetStackCount() == 0 end   -- vizibil doar cand e primit de la Alchemist
function M:IsPurgable() return false end
function M:RemoveOnDeath() return false end
function M:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function M:GetTexture() return "item_ultimate_scepter" end

function M:OnCreated()
	if not IsServer() then return end
	local p = self:GetParent()
	local hero = p:GetUnitName()
	if AG.BUILTIN[hero] and not p:HasModifier(AG.CONSUMED) then
		p:AddNewModifier(p, nil, AG.CONSUMED, {})
	end
	for _, name in ipairs(AG.GRANT[hero] or {}) do
		local a = p:FindAbilityByName(name)
		if a then
			a:SetHidden(false)
			a:SetActivated(true)
			if a:GetLevel() < 1 and a:GetMaxLevel() >= 1 then a:SetLevel(1) end
		end
	end
	local extra = AG.EXTRA and AG.EXTRA[hero]
	if extra then
		if extra.modifier and not p:HasModifier(extra.modifier) then p:AddNewModifier(p, nil, extra.modifier, {}) end
		if extra.gained then extra.gained(p) end
	end
end

function M:OnDestroy()
	if not IsServer() then return end
	local p = self:GetParent()
	if p:IsNull() then return end
	local hero = p:GetUnitName()
	if AG.BUILTIN[hero] then p:RemoveModifierByName(AG.CONSUMED) end
	for _, name in ipairs(AG.GRANT[hero] or {}) do
		local a = p:FindAbilityByName(name)
		if a then
			a:SetHidden(true)
			a:SetActivated(false)
			if a:GetMaxLevel() == 1 then a:SetLevel(0) end
		end
	end
	local extra = AG.EXTRA and AG.EXTRA[hero]
	if extra then
		if extra.modifier then p:RemoveModifierByName(extra.modifier) end
		if extra.lost then extra.lost(p) end
	end
end

function M:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ABILITY_FULLY_CAST, MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING, MODIFIER_PROPERTY_ATTACK_RANGE_BONUS }
end

function M:OnAbilityFullyCast(params)
	if not IsServer() or params.unit ~= self:GetParent() or not params.ability then return end
	local ability = params.ability
	local hook = AG.HOOKS[ability:GetName()]
	if not hook then return end
	local parent = self:GetParent()
	local level = ability:GetLevel()
	if hook.mana then
		local normal = ability:GetManaCost(level - 1)
		local refund = normal - level_value(hook.mana, level)
		if refund > 0 then parent:GiveMana(refund) end
	end
	if hook.cooldown then
		local cd = level_value(hook.cooldown, level)
		Dota688Timers:After(0, function()
			if ability:IsNull() then return end
			local base = ability:GetCooldown(level - 1)
			local remaining = ability:GetCooldownTimeRemaining()
			if cd <= 0 then
				ability:EndCooldown()
				return
			end
			-- pastram reducerile de cooldown (Octarine): scalam proportional cu ce a ramas din cooldown-ul normal
			local factor = 1
			if base > 0 and remaining > 0 then factor = math.min(1, remaining / base) end
			ability:EndCooldown()
			ability:StartCooldown(cd * factor)
		end)
	end
end

function M:GetModifierCastRangeBonusStacking(params)
	local ability = params and params.ability
	if not ability then return 0 end
	local hook = AG.HOOKS[ability:GetName()]
	if not hook or not hook.cast_range then return 0 end
	return level_value(hook.cast_range, ability:GetLevel())
end

function M:GetModifierAttackRangeBonus()
	local p = self:GetParent()
	for name, hook in pairs(AG.HOOKS) do
		if hook.attack_range then
			local a = p:FindAbilityByName(name)
			if a and a:GetLevel() > 0 then return hook.attack_range end
		end
	end
	return 0
end

LinkLuaModifier(AG.MODIFIER, "dota688/aghanim", LUA_MODIFIER_MOTION_NONE)
require("dota688/aghanim_extras")
