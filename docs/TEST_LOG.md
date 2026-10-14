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


## 10. Re‑verificare a build‑ului final înainte de publicarea patch notes‑urilor HTML (2026‑10‑13, dimineața)

Codul jocului (Lua, KV, hartă) este identic cu cel testat în secțiunile 8–9 (de atunci s‑au schimbat doar documentația,
pagina HTML, imaginea de previzualizare și tagline‑ul din `addoninfo.txt`). Reluat totuși în joc, pe harta `dota_688`, în fereastră:

| Test | Rezultat |
|---|---|
| Pornire pe hartă (`tryown.sh`) | OK – PRE_GAME, 0 erori Lua la încărcare |
| `basics` (CM nivel 10) | OK – HP 819 / mana 554 / armură bază + AGI/7 / respawn 8,8 … 100 s / XP 2000 / 6000 / 13500 / 32400 / buyback 400 |
| `verify1` aur pasiv | 0/s în PRE_GAME (normal); după `forcegamestart` 1,662/s (6.88: 1,667/s); Roshan 8000 HP / 5 armură / 65 daune |
| `items2` (lotul 2 de iteme) | OK – Manta +10 %, Vlad +4 armură / +3 regen, Vlad + Basilius +0, block‑ul nu se cumulează, Mekansm 252 apoi lockout, HotD +3, Flutter 35 → 0, Scythe omoară iluzia |
| `audit1` (Eclipse, Omnislash, Poison Touch, Toss, Tricks, Bloodrage) | OK – fără erori; trei linii ieșeau din așteptări din cauza condițiilor de test, re‑rulate cu condiții corecte (`recheck`, `recheck3`): **Omnislash** exact 9 lovituri de 189‑199 pe un Axe cu 1,86 armură (= 200‑225 × 0,90; diferențele inițiale erau creep‑ul care prelua lovituri și atacurile normale ale lui Juggernaut după ultimate); **Toss** aliatul aruncat 520 → 520 HP lângă o țintă imobilizată (codul nu dă daune aliaților); **Bloodrage** ucigașul din echipa adversă creep‑ului 100 → 240 HP (+137 = 25 % din 550, plus regen) |
| Test de fum eroii 1‑30 (nivel 25, fiecare abilitate activă lansată) | OK – 0 erori Lua, jocul stabil; închis curat cu `quit` |

## 11. Verificare completă a valorilor 6.88 în motor (2026‑10‑13, după‑amiaza)

Metodă nouă: pentru fiecare abilitate din sloturile celor 112 eroi (630) și fiecare item din shop (156), scriptul de test
citește din motor ce s‑a încărcat efectiv (nivel maxim, cooldown, mana, cost și toate valorile speciale pe fiecare nivel,
17 664 de valori) și le compară cu fișierele 6.88f. Apoi teste țintite pe eroi de nivel 25, pe invocări și pe neutrali.

