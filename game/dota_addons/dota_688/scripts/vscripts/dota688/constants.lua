-- Toate constantele de joc ale patch-ului 6.88f (ultimul inainte de 7.00).
-- Sursa valorilor: changelog-urile 7.00+ de pe wiki (inversate) si fisierele originale 6.88f din reference/.
-- Comentariile "ACUM:" descriu valoarea motorului curent, pe care o compensam in Lua.

DOTA688 = DOTA688 or {}
local C = DOTA688

-- Aur ------------------------------------------------------------------------
C.STARTING_GOLD        = 625          -- 7.09 l-a redus la 600
C.GOLD_TICK_TIME       = 0.6          -- 1 aur la 0.6 s = 100 aur/min (7.03 -> 91/min, 7.23 -> 85...)
C.GOLD_PER_TICK        = 1
C.DEATH_GOLD_PER_LEVEL = 30           -- pierdere la moarte: 30 x nivel (aur nesigur); 7.00 -> 100 + networth/50
C.KILL_GOLD_BASE       = 110          -- bounty direct: 110 + streak + 9.9 x nivel victima (7.00 -> x8)
C.KILL_GOLD_PER_LEVEL  = 9.9
C.KILL_STREAK_GOLD     = { [3]=60, [4]=120, [5]=180, [6]=240, [7]=300, [8]=360, [9]=420, [10]=480 } -- valorile de dinainte de 7.25
C.KILL_RADIUS          = 1300         -- raza pentru aur/XP de asistenta (7.07 -> 1500)
-- aur "AoE" per erou aflat in raza, dupa numarul de eroi (1..5): a + b x nivel victima
C.AOE_GOLD = { {150, 6}, {100, 5}, {40, 4}, {25, 3}, {20, 3} }
-- TODO: componenta "comeback" (diferenta de networth intre echipe) din 6.82-6.88 nu este inca implementata.

-- Experienta ----------------------------------------------------------------
-- XP total necesar pentru a atinge nivelul N (6.88, 25 niveluri; tabelul din notele 7.00)
C.XP_TABLE = {
	[1]=0, [2]=200, [3]=500, [4]=900, [5]=1400, [6]=2000, [7]=2600, [8]=3400, [9]=4400, [10]=5400,
	[11]=6000, [12]=8200, [13]=9000, [14]=10400, [15]=11900, [16]=13500, [17]=15200, [18]=17000,
	[19]=18900, [20]=20900, [21]=23000, [22]=25200, [23]=27500, [24]=29900, [25]=32400,
}
C.MAX_LEVEL = 25
-- XP acordat pentru uciderea unui erou de nivel L (impartit intre eroii din raza)
C.HERO_KILL_XP = { 100, 120, 140, 160, 180, 280, 380, 480, 580, 680, 780, 880, 980, 1080, 1180, 1280,
	1380, 1480, 1580, 1680, 1780, 1880, 1980, 2080, 2180 }
-- bonus XP "AoE" per erou (1..5 eroi): factor x nivel victima (formula veche din 7.20: 20/15/10/7/5 x L)
C.AOE_XP_PER_LEVEL = { 20, 15, 10, 7, 5 }

-- Respawn / buyback -----------------------------------------------------------
function C.RespawnTime(level)             -- 6.83b: 5 + 3.8 x nivel (nivel 25 = 100 s)
	return 5 + 3.8 * level
end
C.BUYBACK_COOLDOWN     = 420              -- 7 minute (6.82c); 7.06 -> 8 min
function C.BuybackCost(level, gameTimeSec) -- 100 + 1.5 x nivel^2 + 0.25 x timp (7.11 -> 100 + networth/13)
	return math.floor(100 + 1.5 * level * level + 0.25 * math.max(0, gameTimeSec))
end
C.BUYBACK_GOLD_PENALTY = 0.6              -- 6.84: -60% din tot aurul castigat pana la expirarea timpului de respawn initial

-- Rune -------------------------------------------------------------------------
C.RUNE_INTERVAL        = 120
C.RUNE_INITIAL_BOUNTY_GOLD = 100         -- la 0:00 ambele rune sunt bounty (6.83), 100 aur, 0 XP (6.87)
C.RUNE_BOUNTY_GOLD_BASE    = 50          -- 50 + 2/min (7.08 -> 4/min, 7.10 -> 60 baza)
C.RUNE_BOUNTY_GOLD_PER_MIN = 2
C.RUNE_BOUNTY_XP_BASE      = 50          -- 50 + 5/min (7.07c -> 25 + 7/min, 7.08 -> 0)
C.RUNE_BOUNTY_XP_PER_MIN   = 5
C.POWER_RUNES = { "DOTA_RUNE_DOUBLEDAMAGE", "DOTA_RUNE_HASTE", "DOTA_RUNE_ILLUSION", "DOTA_RUNE_INVISIBILITY", "DOTA_RUNE_REGENERATION", "DOTA_RUNE_ARCANE" }
-- TODO: durata Haste 25 s (7.00 -> 22) si Regenerare 100 HP/67 mana pe secunda (7.07 -> procente) sunt in C++.

