-- Modul de joc "Dota 6.88 Classic": configurarea regulilor si evenimentele.
require("dota688/constants")
require("dota688/util")
require("dota688/gold_xp")
require("dota688/respawn_buyback")
require("dota688/runes")
require("dota688/roshan")
require("dota688/daynight")
require("dota688/backpack")
require("dota688/neutrals")
require("dota688/aghanim")
require("dota688/map_688")
require("dota688/selection")
require("dota688/buildings")
require("dota688/creeps")
require("dota688/courier")

require("dota688/modifiers_link")

local C = DOTA688

if Dota688 == nil then
	Dota688 = class({})
end

function Dota688:Init()
	print("[dota688] initializare reguli 6.88f")
	local gm = GameRules:GetGameModeEntity()
	Dota688Map:Ensure()   -- inainte de Dota688Runes:Init (punctele de rune)

	-- Reguli generale ------------------------------------------------------
	GameRules:SetStartingGold(C.STARTING_GOLD)
	GameRules:SetGoldTickTime(C.GOLD_TICK_TIME)
	GameRules:SetGoldPerTick(C.GOLD_PER_TICK)
	GameRules:SetHeroRespawnEnabled(true)
	GameRules:SetUseUniversalShopMode(false)
	GameRules:SetSameHeroSelectionEnabled(false)
	GameRules:SetPreGameTime(C.PREGAME_TIME)
	GameRules:SetTreeRegrowTime(C.TREE_REGROW_TIME)
	GameRules:SetUseBaseGoldBountyOnHeroes(true)   -- BountyGold al eroilor e 0 in KV: aurul de kill il dam noi
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_GOODGUYS, 5)
	GameRules:SetCustomGameTeamMaxPlayers(DOTA_TEAM_BADGUYS, 5)
	GameRules:SetFirstBloodActive(true)

	-- Nivel / experienta ---------------------------------------------------
	gm:SetCustomXPRequiredToReachNextLevel(C.XP_TABLE)
	gm:SetCustomHeroMaxLevel(C.MAX_LEVEL)
	gm:SetUseCustomHeroLevels(true)

	-- Moarte / respawn / buyback --------------------------------------------
	gm:SetLoseGoldOnDeath(false)                   -- pierderea de aur o calculam noi (30 x nivel)
	gm:SetBuybackEnabled(true)
	gm:SetCustomBuybackCostEnabled(true)            -- costul 6.88 vine din respawn_buyback.lua (PlayerResource:SetCustomBuybackCost)
	gm:SetCustomBuybackCooldownEnabled(true)        -- 7 min, pastrat peste respawn-uri (respawn_buyback.lua)
	gm:SetFixedRespawnTime(-1)
	gm:SetRespawnTimeScale(1.0)
	Dota688SafeCall(gm, "SetKillingSpreeAnnouncerDisabled", false)

	-- Elemente aparute dupa 6.88, dezactivate ------------------------------
	Dota688SafeCall(gm, "SetFreeCourierModeEnabled", false)        -- curierul se cumpara (item_courier, 7.23 l-a facut gratuit)
	Dota688SafeCall(gm, "SetAllowNeutralItemDrops", false)         -- fara iteme neutre (7.23)
	Dota688SafeCall(gm, "SetUseDefaultDOTARuneSpawnLogic", false)  -- rune dupa logica 6.88 (vezi runes.lua)
	-- SetUseDefaultDOTARuneSpawnLogic(false) nu opreste spawner-ele hartii (testat: Shield, Bounty in jungla, power
	-- rune peste cele 6.88). Cu toate tipurile dezactivate motorul nu mai creeaza rune; CreateRune din Lua merge in continuare.
	for _, rune in ipairs({ DOTA_RUNE_DOUBLEDAMAGE, DOTA_RUNE_HASTE, DOTA_RUNE_ILLUSION, DOTA_RUNE_INVISIBILITY, DOTA_RUNE_REGENERATION,
		DOTA_RUNE_BOUNTY, DOTA_RUNE_ARCANE, DOTA_RUNE_WATER, DOTA_RUNE_XP, DOTA_RUNE_SHIELD }) do
		gm:SetRuneEnabled(rune, false)
	end
	Dota688SafeCall(gm, "SetDaynightCycleDisabled", false)
	Dota688SafeCall(gm, "SetTowerBackdoorProtectionEnabled", true)
	Dota688SafeCall(gm, "SetStashPurchasingDisabled", false)
	Dota688SafeCall(gm, "SetCustomBackpackSwapCooldown", 0)
	Dota688SafeCall(gm, "SetCustomBackpackCooldownPercent", 0)
	Dota688SafeCall(gm, "SetNeutralStashEnabled", false)              -- fara iteme neutre (7.23)
	Dota688SafeCall(gm, "SetGiveFreeTPOnDeath", false)                -- TP gratuit la moarte (7.x)
	Dota688SafeCall(gm, "SetRandomHeroBonusItemGrantDisabled", true)  -- iteme bonus la random (7.x)
	Dota688SafeCall(gm, "SetCustomScanCooldown", C.SCAN_COOLDOWN)
	Dota688SafeCall(gm, "SetCustomScanMaxCharges", C.SCAN_CHARGES)
	Dota688SafeCall(gm, "SetMaximumAttackSpeed", C.MAX_ATTACK_SPEED)
	-- blocul innascut al eroilor melee (7.23, 50% sansa sa blocheze 16 damage): in 6.88 doar Stout Shield/PMS/Vanguard
	Dota688SafeCall(gm, "SetInnateMeleeDamageBlockAmount", 0)
	Dota688SafeCall(gm, "SetInnateMeleeDamageBlockPercent", 0)
	Dota688SafeCall(gm, "SetInnateMeleeDamageBlockPerLevelAmount", 0)
	Dota688SafeCall(GameRules, "SetSuggestAbilitiesEnabled", false)   -- procentele de skill-uri sugerate (7.x)
	Dota688SafeCall(GameRules, "SetSuggestItemsEnabled", false)
	-- fantana 6.88: 4 % HP si 14 + 4 % mana pe secunda (7.07 -> 5 % / 6 %)
	Dota688SafeCall(gm, "SetFountainPercentageHealthRegen", C.FOUNTAIN_HP_REGEN_PCT)
	Dota688SafeCall(gm, "SetFountainPercentageManaRegen", C.FOUNTAIN_MANA_REGEN_PCT)
	-- partea constanta (+14) o da modifier_dota688_fountain (Dota688Buildings): apelul motorului nu mai are efect;
	-- 0 ca sa nu se dubleze daca reincepe sa mearga
	Dota688SafeCall(gm, "SetFountainConstantManaRegen", 0)
	Dota688SafeCall(gm, "SetRecommendedItemsDisabled", true)                               -- ghidurile/itemele recomandate (7.x)
	Dota688SafeCall(gm, "SetHUDVisible", DOTA_HUD_VISIBILITY_SHOP_SUGGESTEDITEMS, false)  -- itemele sugerate din shop/quickbuy

	-- Filtre ---------------------------------------------------------------
	gm:SetModifyGoldFilter(Dynamic_Wrap(Dota688, "GoldFilter"), self)
	gm:SetModifyExperienceFilter(Dynamic_Wrap(Dota688, "ExperienceFilter"), self)
	gm:SetBountyRunePickupFilter(Dynamic_Wrap(Dota688, "BountyRuneFilter"), self)
	gm:SetExecuteOrderFilter(Dynamic_Wrap(Dota688, "OrderFilter"), self)
	gm:SetModifierGainedFilter(Dynamic_Wrap(Dota688, "ModifierGainedFilter"), self)
	gm:SetDamageFilter(Dynamic_Wrap(Dota688, "DamageFilter"), self)
	if C.DISABLE_BACKPACK then
		gm:SetItemAddedToInventoryFilter(Dynamic_Wrap(Dota688, "ItemAddedToInventoryFilter"), self)
	end

	-- Evenimente -----------------------------------------------------------
	ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(Dota688, "OnGameRulesStateChange"), self)
	ListenToGameEvent("npc_spawned", Dynamic_Wrap(Dota688, "OnNPCSpawned"), self)
	ListenToGameEvent("entity_killed", Dynamic_Wrap(Dota688, "OnEntityKilled"), self)
	ListenToGameEvent("dota_buyback", Dynamic_Wrap(Dota688, "OnBuyback"), self)

	Dota688Timers:Start()
	Dota688GoldXP:Init(self)
	Dota688Respawn:Init(self)
	Dota688Runes:Init(self)
	Dota688Roshan:Init(self)
	Dota688DayNight:Init(self)
	Dota688Neutrals:Init(self)
	Dota688Backpack:Init()
	Dota688Selection:Init()
	Dota688Buildings:Init(self)
	Dota688Creeps:Init(self)
