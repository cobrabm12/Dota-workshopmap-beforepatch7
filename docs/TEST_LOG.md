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

## 7. Runda a doua: audit cu agenți, rescrieri 6.88 și harta proprie (2026‑10‑12, seara)

Harta 6.88 compilată de noi (`dota_launch_custom_game dota_688 dota_688`), Workshop Tools fără dialogul „Legacy Compiled Data”.

| Test | Rezultat |
|---|---|
| Test de fum: 112 eroi, nivel 25, fiecare abilitate activă lansată printr‑un ordin real | OK – 0 erori Lua; cele 30 de abilități rescrise azi în Lua se lansează (Assassinate verificat separat: ochire 2 s, 244 daune, cd 20 s; în testul de fum ținta era în ceață). Două crash‑uri ale testului: ștergerea unităților dintr‑un Chronosphere activ (REPARAT pentru cod: `Dota688SafeRemove`) și eroi creați fără precache (artefact al testului) |
| 75 de iteme Lua: statistici + activă | OK – 0 erori; Boots of Travel teleportează, Rapier +330, Power Treads/Phase Boots, Dust |
| Tower Protection | OK – +1 armură lângă T1, +3 lângă T2, aura modernă blocată |
| Glyph | OK – 33/33 clădiri invulnerabile 5 s, cooldown 300 s |
| Aur la distrugerea unui turn | REPARAT – 160 echipă + last hit; motorul curent ignoră `reliable` la `ModifyGold` (doar Bounty rune rămâne sigur), deci aurul sigur se dă cu `Dota688GiveGold` (+160 sigur, 0 nesigur) |
| XP de la creepi | OK – motorul blocat, XP‑ul dat de Lua în 1300 (melee 45, ranged 90, o singură dată) |
| Valuri de creepi | OK – siege adăugat la valul 7 (3:30); HP/aur/XP 6.88 (melee 550 HP, 36–40 aur, 45 XP) |
| Neutrali | OK – primul spawn la 0:30 (41 de neutrali la 0:31), fără stack‑uri singure |
| Rune 6.88 | OK – Double Damage 35→70, Haste 522, invizibil după 2 s, Regen +100/+67 pe s, 2 iluzii, Bounty doar pentru cel care o ia (+62 aur, +80 XP la minutul 6); textul din chat „Double Damage” |
| Curier | OK – Animal/Flying Courier; REPARAT – „mark for buy” la secret shop cumpăra în buclă (curierul fără proprietar): acum un singur Energy Booster |
| Sunete | REPARAT – 53 de evenimente dispărute din client refăcute (Techies, Bloodstone, Laguna Blade, Razor...); `check_addon.py` le verifică |
| Comenzile curierului | REPARAT – Return to Base mergea în centrul hărții, Go to Secret Shop la shop‑ul celeilalte echipe (raport din playtest); comenzile 6.88 în Lua: fântâna și secret shop‑ul echipei, stash și livrare pentru jucătorul care dă ordinul (testat) |
| Fântâna | REPARAT – 4 % HP pe secundă (măsurat +82 HP la 1960 maxim); mana 4 % + 14 |
| Backdoor protection | REPARAT – motorul reduce 50 %, 6.88 25 %: atac 14 → 21 fără creepi lângă turn (28 cu creepi) |

## 8. Runda a treia: după restartul PC‑ului (2026‑10‑12, noaptea)

Pornire curată pe harta proprie, jocul în fereastră; repornirile se fac acum cu `quit` din consolă (kill‑urile forțate
declanșau crash‑ul driverului AMD la pornirea următoare).

