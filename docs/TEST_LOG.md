# Jurnal de testare în joc

Testat pe 2026‑10‑12 în Dota 2 Workshop Tools (client build 25845666), cu `-condebug -netconport 29000`.
Secțiunile 1–4 pe harta standard `dota`; secțiunile 5–6 pe harta 6.88 (harta Valve din client copiată în addon ca
`maps/dota.vpk`, vezi `docs/HARTA.md`), ambele cu `dota_launch_custom_game dota_688 dota`. De la secțiunea 7: harta 6.88
compilată de noi (`dota_launch_custom_game dota_688 dota_688`).

**Metodă.** Consola jocului e comandată prin portul VConsole. Scenariile de test sunt scripturi Lua rulate cu
`script_reload_code dota688_test/<scenariu>` (folderul `scripts/vscripts/dota688_test/` nu se comite). Fiecare
scenariu joacă ordine reale (`ExecuteOrderFromTable`), măsoară efectul și scrie rezultatul în consolă; erorile Lua
sunt luate din `console.log`. API‑ul VScript al clientului curent a fost dumpat din VM (server + client) în
`build/vscript_api_*.txt`; `tools/check_addon.py` verifică acum fiecare apel/constantă din Lua față de el, inclusiv
metodele existente doar pe server apelate din cod care rulează și pe client.

Legendă: **OK** = verificat în joc · **REPARAT** = eroare găsită în joc și corectată (commit) · **RĂMÂNE** = diferență
cunoscută, nereparată (motivul e notat).

## 1. Pornire

| Test | Rezultat |
|---|---|
| Încărcare KV (`npc_heroes_custom`, `npc_abilities_override`, `npc_items_generated`, `shops.txt`) | OK – nicio eroare de KV |
| Valorile abilităților/itemelor Lua (`GetSpecialValueFor`) | REPARAT – toate întorceau 0: motorul nu mai citește `AbilitySpecial`; generatorul scrie `AbilityValues` |
| Localizare (tooltip‑uri 6.88) | REPARAT – `LOCFAIL: Ignoring unsupported encoding in localization file 'resource/addon_english.txt'`; fișierele generate se scriu UTF‑8 cu BOM |
| `custom_net_tables.txt` | REPARAT – `Unable to determine buffer encoding`; format KV3 |
| Erori `[VScript]` la pornire/spawn | REPARAT – `respawn_buyback.lua:37: attempt to call method 'SetBuybackCost' (a nil value)` → `PlayerResource:SetCustomBuybackCost` |
| Modifierii globali pe client | REPARAT – `Attempted to create unknown modifier type modifier_dota688_attributes!` (link doar pe server) |
| `[dota688] API lipsa: ...` | OK – nu apare |
| API‑uri dispărute (dump VM) | REPARAT – `ReduceMana`, `SetMinimapIconHidden`, `IsTree`, `MODIFIER_PROPERTY_CANNOT_MISS`, `DOTA_DAMAGE_FLAG_BYPASSES_BLOCK`, 6× `DOTA_PSEUDO_RANDOM_*`, ținta Tether, `GetAbilityDamage`/`IsDaytime`/`GetBaseAttackRange` pe client, `GetCastRange(nil,nil)` |
| Panoul „6.88” în HUD | OK – butonul apare sus‑dreapta |
| HUD: talente, backpack, slot neutru, slot TP | REPARAT – „+” la talente la fiecare level up (motorul adaugă `special_bonus_attributes`) și iconița arborelui de talente peste prima abilitate de la nivelul 10 (`DOTAHUDLevelStatsFrame`); verificat până la nivelul 16. Backpack/neutru/TP ascunse |
| HUD: fațete/innate, indicator Aghanim | REPARAT – ascunse (`RootInnateDisplay`, `AghsStatusContainer`) |
| Attribute Bonus în bara de abilități | REPARAT – HUD‑ul nu afișa `ABILITY_TYPE_ATTRIBUTES`; acum a 7‑a abilitate, cu „+”, 10 niveluri |

## 2. Reguli de joc

