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

	-- Filtre ---------------------------------------------------------------
	gm:SetModifyGoldFilter(Dynamic_Wrap(Dota688, "GoldFilter"), self)
	gm:SetModifyExperienceFilter(Dynamic_Wrap(Dota688, "ExperienceFilter"), self)
	gm:SetBountyRunePickupFilter(Dynamic_Wrap(Dota688, "BountyRuneFilter"), self)
	gm:SetExecuteOrderFilter(Dynamic_Wrap(Dota688, "OrderFilter"), self)
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
end

function Dota688:OnGameRulesStateChange()
	local state = GameRules:State_Get()
	if state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		print("[dota688] joc inceput (0:00)")
		Dota688GoldXP:OnHorn()
		Dota688Runes:OnHorn()
		Dota688DayNight:OnHorn()
		Dota688Neutrals:OnHorn()
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
	if unit:GetTeamNumber() == DOTA_TEAM_NEUTRALS then
		-- motorul adauga singur neutralilor "neutral_upgrade" (cresterea lor in timp, 7.x), chiar daca nu e in KV
		local up = unit:FindAbilityByName("neutral_upgrade")
		if up then
			unit:RemoveModifierByName("modifier_neutral_upgrade")
			unit:RemoveAbilityByHandle(up)
		end
	end
	if not unit:IsRealHero() then Dota688Aghanim.OnUnitSpawned(unit) end
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
	end
end

function Dota688:OnBuyback(ev)
	Dota688Respawn:OnBuyback(ev)
end

-- Filtre --------------------------------------------------------------------
function Dota688:GoldFilter(ev)
	return Dota688GoldXP:GoldFilter(ev)
end

function Dota688:OrderFilter(ev)
	return Dota688Aghanim.OrderFilter(ev)
end

function Dota688:ExperienceFilter(ev)
	return Dota688GoldXP:ExperienceFilter(ev)
end

function Dota688:BountyRuneFilter(ev)
	return Dota688Runes:BountyRuneFilter(ev)
end

function Dota688:ItemAddedToInventoryFilter(ev)
	return Dota688Backpack:ItemAddedToInventoryFilter(ev)
end
