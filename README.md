# Dota 6.88 Classic – hartă Workshop „înainte de 7.00”

Custom game pentru Dota 2 care recreează jocul așa cum era în **6.88f** (decembrie 2016), ultimul patch
dinaintea lui 7.00: fără talente, fără backpack, fără shrine‑uri/outpost‑uri/iteme neutre, harta veche,
112 eroi, Attribute Bonus, 25 de niveluri, aur/XP/respawn/buyback/rune după regulile de atunci.

Proiectul rulează pe motorul curent al Dota 2 (Workshop Tools), deci nu „dă jocul înapoi”, ci
**suprascrie** tot ce s‑a schimbat: valorile eroilor, abilităților, itemelor și unităților vin direct
din fișierele originale Valve de la 6.88f, iar regulile de joc sunt implementate în Lua.

## Stare actuală (fundația)

| Zonă | Stare |
|---|---|
| Date de referință 6.88f (eroi, abilități, iteme, unități, texte) | ✅ `reference/6.88f/` (fișierele originale Valve, din istoricul GameTracking‑Dota2) |
| Generator automat de override‑uri 6.88 → motor curent | ✅ `tools/gen_overrides.py` + `tools/kv.py` |
| 112 eroi activați cu statistici 6.88, 15 eroi noi dezactivați, talente/inate/fațete scoase | ✅ generat în `npc_heroes_custom.txt` |
| Valori 6.88 pentru 530 abilități și 303 iteme (cooldown, mana, damage, rețete, prețuri, niveluri de ultimate 6/11/16) | ✅ generat în `npc_abilities_override.txt` |
| 72 iteme apărute după 6.88 scoase din shop | ✅ |
| Turnuri, barăci, Ancient, fântână, creepi, neutrali, Roshan, curieri cu statistici 6.88 | ✅ generat în `npc_units_custom.txt` (98 unități) |
| Reguli de joc în Lua (aur, XP, nivel 25, respawn, buyback, rune, zi/noapte 4+4, Roshan, fără backpack, curier cumpărat) | ✅ `game/dota_addons/dota_688/scripts/vscripts/` – **netestat încă în joc** |
| Abilități reworkate după 6.88 rescrise în Lua cu mecanica originală | ✅ 90+ abilități de erou (toate cele dispărute + cele cu rework major: Riki, Techies, Lycan, Treant, Necrophos, Viper, Io, OD, Pudge, Slardar, Sven, Tiny, Undying, Visage, Wraith King…) – lista în `docs/STATUS.md` |
| Iteme cu mecanica 6.88 rescrise în Lua (Heart, Skadi, S&Y, Halberd, Abyssal, Dagon, Veil, Medallion, Solar Crest, Octarine, Shiva, Scythe, Urn, Mek, Pipe, Greaves, Vlad, Basilius/Aquila, Soul Ring, Atos, E-Blade, Manta, Armlet, Battle Fury, Drums, Silver Edge, HotD, Bloodstone, Linken, MKB, Butterfly, Satanic, MoM, Phase, Treads, Diffusal, Midas, Iron Talon…) | ✅ 64 iteme + shop-ul cu layout-ul 6.88 (`shops.txt`) |
| Abilități built-in cu mecanici noi dezactivate prin override manual (`tools/manual_overrides.json`) | ✅ parțial (Mana Break, Heartstopper, Necromastery, Psionic Trap, Divided We Stand…) |
| Panorama: talente, backpack, slot neutru, slot TP ascunse | ✅ `content/.../panorama` – de verificat ID-urile la patch-uri noi |
| Abilități rămase de verificat/rescris (ex. Invoker Quas/Wex/Exort, Ogre Multicast, Medusa Split Shot, Techies Minefield Sign) | 🔜 vezi secțiunea „valori speciale dispărute” din `docs/STATUS.md` |
| Harta 6.88 (Hammer) | 🔜 plan în `docs/HARTA.md` |
| Testare în Workshop Tools | 🔜 |