| Problemă găsită | Corecție | Verificat în joc |
|---|---|---|
| Pasivele care azi cresc cu nivelul eroului (Desolate +1,5/nivel, Poison Sting, Hunter in the Night, încărcăturile Stone Remnant) păstrau creșterea peste valorile 6.88 | generatorul scrie `"hero_levelup" "0"` pentru orice cheie suprascrisă care are creștere | Desolate 65, Poison Sting 15 s / 24, Stone Remnant 6 încărcături la nivel 25 |
| Night Stalker nu putea învăța Hunter in the Night (motorul îi forțează nivelul maxim la 0) | rescris în Lua (`dota688_night_stalker_hunter_in_the_night`) | se învață, noaptea +35 % viteză (295 → 398) |
| Serpent Wards făceau 0 daune (în 6.88 daunele veneau din abilitate) | generatorul de unități pune 40–45 / 60–65 / 80–85 | 80–85 la nivel 3 |
| Mecanici 6.88 lipsă la abilități built‑in | `dota688/extras_688.lua` | Morph +6 AGI/+6 STR; splash la wards (2 ținte lovite); Phantom Strike se termină după 4 atacuri; Corrosive Skin −25 % viteză la 1300; Thunder Clap 8 s creep / 4 s erou; Reverse Polarity 5 s creep / 3,75 s erou |
| Mecanici moderne active (chei care există doar în clientul curent) | `tools/manual_overrides.json` (187 de intrări) | Death Ward, Glimpse, Double Edge, Shockwave, Skeleton Walk, Coup de Grace pe dagger, Spell Steal, Reactive Armor, lupi, golemi, panda, Corrosive Skin, spiderlings, Split Shot, Mystic Snake; la unități: Roshan, Satyr, Mud Golem, Dark Troll, Vhoul, Thunder Lizard, Cyclone, Earth Brewling, Arcane Boots |
| Diferențe rămase în verificarea de valori | toate explicate: costurile citite 0 fără erou sunt corecte la cast (Blade Fury 90, Hoof Stomp 130, Searing Arrows 10, Healing Ward 140), Manta 30 s melee / 45 s ranged, Unrefined Fireblast 60 % din mana curentă, Magic Stick/Wand 13 s și +15 HP/mana pe încărcătură | – |
| Invocări comparate cu unitățile 6.88 | Golem, Panda, lupi, Eidolon, Boar, Spirit Bear, zombi, Plague Ward, Death Ward (60/105/150) identice; Familiars primesc daunele din încărcături prin Lua | – |
| Unități (după corecții) | Earth Brewling imun la vrăji (Fire/Storm nu); Dark Troll: 2 scheleți, 250 HP, 23–25 daune; Satyr: −100 mana fix la un Lion cu 112 INT; Arcane Boots fără aură de mana; Roshan 0 % rezistență la status și la slow | – |
| Statistici de bază ale eroilor (nivel 1) | atribute de bază și creșteri, atribut principal, viteză, rază de atac, BAT, attack point, viteza proiectilului, daune, viziune zi/noapte și armura efectivă (bază + AGI/7): **0 diferențe** la 111 eroi (Silencer verificat separat ca erou al jucătorului, crash doar în Workshop Tools) | – |
| Test de fum pe build‑ul corectat (nivel 25, fiecare abilitate activă lansată) | **0 erori Lua**: eroii 1–80 și 82–112 | – |
| Meci jucat prin HUD pe build‑ul final (Techies pe mid, ~22 min de joc la viteză dublă, mouse + tastatură) | OK – 0 erori Lua. Abilități învățate din „+” (Land Mines 60 mana, Stasis Trap 80, Suicide 100, Minefield Sign cu punct de abilitate ca în 6.88, Remote Mines la nivel 6 cu 300/450/600 și „următorul nivel la 11”); Land Mines au omorât creepi Dire (aurul la Techies), Remote Mines plantate și detonate cu Focused Detonate; aur pasiv 1,67/s; valuri de creepi la 30 s; respawn real 20,2 s la nivel 4 și 39,2 s la nivel 9 (5 + 3,8 × nivel), buyback 100 + 1,5 × nivel² + 0,25 × timp; Suicide: respawn la jumătate (~21,5 s la nivel 10), cooldown 160. Mesajele de client „unknown modifier type modifier_dota688_tower_aura/fountain” la încărcarea hărții sunt inofensive (surse de aură ascunse, calculate pe server; efectele ajung normal la client) | – |

## 12. Test din Arcade, cu versiunea descărcată din Workshop (2026‑10‑13, după‑amiaza)

Până aici testele rulau în Workshop Tools, din fișierele proiectului. Testat acum ca un jucător: clientul Dota normal → Arcade →
„Dota 6.88 Classic” → Update → Play / Create Custom Lobby.

| Test | Rezultat |
|---|---|
| Play / Create Custom Lobby pe versiunea publicată dimineață | **BUG** – lista de hărți din Create Lobby era goală, iar Play nu pornea nimic (exact ce a pățit un prieten al autorului). Cauza: în `addoninfo.txt`, `"maps"` era scris ca bloc; Dota cere un text cu numele hărților (ca în exemplele Valve `conquest`, `manyplayer_example`) și `"IsPlayable" "1"`. REPARAT, plus o verificare nouă în `check_addon.py` |
| Jucător care nu alege eroul la timp | **BUG** – rămânea fără erou (HUD gol, 0 aur). REPARAT: la Strategy Time / Pre‑game primește un erou random (fără bonusul de +200 pentru random voluntar); testat în Workshop Tools (Dazzle random, 567 aur după penalizarea de întârziere a motorului) |
| După re‑upload: Arcade → Update → Create Custom Lobby | OK – harta `dota_688` apare, lobby creat, Start Game → Accept → încărcare → Custom Game Setup → alegerea eroului (grila 6.88 fără Universal, 112 eroi) → Strategy Time cu 625 aur → joc pe harta 6.88 cu dialogul „Dota 6.88 rules”, regulile 6.88 active (creepi 6.88, aur pasiv), 0 erori Lua |
| Notă pentru jucători | Jocul este „Player‑Hosted”: Play caută un lobby existent; dacă nu există niciunul, se folosește **Create Custom Lobby** → Create → Start Game |

