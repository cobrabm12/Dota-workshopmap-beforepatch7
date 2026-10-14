# Dota 6.88 Classic – the "before 7.00" Workshop map

A Dota 2 custom game that recreates the game as it was in **6.88f** (December 2016), the last patch
before 7.00: no talents, no backpack, no shrines / outposts / neutral items, the old map, 112 heroes,
Attribute Bonus, 25 levels, and the gold / XP / respawn / buyback / rune rules of that time.

Steam Workshop: **[Dota 6.88 Classic](https://steamcommunity.com/sharedfiles/filedetails/?id=3818931233)** ·
**[Full patch notes](https://cobrabm12.github.io/Dota-workshopmap-beforepatch7/patchnotes/)** (Valve‑style: every hero with its abilities, every item, the map and the rules; [text version](docs/PATCH_NOTES.md))

![Mid lane on the 6.88 map](docs/img/mid_lane.jpg)

The project runs on the current Dota 2 engine (Workshop Tools), so it does not "roll the game back":
it **overrides** everything that changed since. Hero, ability, item and unit values come straight from
Valve's original 6.88f files, and the game rules are implemented in Lua.

## Current state

| Area | State |
|---|---|
| 6.88f reference data (heroes, abilities, items, units, texts) | ✅ `reference/6.88f/` (Valve's original files, from the GameTracking‑Dota2 history) |
| Automatic 6.88 → current engine override generator | ✅ `tools/gen_overrides.py` + `tools/kv.py` |
| 112 heroes enabled with 6.88 stats, 15 newer heroes disabled, talents / innates / facets removed | ✅ generated into `npc_heroes_custom.txt` |
| 6.88 values for 530 abilities and 303 items (cooldown, mana, damage, recipes, prices, ultimate levels 6/11/16) | ✅ generated into `npc_abilities_override.txt` |
| 72 items added after 6.88 removed from the shop | ✅ |
| Towers, barracks, Ancient, fountain, creeps, neutrals, Roshan with 6.88 stats | ✅ generated into `npc_units_custom.txt` |
| Game rules in Lua (gold, XP, level 25, respawn, buyback, runes, 4+4 day/night, Roshan, no backpack) | ✅ `game/dota_addons/dota_688/scripts/vscripts/` |
| Courier | the current Dota 2 one (free personal courier) – a deliberate exception to 6.88 |
| Abilities reworked after 6.88 rewritten in Lua with their original mechanics | ✅ ~190 hero abilities (every removed one plus those with major reworks: Riki, Techies, Lycan, Treant, Necrophos, Viper, Io, OD, Pudge, Slardar, Sven, Tiny, Undying, Visage, Wraith King…) – list in `docs/STATUS.md` |
| Items with 6.88 mechanics rewritten in Lua (Heart, Skadi, S&Y, Halberd, Abyssal, Dagon, Veil, Medallion, Solar Crest, Octarine, Shiva, Scythe, Urn, Mek, Pipe, Greaves, Vlad, Basilius/Aquila, Soul Ring, Atos, E‑Blade, Manta, Armlet, Battle Fury, Drums, Silver Edge, HotD, Bloodstone, Linken, Lotus, MKB, Butterfly, Satanic, MoM, Phase, Treads, Diffusal, Midas, Iron Talon…) | ✅ 76 items + the shop with the 6.88 layout (`shops.txt`) |
| Built‑in abilities with new mechanics disabled through manual overrides (`tools/manual_overrides.json`) | ✅ 187 abilities / items (Mana Break, Heartstopper, Necromastery, Psionic Trap, Culling Blade, Invoker, Glimpse, Double Edge, Roshan resistances, consumables…); no ability scales with hero level |
| 6.88 details on built‑in abilities restored in Lua (`dota688/extras_688.lua`) | ✅ Morph passive stats, Serpent Ward splash, Phantom Strike 4 attacks, Corrosive Skin movement slow, creep durations of Thunder Clap / Reverse Polarity, Earth Brewling spell immunity |
| Panorama: talents, backpack, neutral slot, TP slot, 7.x timers hidden | ✅ `content/.../panorama` – IDs to be re‑checked after new patches |
| Aghanim's Scepter as in 6.88: own item (no modern upgrades), the 6.88 upgrades reproduced per hero, Alchemist can give it to allies | ✅ `docs/AGHANIM.md` – 84 heroes, all reproduced (the Spirit Bear is in Lua too); Invoker, Lone Druid, Ogre Magi and Wraith King still need an in‑game re‑test |
| Localization | ✅ English, generated from the 6.88 texts |
| Assets (particles / models) verified against the current client | ✅ |
| The 6.88 map: the original 6.88f map, Hammer source in the repo, compiled by us in the current format | ✅ `docs/HARTA.md` – tested in game |
| In‑game testing (112 heroes, 76 items, rules, map, courier, play‑through) | ✅ `docs/TEST_LOG.md` |
| Steam Workshop | ✅ published (id 3818931233); republish from Workshop Tools → Asset Browser → Tools → Workshop Manager |

Details (in Romanian): `docs/REGULI_6.88.md` (every rule and its source), `docs/STATUS.md` (generated report),
`docs/AGHANIM.md` (scepter per hero), `docs/HARTA.md` (the 6.88 map: import, compilation, tests),
`docs/TEST_LOG.md` (in‑game test results), `docs/ROADMAP.md`.

## Repository layout

```
game/dota_addons/dota_688/        <- the addon (copy or link into dota 2 beta/game/dota_addons/)
  addoninfo.txt
  resource/addon_*.txt            <- texts
  scripts/npc/                    <- KV: heroes, abilities, items, units (generated + custom)
  scripts/vscripts/               <- Lua: game rules, modifiers, custom abilities and items
content/dota_addons/dota_688/     <- map source (Hammer), panorama, sound events, Workshop preview
reference/6.88f/                  <- Valve's original 6.88f files
reference/current/                <- Valve's current files (for diffs)
tools/                            <- the generator and checks (Python 3, no dependencies)
docs/                             <- documentation (Romanian)
```

## Installing for testing

1. In Steam: Dota 2 → Properties → DLC → enable **Dota 2 Workshop Tools DLC**.
2. Clone the repository and copy (or symlink / junction):
   * `game/dota_addons/dota_688` → `...\dota 2 beta\game\dota_addons\dota_688`
   * `content/dota_addons/dota_688` → `...\dota 2 beta\content\dota_addons\dota_688`
3. Start Workshop Tools and pick the `dota_688` addon.
4. Build the 6.88 map (`docs/HARTA.md`): `python tools/import_harta_688.py` (needs `maps/dota.vpk` from the
   6.88f client, downloaded once with DepotDownloader, and Source2Viewer‑CLI; it writes the Hammer source
   `content/dota_addons/dota_688/maps/dota_688.vmap` and its files), then `python tools/compile_harta_688.py`,
   and in the console `dota_launch_custom_game dota_688 dota_688`.

## Adding a 6.88 reimplementation

1. Hero ability: create `scripts/vscripts/abilities/heroes/dota688_<original_name>.lua` (a Lua class with the same name).
   Item: `scripts/vscripts/items/item_dota688_<name_without_item_>.lua` (you can use `Dota688DefineItem` from `items/dota688_item_base.lua`).
2. Run `python tools/gen_overrides.py`. The generator:
   * copies the original 6.88 KV block (`AbilitySpecial`, cooldown, mana, etc.) into `npc_abilities_generated.txt` / `npc_items_generated.txt`, with `BaseClass ability_lua/item_lua` and the original texture;
   * puts the ability into the hero's slot in place of the built‑in one; for items it removes the built‑in from the shop, generates the custom recipe and rewrites the recipes that use it;
   * copies the 6.88 tooltips into `resource/addon_english.txt`.
3. Values are read in Lua with `self:GetSpecialValueFor("key_from_6.88")`.

## Regenerating the KV files and running the checks

```
python tools/gen_overrides.py     # regenerates KV, shop, tooltips, docs/STATUS.md
python tools/check_addon.py      # consistency checks (slots, Lua scripts, recipes, shop, syntax, sounds, particles) – must report 0 errors
python tools/gen_patchnotes.py   # regenerates docs/patchnotes/index.html (the HTML patch notes, published with GitHub Pages)
```

The generator reads `reference/6.88f` and `reference/current` and writes the files in `scripts/npc/` and `docs/STATUS.md`.
Abilities / items defined manually in `npc_abilities_custom.txt` / `npc_items_custom.txt` (Lua reimplementations)
are detected by name and placed automatically into the heroes' slots in place of the built‑in variant.

To update `reference/current` after a new Dota 2 patch, see `tools/README.md`.

## License

Project code: GPL‑3.0 (see `LICENSE`). The files under `reference/` are Valve game data, included only as
reference for a custom game published in the Dota 2 Steam Workshop.
