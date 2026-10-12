# Harta 6.88 (de construit în Hammer)

Harta 7.00 a schimbat terenul; harta noastră trebuie să reproducă layout‑ul 6.88. Fișierul sursă va fi
`content/dota_addons/dota_688/maps/dota_688.vmap`, compilat în `game/dota_addons/dota_688/maps/dota_688.vpk`.

## Punct de plecare

1. Deschide Hammer din Workshop Tools pentru addon‑ul `dota_688`.
2. Caută (File → Open) sursele de hartă livrate de Valve cu Tools (ex. `dota.vmap` sau prefab‑urile PvP).
   Dacă sunt disponibile, copiază una în `content/dota_addons/dota_688/maps/dota_688.vmap` și modifică‑o;
   altfel se construiește de la zero după planul de mai jos (terenul 6.88 nu există ca sursă publică).

## Diferențe 6.88 față de harta curentă (de refăcut)

* **Roshan**: groapa în râu, pe partea Dire, lângă runa de jos (7.00 l‑a mutat la runa de sus; 7.33 a făcut două gropi).
* **Rune**: doar două locuri, în râu (sus și jos). Fără rune în jungle. Fără Wisdom/Water/Shield rune.
  Pune `info_target` numite `dota688_rune_top` și `dota688_rune_bot` (Lua le folosește) sau spawner‑ele
  `dota_item_rune_spawner_powerup` în cele două locuri.
* **Fără**: shrine‑uri, outpost‑uri, Tormentor, Lotus Pool, Twin Gates, Watchers, iteme neutre.
* **Side shop‑uri**: la întâlnirea lane‑urilor laterale (top/bot), cu lista de iteme 6.88 (`SideShop 1` în KV).
* **Secret shop**: pozițiile 6.88 (în jungle, nu lângă shrine).
* **Jungle**: jungla principală a fiecărei echipe: 2 camp‑uri mari, 2 medii, 1 mic; jungla secundară: 1 ancient + 1 mare.
  Fără Prowler camp. Ancienții sunt imuni la magie (stats din `npc_units_custom.txt`).
* **Turnuri/barăci/Ancient**: pozițiile 6.88 (7.31 a mutat turnurile de offlane cu 320 unități).
* **Efigii**: 15 clădiri „filler” pe bază (500 HP, 10 armură, 111 aur).
* **Lane‑uri, copaci, ward‑spots, juke paths**: ca în 6.88 (7.00 a refăcut marginile lane‑urilor laterale).
* **Zi/noapte**: nu depinde de hartă (Lua).

## Entități obligatorii pentru modul PvP

* `info_player_start_goodguys` / `info_player_start_badguys`
* `npc_dota_spawner_good_*` / `npc_dota_spawner_bad_*` (creepi pe lane) și `path_corner`‑urile lane‑urilor
* `npc_dota_neutral_spawner` pentru fiecare camp (tipul de camp în proprietăți)
* `npc_dota_roshan_spawner`
* `npc_dota_tower`, `npc_dota_barracks`, `npc_dota_fort`, `npc_dota_healer` (fântână), efigii
* `dota_item_rune_spawner_powerup` ×2 (sau `info_target` `dota688_rune_*`)
* `trigger_shop` cu `shoptype` 0 (bază), 1 (side), 2 (secret)
* `ent_dota_fountain`, `dota_minimap_boundary`, lumina/skybox

## Referințe vizuale

Pentru layout folosește minimap‑ul și replay‑urile din 2016 (meciuri TI6 / Boston Major au harta 6.88).