## 13. Bug‑uri raportate de jucători din Arcade (2026‑10‑13, seara)

| Bug | Cauză | Corecție, verificată în joc |
|---|---|---|
| Invoker: orbe nelimitate și daune nelimitate; Invoke nu mai mergea, pe model se vedea un singur orb | motorul curent ia limita de 3 instanțe din Invoke‑ul built‑in, pe care l‑am înlocuit cu `dota688_invoker_invoke` (testat: 10 × Exort = 10 instanțe, daune 134 → 358) | `modifier_dota688_invoker_orbs` păstrează maxim 3 instanțe (orbul nou o înlocuiește pe cea mai veche), ca în 6.88. Testat: 10 × Exort → 3 instanțe (+21 daune fiecare), Q W W + Invoke → Tornado |
| Blink Dagger sărea pe loc | în 6.88 raza era în `blink_range`, iar `AbilityCastRange` era 0; generatorul copia 0 peste raza de 1200 a motorului curent | generatorul nu mai suprascrie o rază de cast cu 0; `AbilityOvershootCastRange` 960 pentru clicul peste rază (6.88: 4/5 din 1200). Testat: țintă la 1000 → salt ~1000, țintă la 2000 → salt ~960 |

## 14. A doua rundă de bug‑uri raportate din Arcade (2026‑10‑13, seara)

