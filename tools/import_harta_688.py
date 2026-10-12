"""Construieste sursa hartii 6.88 (content/dota_addons/dota_688/maps/dota_688.vmap) din harta clientului 6.88f.

Intrari (nu sunt in repo):
  * maps/dota.vpk din clientul 6.88f (7 dec 2016, descarcat cu DepotDownloader in C:\\dota688_depot\\game\\dota\\maps,
    vezi docs/HARTA.md); daca lipseste, pentru trigger-e si lump-uri se foloseste maps/dota_688.vpk din clientul curent
    (harta 6.88 recompilata de Valve: aceeasi geometrie a trigger-elor, verificat hull cu hull);
  * folderul de export al lui Source2Viewer-CLI cu harta decompilata (maps/dota.vmap + world node-urile); daca lipseste,
    il cream noi cu Source2Viewer-CLI din maps/dota.vpk 2016;
  * Workshop Tools (dmxconvert.exe) si Source2Viewer-CLI (C:\\dota688_tools\\S2V-CLI), doar rulate.
Iesire: content/dota_addons/dota_688/maps/dota_688.vmap + maps/dota_688/worldnodes/*.vmdl|*.dmx + texturile flow/fog.
Compilarea: python tools/compile_harta_688.py -> game/dota_addons/dota_688/maps/dota_688.vpk (harta "dota_688").

Caile maps/dota/... sunt redenumite in maps/dota_688/... (in DMX binar v9 sirurile sunt terminate cu 0,
fara lungimi/offset-uri, deci inlocuirea cu un sir mai lung este sigura). Modelele de prop-uri exportate
(models/props_*) NU se copiaza: exista in clientul curent si le-ar umbri pe cele ale jocului.

Entitatile se editeaza in forma text (keyvalues2), cu dmxconvert.exe, apoi harta se scrie inapoi in binar
(~44 MB, sub limita de 50 MB pentru commit):
  * cele doua dota_item_rune_spawner din 2016 (clasa nu mai exista) devin info_target "dota688_rune_top" /
    "dota688_rune_bot", punctele cautate de scripts/vscripts/dota688/runes.lua;
  * cheia "holdanimation" de pe prop_dynamic* e scoasa (motorul curent: "obsolete HoldAnimation key" + assert);
  * se adauga entitatile pe care motorul curent le cere la PRE_GAME (fara ele jocul cade, testat):
    info_courier_spawn_radiant_1..5 / dire_1..5 (curier pe jucator) si info_player_start_dota
    "roshan_location_1/2" (pozitiile lui Roshan din 7.33), ambele in groapa 6.88 ca Roshan sa nu se mute;
  * TRIGGER-ELE (11 trigger_shop, 22 trigger_multiple = 14 volume de camp + groapa lui Roshan + 7 bad_result_position,
    6 trigger_no_wards, 1 trigger_boss_attackable): decompilarea hartii pastreaza doar entitatea cu "model"
    maps\\dota\\entities\\*.vmdl, fara geometrie, iar resourcecompiler arunca entitatile brush fara mesh. Modelele
    compilate ale trigger-elor au insa hull-urile de fizica: le decompilam (Source2Viewer-CLI -> .vmdl + *_hull*.dmx),
    iar fiecare hull devine un mesh convex cu materialul toolstrigger, copil al entitatii (tools/vmap_mesh.py),
    exact ca un trigger desenat in Hammer. Cheia "model" se scoate; compilatorul face modelele
    maps/dota_688/entities/*.vmdl in formatul curent;
  * WORLD LAYER-ELE (baza / baza distrusa a fiecarei echipe): Source2Viewer pune entitatile din lump-urile
    world_layer_*.vents in lumea principala ("not referenced by any point_template, emitting its entities at stored
    positions"), deci toate ar aparea de la inceput (2491 de copaci in loc de 2371, plus particulele si prop-urile
    bazei distruse). Le mutam inapoi in CMapWorldLayer-ul lor (potrivite dupa clasa / pozitie / unghiuri / model
    cu lump-urile din harta 2016). Layer-ele si info_world_layer primesc numele din sursele Valve ("dire_base",
    compilatorul adauga prefixul world_layer_) si childSpawnGroup 1 (ca in harta 6.88 a lui Valve), iar
    npc_dota_fort le comuta la distrugere (OnKilled -> HideWorldLayerAndDestroyEntities / ShowWorldLayerAndSpawnEntities).
Motorul cauta pentru orice harta maps/<harta>/water_flow_map, fog_flow_map si fog_opacity_map (pictate in Hammer;
harta din 2016 nu le avea). Le luam din harta curenta a jocului (Source2Viewer-CLI, doar citire) ca surse .png + .vtex.

Rezerva, doar pentru comparatii (nu se mai foloseste in joc): cu --harta-valve se copiaza si maps/dota_688.vpk din
client (harta recompilata de Valve, date compilate vechi: Workshop Tools arata la pornire "Legacy Compiled Data") IN
addon, ca game/dota_addons/dota_688/maps/dota.vpk, pornita cu dota_launch_custom_game dota_688 dota. Fara optiune,
o copie ramasa de la rulari vechi se sterge (altfel dialogul revine si harta ar fi publicata in Workshop cu addon-ul).

    python tools/import_harta_688.py [C:\\dota688_depot\\export] [--harta-valve]
"""
import os
import re
import shutil
import subprocess
import sys
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from harta_entitati import parse_vents  # noqa: E402
import vmap_mesh  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOTA = os.environ.get("DOTA_DIR", r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta")
DMXCONVERT = os.environ.get("DMXCONVERT", os.path.join(DOTA, "game", "bin", "win64", "dmxconvert.exe"))
DEST = os.path.join(ROOT, "content", "dota_addons", "dota_688", "maps")
S2V_CLI = os.environ.get("S2V_CLI", r"C:\dota688_tools\S2V-CLI\Source2Viewer-CLI.exe")
GAME_MAP_VPK = os.environ.get("GAME_MAP_VPK", os.path.join(DOTA, "game", "dota", "maps", "dota.vpk"))
FLOW_MAPS = ("water_flow_map", "fog_flow_map", "fog_opacity_map")
MAP_2016_VPK = os.environ.get("MAP_2016_VPK", r"C:\dota688_depot\game\dota\maps\dota.vpk")
VALVE_MAP_688 = os.environ.get("VALVE_MAP_688", os.path.join(DOTA, "game", "dota", "maps", "dota_688.vpk"))
GAME_ADDON = os.path.join(ROOT, "game", "dota_addons", "dota_688")
ROSHAN_PIT_688 = "4320 -1824 168"
WORLD_LAYERS = ("radiant_base", "radiant_destruction", "dire_base", "dire_destruction")
TRIGGER_MATERIAL = "materials/tools/toolstrigger.vmat"
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


def s2v(vpk, path_filter, out, ext=None):
    """Source2Viewer-CLI: decompileaza fisierele din vpk care incep cu path_filter (doar citeste vpk-ul)."""
    cmd = [S2V_CLI, "-i", vpk, "-f", path_filter, "-d", "-o", out] + (["-e", ext] if ext else [])
    r = subprocess.run(cmd, capture_output=True, text=True, errors="replace")
    if r.returncode != 0:
        sys.exit(f"Source2Viewer-CLI a esuat ({' '.join(cmd)}):\n{r.stdout[-2000:]}\n{r.stderr[-2000:]}")


def source_vpk():
    """Harta din care luam trigger-ele si lump-urile: 6.88f din 2016 sau, in lipsa ei, cea recompilata de Valve."""
    for vpk in (MAP_2016_VPK, VALVE_MAP_688):
        if os.path.exists(vpk):
            return vpk
    sys.exit(f"lipseste harta 6.88: nici {MAP_2016_VPK}, nici {VALVE_MAP_688}")


def trigger_hulls(vpk, workdir):
    """{nume model (ex. unnamed_11): [hull = lista de puncte in coordonatele entitatii]} din maps/dota/entities/*.vmdl_c."""
    out = os.path.join(workdir, "triggere")
    shutil.rmtree(out, ignore_errors=True)
    s2v(vpk, "maps/dota/entities/", out, "vmdl_c")
    src = os.path.join(out, "maps", "dota", "entities")
    hulls = {}
    for name in sorted(os.listdir(src)):
        if not name.endswith(".vmdl"):
            continue
        vmdl = open(os.path.join(src, name), encoding="utf-8").read()
        files = re.findall(r'filename = "maps/dota/entities/([^"]+\.dmx)"', vmdl)
        if not files or "PhysicsMeshFile" in vmdl:
            sys.exit(f"{name}: astept doar PhysicsHullFile")
        hulls[name[:-5]] = []
        for f in files:
            txt = os.path.join(out, f + ".txt")
            dmxconvert(os.path.join(src, f), txt, "keyvalues2")
            m = re.search(r'"position\$0" "vector3_array"\s*\[(.*?)\]', open(txt, encoding="utf-8").read(), re.S)
            hulls[name[:-5]].append([tuple(float(c) for c in v.split()) for v in re.findall(r'"([^"]*)"', m.group(1))])
    return hulls


def layer_lumps(vpk, workdir):
    """{nume layer (ex. dire_base): entitatile din maps/dota/entities/world_layer_<nume>.vents}"""
    out = os.path.join(workdir, "lumpuri")
    shutil.rmtree(out, ignore_errors=True)
    s2v(vpk, "maps/dota/entities/", out, "vents_c")
    src = os.path.join(out, "maps", "dota", "entities")
    return {layer: parse_vents(os.path.join(src, f"world_layer_{layer}.vents")) for layer in WORLD_LAYERS}


# --- vmap in forma text: copiii lui CMapWorld ------------------------------------------------------------------
# dmxconvert scrie elementele inline cu indentare fixa: copiii lumii la 3 tab-uri, copiii unui copil la 5 tab-uri.

def array_items(lines, open_idx, ind):
    """Elementele unui element_array care incepe la lines[open_idx] == ind + '[' -> (liste de linii fara virgula, inchidere)."""
    items, i = [], open_idx + 1
    while lines[i] != ind + "]":
        if lines[i + 1] == ind + "\t{":
            j = i + 2
            while lines[j].rstrip(",") != ind + "\t}":
                j += 1
            items.append(lines[i:j] + [ind + "\t}"])
            i = j + 1
        else:
            items.append([lines[i].rstrip(",")])
            i += 1
    return items, i


def join_items(items):
    out = []
    for k, it in enumerate(items):
        out += it[:-1] + [it[-1] + ("," if k < len(items) - 1 else "")]
    return out


def children_span(item, ind):
    """(deschidere, inchidere) ale array-ului "children" al unui element inline indentat cu ind."""
    o = item.index(ind + '\t"children" "element_array" ') + 1
    c = o + 1
    while item[c] != ind + "\t]":
        c += 1
    return o, c


def ent_info(item):
    t = "\n".join(item)
    cls = re.search(r'"classname" "string" "([^"]*)"', t)
    model = re.search(r'"model" "string" "([^"]*)"', t)
    vec = lambda key: next(l.split('"')[5] for l in item if l.startswith(f'\t\t\t\t"{key}" '))
    return cls.group(1) if cls else "", model.group(1) if model else "", vec("origin"), vec("angles")


def ent_key(cls, model, origin, angles):
    nums = lambda s: [float(x) for x in s.replace(",", " ").strip("[] ").split()]
    model = model.replace("\\\\", "/").replace("\\", "/").lower().replace("maps/dota_688/", "maps/dota/")
    return (cls, model, tuple(round(x, 1) for x in nums(origin)),
            tuple(round(x % 360, 1) % 360 for x in nums(angles)))


def structure(t, hulls, lumps):
    """Trigger-ele primesc mesh-uri, entitatile layer-elor trec in CMapWorldLayer-ul lor."""
    lines = t.split("\n")
    w = lines.index('\t"world" "CMapWorld"')
    o = lines.index('\t\t"children" "element_array" ', w) + 1
    items, c = array_items(lines, o, "\t\t")

    # 1. trigger-e: meshe din hull-uri
    triggers = 0
    for n, it in enumerate(items):
        if it[0] != '\t\t\t"CMapEntity"':
            continue
        cls, model, origin, angles = ent_info(it)
        m = re.match(r"maps[\\/]+dota[\\/]+entities[\\/]+([a-z0-9_]+)\.vmdl$", model)
        if not m:
            continue
        if m.group(1) not in hulls:
            sys.exit(f"{cls} {model}: modelul lipseste din harta sursa")
        org = [float(x) for x in origin.split()]
        ang = [float(x) for x in angles.split()]
        meshes = [vmap_mesh.cmapmesh([vmap_mesh.rotate(p, ang) for p in hull], org, TRIGGER_MATERIAL).split("\n")
                  for hull in hulls[m.group(1)]]
        co, cc = children_span(it, "\t\t\t")
        it = [l for l in it[:co + 1] if not l.startswith('\t\t\t\t\t"model" "string" ')] + join_items(meshes) + it[cc:]
        items[n] = it
        triggers += 1

    # 2. world layer-e
    layer_at = {}
    for n, it in enumerate(items):
        if it[0] == '\t\t\t"CMapWorldLayer"':
            k = next(i for i, l in enumerate(it) if l.startswith('\t\t\t\t"worldLayerName" "string" '))
            name = it[k].split('"')[5].replace("world_layer_", "")
            it[k] = f'\t\t\t\t"worldLayerName" "string" "{name}"'
            layer_at[name] = n
    if sorted(layer_at) != sorted(WORLD_LAYERS):
        sys.exit(f"layer-e neasteptate in vmap: {sorted(layer_at)}")
    pool = {}
    for n, it in enumerate(items):
        if it[0] == '\t\t\t"CMapEntity"':
            pool.setdefault(ent_key(*ent_info(it)), []).append(n)
    move = {}
    for layer in WORLD_LAYERS:
        for e in lumps[layer]:
            k = ent_key(e.get("classname", ""), e.get("model", ""), e.get("origin", "0 0 0"), e.get("angles", "0 0 0"))
            if not pool.get(k):
                sys.exit(f"entitatea {k} din layer-ul {layer} nu e in vmap")
            move[pool[k].pop(0)] = layer
    for layer in WORLD_LAYERS:
        n = layer_at[layer]
        it = items[n]
        co, cc = children_span(it, "\t\t\t")
        kids, _ = array_items(it, co, "\t\t\t\t")
        kids += [["\t\t" + l if l else l for l in items[k]] for k in sorted(move) if move[k] == layer]
        items[n] = it[:co + 1] + join_items(kids) + it[cc:]
    items = [it for n, it in enumerate(items) if n not in move]

    # 3. info_world_layer: numele layer-ului fara prefix, fara worldname (le pune compilatorul), childSpawnGroup 1
    fixed = 0
    for n, it in enumerate(items):
        if it[0] != '\t\t\t"CMapEntity"' or not any('"classname" "string" "info_world_layer"' in l for l in it):
            continue
        new = []
        for l in it:
            if l.startswith('\t\t\t\t\t"layername" "string" '):
                l = l.replace('"world_layer_', '"')
                new.append(l)
                new.append('\t\t\t\t\t"childSpawnGroup" "string" "1"')
            elif not l.startswith('\t\t\t\t\t"worldname" ') and not l.lower().startswith('\t\t\t\t\t"childspawngroup" '):
                new.append(l)
        items[n] = new
        fixed += 1
    if fixed != 4:
        sys.exit(f"astept 4 info_world_layer, gasite {fixed}")
    counts = {layer: sum(1 for v in move.values() if v == layer) for layer in WORLD_LAYERS}
    print(f"trigger-e: {triggers} entitati brush cu mesh din {sum(len(h) for h in hulls.values())} hull-uri; "
          f"world layer-e: {len(move)} entitati mutate {counts}")
    return "\n".join(lines[:o + 1] + join_items(items) + lines[c:])


def edit_entities(vmap_path, workdir, hulls, lumps):
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

    # entitati cerute de motorul curent la PRE_GAME
    added = []
    for team in ("radiant", "dire"):
        for i in range(1, 6):
            added.append(clone_entity(t, f"info_courier_spawn_{team}", f"info_courier_spawn_{team}_{i}"))
    for i in (1, 2):
        added.append(clone_entity(t, "info_player_start_goodguys", "info_player_start_dota", ROSHAN_PIT_688, f"roshan_location_{i}"))
    _, end = entity_span(t, "info_player_start_goodguys")
    t = t[:end] + "".join(",\n\t\t\t" + b for b in added) + t[end:]
    t = structure(t, hulls, lumps)
    with open(text_path, "w", encoding="utf-8", newline="\n") as f:
        f.write(t)
    dmxconvert(text_path, vmap_path, "binary")
    os.remove(text_path)
    print(f"entitati: {runes} spawnere de rune -> info_target dota688_rune_top/bot; holdanimation scos de pe {hold} prop_dynamic; "
          f"{len(added)} entitati adaugate (curieri, pozitii Roshan)")


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


def valve_map(copy):
    """Rezerva: maps/dota_688.vpk din client (harta 6.88 recompilata de Valve) -> game/dota_addons/dota_688/maps/dota.vpk"""
    dest = os.path.join(GAME_ADDON, "maps", "dota.vpk")
    if not copy:
        if os.path.exists(dest):
            os.remove(dest)
            print(f"sters {dest} (copia hartii Valve de la rulari vechi; refaceti-o cu --harta-valve)")
        return
    if not os.path.exists(VALVE_MAP_688):
        sys.exit(f"lipseste {VALVE_MAP_688}")
    os.makedirs(os.path.dirname(dest), exist_ok=True)
    shutil.copyfile(VALVE_MAP_688, dest)
    print(f"harta de rezerva: {VALVE_MAP_688} -> {dest} ({os.path.getsize(dest) / 1e6:.1f} MB)\n"
          "ATENTIE: date compilate vechi (Workshop Tools arata \"Legacy Compiled Data\"); doar pentru comparatii, "
          "porniti-o cu dota_launch_custom_game dota_688 dota si stergeti-o (rulare fara --harta-valve) inainte de publicare")


def flow_maps(workdir):
    """water_flow_map / fog_flow_map / fog_opacity_map din harta curenta -> content/.../maps/dota_688/*.png + .vtex"""
    if not (os.path.exists(S2V_CLI) and os.path.exists(GAME_MAP_VPK)):
        sys.exit("lipsesc Source2Viewer-CLI sau maps/dota.vpk al jocului: texturile flow/fog nu pot fi create")
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


def decompile_map(export_dir):
    """Harta 2016 decompilata (maps/dota.vmap + world node-urile) in export_dir/maps, daca nu exista deja."""
    vmap = os.path.join(export_dir, "maps", "dota.vmap")
    if os.path.exists(vmap):
        return
    if not os.path.exists(MAP_2016_VPK):
        sys.exit(f"lipsesc {vmap} si {MAP_2016_VPK} (clientul 6.88f, vezi docs/HARTA.md)")
    print(f"decompilez {MAP_2016_VPK} -> {export_dir} (cateva minute)...")
    os.makedirs(os.path.dirname(vmap), exist_ok=True)
    s2v(MAP_2016_VPK, "maps/dota.vmap_c", vmap)


def main(args):
    flags = {a for a in args if a.startswith("--")}
    unknown = flags - {"--harta-valve"}
    if unknown:
        sys.exit(f"optiuni necunoscute: {', '.join(sorted(unknown))}")
    paths = [a for a in args if not a.startswith("--")]
    export_dir = paths[0] if paths else r"C:\dota688_depot\export"
    for tool in (DMXCONVERT, S2V_CLI):
        if not os.path.exists(tool):
            sys.exit(f"lipseste {tool}")
    valve_map("--harta-valve" in flags)
    decompile_map(export_dir)
    vpk = source_vpk()
    print(f"trigger-e si world layer-e din {vpk}")
    hulls = trigger_hulls(vpk, export_dir)
    lumps = layer_lumps(vpk, export_dir)

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
    flow_maps(export_dir)
    edit_entities(out, export_dir, hulls, lumps)

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
    main(sys.argv[1:])
