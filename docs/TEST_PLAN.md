# Plan de testare în joc (Workshop Tools)

Tot ce este aici nu se poate verifica offline. Se testează cu `dota_launch_custom_game dota_688 dota_688` (sau pe harta
`dota` a jocului dacă `dota_688.vpk` nu există încă: `dota_launch_custom_game dota_688 dota`), cu `sv_cheats 1`,
`dota_bot_populate`/`-cheats` după nevoie. Comenzi utile: `-lvlmax`, `-gold 99999`, `-item item_dota688_ultimate_scepter`,
`-createhero npc_dota_hero_x enemy`, `dota_ability_debug 1`, `script_reload`.

Rezultatele se scriu în `docs/TEST_LOG.md` (o linie per test: OK / eroare + mesajul din consolă). Erorile de Lua apar în
consolă ca `[VScript]` / `Script Runtime Error`; cele de KV ca avertismente la încărcarea addon‑ului.

## 1. Pornire

- [ ] Addon‑ul se încarcă fără erori de KV (`npc_heroes_custom`, `npc_abilities_override`, `npc_items_generated`, `shops.txt`).
- [ ] Nicio eroare `[VScript]` la pornire (`addon_game_mode.lua`, `dota688/*.lua`).
- [ ] Mesajul `[dota688] API lipsa: ...` nu apare; dacă apare, API‑ul respectiv trebuie înlocuit (lista în `dota688/gamemode.lua`).
- [ ] Panoul „6.88” din HUD se deschide; talentele, backpack‑ul, slotul neutru și slotul de TP sunt ascunse.

## 2. Reguli de joc (`docs/REGULI_6.88.md`)

- [ ] Aur de start 625; +1 aur la 0.6 s; aur/XP la kill după formulele 6.88 (compară cu `dota688/constants.lua`).
- [ ] Atribute: HP/mana pe punct, armura din AGI 1/7, fără spell amp din INT; HP de bază 200, mana 50 (verifică un erou la nivel 1).
- [ ] Atribute Bonus +2 ×10 niveluri; ultimate la 6/11/16; nivel maxim 25.
- [ ] Rune: două locuri în râu, la fiecare 2 min, una mereu Bounty; la 0:00 ambele Bounty.
- [ ] Zi/noapte 4+4 minute; Roshan 8000 HP și bonusurile la 4 min; Cheese de la a 3‑a moarte.
- [ ] Respawn 5+3.8×L; buyback 100+1.5L²+0.25t, cooldown 420 s, penalizare −60 % aur; curier cumpărat (100/150).
- [ ] Neutralii apar la 0:30; fără iteme neutre; fără shrines.
- [ ] Shop: layout 6.88; itemele vechi (Iron Talon, Poor Man's Shield, Ring of Aquila, Necronomicon vechi…) se cumpără și funcționează.

## 3. Eroi și abilități

- [ ] Fiecare erou din `herolist.txt` se poate alege și are abilitățile din 6.88 în sloturile corecte (fără fațete/inate/talente).
- [ ] Abilitățile Lua (`dota688_*`, lista în `docs/STATUS.md`) se pot învăța, au tooltip, se lansează fără eroare.
- [ ] Itemele Lua (`item_dota688_*`) dau statisticile corecte și efectele active (Dagon, Force Staff, Euls, Manta, Blink…).
- [ ] Invoker: orbele dau atribute pe instanță; Multicast la Ogre; Split Shot la Medusa; familiarii lui Visage; Meepo cu 3 clone.
- [ ] Techies: mine, capcane, Suicide, Focused Detonate, Minefield Sign.

## 4. Aghanim's Scepter (`docs/AGHANIM.md`)

Cumpără `item_dota688_ultimate_scepter` și verifică pe rând:

- [ ] Eroii „built‑in” (Earthshaker, Witch Doctor, Tidehunter, Weaver, Batrider, Undying, Phoenix, Winter Wyvern, Silencer,
      Shadow Demon, Nyx, Earth Spirit): modifierul `modifier_item_ultimate_scepter_consumed` apare și upgrade‑ul se activează;
      dispare când itemul e vândut.
- [ ] Abilitățile deblocate (Assimilate, Unrefined Fireblast, Walrus Kick, Chakram 2, Eyes in the Forest, Hybrid) apar la
      nivel 1 cu scepter și dispar fără.
- [ ] HOOKS: Primal Roar cd 45/rază 950, Chronosphere cd 60, Hookshot cd 12, Time Lapse cd 16 + pe aliat, Viper Strike,
      Impetus +190, Invoke cd 16/8/4/2 fără mana, Spell Steal cd 2/rază 1400 (verifică că Octarine scalează corect).
- [ ] Fiecare ultimate rescris în Lua, cu și fără scepter (lista completă în tabelul din `docs/AGHANIM.md`); atenție la:
      Meat Hook (tragerea), Burrowstrike (mișcarea + stun), Ghostship (Rum, tragerea cu scepter), Ice Blast (trasor + release),
      Song of the Siren (cancel), Chain Frost (sărituri), Requiem (linii + întoarcere), Eclipse pe aliat/zonă, Toss.
- [ ] Modifieri built‑in aplicați din Lua: Overgrowth lângă ochii lui Treant, Astral Imprisonment din Sanity's Eclipse,
      Nightmare pe cine atacă Bane în Fiend's Grip.
- [ ] Rupture: `SetCurrentAbilityCharges` afișează 2 încărcături (dacă API‑ul lipsește, scoate apelul).
- [ ] Ursa: Enrage sub stun/hex (filtrul de ordine primește ordinul); fără scepter nu merge.
- [ ] Venge: la moarte cu scepter apare copia cu abilități, controlabilă, dispare la respawn, nu dă aur/XP.
- [ ] Morphling Hybrid: copia aliatului cu abilități, 20 s.
- [ ] Invoker: Quas/Wex/Exort +1 nivel cu scepter (spell‑urile invocate mai puternice), atributele orbelor neschimbate,
      la vânzare nivelul revine.
- [ ] Rubick: un spell furat de la Witch Doctor are Death Ward cu sărituri; furtul unui spell nou nu fură 2 spell‑uri.
- [ ] Meepo: a 4‑a clonă cu scepter, dispare la vânzare; clonele au 20 %/100 % din atributele din iteme.
- [ ] Alchemist: itemul se poate arunca pe aliat; aliatul primește modifierul permanent; ceilalți eroi nu pot folosi itemul.
- [ ] Tiny: copacul apare în mână cu scepter + Grow.
- [ ] Sven (aură), Gyro (Side Gunner), Batrider (100 dps), Shaman (wards +45), Warlock (2 golemi −25 %), Visage (3 familiari),
      Brewmaster (brewlingii cu Thunder Clap / Drunken Haze / Drunken Brawler).

## 5. Harta (`docs/HARTA.md`)

- [ ] `dota_688.vmap` compilată; spawner‑ele, shop‑urile, Roshan, runele (`dota688_rune_top/bot`), turnurile, barăcile, fântânile.

## Cum se corectează

1. Erorile de Lua se repară în fișierul indicat în consolă (`scripts/vscripts/...`), apoi `script_reload` sau restart.
2. După orice schimbare în `tools/` sau în fișierele Lua: `python tools/gen_overrides.py` și `python tools/check_addon.py`.
3. Commit cu mesaj clar, push pe branch‑ul de lucru; PR‑ul se actualizează singur.
