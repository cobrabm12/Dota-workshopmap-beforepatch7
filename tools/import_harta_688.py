"""Copiaza harta 6.88f decompilata (Source2Viewer-CLI) in content/dota_addons/dota_688/maps.

Intrare: folderul de export al lui Source2Viewer-CLI (contine maps/dota.vmap si world node-urile in maps/).
Iesire:  content/dota_addons/dota_688/maps/dota_688.vmap + maps/dota_688/worldnodes/*.vmdl|*.dmx

Caile maps/dota/... sunt redenumite in maps/dota_688/... (in DMX binar v9 sirurile sunt terminate cu 0,
fara lungimi/offset-uri, deci inlocuirea cu un sir mai lung este sigura). Modelele de prop-uri exportate
(models/props_*) NU se copiaza: exista in clientul curent si le-ar umbri pe cele ale jocului.

    python tools/import_harta_688.py C:\\dota688_depot\\export
"""
import os
import re
import shutil
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEST = os.path.join(ROOT, "content", "dota_addons", "dota_688", "maps")
OLD, NEW = b"maps/dota/", b"maps/dota_688/"
# resurse referite de harta 6.88f care nu exista in clientul curent (nici in pak01 din 2016) -> echivalente actuale
RESOURCE_FIXES = {
    b"materials/effects/fog_world_00.vtex": b"materials/effects/fog_world_01.vtex",
    b"materials/effects/fow_clouds_00.vtex": b"materials/dev/fow_clouds_00.vtex",
}


def main(export_dir):
    src = os.path.join(export_dir, "maps")
    vmap = open(os.path.join(src, "dota.vmap"), "rb").read()
    if not vmap.startswith(b"<!-- dmx encoding binary 9 "):
        sys.exit("format neasteptat: " + vmap[:60].decode("ascii", "replace"))
    count = vmap.count(OLD)
    vmap = vmap.replace(OLD, NEW)
    for old, new in RESOURCE_FIXES.items():
        count += vmap.count(old)
        vmap = vmap.replace(old, new)
    os.makedirs(DEST, exist_ok=True)
    with open(os.path.join(DEST, "dota_688.vmap"), "wb") as f:
        f.write(vmap)

    nodes = os.path.join(DEST, "dota_688", "worldnodes")
    os.makedirs(nodes, exist_ok=True)
    copied = 0
    for name in sorted(os.listdir(src)):
        if not re.match(r"node\d+_layer\d+_mesh_", name):
            continue
        path = os.path.join(src, name)
        if name.endswith(".vmdl"):
            data = open(path, "rb").read().replace(OLD, NEW)
            with open(os.path.join(nodes, name), "wb") as f:
                f.write(data)
        else:
            shutil.copyfile(path, os.path.join(nodes, name))
        copied += 1
    print(f"dota_688.vmap: {count} cai redenumite; worldnodes: {copied} fisiere -> {nodes}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else r"C:\dota688_depot\export")
