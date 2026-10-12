#!/usr/bin/env python3
"""Lista fișierelor hărții 6.88f (din reference/6.88f/maps_dota_manifest.txt – manifestul `game/dota/maps/dota.txt`
al clientului din 7 dec 2016) și comenzile de extragere/decompilare.

În clientul 6.88f harta NU era un VPK separat: fișierele `maps/dota.*` și `maps/dota/...` stăteau în `pak01_*.vpk`.
Rulare: python3 tools/map_files_688.py  -> scrie build/map_files_688.txt (lista pentru extragere) și afișează pașii.
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = os.path.join(ROOT, "reference", "6.88f", "maps_dota_manifest.txt")
out_dir = os.path.join(ROOT, "build")
os.makedirs(out_dir, exist_ok=True)
files = []
with open(src, encoding="utf-8", errors="replace") as f:
    for line in f:
        m = re.match(r"^(maps/\S+)\s+CRC:", line)
        if m:
            files.append(m.group(1))
with open(os.path.join(out_dir, "map_files_688.txt"), "w", encoding="utf-8") as f:
    f.write("\n".join(files) + "\n")
print(f"{len(files)} fișiere ale hărții 6.88f listate în build/map_files_688.txt")
print("""
PAȘI (pe PC-ul tău, cu Steam):
 1. DepotDownloader (https://github.com/SteamRE/DepotDownloader), cu contul tău Steam:
      DepotDownloader -app 570 -depot <ID_DEPOT_CONTENT> -manifest <ID_MANIFEST_7_DEC_2016> -username <cont> -filelist pak01.txt
    unde pak01.txt conține:   regex:game/dota/pak01_.*\\.vpk
    ID-ul depotului de conținut și ID-ul manifestului din 7 dec 2016 (build 1805, ultimul înainte de 7.00) se iau de pe
    https://steamdb.info/app/570/depots/  ->  depotul de conținut (Dota 2 Content)  ->  Manifests  (necesită cont SteamDB/Steam).
 2. Source 2 Viewer (https://s2v.app): deschide game/dota/pak01_dir.vpk din ce ai descărcat, mergi la maps/dota.vmap_c,
    click dreapta -> Decompile & Export -> vmap -> salvează în content/dota_addons/dota_688/maps/ (ca dota_688.vmap, cu folderul maps/dota_688/ lângă).
    Sau CLI:  Source2Viewer-CLI -i game/dota/pak01_dir.vpk -o export/ -d -f maps/dota.vmap_c
 3. Hammer (Workshop Tools, addon dota_688): deschide dota_688.vmap, verifică entitățile (vezi docs/HARTA.md), compilează.
""")