end

function Dota688:OnGameRulesStateChange()
	local state = GameRules:State_Get()
	if state == DOTA_GAMERULES_STATE_PRE_GAME then
		-- 6.88: +200 aur pentru random (7.x da iteme in loc de aur)
		for pid = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
			if PlayerResource:IsValidPlayerID(pid) and PlayerResource:HasRandomed(pid) then
				PlayerResource:ModifyGold(pid, C.RANDOM_BONUS_GOLD, false, DOTA_ModifyGold_Unspecified)
			end
		end
	end
	if state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		print("[dota688] joc inceput (0:00)")
		Dota688GoldXP:OnHorn()
		Dota688Runes:OnHorn()
		Dota688DayNight:OnHorn()
		Dota688Neutrals:OnHorn()
		Dota688Buildings:OnHorn()
	end
end

function Dota688:OnNPCSpawned(ev)
	local unit = EntIndexToHScript(ev.entindex)
	if not unit then return end
	if unit:IsRealHero() then
		-- motorul adauga fiecarui erou "special_bonus_attributes" (atributele-talent din 7.x, 0/7): cat exista,
		-- HUD-ul ofera "+" la talente la fiecare level up. In 6.88 nu exista (inlocuit de dota688_attribute_bonus).
		local sb = unit:FindAbilityByName("special_bonus_attributes")
		if sb then unit:RemoveAbilityByHandle(sb) end
		if not unit:HasModifier("modifier_dota688_attributes") then
			unit:AddNewModifier(unit, nil, "modifier_dota688_attributes", {})
		end
		if not unit.dota688_spawned then
			unit.dota688_spawned = true
			Dota688Timers:After(0.1, function()
				if not unit:IsNull() then Dota688Backpack:OnHeroFirstSpawn(unit) end
			end)
		end
		Dota688Respawn:OnHeroSpawned(unit)
		Dota688Aghanim.OnHeroSpawned(unit)
		if unit:GetUnitName() == "npc_dota_hero_invoker" and not unit:HasModifier("modifier_dota688_invoker_orbs") then
			unit:AddNewModifier(unit, nil, "modifier_dota688_invoker_orbs", {})
		end
	elseif string.find(unit:GetUnitName(), "npc_dota_visage_familiar", 1, true) == 1 then
		unit:AddNewModifier(unit, nil, "modifier_dota688_familiar", {})
	elseif unit:GetUnitName() == "npc_dota_roshan" then
		Dota688Roshan:OnRoshanSpawned(unit)
	end
	if not unit:IsHero() then
		-- abilitati 7.x pe care motorul le adauga singur unitatilor, chiar daca nu sunt in KV (testat):
		-- neutral_upgrade (cresterea neutralilor in timp), twin_gate_portal_warp (creepii de lane),
		-- flagbearer_creep_aura_effect (aur in plus la moartea creep-ului cu steag)
		for ability, modifiers in pairs(C.MODERN_UNIT_ABILITIES) do
			local a = unit:FindAbilityByName(ability)
			if a then
				for _, m in ipairs(modifiers) do unit:RemoveModifierByName(m) end
				unit:RemoveAbilityByHandle(a)
			end
		end
	end
	if not unit:IsRealHero() then Dota688Aghanim.OnUnitSpawned(unit) end
	Dota688Buildings:OnNPCSpawned(unit)
	Dota688Creeps:OnNPCSpawned(unit)