-- Zi / noapte ---------------------------------------------------------------
C.DAY_NIGHT_HALF_CYCLE = 240             -- 4 min zi + 4 min noapte (7.20 -> 5 + 5)
C.EMULATE_DAY_NIGHT    = true

-- Atribute (per punct) --------------------------------------------------------
C.ATTR = {
	HP_PER_STR         = 20,     -- 6.87-7.12 (ACUM: 22)
	HP_REGEN_PER_STR   = 0.03,   -- (ACUM: 0.09 flat)
	MANA_PER_INT       = 12,     -- (ACUM: 12)
	MANA_REGEN_PER_INT = 0.04,   -- (ACUM: 0.05 flat)
	ARMOR_PER_AGI      = 1 / 7,  -- (ACUM: 1/6)
	AS_PER_AGI         = 1,      -- (ACUM: 1)
	SPELL_AMP_PER_INT  = 1 / 16, -- procente: 1% la 16 INT (6.87-7.04); (ACUM: 0)
	MAGIC_RES_PER_INT  = 0,      -- (ACUM: 0.1% pe punct de INT, adunat la baza)
	BASE_MAGIC_RES     = 25,     -- toti eroii 6.88
	BASE_HP            = 200,    -- (ACUM: 120) - setat prin KV (StatusHealth) in npc_heroes_custom.txt
	BASE_MANA          = 50,     -- (ACUM: 75)  - setat prin KV (StatusMana)
}
-- valorile motorului curent, de compensat (verificate pe wiki la data generarii; de reverificat la patch-uri noi)
C.ATTR_NOW = {
	HP_PER_STR = 22, HP_REGEN_PER_STR = 0.09, MANA_PER_INT = 12, MANA_REGEN_PER_INT = 0.05,
	ARMOR_PER_AGI = 1 / 6, AS_PER_AGI = 1, SPELL_AMP_PER_INT = 0, MAGIC_RES_PER_INT = 0.1,
	BASE_HP_ENGINE = 120, BASE_MANA_ENGINE = 75,   -- baza motorului curent, daca ignora StatusHealth/StatusMana din KV
}

-- Roshan ---------------------------------------------------------------------
-- 6.88: 8000 HP, 5 armura, 128 raza (prin npc_units_custom.txt) + la fiecare 4 minute: +700 HP, +10 dmg, +0.7 armura.
C.ROSHAN_BASE = { HP = 8000, ARMOR = 5, DAMAGE = 65 }   -- reference/6.88f/npc_units.txt
C.ROSHAN_GROWTH_INTERVAL = 240
C.ROSHAN_GROWTH = { HP = 700, DAMAGE = 10, ARMOR = 0.7 }
-- motorul curent creste Roshan in fiecare minut (HP de baza 6000 + 130/min impus din C++, armura/daune prin
-- modifier_roshan_inherent_buffs); modifier_dota688_roshan masoara si compenseaza diferenta
C.ROSHAN_CHEESE_FROM_DEATH = 3           -- Cheese din a 3-a moarte (7.06 -> a 2-a)
C.ROSHAN_EXTRA_DROPS = { "item_refresher_shard", "item_aghanims_blessing_roshan", "item_aghanims_shard_roshan", "item_roshans_banner" }

-- Diverse ----------------------------------------------------------------
C.DISABLE_BACKPACK     = true            -- 7.00 a adaugat backpack-ul; refuzam itemele in sloturile 7-9
C.PREGAME_TIME         = 90
C.TREE_REGROW_TIME     = 300
C.ILLUSION_BOUNTY      = false           -- 7.00 a adaugat bounty pentru iluzii (TODO: filtrare)

-- Abilitati 7.x pe care motorul le adauga singur unitatilor (nu sunt in KV) -> {ability = {modifieri de scos}}
C.MODERN_UNIT_ABILITIES = {
	neutral_upgrade = { "modifier_neutral_upgrade" },                 -- cresterea neutralilor in timp (7.x)
	twin_gate_portal_warp = {},                                        -- Twin Gates (7.33)
	flagbearer_creep_aura_effect = { "modifier_flagbearer_creep_aura_effect", "modifier_creep_bonus_xp" },  -- 7.32
}

-- Mecanici fara KV --------------------------------------------------------
C.MAX_ATTACK_SPEED     = 600             -- 6.88: 600 (azi 700)
C.SCAN_COOLDOWN        = 270             -- scan (6.87): 270 s, o singura incarcare (7.34 -> 2 incarcari)
C.SCAN_CHARGES         = 1
C.NEUTRAL_FIRST_SPAWN_OFFSET = -30       -- motorul: primul spawn la 1:00 -> 0:30 (6.88)