| Test | Rezultat |
|---|---|
| Pornire | OK – 0 erori Lua, 66 de clădiri, 0 entități lipsă pe hartă |
| Fântâna: mana | REPARAT – `SetFountainConstantManaRegen` nu mai are efect (măsurat: doar 4 %); +14 mana/s printr‑o aură proprie pe fântâni: 27.5 mana/s la 314 mana maximă (14 + 12.56 + regen propriu) |
| Techies – Suicide Squad, Attack! | OK – respawn × 0.5 (21.5 s la nivelul 10), inamicii nu primesc XP sau aur |
| Bloodstone | REPARAT – pierdea două treimi din charge‑uri (`on_death_removal 0.67` = cât rămâne): acum 12 → 8 → 5; +1 mana/s pe charge (tooltip 6.88) lipsea; respawn −3 s/charge, vindecare aliați, Pocket Deny fără XP pentru inamici, +1 charge la erou inamic mort în 1600 |
| Curier – butoanele din HUD | REPARAT – Deliver Items, F3, burst, meniul de click dreapta (fântână / secret shop) și Select Courier căutau curierul personal 7.x și nu trimiteau niciun ordin; acum merg prin server pentru orice jucător al echipei (testat cu click‑uri reale și cu un coechipier simulat) |
| Curier – statistici | REPARAT – motorul punea magic immune, phased și +10 viteză/nivel; burst‑ul dădea +800 % (3420 viteză) în loc de 800; în fântână curierul avea 550. Acum 350 (sol și zburător), burst 800 timp de 4 s, cooldown 90 |
| Curier – moarte | REPARAT – motorul îl reînvia după 50–66 s; acum 120 s / 180 s (zburător), cu itemele, în fântână |
| Formula armurii | OK – măsurat 1000 daune fizice la 6,6 armură = 715 (0,06·A/(1+0,06·\|A\|)); la armură negativă motorul folosește aceeași formulă, identică cu Dota 2 6.88 (formula cu 0,94 era doar în WC3 DotA) |
| Atribute | OK – +10 STR = +200 HP, +10 INT = +120 mana, +10 AGI = +1,43 armură; rezistență magică 25 % (10000 magic → 7500); regen mana 0,01 + 0,04·INT; nivel maxim 25, Attribute Bonus 0/10 |
| Regen HP | REPARAT – motorul dă acum 0,1 HP/s pe STR (compensam 0,09): CM 1,50 → 1,19 (0,25 + 0,03·31), Axe 4,43 |
| Respawn / buyback / XP | OK – 5 + 3,8·nivel (100 s la 25), buyback 100 + 1,5·nivel² + 0,25·timp (400 la nivel 10 / 10 min), tabelul de XP 6.88 (2000 / 6000 / 13500 / 32400) |

## 9. Audit cu agenți: iteme și abilități Lua față de KV‑ul și tooltip‑urile 6.88 (2026‑10‑13, noaptea)

Patru agenți au comparat fiecare `GetSpecialValueFor` și fiecare mecanică din tooltip‑urile 6.88 cu codul Lua (76 de iteme, 190 de
abilități). Toate cheile citite există în KV‑ul încărcat; problemele erau semantice. Corectate (verificate în joc unde scrie „testat”):

