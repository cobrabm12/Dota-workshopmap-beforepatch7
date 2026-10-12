"""Copiaza harta 6.88f decompilata (Source2Viewer-CLI) in content/dota_addons/dota_688/maps.

Intrare: folderul de export al lui Source2Viewer-CLI (contine maps/dota.vmap si world node-urile in maps/).
Iesire:  content/dota_addons/dota_688/maps/dota_688.vmap + maps/dota_688/worldnodes/*.vmdl|*.dmx

Caile maps/dota/... sunt redenumite in maps/dota_688/... (in DMX binar v9 sirurile sunt terminate cu 0,
fara lungimi/offset-uri, deci inlocuirea cu un sir mai lung este sigura). Modelele de prop-uri exportate
(models/props_*) NU se copiaza: exista in clientul curent si le-ar umbri pe cele ale jocului.

Entitatile se editeaza in forma text (keyvalues2), cu dmxconvert.exe din Workshop Tools, apoi harta se scrie
inapoi in binar (~44 MB, sub limita de 50 MB pentru commit):
  * cele doua dota_item_rune_spawner din 2016 (clasa nu mai exista) devin info_target "dota688_rune_top" /
    "dota688_rune_bot", punctele cautate de scripts/vscripts/dota688/runes.lua.

    python tools/import_harta_688.py C:\\dota688_depot\\export
"""
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DMXCONVERT = os.environ.get("DMXCONVERT", r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\bin\win64\dmxconvert.exe")
DEST = os.path.join(ROOT, "content", "dota_addons", "dota_688", "maps")
OLD, NEW = b"maps/dota/", b"maps/dota_688/"
# resurse referite de harta 6.88f care nu exista in clientul curent (nici in pak01 din 2016) -> echivalente actuale
RESOURCE_FIXES = {
    b"materials/effects/fog_world_00.vtex": b"materials/effects/fog_world_01.vtex",
    b"materials/effects/fow_clouds_00.vtex": b"materials/dev/fow_clouds_00.vtex",
}


def dmxconvert(src, dst, encoding):
    r = subprocess.run([DMXCONVERT, "-i", src, "-o", dst, "-oe", encoding], capture_output=True, text=True)
    if r.returncode != 0 or not os.path.exists(dst):
        sys.exit(f"dmxconvert a esuat: {r.stdout}\n{r.stderr}")


def edit_entities(vmap_path, workdir):
    """Editeaza entitatile hartii in forma text keyvalues2 si scrie harta inapoi in binar."""
    text_path = os.path.join(workdir, "dota_688_kv2.vmap")
    dmxconvert(vmap_path, text_path, "keyvalues2")
    t = open(text_path, encoding="utf-8").read()
    runes = 0

    def rune(m):
        nonlocal runes
        props, origin = m.group(1), m.group(2)
        y = float(origin.split()[1])
        name = "dota688_rune_top" if y > 0 else "dota688_rune_bot"
        props = props.replace('"classname" "string" "dota_item_rune_spawner"', '"classname" "string" "info_target"')
        props = re.sub(r'"targetname" "string" "[^"]*"', f'"targetname" "string" "{name}"', props)
        runes += 1
        return props + m.group(0)[len(m.group(1)):]
    t = re.sub(r'("entity_properties" "EditGameClassProps"\s*\{[^{}]*?"classname" "string" "dota_item_rune_spawner"[^{}]*\}\s*)'
               r'"origin" "vector3" "([^"]+)"', rune, t)
    if runes != 2:
        sys.exit(f"asteptam 2 dota_item_rune_spawner, gasite {runes}")
    with open(text_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(t)
    dmxconvert(text_path, vmap_path, "binary")
    os.remove(text_path)
    print(f"entitati: {runes} spawnere de rune -> info_target dota688_rune_top/bot")


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
    out = os.path.join(DEST, "dota_688.vmap")
    with open(out, "wb") as f:
        f.write(vmap)
    if os.path.exists(DMXCONVERT):
        edit_entities(out, export_dir)
    else:
        print("AVERTISMENT: dmxconvert.exe lipsa (Workshop Tools): entitatile nu au fost editate")

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
