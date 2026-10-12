# Harta 6.88

## Starea actuală (harta folosită în joc)

Clientul curent Dota 2 conține `game/dota/maps/dota_688.vpk`: harta 6.88 **recompilată de Valve** pentru motorul
actual (aceleași entități ca harta din decembrie 2016, cu trigger‑ele de shop / no‑wards / camp‑uri și fizica în formatul
nou). `python tools/import_harta_688.py` o copiază în addon ca `game/dota_addons/dota_688/maps/dota.vpk` (în .gitignore).
Căile din interior sunt `maps/dota/...`, deci harta se pornește cu numele `dota`, iar cea din addon are prioritate
față de harta 7.x a jocului:

    dota_launch_custom_game dota_688 dota

Motorul curent cere câteva entități care nu existau în 2016; `scripts/vscripts/dota688/map_688.lua` le adaugă la pornire:
`info_courier_spawn_radiant_1..5` / `dire_1..5` (fără ele jocul cade la PRE_GAME), `info_player_start_dota`
`roshan_location_1/2` (ambele în groapa 6.88, ca Roshan să nu se mute) și `info_target` `dota688_rune_top/bot`.

Testat (TEST_LOG, secțiunea 5): 11 `trigger_shop` (side și secret shop funcționează), 14 volume de camp (fără stack‑uri
singure: 7 minute fără eroi în jungla, numărul de neutrali rămâne constant), Roshan în groapa 6.88 cu 8000 HP.

Vmap‑ul decompilat (`content/dota_addons/dota_688/maps/dota_688.vmap`, cu `tools/compile_harta_688.py`) rămâne sursa
pentru editare în Hammer. Decompilarea nu recuperează geometria trigger‑elor, deci harta compilată din el **nu** are
shop‑uri, volume de camp și no‑wards; pentru joc se folosește harta de mai sus.

## Istoric: recuperarea hărții din clientul 2016

Harta 7.00 a schimbat terenul; harta noastră trebuie să reproducă layout‑ul 6.88. Fișierul sursă este
`content/dota_addons/dota_688/maps/dota_688.vmap`, compilat în `game/dota_addons/dota_688/maps/dota_688.vpk`.

## Punct de plecare: recuperarea hărții 6.88 din clientul vechi (recomandat)

Sursa `.vmap` a hărții 6.88 nu a fost publicată niciodată, dar harta **compilată** există în fișierele clientului
Dota 2 din 7 decembrie 2016 (build 1805, ultimul înainte de 7.00), iar [Source 2 Viewer](https://s2v.app) o poate
decompila înapoi într‑un `.vmap` editabil în Hammer (entități, geometrie pe materiale, static props, layere, fizică).
Se pierd doar prefab‑urile, numele grupurilor, parametrii overlay‑urilor și subdiviziunile; skybox‑ul poate lipsi parțial.

Nu pot descărca eu fișierele: depoturile vechi Steam cer un cont Steam (Dota 2 trebuie să fie în bibliotecă).
Pașii, pe PC‑ul tău:

1. **Descarcă clientul 6.88f** cu [DepotDownloader](https://github.com/SteamRE/DepotDownloader):
   * pe [SteamDB, app 570 → Depots](https://steamdb.info/app/570/depots/) ia ID‑ul depotului de conținut („Dota 2 Content”)
     și, din pagina lui de *Manifests*, ID‑ul manifestului din **7 decembrie 2016** (înainte de cel din 12 decembrie = 7.00);
   * `DepotDownloader -app 570 -depot <depot> -manifest <manifest> -username <cont> -filelist pak01.txt`,
     unde `pak01.txt` conține `regex:game/dota/pak01_.*\.vpk` (harta era în `pak01`, nu într‑un VPK separat; sunt câțiva GB).
2. **Decompilează**: în Source 2 Viewer deschide `game/dota/pak01_dir.vpk`, mergi la `maps/dota.vmap_c`, click dreapta →
   *Decompile & Export* → *vmap*, salvează ca `content/dota_addons/dota_688/maps/dota_688.vmap` (cu folderul `maps/dota_688/` lângă).
   Lista celor 140 de fișiere ale hărții este în `reference/6.88f/maps_dota_manifest.txt` (`python3 tools/map_files_688.py`).
3. **Hammer**: deschide `dota_688.vmap`, verifică lista de entități de mai jos (spawner‑ele de creepi, neutrali, Roshan,
   shop‑urile, runele – adaugă `info_target` `dota688_rune_top`/`dota688_rune_bot` sau păstrează spawner‑ele de rune),
   redenumește și compilează. Modelele/texturile din 2016 care nu mai există în joc apar ca erori la compilare: înlocuiește‑le
   cu echivalentele actuale.

Alternativa, dacă nu vrei să descarci clientul vechi: pornește de la harta curentă (`dota.vmap`, dacă e livrată cu Tools)
și refă layout‑ul după lista de diferențe de mai jos.

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