Detalii: `docs/REGULI_6.88.md` (toate regulile și sursa lor), `docs/STATUS.md` (raport generat),
`docs/HARTA.md` (ce trebuie construit în Hammer), `docs/ROADMAP.md`.

## Structura repo‑ului

```
game/dota_addons/dota_688/        <- addon-ul (se copiază/linkează în dota 2 beta/game/dota_addons/)
  addoninfo.txt
  resource/addon_*.txt            <- texte
  scripts/npc/                    <- KV: eroi, abilități, iteme, unități (generate + custom)
  scripts/vscripts/               <- Lua: reguli de joc, modifiers, abilități custom
content/dota_addons/dota_688/     <- sursa hărții (Hammer), panorama (se copiază în .../content/dota_addons/)
reference/6.88f/                  <- fișierele originale Valve din 6.88f
reference/current/                <- fișierele Valve curente (pentru diff)
tools/                            <- generatorul (Python 3, fără dependențe)
docs/                             <- documentație (română)
```

## Instalare pentru testare

1. În Steam: Dota 2 → Proprietăți → DLC → bifează **Dota 2 Workshop Tools DLC**.
2. Clonează repo‑ul și copiază (sau fă symlink/junction):
   * `game/dota_addons/dota_688` → `...\dota 2 beta\game\dota_addons\dota_688`
   * `content/dota_addons/dota_688` → `...\dota 2 beta\content\dota_addons\dota_688`
3. Pornește `dota2cfg.exe` / Workshop Tools, alege addon‑ul `dota_688`.
4. Până există harta proprie, testează regulile pe harta standard: în consolă
   `dota_launch_custom_game dota_688 dota` (vei vedea harta 7.x, dar eroii/itemele/regulile sunt 6.88).
   Runele cer punctele `dota688_rune_top` / `dota688_rune_bot` sau spawner‑ele Valve de rune de putere.

## Cum adaugi o reimplementare 6.88

1. Abilitate de erou: creează `scripts/vscripts/abilities/heroes/dota688_<nume_original>.lua` (clasa Lua cu același nume).
   Item: `scripts/vscripts/items/item_dota688_<nume_fără_item_>.lua` (poți folosi `Dota688DefineItem` din `items/dota688_item_base.lua`).
2. Rulează `python3 tools/gen_overrides.py`. Generatorul:
   * copiază blocul KV original din 6.88 (`AbilitySpecial`, cooldown, mana, etc.) în `npc_abilities_generated.txt` / `npc_items_generated.txt`, cu `BaseClass ability_lua/item_lua` și textura originală;
   * pune abilitatea în slotul eroului în locul celei built-in; pentru iteme scoate built-in-ul din shop, generează rețeta custom și rescrie rețetele care îl folosesc;
   * copiază tooltip-urile 6.88 în `resource/addon_english.txt`.
3. Valorile se citesc în Lua cu `self:GetSpecialValueFor("cheie_din_6.88")`.

## Regenerarea fișierelor KV și verificările

```
python3 tools/gen_overrides.py     # regenerează KV, shop, tooltip-uri, docs/STATUS.md
python3 tools/check_addon.py      # verificări de consistență (sloturi, scripturi Lua, rețete, shop, sintaxă)
```

Citește `reference/6.88f` și `reference/current`, scrie fișierele din `scripts/npc/` și `docs/STATUS.md`.
Abilitățile/itemele definite manual în `npc_abilities_custom.txt` / `npc_items_custom.txt` (reimplementări Lua)
sunt detectate după nume și puse automat în sloturile eroilor în locul variantei built‑in.

Pentru a actualiza `reference/current` după un patch nou al Dota 2, vezi `tools/README.md`.

## Licență

Codul proiectului: GPL‑3.0 (vezi `LICENSE`). Fișierele din `reference/` sunt date de joc Valve,
incluse doar ca referință pentru un custom game publicat în Steam Workshop al Dota 2.