end

function Dota688:OnEntityKilled(ev)
	local killed = EntIndexToHScript(ev.entindex_killed)
	if not killed then return end
	local attacker = ev.entindex_attacker and EntIndexToHScript(ev.entindex_attacker) or nil
	if killed.dota688_copy then
		return   -- copie (Vengeance Illusion / Hybrid): fara aur, XP sau respawn
	end
	if killed:IsRealHero() and not killed:IsReincarnating() then
		Dota688Respawn:OnHeroKilled(killed, attacker)
		Dota688GoldXP:OnHeroKilled(killed, attacker)
	elseif killed:GetUnitName() == "npc_dota_roshan" then
		Dota688Roshan:OnRoshanKilled(killed, attacker)
		Dota688Buildings:OnRoshanKilled(killed, attacker)
	elseif killed:IsBuilding() then
		Dota688Buildings:OnBuildingKilled(killed, attacker)
	end
	if not killed:IsHero() then Dota688Creeps:OnUnitKilled(killed, attacker) end
end

function Dota688:OnBuyback(ev)
	Dota688Respawn:OnBuyback(ev)
end

-- Filtre --------------------------------------------------------------------
function Dota688:GoldFilter(ev)
	if not Dota688Runes:GoldFilter(ev) then return false end
	if not Dota688Buildings:GoldFilter(ev) then return false end
	return Dota688GoldXP:GoldFilter(ev)
end

-- ordine aparute dupa 6.88 (meniul de item: blocare combinare, lasat la fantana, marcat de vanzare)
local MODERN_ORDERS = {}
for _, o in ipairs({ "DOTA_UNIT_ORDER_SET_ITEM_COMBINE_LOCK", "DOTA_UNIT_ORDER_DROP_ITEM_AT_FOUNTAIN", "DOTA_UNIT_ORDER_SET_ITEM_MARK_FOR_SELL" }) do
	if _G[o] then MODERN_ORDERS[_G[o]] = true end
end

function Dota688:OrderFilter(ev)
	if MODERN_ORDERS[ev.order_type] then return false end
	if not Dota688Buildings:OrderFilter(ev) then return false end
	if not Dota688Courier:OrderFilter(ev) then return false end
	Dota688Selection:OrderFilter(ev)
	return Dota688Aghanim.OrderFilter(ev)
end

function Dota688:ExperienceFilter(ev)
	if not Dota688Creeps:ExperienceFilter(ev) then return false end
	return Dota688GoldXP:ExperienceFilter(ev)
end

function Dota688:DamageFilter(ev)
	return Dota688Buildings:DamageFilter(ev)
end

function Dota688:ModifierGainedFilter(ev)
	if not Dota688Runes:ModifierGainedFilter(ev) then return false end
	return Dota688Buildings:ModifierGainedFilter(ev)
end

function Dota688:BountyRuneFilter(ev)
	return Dota688Runes:BountyRuneFilter(ev)
end

function Dota688:ItemAddedToInventoryFilter(ev)
	return Dota688Backpack:ItemAddedToInventoryFilter(ev)
end