| Test | Rezultat |
|---|---|
| Aur de start 625 | OK |
| Aur pasiv 1 / 0.6 s | REPARAT – motorul nu mai dădea nimic (`SetGoldPerTick` fără efect); dat din Lua: măsurat 1.667/s |
| Atribute (Techies 17/14/22): HP 200+20·STR, mana 50+12·INT, armură AGI/7, spell amp INT/16 % | OK – 540 HP, 314 mana, 7.0 armură, 1.37 % |
| Viteza de atac de bază 100 | REPARAT – motorul are 85–125 per erou (Techies 104 în loc de 114) |
| Rezistență la magie 25 % | REPARAT – motorul adaugă 0.1 %/INT (27.2 %); compensat exact → 25.00 % |
| Ultimate la 6/11/16, de bază 1/3/5/7 | REPARAT – ultimate‑urile Lua erau abilități de bază (`DOTA_ABILITY_TYPE_ULTIMATE` nerecunoscut), toate erau 6/12/18 |
| Aur/XP la kill (nivel 10 vs 10) | OK – 419 aur (110+9.9·L direct + 150+6·L AoE), 880 XP |
| Respawn 5 + 3.8·L | OK – 46.3 s la nivel 11 (46.8) |
| Buyback 100 + 1.5·L² + 0.25·t | OK – 108 la nivel 1 / 0:28; 298 la nivel 11 |
| Zi/noapte 4 + 4 min | OK – ciclu măsurat 482 s |
| Rune: două în râu, Bounty la 0:00 | REPARAT – motorul punea rune Shield/Bounty în junglă/power peste cele 6.88; toate tipurile dezactivate în motor |
| Creepi pe lane | OK – valurile pornesc la 0:00 (60 de creepi la 0:43) |
| Neutrali la 0:30, fără `neutral_upgrade` | OK/REPARAT – 28/28 camp‑uri, 2–5 per camp; `neutral_upgrade` (creșterea 7.x) adăugat de motor la spawn e scos |
| Abilitățile unităților (neutrali, Roshan, curier) | REPARAT – erau cele moderne (Revenge Roar, Grab and Throw, Courier Shield, Fel Beast Haunt...); acum cele 6.88 + emularea tipurilor de atac/armură; ancienții au din nou imunitate la magie |
| Roshan 8000 HP / 5 armură / 65 daune, +700/+0.7/+10 la 4 min | REPARAT – `roshan_inherent_buffs` modern impunea 6000 + 130/min la fiecare frame; scos, creșterea 6.88 în Lua; măsurat 8000/5/65 la 0:17 |
| Shop: Courier 100, Flying 150, Iron Talon, Poor Man's Shield, Aquila, Necronomicon, Tango 125 | OK |
| Backpack / slot neutru gol | OK |
| Tower Protection (aura turnului) | RĂMÂNE – aceleași modifiere ca în 6.88 (`modifier_tower_aura` / `modifier_tower_aura_bonus`), dar cu valorile actuale (+3/5/5/5 armură și regenerare; 6.88: +1/3/3/3 armură, rază 900) |

## 3. Eroi și abilități