| Bug | Cauză | Corecție, verificată în joc |
|---|---|---|
| Boots of Travel nu se putea cumpăra | rețetele generate (`item_recipe_dota688_*`) nu aveau `BaseClass`: „entity class is NULL”, cumpărarea eșua | `BaseClass item_datadriven` pe toate cele 65 de rețete; toate se creează. BoT 1 și 2 cumpărate din shop (2400 + 2000) |
| Morbid Mask devenea MoM la cumpărare și se vindea cu profit | rețeta built‑in a lui MoM e gratuită în patch‑ul curent și ducea la MoM‑ul Lua | rețetele built‑in nu mai produc nimic (cost 99999, necumpărabile). Morbid Mask rămâne Morbid Mask; MoM = Morbid Mask + rețetă 900 |
| Mask of Madness „nu merge” | MoM venea din rețeta built‑in | MoM cumpărat normal: Berserk +100 AS, +17 % MS, cooldown 25 |
| Corabia lui Kunkka buguită | `kunkka_ghost_ship.vpcf` primește viteza în CP1, codul punea ținta | CP1 = direcție × 650; corabia pleacă de la 1000 în spatele lui Kunkka și se sfărâmă la țintă (poziții la 0,5 s: −1122 … 497, țintă 600); daune și stun |
| Tidebringer | – | funcționează: 206 daune pe fiecare creep din spate până la 800 |
| Shadow Fiend: Requiem nu se vedea, sunetul incomplet | liniile au durata în CP2 (`C_OP_StopAfterCPDuration`), nesetat; lipseau aripile și sunetul de lansare | linii create cu CP2 = durata drumului; aripi + `RequiemOfSoulsCast` în faza de lansare (verificat vizual) |
| Rune „Arcane și multe Bounty” | nu e bug: Arcane există din 6.84; la 0:00 ambele rune sunt Bounty | verificat până la 7:00: mereu 2 rune, una Bounty și una de putere |
| Orb effects se cumulau | doar lifesteal‑ul itemelor era coordonat; Morbid Mask, Desolator și Blight Stone erau built‑in | `dota688/uam.lua` (regulile 6.88), Morbid Mask / Desolator / Blight Stone în Lua. Testat: MoM vechi + Deso → doar lifesteal; Deso vechi + MoM → doar Corruption; Skadi + MoM → ambele; pe turn → Corruption; AM → niciun orb din iteme; Frost Arrows → niciun orb din iteme; Liquid Fire + Skadi → ambele; proc Mjollnir → fără lifesteal pe acel atac |
| Iteme care apar dar nu se cumpără | River Vials (Battle Pass 2016) erau în shop‑ul 6.88 | scoase din shop; celelalte 146 de iteme din shop se creează, sunt cumpărabile și au cost |
| Power Treads nu arăta atributul | atributul era ținut doar pe server | stack count + marcaj pe erou; iconița trece STR → AGI → INT (verificat vizual), statisticile corecte |
| Creepi moderni în junglă (ancient) | motorul alege aleator și camp‑uri apărute după 6.88 | camp‑ul modern e înlocuit cu un camp 6.88 de același nivel. Testat: neutrii creați din Lua ripostează, urmăresc și se întorc (ca neutrii motorului); 3 cicluri de respawn cu Prowlers / Ice Shaman / Warpine → camp‑uri 6.88, câte unul pe spawner; 9 minute fără dubluri |
| Quarterstaff (și Stout Shield, Hood, Necronomicon, Tome) nu se cumpăra | `IsObsolete 1` în patch‑ul curent: motorul refuză cumpărarea și combinarea | `IsObsolete 0` pe itemele și rețetele 6.88. Testat cu ordinul de cumpărare al HUD‑ului: cele 63 de iteme de bază se cumpără (cele secrete la Secret Shop), toate cele 83 de iteme compuse se combină |
| Phantom Assassin: indicator de crit deasupra | Coup de Grace curent dă „Deadly Focus” (critic garantat la atacul următor) | Coup de Grace în Lua (15 %, 230/340/450 %, direct pe atac). Testat: 16 % din atacuri critice, Stifling Dagger dă critic, fără Deadly Focus |
| Abilități built‑in cu mecanici noi (audit cu 2 agenți pe 229 de descrieri schimbate) | chei ale motorului curent care adaugă efecte | reparate din valori și testate: Phantasm 3–4 iluzii, Hoof Stomp stun la 0,57 s (windup‑ul rămâne: e chiar întârzierea), plus Shadow Word, Gust, Insatiable Hunger, Amplify Damage, Snowball, Stone Caller, Grave Chill, Spark Wraith, Phase Shift. De refăcut în Lua: Epicenter (testat: fără channel, nu se mai întrerupe), Rolling Boulder (stun la coliziune), Astral (daunele în arie), Void, Battle Hunger, Enchant, Echo Slam și altele |
| Test de fum după toate corecțiile (eroii 1–80 și 82–112) | – | 0 erori Lua |

## 15. Mecanici built‑in schimbate după 6.88 (2026‑10‑13, seara)

Audit cu agenți: 229 de abilități built‑in cu descrierea schimbată față de 6.88 și toate itemele built‑in din shop. Corecturi testate în Workshop Tools:

| Abilitate / item | 6.88 | Rezultat testat |
|---|---|---|
| Epicenter (Lua) | channel 2 s, stun‑ul îl anulează | canalizează; stun la 1 s → fără pulsuri, cooldown consumat; complet → 856 daune + slow |
| Rolling Boulder (Lua) | daune, fără stun; slow prin Stone Remnant | 70 daune după rezistență, fără stun, se oprește la erou; prin Stone Remnant → slow |
| Void (Lua) | mini‑stun și ziua | 2 s ziua; întrerupe Freezing Field ziua |
| Battle Hunger (Lua) | slow mereu, +12 % viteză Axe per țintă | Sven cu fața spre Axe 290 → 255; Axe +24 % cu 2 ținte; se termină la kill |
| Enchant (Lua) | fără dispel pe eroi | creep controlat 80 s, apoi dispare |
| Echo Slam (Lua) | un ecou per inamic | 213 inițial + 2 × 56 ecouri pe fiecare din 2 eroi |
| Phantom Rush (Lua) | pasiv | 290 → 1090 viteză, țintă atinsă în 0,53 s |
| Whirling Death (Lua) | pure dacă taie un copac | 200 magice fără copaci, 266 pure lângă copaci; −15 % STR |
| Refraction (Lua) | instanțe de minim 5 daune | 4 daune trec fără consum; 100 blocate, o instanță |
| Winter's Curse, Flux, Surge, Power Cogs, Natural Order (Lua, scrise de agenți) | vezi PATCH_NOTES | ținta înghețată și imună la echipa Wyvern, aliatul o atacă; Flux 0 slow lângă un aliat; Surge 522; Clockwerk și Sven rămân în cerc; Natural Order −33 % rezistență |
| Homing Missile | daune după distanță | 56 la 300, 244 la 1000 |
| Stone Gaze | 100 % rezistență la magie, iluziile mor | 100 magice → 0; iluzia moare |
| Wind Walk, Blade Fury, Devour, BKB | vezi PATCH_NOTES | Strafe scoate invizibilitatea; Blade Fury imun la magie; Devour 55 s pe Centaur Khan (1100 HP); BKB: IsMagicImmune adevărat, Void și Hex nu se aplică |
| Stout / PMS / Vanguard (Lua) + Healing Salve (Lua) | doar cel mai mare block; Salve întreg pe aliați | media daunelor pe atac: 70,2 fără, 61,0 Stout, 48,3 PMS, 38,4 Vanguard + Stout; Salve pe aliat +452 în 8 s |
| Valori | chei moderne care adaugă efecte | Phantasm 3–4 iluzii; Hoof Stomp stun la 0,57 s |

