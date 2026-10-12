"""Copiaza harta 6.88f decompilata (Source2Viewer-CLI) in content/dota_addons/dota_688/maps.

Intrare: folderul de export al lui Source2Viewer-CLI (contine maps/dota.vmap si world node-urile in maps/).
Iesire:  content/dota_addons/dota_688/maps/dota_688.vmap + maps/dota_688/worldnodes/*.vmdl|*.dmx

Caile maps/dota/... sunt redenumite in maps/dota_688/... (in DMX binar v9 sirurile sunt terminate cu 0,
fara lungimi/offset-uri, deci inlocuirea cu un sir mai lung este sigura). Modelele de prop-uri exportate
(models/props_*) NU se copiaza: exista in clientul curent si le-ar umbri pe cele ale jocului.

Entitatile se editeaza in forma text (keyvalues2), cu dmxconvert.exe din Workshop Tools, apoi harta se scrie
inapoi in binar (~44 MB, sub limita de 50 MB pentru commit):
  * cele doua dota_item_rune_spawner din 2016 (clasa nu mai exista) devin info_target "dota688_rune_top" /
    "dota688_rune_bot", punctele cautate de scripts/vscripts/dota688/runes.lua;
  * cheia "holdanimation" de pe prop_dynamic* e scoasa (motorul curent: "obsolete HoldAnimation key" + assert);
  * se adauga entitatile pe care motorul curent le cere la PRE_GAME (fara ele jocul cade, testat):
    info_courier_spawn_radiant_1..5 / dire_1..5 (curier pe jucator) si info_player_start_dota
    "roshan_location_1/2" (pozitiile lui Roshan din 7.33), ambele in groapa 6.88 ca Roshan sa nu se mute;
  * trigger-ele (shop-uri, no-wards, volumele camp-urilor, groapa lui Roshan) refera modelele brush compilate in
    2016 (maps\\dota\\entities\\*.vmdl); decompilarea nu le da geometria, deci resourcecompiler le arunca (testat:
    0 trigger_shop in harta compilata). Caile se normalizeaza doar pentru Hammer.

HARTA FOLOSITA IN JOC: clientul curent contine maps/dota_688.vpk = harta 6.88 recompilata de Valve pentru motorul
actual (aceleasi entitati ca in 2016, cu trigger-ele si fizica in formatul nou). O copiem in addon ca maps/dota.vpk
(caile interne sunt maps/dota/..., deci numele hartii trebuie sa fie "dota"): dota_launch_custom_game dota_688 dota.
Entitatile cerute in plus de motorul curent (curieri 1..5, roshan_location, punctele de rune) le adauga
scripts/vscripts/dota688/map_688.lua la pornire. Vmap-ul decompilat ramane sursa pentru editare in Hammer.
Motorul cauta pentru orice harta maps/<harta>/water_flow_map, fog_flow_map si fog_opacity_map (pictate in Hammer;
harta din 2016 nu le avea). Le luam din harta curenta a jocului (Source2Viewer-CLI, doar citire) ca surse .png + .vtex.

    python tools/import_harta_688.py C:\\dota688_depot\\export
"""
import os
import re
import shutil
import subprocess
import sys
import uuid

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DMXCONVERT = os.environ.get("DMXCONVERT", r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\bin\win64\dmxconvert.exe")
DEST = os.path.join(ROOT, "content", "dota_addons", "dota_688", "maps")
S2V_CLI = os.environ.get("S2V_CLI", r"C:\dota688_tools\S2V-CLI\Source2Viewer-CLI.exe")
GAME_MAP_VPK = os.environ.get("GAME_MAP_VPK", r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\maps\dota.vpk")
FLOW_MAPS = ("water_flow_map", "fog_flow_map", "fog_opacity_map")
VALVE_MAP_688 = os.environ.get("VALVE_MAP_688", r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta\game\dota\maps\dota_688.vpk")
GAME_ADDON = os.path.join(ROOT, "game", "dota_addons", "dota_688")
ROSHAN_PIT_688 = "4320 -1824 168"
VTEX_TEMPLATE = """<!-- dmx encoding keyvalues2_noids 1 format vtex 1 -->
"CDmeVtex"
{
	"m_inputTextureArray" "element_array"
	[
		"CDmeInputTexture"
		{
			"m_name" "string" "InputTexture"
			"m_fileName" "string" "maps/dota_688/%s.png"
			"m_colorSpace" "string" "linear"
			"m_typeString" "string" "2D"
			"m_imageProcessorArray" "element_array"
			[
			]
		}
	]
	"m_outputTypeString" "string" "2D"
	"m_outputFormat" "string" "RGBA8888"
	"m_outputClearColor" "vector4" "0 0 0 0"
	"m_nOutputMinDimension" "int" "0"
	"m_nOutputMaxDimension" "int" "0"
	"m_textureOutputChannelArray" "element_array"
	[
		"CDmeTextureOutputChannel"
		{
			"m_inputTextureArray" "string_array"
			[
				"InputTexture"
			]
			"m_srcChannels" "string" "rgba"
			"m_dstChannels" "string" "rgba"
			"m_mipAlgorithm" "CDmeImageProcessor"
			{
				"m_algorithm" "string" ""
				"m_stringArg" "string" ""
				"m_vFloat4Arg" "vector4" "0 0 0 0"
			}
			"m_outputColorSpace" "string" "linear"
		}
	]
	"m_vClamp" "vector3" "0 0 0"
	"m_bNoLod" "bool" "0"
}
"""
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

    # "holdanimation" pe prop_dynamic: cheie scoasa din motor, declanseaza un assert la incarcarea hartii
    hold = 0

    def drop_hold(m):
        nonlocal hold
        block = m.group(0)
        if '"classname" "string" "prop_dynamic' not in block:  # si prop_dynamic_clientside
            return block
        new = re.sub(r'\n\s*"holdanimation" "[a-z]+" "[^"]*"', "", block)
        hold += block != new
        return new
    t = re.sub(r'"entity_properties" "EditGameClassProps"\s*\{[^{}]*\}', drop_hold, t)

    # modelele brush ale trigger-elor: maps\dota\entities\x.vmdl -> maps/dota/entities/x.vmdl
    # (in keyvalues2 backslash-ul e scris dublat: "maps\\dota\\entities\\x.vmdl")
    brush_re = r'"model" "string" "maps\\\\dota\\\\entities\\\\([^"]+)"'
    brush = len(re.findall(brush_re, t))
    t = re.sub(brush_re, r'"model" "string" "maps/dota/entities/\1"', t)

    # entitati cerute de motorul curent la PRE_GAME
    added = []
    for team in ("radiant", "dire"):
        for i in range(1, 6):
            added.append(clone_entity(t, f"info_courier_spawn_{team}", f"info_courier_spawn_{team}_{i}"))
    for i in (1, 2):
        added.append(clone_entity(t, "info_player_start_goodguys", "info_player_start_dota", ROSHAN_PIT_688, f"roshan_location_{i}"))
    _, end = entity_span(t, "info_player_start_goodguys")
    t = t[:end] + "".join(",\n\t\t\t" + b for b in added) + t[end:]
    with open(text_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(t)
    dmxconvert(text_path, vmap_path, "binary")
    os.remove(text_path)
    print(f"entitati: {runes} spawnere de rune -> info_target dota688_rune_top/bot; holdanimation scos de pe {hold} prop_dynamic; "
          f"{brush} modele brush; {len(added)} entitati adaugate (curieri, pozitii Roshan)")


def entity_span(t, cls):
    """(inceput, sfarsit) ale primului element CMapEntity cu clasa data, in vmap-ul text."""
    m = re.search(r'"classname" "string" "%s"' % re.escape(cls), t)
    j = t.rfind('"CMapEntity"', 0, m.start())
    depth, p = 0, t.index("{", j)
    while True:
        if t[p] == "{":
            depth += 1
        elif t[p] == "}":
            depth -= 1
            if depth == 0:
                return j, p + 1
        p += 1


def clone_entity(t, cls_src, cls_new, origin=None, targetname=None):
    """Copie a unei entitati existente, cu ID-uri noi, alta clasa si optional alta pozitie/nume."""
    j, e = entity_span(t, cls_src)
    b = re.sub(r'"id" "elementid" "[0-9a-f-]+"', lambda _: f'"id" "elementid" "{uuid.uuid4()}"', t[j:e])
    b = b.replace(f'"classname" "string" "{cls_src}"', f'"classname" "string" "{cls_new}"')
    if origin:
        b = re.sub(r'"origin" "vector3" "[^"]+"', f'"origin" "vector3" "{origin}"', b)
    if targetname:
        b = b.replace(f'"classname" "string" "{cls_new}"', f'"targetname" "string" "{targetname}"\n\t\t\t\t\t"classname" "string" "{cls_new}"')
    return b


def valve_map():
    """maps/dota_688.vpk din client (harta 6.88 recompilata de Valve) -> game/dota_addons/dota_688/maps/dota.vpk"""
    if not os.path.exists(VALVE_MAP_688):
        print(f"AVERTISMENT: lipseste {VALVE_MAP_688}: harta de joc 6.88 nu a fost copiata")
        return
    dest = os.path.join(GAME_ADDON, "maps", "dota.vpk")
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copyfile(VALVE_MAP_688, dest)
    print(f"harta de joc: {VALVE_MAP_688} -> {dest} ({os.path.getsize(dest) / 1e6:.1f} MB)")


def flow_maps(workdir):
    """water_flow_map / fog_flow_map / fog_opacity_map din harta curenta -> content/.../maps/dota_688/*.png + .vtex"""
    if not (os.path.exists(S2V_CLI) and os.path.exists(GAME_MAP_VPK)):
        print("AVERTISMENT: Source2Viewer-CLI sau maps/dota.vpk lipsa: texturile flow/fog nu au fost create")
        return
    out = os.path.join(workdir, "flowmaps")
    dest = os.path.join(DEST, "dota_688")
    os.makedirs(dest, exist_ok=True)
    for name in FLOW_MAPS:
        # cu un singur fisier filtrat, -o este numele fisierului de iesire (nu un folder)
        png = os.path.join(out, name + ".png")
        os.makedirs(out, exist_ok=True)
        subprocess.run([S2V_CLI, "-i", GAME_MAP_VPK, "-f", f"maps/dota/{name}.vtex_c", "-d", "-o", png], capture_output=True)
        if not os.path.exists(png):
            sys.exit(f"nu am putut extrage {name}")
        shutil.copyfile(png, os.path.join(dest, name + ".png"))
        with open(os.path.join(dest, name + ".vtex"), "w", encoding="utf-8", newline="\n") as f:
            f.write(VTEX_TEMPLATE % name)
    print(f"texturi: {', '.join(FLOW_MAPS)} -> {dest}")


def main(export_dir):
    valve_map()
    src = os.path.join(export_dir, "maps")
    if not os.path.exists(os.path.join(src, "dota.vmap")):
        print(f"(fara {src}\\dota.vmap decompilat: sursa pentru Hammer nu a fost reimportata)")
        return
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
    flow_maps(export_dir)
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