| Test | Rezultat |
|---|---|
| Test de fum: 112 eroi, nivel 25, fiecare abilitate activă lansată pe un inamic | OK după corecții – 0 erori Lua; cele raportate „nelansate” verificate individual (Call Down, Waveform, Illusory Orb, Blink, Infest, Static Remnant, Ball Lightning, Fatal Bonds, Shadow Word, Winter's Curse): toate se lansează |
| Erori găsite de testul de fum | REPARAT – Pugna Life Drain, Meepo Geostrike, Night Stalker Darkness/Crippling Fear, Troll Berserker's Rage; 38 de callback‑uri + 258 de citiri de valori protejate când sursa dispare (Rubick, iluzii, item vândut) |
| Techies: Land Mines, Stasis Trap, Remote Mines, Focused Detonate, Minefield Sign, Suicide | REPARAT/OK – 260 fizic, stun 4 s, detonare individuală și Focused, Suicide 1150 + respawn 50 %; Focused Detonate (NOT_LEARNABLE) primește nivel la învățarea Remote Mines |
| Abilități oferite de scepter vizibile fără scepter | REPARAT – Chakram 2, Assimilate, Unrefined Fireblast, Walrus Kick, Eyes in the Forest, Hybrid se puteau învăța fără scepter |
| 65 de iteme Lua: statistici + activă | REPARAT/OK – zeci de erori în aure/buff‑uri după ce itemul dispare; acum 0 erori. Midas/Dominator/Iron Talon refuză eroii, Dagon 1–5 cooldown comun |
| Iconițe | REPARAT – 8 iconițe 6.88 inexistente înlocuite cu cele actuale |

## 4. Aghanim's Scepter

| Test | Rezultat |
|---|---|
| Fiecare erou din `docs/AGHANIM.md`, cu și fără scepter: ultimate‑ul lansat pe un inamic, efectul măsurat | OK – 107/109 la prima trecere, 0 erori Lua |
| Meepo cu scepter (o clonă în plus) | REPARAT – clonele în plus rămâneau „fantomă”; acum se păstrează o clonă per nivel (`UTIL_Remove` pentru restul), Divided We Stand trece la nivelul 4 cu scepter |
| Rubick Spell Steal cu scepter | OK – cooldown 2 s (6.88) confirmat |
| Combinarea componentelor în scepter‑ul 6.88 | RĂMÂNE – rețeta modernă (gratuită) a lui `item_ultimate_scepter` se combină înaintea celei 6.88, deci componentele dau scepter‑ul modern (găsit în playtest la Techies) |

## 5. Harta

| Test | Rezultat |
|---|---|
| Harta decompilată din 2016, compilată cu `resourcecompiler` | REPARAT/RĂMÂNE – cădea la PRE_GAME fără `info_courier_spawn_*_1..5` și `roshan_location_1/2` (adăugate); assert‑uri `HoldAnimation` (cheia scoasă); flow/fog maps luate din harta curentă. Trigger‑ele (shop, volume de camp, no‑wards) nu au geometrie după decompilare, deci compilatorul le aruncă: 0 `trigger_shop` |
| Harta 6.88 recompilată de Valve (`game/dota/maps/dota_688.vpk` din client) ca `maps/dota.vpk` al addon‑ului | OK – 22 turnuri, 12 barăci, 2 forturi, 6 `ent_dota_shop`, 11 `trigger_shop`, 22 `trigger_multiple` (14 volume de camp), 6 `trigger_no_wards`, groapa lui Roshan; `map_688.lua` adaugă curierii 1..5, pozițiile lui Roshan și punctele de rune |
| Side shop / secret shop | OK – eroul care intră pe jos vede `DOTA_SHOP_SIDE` / `DOTA_SHOP_SECRET` |
| Neutrali: fără stack‑uri singure | REPARAT – pe harta decompilată camp‑urile se umpleau în fiecare minut (fără volume); pe harta Valve, 7 minute fără eroi în junglă: 49 de neutrali constant |
| Roshan | OK – în groapa 6.88 (4320, ‑1824), 8000 HP |
| Rune | OK – cele două puncte din râu (‑2237, 1621) și (2812, ‑2241) |
| Avertisment „Legacy Compiled Data” în Asset Browser | RĂMÂNE – harta Valve e în formatul compilat vechi; acum se încarcă normal. Pe viitor: modelele trigger‑elor se pot decompila din harta Valve (`PhysicsHullFile`) și recompila |
| Assert `HoldAnimation` pe 2 `prop_dynamic` ale hărții Valve | RĂMÂNE – apare doar în Workshop Tools (camere decorative ale Ancient‑ului), inofensiv |

## 6. Playtest și audit 6.88 (după secțiunile 1–5)

Corecții testate în joc pe harta 6.88:

| Test | Rezultat |
|---|---|
| „Creep‑ul dă aur de 2 ori” | REPARAT – creep‑ul flagbearer (7.32, aur în plus inamicilor la moarte) e acum un creep melee 6.88 (model, bounty 36–40, fără aură); un creep obișnuit dă un singur eveniment de aur |
| Neutrali: viteza de atac | REPARAT – 7.31 le dăduse `BaseAttackSpeed` 110–200: atacau de 1.25–2× mai repede; acum 1.30–1.80 s/atac ca în 6.88; turnurile 1.0 s |
| Neutrali: tipul de atac, viteza de rotire, rezistența ancienților | REPARAT – Basic/Pierce emulate (`creep_irresolute`/`creep_piercing`), rotire 0.5, ancienți 0 % + imunitate |
| Primul spawn de neutrali la 0:30 | OK – 46 de neutrali la 0:31 (`SetNeutralInitialSpawnOffset(-30)`) |
| Panoul „0/6” (Madstone) și itemele neutre | REPARAT – ascunse; stash‑ul și sloturile neutre dezactivate |
| Stocuri: tango/clarity/salve/mango/sentry | REPARAT – fără limită ca în 6.88 (erau 10/5/5/4/8) |
| TP | REPARAT – fără TP la start/moarte; TP‑ul cumpărat ajunge într‑un slot normal și se adună cu cele existente |
| Cooldown‑ul de buyback | REPARAT – se ștergea la fiecare respawn |
| Remote Mines: mai multe mine selectate + detonare | REPARAT – clientul trimitea ordinul doar pentru mina principală; HUD‑ul trimite selecția, serverul le detonează pe toate (testat de utilizator) |
| Curierul | REPARAT – `item_courier` nu mai făcea nimic; Animal/Flying Courier în Lua, curier al echipei (75 HP sol; 150 HP, 10 armură, zbor, burst după upgrade), nu crește cu eroul, nu reînvie |
| Hand of Midas | REPARAT – dădea și bounty‑ul creep‑ului |
| Scan, viteza maximă de atac, blocul innascut al melee, XP de recuperare/outpost | REPARAT – 270 s / 1 încărcare, 600, fără, fără |

Rămân (găsite de audit, de reparat):

| Problemă | Detalii |
|---|---|
| Quickbuy / „mark for buy” | Curierul echipei aflat la secret shop cumpără în buclă itemele marcate (6 Point Booster); clientul nu vede itemele de pe un curier care nu e al jucătorului |
| Rețete moderne | Rețetele gratuite ale itemelor built‑in înlocuite în Lua se combină înaintea celor 6.88 (scepter) |
| Iteme | Sage's Mask/Void Stone/Orchid/Eul's/Refresher +50–250 mana/s (cheie procentuală devenită fixă); Quelling Blade +140 fix; Boots of Travel fără teleport; Rapier 430; Blade Mail pasiv; BKB 60 %; Vanguard 60 %; Desolator/Arcane Boots/Bracer/Moon Shard/Tome/Smoke cu mecanici noi |
| Abilități (generator) | ~70 de abilități cu `AbilityDamage`/`AbilityDuration` mutate în chei cu nume nou; încetiniri cu semn inversat (Viper Strike, Battle Hunger, Breathe Fire...); fracții în chei procentuale (Multicast); abilități devenite innate/ascunse; tipuri de damage și imunitate neschimbate; zeci de mecanici noi de pus pe 0 |
| Abilități rescrise complet în motor | ~25 de rescris în Lua (Time Lock, Time Dilation, Replicate, Rip Tide, Repel, Battle Trance, Leech Seed, Assassinate, Static Field, Mana Shield, Multicast, Sand Storm...) |
| Clădiri | Aur de echipă la turnuri/barăci (6.88: 160/200/240/280 și 275/225, sigur; motorul dă doar last hit), Roshan 200/jucător; glyph 5 s doar pe clădiri; Tower Protection; backdoor 25 %; iluzii −30 % pe clădiri |
| Creepi | Raza de XP 1300, 35 % XP când îi omoară neutralii, upgrade‑uri +12 HP/+2 aur la 7:30, siege la fiecare al 7‑lea val |
| HUD | Timere moderne (rune, Roshan, Tormentor), fațete, talentele din scoreboard, Ring of Health/Void Stone marcate de secret shop, +200 aur la random |