Crash‑uri văzute în teste: doar la ștergerea forțată (`UTIL_Remove`) a unui erou în mijlocul unei abilități built‑in (Timbersaw după Timber Chain + Chakram, Earth Spirit cu Boulder Smash în zbor). Reprodus și fără codul addon‑ului (fără Whirling Death Lua), deci al motorului; într‑un meci eroii nu sunt șterși.

Rezolvate apoi (aceeași seară):

| Ce | Rezultat testat |
|---|---|
| Meepo | motorul punea pe clonă pasivele tuturor itemelor (Claymore +21, Desolator, Skadi); acum doar cizmele. Share‑ul de 20 % nu ajungea pe clone (npc_spawned vine înainte de IsClone); clona: 49/43/37 = bază + Attribute Bonus + Power Treads + 20 % din Skadi, fără daunele Desolator / Claymore |
| Boulder Smash pe Stone Remnant | lovit pe teren lângă remnant (ținta directă e refuzată, remnant‑ul e invulnerabil): Sven pe traiectorie −150 și stun |
| Skull Basher | built‑in‑ul dădea bash pe Troll (4 în 15 s); Lua: pe Troll doar bash‑ul lui, pe Sven bash‑ul itemului |
| Bottle | motorul umple Bottle‑ul la 3 când stochezi runa, ca în 6.88; nimic de schimbat |
| Smoke | invizibilitatea nu se vede cu True Sight și în 6.88; nimic de schimbat |

## 16. Revizuire de cod fără joc (2026‑10‑14, sesiunea cloud) – de re‑testat pe PC

Patru revizuiri paralele (abilități, reguli/iteme, generator/KV, documentație) peste commit‑ul `055c15b`. Corectate în cod
(verificare sintactică și checker OK; **netestate în joc**):

