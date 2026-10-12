# Jurnal de testare în joc

Testat pe 2026‑10‑12 în Dota 2 Workshop Tools (client build 25845666), harta standard `dota`
(`dota_launch_custom_game dota_688 dota`), cu `-condebug -netconport 29000`.

**Metodă.** Consola jocului este comandată prin portul VConsole; scenariile de test sunt scripturi Lua rulate cu
`script_reload_code dota688_test/<scenariu>` (folderul `scripts/vscripts/dota688_test/` nu se comite). Fiecare
scenariu joacă ordine reale (`ExecuteOrderFromTable`), măsoară efectul și scrie rezultatul în consolă; erorile Lua
sunt luate din `console.log`. API‑ul VScript al clientului curent a fost dumpat din VM (server + client) în
`build/vscript_api_*.txt`, iar `tools/check_addon.py` verifică acum fiecare apel/constantă din Lua față de el.

Legendă: **OK** = verificat în joc · **REPARAT** = eroare găsită în joc și corectată (commit) · **DE FĂCUT** = netestat încă.

## 1. Pornire

| Test | Rezultat |
|---|---|
| Încărcare KV (`npc_heroes_custom`, `npc_abilities_override`, `npc_items_generated`, `shops.txt`) | OK (nicio eroare de KV la încărcare) |
| Valorile abilităților Lua (`GetSpecialValueFor`) | REPARAT – toate întorceau 0: motorul curent nu mai citește `AbilitySpecial`; generatorul scrie acum `AbilityValues` (Remote Mines `max_mines` 0 → 21) |
| Localizare | REPARAT – `LOCFAIL: Ignoring unsupported encoding in localization file 'resource/addon_english.txt'`; fișierele generate se scriu UTF‑8 cu BOM |
| `custom_net_tables.txt` | REPARAT – `Unable to determine buffer encoding`; format KV3 |
| Erori `[VScript]` la pornire | REPARAT – `respawn_buyback.lua:37: attempt to call method 'SetBuybackCost' (a nil value)` la fiecare spawn/moarte → `PlayerResource:SetCustomBuybackCost` |
| Modifierii globali pe client | REPARAT – `Attempted to create unknown modifier type modifier_dota688_attributes!` (clientul nu avea `LinkLuaModifier`) |
| `[dota688] API lipsa: ...` | OK – nu apare; toate apelurile `Dota688SafeCall` există în API |
| API‑uri dispărute din Lua (găsite cu dump‑ul VM) | REPARAT – `ReduceMana`, `SetMinimapIconHidden`, `IsTree`, `MODIFIER_PROPERTY_CANNOT_MISS`, `DOTA_DAMAGE_FLAG_BYPASSES_BLOCK`, 6 constante `DOTA_PSEUDO_RANDOM_*`, ținta Tether |
| Panoul „6.88” în HUD | OK – butonul „6.88” apare sus‑dreapta |
| Talente, backpack, slot neutru, slot TP ascunse | OK – inventar 6 sloturi, fără backpack/neutru |

## 2. Reguli de joc

| Test | Rezultat |
|---|---|
| Aur de start 625 | OK |
| Atribute nivel 1 (Techies 17/14/22): HP 200+20×STR, mana 50+12×INT, armură AGI/7 | OK – 540 HP, 314 mana, 7.0 armură |
| Viteza de atac | REPARAT – 104 în loc de 114: motorul curent are viteză de bază per erou (85–125); toți eroii au acum 100 ca în 6.88 |
| Rezistență la magie | REPARAT – 27.2 % în loc de 25 %: motorul adaugă 0.1 %/INT; compensat în `modifier_dota688_attributes` |
| Spell amp din INT (1 % / 16 INT) | OK – 1.37 % la 22 INT |
| Ultimate la 6/11/16 | REPARAT – ultimate‑urile Lua aveau `DOTA_ABILITY_TYPE_ULTIMATE` (nume 6.88, nerecunoscut → 4 niveluri de la nivelul 1); toate ultimate‑urile erau la 6/12/18 |
| Abilități de bază 1/3/5/7 | OK |
| Attribute Bonus în bara de abilități | REPARAT – HUD‑ul curent nu afișează `ABILITY_TYPE_ATTRIBUTES`; abilitatea devine de tip BASIC (10 niveluri) |
| Buyback 100 + 1.5·L² + 0.25·t | OK – 108 la nivel 1, 0:28 |
| Rune: două în râu, Bounty la 0:00 | REPARAT – spawner‑ele hărții adăugau rune Shield/Bounty în junglă/power rune peste cele 6.88; toate tipurile sunt dezactivate în motor, runele vin doar din `runes.lua` |
| Creepi pe lane | OK – valurile pornesc la 0:00 |
| Neutrali la 0:30 | OK – 28/28 camp‑uri, 2–5 neutrali pe camp, fără stivuire |

## 3. Eroi și abilități

| Test | Rezultat |
|---|---|
| Techies: Land Mines, Stasis Trap, Remote Mines, Focused Detonate, Minefield Sign, Suicide | REPARAT/OK – 260 fizic, stun 4 s, detonare individuală și Focused, semn, Suicide 1150 + respawn 50 %; Focused Detonate (NOT_LEARNABLE) nu primea nivel la învățarea Remote Mines |
| Modifieri care rămân după ce abilitatea dispare (Rubick, iluzii) | REPARAT – 38 de callback‑uri protejate (thinker‑ele se opresc, getter‑ele întorc 0) |
| Iconițe | REPARAT – 8 iconițe 6.88 inexistente înlocuite cu cele actuale |
