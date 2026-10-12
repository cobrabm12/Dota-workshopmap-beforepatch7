# Harta 6.88

## Starea actuală (harta folosită în joc)

Harta jocului este **harta noastră** `dota_688`, compilată de noi în formatul curent al motorului
(`game/dota_addons/dota_688/maps/dota_688.vpk`, în .gitignore) din sursa Hammer
`content/dota_addons/dota_688/maps/dota_688.vmap` (în repo). Se pornește cu:

    dota_launch_custom_game dota_688 dota_688

și este singura hartă din `addoninfo.txt`. Nu mai conține date compilate vechi: Workshop Tools nu mai afișează
„Legacy Compiled Data”, iar assert‑ul „obsolete HoldAnimation key” nu mai apare.

Refacerea completă, dintr‑o singură rulare (are nevoie de Workshop Tools, de Source2Viewer‑CLI în
`C:\dota688_tools\S2V-CLI` și de `maps/dota.vpk` din clientul 6.88f în `C:\dota688_depot\game\dota\maps`, vezi mai jos):

    python tools/import_harta_688.py      # decompilează harta 2016 (dacă lipsește C:\dota688_depot\export) și scrie vmap-ul
    python tools/compile_harta_688.py     # resourcecompiler: texturi flow/fog, world node-uri, harta

Ce face `tools/import_harta_688.py` peste harta decompilată de Source 2 Viewer:

* **Trigger‑ele** (11 `trigger_shop`, 22 `trigger_multiple` = 14 volume de camp + `roshan_location` + 7
  `bad_result_position`, 6 `trigger_no_wards`, 1 `trigger_boss_attackable`): decompilarea păstrează doar entitatea, fără
  geometrie, iar compilatorul aruncă entitățile brush fără mesh. Modelele lor compilate (`maps/dota/entities/*.vmdl_c`)
  au însă hull‑urile de fizică: le decompilăm, iar fiecare hull devine un mesh convex cu `materials/tools/toolstrigger.vmat`,
  copil al entității (`tools/vmap_mesh.py`, structura half‑edge a lui Hammer). În Hammer apar ca trigger‑e obișnuite,
  iar compilatorul face `maps/dota_688/entities/*.vmdl` cu fizica în formatul curent. Geometria e identică în harta
  2016 și în `maps/dota_688.vpk` al lui Valve (verificat hull cu hull, și după compilare).
* **World layer‑ele** bazelor (`radiant_base`, `radiant_destruction`, `dire_base`, `dire_destruction`): Source 2 Viewer
  scotea entitățile lor în lumea principală, deci baza distrusă apărea de la început (2491 de copaci în loc de 2371).
  Le mutăm înapoi în layer‑ul lor (313 entități), cu numele și `childSpawnGroup` ca în harta lui Valve; Ancient‑ul
  comută layer‑ele la distrugere.
* Spawner‑ele de rune 2016 → `info_target` `dota688_rune_top` / `dota688_rune_bot` (căutate de `runes.lua`);
  cheia `holdanimation` scoasă de pe `prop_dynamic*`; `info_courier_spawn_radiant_1..5` / `dire_1..5` (fără ele jocul
  cade la PRE_GAME) și `info_player_start_dota` `roshan_location_1/2` (ambele în groapa 6.88) adăugate.
* Texturile `water_flow_map` / `fog_flow_map` / `fog_opacity_map` (cerute de motor pentru orice hartă) luate din harta
  curentă a jocului.

`scripts/vscripts/dota688/map_688.lua` verifică la pornire entitățile de mai sus (le adaugă doar dacă lipsesc) și
scrie un avertisment în consolă dacă harta nu are toate trigger‑ele 6.88.

Testat în joc (harta compilată, 12 oct 2026): pornire fără crash în PRE_GAME; la runtime exact aceleași entități server
ca harta 6.88 a lui Valve (2831 față de 2833: diferă doar cele 2 `dota_item_rune_spawner`, la noi `info_target`),
inclusiv 2371 `ent_dota_tree`; 11 `trigger_shop`: shop‑ul de bază (Radiant și Dire), cele 4 secret shop‑uri și cele 4
side shop‑uri funcționează când eroul intră mergând; 14 volume de camp: 43 de neutrali constant 9 minute fără eroi în
junglă (fără stack‑uri singure), camp ocupat de erou la minut = nu apare, liber la minutul următor = apare; Roshan în
groapa 6.88; runele în cele două locuri din râu.

Rezervă, doar pentru comparații: `python tools/import_harta_688.py --harta-valve` copiază și `maps/dota_688.vpk` din
client (harta 6.88 recompilată de Valve, cu căile `maps/dota/...`) în addon ca `maps/dota.vpk`, pornită cu
`dota_launch_custom_game dota_688 dota`. Are date compilate vechi (dialogul „Legacy Compiled Data” revine), deci o
rulare fără opțiune o șterge; nu o lăsați în addon la publicare.

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

1. **Descarcă harta clientului 6.88f** cu [DepotDownloader](https://github.com/SteamRE/DepotDownloader) (contul Steam îl
   introduci tu, în DepotDownloader):
   * pe [SteamDB, app 570 → Depots](https://steamdb.info/app/570/depots/) ia ID‑ul depotului de conținut („Dota 2 Content”,
     373301) și, din pagina lui de *Manifests*, ID‑ul manifestului din **7 decembrie 2016** (6583592615927321343);
   * `DepotDownloader -app 570 -depot 373301 -manifest <manifest> -username <cont> -filelist harta.txt -dir C:\dota688_depot`,
     unde `harta.txt` conține `regex:game/dota/maps/dota\.vpk` (în 6.88f harta era un VPK separat, 21 MB).
2. **Import + compilare**: `python tools/import_harta_688.py` (decompilează `maps/dota.vmap_c` cu Source2Viewer‑CLI în
   `C:\dota688_depot\export`, apoi aplică modificările de mai sus) și `python tools/compile_harta_688.py`.
   Lista celor 140 de fișiere ale hărții este în `reference/6.88f/maps_dota_manifest.txt` (`python3 tools/map_files_688.py`).
3. **Hammer** (opțional): `dota_688.vmap` se deschide și se editează în Hammer; după editare, compilează din Hammer sau cu
   `tools/compile_harta_688.py`. Atenție: o nouă rulare a importului rescrie vmap‑ul din harta 2016.

Alternativa, dacă nu vrei să descarci clientul vechi: pornește de la harta curentă (`dota.vmap`, dacă e livrată cu Tools)
și refă layout‑ul după lista de diferențe de mai jos.

## Diferențe 6.88 față de harta curentă (referință; harta noastră este cea 6.88 originală)

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