| Ce | Problema | Corecție |
|---|---|---|
| Nether Strike (Lua) | citea `knockback_distance`/`knockback_duration`/`movespeed_duration` din Greater Bash, chei care nu mai există în KV‑ul curent → bash fără knockback, haste de 0 s | valori 6.88 de rezervă în `dota688_spirit_breaker_nether_strike.lua` |
| Stun/Hook/Toss/Grip/Black Hole/Song | `GetOverrideAnimation` fără `MODIFIER_PROPERTY_OVERRIDE_ANIMATION` declarat → unitățile nu jucau animația | declarat în `stun.lua` și cele 5 abilități |
| Rubick fură alt spell cât timp efectul primului e activ | Frostbite, Rupture, minele Techies, Nature's Guise, Song (scepter), Last Word, Toss, Walrus Punch citeau `GetAbility()` nul în think → erori la fiecare tick, efect oprit | `Dota688Val` / garduri |
| Drunken Brawler | evaziunea garantată rămânea 100 % pentru totdeauna (atacul evitat nu ajunge în `OnAttacked`) | cronometrul se resetează când se aplică evaziunea garantată |
| Meepo | moartea unei clone omora toți Meepo și fiecare moarte dădea aur/XP de kill și pierdere de aur | doar prima moarte dintr‑o secundă contează (`gamemode.lua`) |
| Aegis / Reincarnation | moartea cu Aegis sau cu Reincarnation nu dădea deloc aur/XP de kill (6.88 dădea) | aurul/XP‑ul se dau; doar respawn‑ul se sare |
| Vengeance Illusion / Hybrid | copiile de erou intrau în aurul de zonă (de două ori pentru același jucător), în împărțirea XP‑ului la creepi și în costul de buyback | excluse (`dota688_copy`) |
| Linken's Transfer | transferul pe un aliat cu propriul Linken's îi înlocuia blocul permanent cu unul de 20 s (apoi dispărea); cumpărarea în timpul unui transfer primit lăsa blocul temporar | `item_dota688_sphere.lua` |
| Aure de iteme (Basilius/Aquila, Mek, Pipe, Greaves, Vlad, Drum, Headdress, Shiva) | la vânzarea/combinarea unui exemplar din două, aura rămânea legată de itemul dispărut (rază 0) | `Dota688ReapplyAura` re‑leagă aura de exemplarul rămas |
| Diffusal (Feedback) și Orb of Venom | se aplicau în afara regulilor UAM (se cumulau cu Desolator/Skadi/lifesteal) | trec prin `dota688/uam.lua` |
| Runa Bounty după buyback | aurul ocolea penalizarea de −60 % | `Dota688GoldXP:Penalize` în `runes.lua` |
| Timere | lista de timere era modificată în timpul iterării (`pairs`) | se adună întâi cele scadente |
| Aether Lens | două Aether Lens se cumulau | bonus de cast range unic (`MODIFIER_PROPERTY_CAST_RANGE_BONUS`) |
| Generator: flaguri de țintire | Death Ward și Geminate Attack primeau `DOTA_UNIT_TARGET_FLAG_NONE` deși în 6.88 treceau prin imunitate | regula sare abilitățile cu `SPELL_IMMUNITY_ENEMIES_YES` |
| Generator: scepter built‑in | sub‑cheia modernă `special_bonus_scepter` supraviețuia override‑ului: Lasso 400+650, Decay +4 în loc de 10, Gush 260/2200, Death Ward 575 + lifesteal, Arctic Burn 20 mana + 25 MS, Enchant Totem cleave, Demonic Purge 2 încărcături/70 s, Time Lapse cd modern | override cu bloc `{value, special_bonus_scepter "=…"}` din `manual_overrides.json` (acum acceptă blocuri) |
| Tooltip‑uri | 156 de modifieri Lua vizibili fără nume în HUD | generatorul dă fiecărui `LinkLuaModifier` fără token numele abilității/itemului |
| Override‑uri manuale inerte | 30 de intrări țintesc abilități/iteme înlocuite de Lua | generatorul le sare și avertizează |

Rămase deschise (nu se pot rezolva fără joc sau sunt decizii):

* De re‑testat în joc tot tabelul de mai sus, plus Aghanim la Invoker, Lone Druid, Ogre Magi, Wraith King, Rupture (încărcături),
  Ursa (Enrage sub stun), Venge/Hybrid (copii), Rubick (Death Ward furat), Alchemist (dă scepter‑ul), Tiny (copacul),
  HOOKS (Primal Roar, Chronosphere, Hookshot, Time Lapse, Impetus, Viper Strike, Invoke) – nu au rând în TEST_LOG.
* Iluziile −30 % daune pe clădiri (TEST_LOG §6) – nu există cod; Astral Imprisonment (daune în arie) – încă built‑in.
* Comeback / First Blood / bounty iluzii (commit `1298a63`), Omnislash fără BKB (`e1bdc3d`), Rum pe toți aliații (`055c15b`) – fără test.
* Octarine ×2 și Pipe + Hood se cumulează (6.88: nu); Lotus Orb reflectă prin iteme reale în inventar 3 s; Tempest Double
  moare ca erou (pierdere de aur 30×nivel); random forțat și pentru sloturile fără echipă; viteză maximă 550 (fără API).
* Documentație: TEST_LOG §2/§6–8 descriu curierul 6.88 scos apoi (f94b009); numerele din README/PATCH_NOTES (abilități/iteme)
  diferă de STATUS.md; `dota_688.vmap` (31 MB) este comis direct (candidat Git LFS).
