# Regulile de joc 6.88f și cum sunt implementate

Valorile sunt reconstruite din changelog‑urile 7.00+ (inversate) de pe Dota 2 Wiki și din fișierele
originale 6.88f. Coloana „Implementare” spune unde se face în proiect.

## Aur

| Regulă | 6.88 | Implementare |
|---|---|---|
| Aur de start | 625 | `constants.lua` → `SetStartingGold` |
| Aur pasiv | 1 aur / 0,6 s (100/min), continuu | `SetGoldTickTime/SetGoldPerTick` |
| Bounty direct la kill | 110 + bonus streak + 9,9 × nivel victimă | `gold_xp.lua` |
| Aur „AoE” (fiecare erou în 1300) | 1 erou: 150+6L · 2: 100+5L · 3: 40+4L · 4: 25+3L · 5: 20+3L | `gold_xp.lua` |
| Componenta de „comeback” (diferență networth) | existentă în 6.82–6.88 | `gold_xp.lua` (`ComebackGold`, `C.AOE_COMEBACK`) – de verificat în joc |
| Bonus streak (victima avea 3..10 kill‑uri) | 60/120/…/480 | `gold_xp.lua` (valori de dinainte de 7.25, presupuse neschimbate) |
| Pierdere la moarte | 30 × nivel (doar aur nesigur) | `SetLoseGoldOnDeath(false)` + `gold_xp.lua` |
| Bounty pentru iluzii | nu exista (7.00) | `modifiers/modifier_dota688_illusion_bounty.lua` – de verificat în joc |
| Deny creep | 0 aur pentru cel care face deny | motorul curent (identic) |

## Experiență și niveluri

| Regulă | 6.88 | Implementare |
|---|---|---|
| Nivel maxim | 25 | `SetCustomHeroMaxLevel` |
| Tabel XP (cumulat) | 200/500/900/1400/2000/2600/3400/4400/5400/6000/8200/9000/10400/11900/13500/15200/17000/18900/20900/23000/25200/27500/29900/32400 | `SetCustomXPRequiredToReachNextLevel` |
| Ultimate | nivel 6/11/16 | `RequiredLevel`/`LevelsBetweenUpgrades` în `npc_abilities_override.txt` (din KV 6.88) |
| Attribute Bonus | +2 la toate, 10 niveluri | `dota688_attribute_bonus` (Lua) |
| Talente | nu există | sloturile 10–17 golite în `npc_heroes_custom.txt` |
| XP la kill de erou (nivel victimă 1..25) | 100,120,140,160,180,280,380,…,2180, împărțit între eroii din 1300 | `gold_xp.lua` |
| Bonus XP „AoE” | 20/15/10/7/5 × nivel victimă (1..5 eroi) + componentă comeback | parțial (`gold_xp.lua`, fără comeback) |
| Deny creep | 50 % XP pentru inamic | motorul curent (identic) |

## Moarte, respawn, buyback

| Regulă | 6.88 | Implementare |
|---|---|---|
| Timp de respawn | 5 + 3,8 × nivel (8,8 s … 100 s) | `respawn_buyback.lua` → `SetTimeUntilRespawn` |
| Minim 26 s la moartea de neutrali | nu (adăugat în 7.00) | nimic de făcut |
| Cost buyback | 100 + 1,5 × nivel² + 0,25 × secunde de joc | `SetBuybackCost` recalculat la fiecare secundă |
| Cooldown buyback | 7 min | `SetBuybackCooldownTime` |
| Penalizare buyback | −60 % din aurul câștigat până expira respawn‑ul inițial | filtru de aur |

## Atribute