| Zonă | Corecții |
|---|---|
| Iteme, impact mare | Hurricane Pike (+100 AS doar în activă), Echo Sabre (atacul dublu lipsea), Ethereal Blade (atributul principal), Bloodthorn (145 % pentru orice atacator), Urn (goală la început, +2/+1, doar cea mai apropiată, se rupe la eroi/turnuri), Linken (Transfer Spellblock lipsea), Lotus Orb (Echo Shell reflectă – testat cu Hex de la Lion) |
| Iteme, impact mediu | Damage block doar pe atacuri și fără cumulare; lifesteal‑ul itemelor UAM; aurele de armură Basilius/Aquila/Vlad unice; Vlad +3 regen în aură; Crimson Guard doar eroi + lockout 50 s; Mek/Greaves lockout 25 s; Manta +10 % (unic); Medallion/Solar +regen mana; HotD +3 regen și unitatea moare la vânzare; Abyssal fără bash pe SB/Void/Slardar/Troll și Linken pe activă; Flutter scoate evaziunea; Scythe distruge iluziile și nu face dispel; Silver Edge/Glimmer/Heart după note |
| Eroi, impact mare | Toss, Tricks of the Trade, Essence Aura, Meat Hook, Eclipse (fără stun, noapte 10 s – testat), Necromastery/Requiem, Omnislash (200‑225, creepii mor – testat), Starstorm, Howl, Drunken Brawler, Black Hole, Poison Touch (testat), Ice Blast, Marksmanship, Curse of Avernus, Bloodrage (vindecarea ucigașului), Life Break, Berserker's Blood liniar |
| Eroi, imunitate la vraji după KV | Eye of the Storm, Land Mines (+clădiri), Poison Nova, Plague Aura, Windrun, Counter Helix, Ice Blast, Weave, Earth Splitter; Reaper's Scythe nu mai dă daune prin imunitate |
| Eroi, restul | Sanity's Eclipse pe imprisonați, TGW nu lovește invizibili, Nether Strike în spate, Mystic Flare fără iluzii, Blink Strike fără atac gratuit, Enrage dispel, Life Drain, Stasis Trap, Chain Frost (mini‑stun, fără zombii), Sadist/Necromastery la deny, KotL heal cu scepter, Hybrid fără ultimate, Enfeeble nepurgabil, Shadow Walk/Stampede/Sprint prin unități, Reality Rift cu iluzii, Chilling Touch pe AA, Return pe turnuri, Fiend's Grip, Wall of Replica, Thirst, Gravekeeper's Cloak > 15, Nethertoxin pe clădiri, Unstable Current, Arcane Orb pe invocați, Suicide/Nether Swap distrug copaci, Electric Vortex fără ancienți, Duel la 2000, Living Armor pe minimap, Nature's Guise la cast, Flesh Heap la kill‑uri, Witchcraft pe Silence, Vengeance Aura negativă pe ucigaș |
| Verificate și corecte | Formula armurii (0,06 cu \|A\| și în 6.88), Decrepify pe aliați (KV ambiguu, lăsat ca −25 % daune), pasivele neînvățate nu au efect (modifier‑ul nu există la nivel 0) |
| Verificate după restart (a doua rundă) | Omnislash permite iteme (Dust folosit, Blade Fury blocat – testat), Lotus Orb reflectă și itemele (Dagon 5 reflectat pe Lion, copia scoasă din inventar – testat), Echo Sabre lovește dublu și respectă cooldown‑ul de 5 s (testat pe creep), Bloodrage vindecă ucigașul (+137 – testat); Death Prophet are în 6.88f Spirit Siphon (nu Witchcraft), deci nota agentului nu se aplică; 0 abilități post‑6.88 în sloturile celor 112 eroi |
| Bloodthorn True Strike | REPARAT – evaziunea țintei cu Soul Rend e anulată pentru toți atacatorii (`NEGATIVE_EVASION_CONSTANT`; testat: Butterfly 0,35 → −99,65) |
| Ghostship | REPARAT – corabia pornea de la 1000 în spatele punctului țintit (impact la 1,5 s); în 6.88 pornea de la 1000 în spatele lui Kunkka și parcurgea până la 2000 (Liquipedia, Archive:Kunkka: „~3 s până la impact”). Testat: impact la 3,5 s pentru o țintă la 1000 (2000/650 + cast point), Kunkka primește Rum |
| Rămase | – |
| Test de fum după audit: 112 eroi, nivel 25, fiecare abilitate activă lansată | OK – 0 erori Lua din corecții; o eroare veche găsită și reparată (aura Flesh Golem rămasă fără abilitate după ce Undying dispare; același gard pus la Eye of the Storm și Dream Coil). Crash‑ul cunoscut la Silencer (modelele cosmetice neprecache‑uite în tools) rămâne un artefact al testului |
| Lotul 2 de iteme, testat în joc | Manta 290 → 319 (+10 %), Vlad +4 armură și +3 regen, Vlad + Basilius +0 armură, Restore al doilea +0 (lockout), HotD +3 regen, Flutter evaziune 35 → 0, Scythe omoară iluzia, Bloodrage: ucigașul inamic +137 HP |
| Test de fum final, pe codul final | OK – eroii 1‑80 și 82‑112 (două sesiuni), nivel 25, fiecare abilitate activă lansată printr‑un ordin real: 0 erori Lua. Silencer e sărit (crash al Workshop Tools la modelele lui cosmetice, nu al addon‑ului). Abilitățile raportate „nelansate” de test sunt cele cu condiții pe care testul nu le îndeplinește (toggle‑uri, ținte creep/aliat, Invoker etc.), aceleași ca în rundele anterioare |
| Silencer (ocolit la fum) | OK – testat ca erou al jucătorului (precache normal, fără crash): Glaives of Wisdom +60 % INT, Last Word pune silence după cast‑ul inamicului, Curse of the Silent și Global Silence (built‑in) se aplică. Crash‑ul de la fum vine din crearea lui cu `CreateUnitByName` fără modelele cosmetice precache‑uite (Workshop Tools), nu din addon |
| Play‑through real (mouse + tastatură prin HUD, meci natural pe harta 6.88) | OK – level‑up din „+”, Land Mines (Q) plantată pe sol, atac‑move (A), 2 last‑hit‑uri cu aur/XP (nivel 4 la 10:50), moarte la creep: respawn 24 s la nivel 5 (5 + 3,8·5), −150 aur (30·5), buyback afișat 314, respawn în fântână cu HP plin, K/D/A 0/1/0 în HUD; shop‑ul cu layout‑ul 6.88 se deschide cu F4 (click‑urile sintetice ale uneltei de automatizare nu produc ordine de cumpărare în grilă – cumpărăturile din shop au fost verificate de utilizator în sesiunile anterioare) |