| Pe punct | 6.88 | Motor curent | Implementare |
|---|---|---|---|
| HP / STR | 20 | 22 | `modifier_dota688_attributes` |
| Regen HP / STR | 0,03 | 0,09 | idem |
| Mana / INT | 12 | 12 | – |
| Regen mana / INT | 0,04 | 0,05 | idem |
| Armură / AGI | 1/7 | 1/6 | idem |
| Viteză atac / AGI | 1 | 1 | – |
| Amplificare vrăji / INT | 1 % la 16 INT | 0 | idem |
| HP / mana de bază | 200 / 50 | 120 / 75 | `StatusHealth`/`StatusMana` în `npc_heroes_custom.txt` |
| Formula armurii | 0,06·A / (1 + 0,06·\|A\|) (și la armură negativă) | identică (7.27 a revenit la ea; măsurat în joc: 1000 daune la 6,6 armură = 715) | – |
| Viteză maximă | 522 | 550 | **TODO** (nu există API) |

## Hartă și obiecte

| Regulă | 6.88 | Implementare |
|---|---|---|
| Rune | 2 locuri în râu, la fiecare 2 min de la 0:00; la 0:00 ambele Bounty (100 aur); apoi una Bounty + una de putere | `runes.lua` (`SetUseDefaultDOTARuneSpawnLogic(false)`) |
| Bounty rune | 50 + 2/min aur, 50 + 5/min XP | `SetBountyRunePickupFilter` |
| Haste 25 s, Regen 100 HP/67 mana pe s | | `modifiers/modifier_dota688_runes.lua` (testat: TEST_LOG §7) |
| Shrine‑uri, outpost‑uri, Tormentor, Lotus, Twin Gates, Watchers | nu există | harta nu le conține |
| Backpack | nu există | `backpack.lua` (refuză sloturile 7–9) |
| Iteme neutre | nu există | `SetAllowNeutralItemDrops(false)` |
| Aghanim's Shard, Blood Grenade etc. | nu există | `ItemPurchasable 0` (generat) |
| Curier | **excepție decisă de autor (13.10.2026): curierul din ultimul patch** – personal și gratuit pentru fiecare jucător (6.88: se cumpăra, 100 aur, zburător 150, comun echipei) | `SetFreeCourierModeEnabled(true)`; Animal/Flying Courier scoase din shop (`SHOP_EXCLUDED` în generator) |
| Zi/noapte | 4 + 4 min | `daynight.lua` (emulat prin `SetTimeOfDay`) |
| Turnuri | T1 1300 HP/20 armură/100‑120 dmg; T2‑4 122‑182 dmg; glyph 5 min | `npc_units_custom.txt` |
| Ancient | 4250 HP, 15 armură, viziune 1900/1200 | idem |
| Roshan | 8000 HP, 5 armură, 128 rază, +700 HP/+10 dmg/+0,7 armură la 4 min; Aegis, Cheese din a 3‑a moarte | unități + `roshan.lua` + `modifier_dota688_roshan` |
| Neutrali | spawn la 0:30 și apoi la fiecare minut; ancienții imuni la magie | `constants.lua` (`NEUTRAL_FIRST_SPAWN_OFFSET`), testat TEST_LOG §6; stats din unități |
| Creepi pe lane | statistici 6.88 | `npc_units_custom.txt` |
| Side shop | există | harta (entitate shop) |

## Eroi și abilități

* 112 eroi (ultimul adăugat: Underlord, 6.86). Monkey King și toți cei de după sunt dezactivați.
* Fiecare erou primește statisticile de bază din 6.88 și lista de abilități din 6.88.
* Pentru fiecare abilitate care există și azi sub același nume, toate valorile numerice din 6.88 care
  mai au corespondent sunt suprascrise (cooldown, mana, damage, durate, raze, specials).
* Abilitățile reworkate (nume dispărut sau valori fără corespondent) sunt listate în `docs/STATUS.md`
  și se rescriu în Lua, una câte una, în `scripts/vscripts/abilities/` + `npc_abilities_custom.txt`.
* Aghanim's Scepter este un item propriu (`item_dota688_ultimate_scepter`); upgrade‑urile moderne din C++ nu se mai activează, iar cele din 6.88 sunt reproduse per erou – vezi `docs/AGHANIM.md`.
