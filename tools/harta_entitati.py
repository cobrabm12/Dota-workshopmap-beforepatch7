"""Genereaza docs/HARTA_ENTITATI.md din harta 6.88f decompilata.

Intrari (nu sunt in repo):
  * entity lump-urile decompilate cu Source2Viewer-CLI:
      Source2Viewer-CLI -i <depot>/game/dota/maps/dota.vpk -f maps/dota/entities/ -e vents_c -d -o <ents>
  * content/dota_addons/dota_688/maps/dota_688.vmap (din tools/import_harta_688.py)
  * build/pak01_listing.txt si build/core_pak01_listing.txt: listarea VPK-urilor clientului curent
      Source2Viewer-CLI -i ".../game/dota/pak01_dir.vpk" --vpk_list > build/pak01_listing.txt

    python tools/harta_entitati.py C:\\dota688_depot\\ents
"""
import collections
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "docs", "HARTA_ENTITATI.md")
VMAP = os.path.join(ROOT, "content", "dota_addons", "dota_688", "maps", "dota_688.vmap")
LISTINGS = [os.path.join(ROOT, "build", n) for n in ("pak01_listing.txt", "core_pak01_listing.txt")]

TEAM = {"2": "Radiant", "3": "Dire", "0": "-", "": "-"}
NEUTRAL = {"0": "mic", "1": "mediu", "2": "mare", "3": "ancient"}
SHOP = {"0": "baza", "1": "side", "2": "secret"}
RES_RE = re.compile(r"(?:models|materials|particles|sounds|maps|scripts|panorama)/[A-Za-z0-9_\-/.]+\.(?:vmdl|vmat|vpcf|vtex|vsnd|vsndevts|vmap|vents|vphys)")


def parse_vents(path):
    ents, cur = [], None
    for line in open(path, encoding="utf-8", errors="replace"):
        line = line.rstrip("\n")
        if re.match(r"^====\d+====$", line):
            cur = {"_outputs": []}
            ents.append(cur)
            continue
        if cur is None or not line.strip():
            continue
        if line.startswith("@"):
            cur["_outputs"].append(line[1:])
            continue
        m = re.match(r"^(\S+)\s+(.*)$", line)
        if m:
            v = m.group(2).strip()
            if v.startswith('"') and v.endswith('"'):
                v = v[1:-1]
            cur[m.group(1)] = v
    return ents


def name(e):
    return e.get("targetname", "").replace("[PR#]", "")


def pos(e):
    o = e.get("origin", "")
    try:
        return " ".join(str(round(float(x))) for x in o.split())
    except ValueError:
        return o


def table(rows, header):
    out = ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    out += ["| " + " | ".join(str(c) for c in r) + " |" for r in rows]
    return out


def main(ents_dir):
    lumps = {}
    for root, _, files in os.walk(ents_dir):
        for f in sorted(files):
            if f.endswith(".vents"):
                lumps[f[:-6]] = parse_vents(os.path.join(root, f))
    ents = [e for lst in lumps.values() for e in lst]
    by = collections.defaultdict(list)
    for e in ents:
        by[e.get("classname", "?")].append(e)

    md = ["# Entitățile hărții 6.88f", "",
          "Generat de `tools/harta_entitati.py` din `maps/dota.vpk` al clientului 6.88f (depot 373301, manifest",
          "6583592615927321343, 7 dec 2016, build 1805), decompilat cu Source 2 Viewer. Coordonatele sunt `x y z` în",
          "unitățile hărții. Echipa: 2 = Radiant, 3 = Dire. Harta sursă: `content/dota_addons/dota_688/maps/dota_688.vmap`.", "",
          "Notă: în 6.88f harta era un VPK separat (`game/dota/maps/dota.vpk`, 21 MB), nu în `pak01`.", "",
          "## Clase (toate lump‑urile)", ""]
    rows = []
    for cls, lst in sorted(by.items(), key=lambda kv: (-len(kv[1]), kv[0])):
        per = collections.Counter()
        for ln, l in lumps.items():
            per[ln] = sum(1 for e in l if e.get("classname") == cls)
        rows.append((f"`{cls}`", len(lst), ", ".join(f"{k}: {v}" for k, v in per.items() if v)))
    md += table(rows, ["Clasă", "Total", "Pe lump"]) + [""]

    def section(title, classes, cols, note=None):
        lst = [e for c in classes for e in by.get(c, [])]
        if not lst:
            return
        md.extend([f"## {title}", ""])
        if note:
            md.extend([note, ""])
        lst.sort(key=lambda e: (e.get("classname", ""), name(e), pos(e)))
        md.extend(table([[f(e) for _, f in cols] for e in lst], [h for h, _ in cols]))
        md.append("")

    C = lambda e: f"`{e.get('classname')}`"
    N = lambda e: name(e) or e.get("volumename", "").replace("[PR#]", "")
    section("Start, fântâni, curieri", ["info_player_start", "info_player_start_goodguys", "info_player_start_badguys",
            "ent_dota_fountain", "info_courier_spawn_radiant", "info_courier_spawn_dire"],
            [("Clasă", C), ("Nume", N), ("Echipă", lambda e: TEAM.get(e.get("teamnumber", ""), e.get("teamnumber"))), ("Poziție", pos)])
    section("Spawner‑e de creepi (lane)", [c for c in by if c.startswith("npc_dota_spawner_")],
            [("Clasă", C), ("Nume", N), ("Poziție", pos)])
    section("Path corner‑uri", ["path_corner"],
            [("Nume", N), ("Următorul", lambda e: e.get("target", "").replace("[PR#]", "")), ("Poziție", pos)])
    section("Camp‑uri de neutrali", ["npc_dota_neutral_spawner"],
            [("Volum", N), ("Tip", lambda e: NEUTRAL.get(e.get("neutraltype", ""), e.get("neutraltype"))),
             ("Pull", lambda e: e.get("pulltype", "")), ("Poziție", pos)],
            "Tipuri 6.88: per junglă principală 2 mari, 2 medii, 1 mic; secundară 1 ancient + 1 mare.")
    section("Roshan și rune", ["npc_dota_roshan_spawner", "trigger_boss_attackable", "dota_item_rune_spawner",
            "dota_item_rune_spawner_powerup", "dota_item_rune_spawner_bounty"],
            [("Clasă", C), ("Nume", N), ("Poziție", pos)],
            "`dota_item_rune_spawner` este clasa din 2016; Lua (`dota688/runes.lua`) caută `info_target` "
            "`dota688_rune_top` / `dota688_rune_bot`, care se adaugă în Hammer la aceste două poziții.")
    section("Turnuri, barăci, Ancient", ["npc_dota_tower", "npc_dota_barracks", "npc_dota_fort"],
            [("Clasă", C), ("Nume", N), ("Unitate", lambda e: e.get("mapunitname", "")),
             ("Echipă", lambda e: TEAM.get(e.get("teamnumber", ""), e.get("teamnumber"))), ("Poziție", pos)])
    section("Clădiri (efigii etc.)", ["npc_dota_building"],
            [("Nume", N), ("Unitate", lambda e: e.get("mapunitname", "")),
             ("Echipă", lambda e: TEAM.get(e.get("teamnumber", ""), e.get("teamnumber"))), ("Poziție", pos)])
    section("Shop‑uri", ["trigger_shop", "ent_dota_shop"],
            [("Clasă", C), ("Nume", N), ("Tip", lambda e: SHOP.get(e.get("shoptype", ""), e.get("shoptype", ""))),
             ("Poziție", pos)])
    section("Alte entități de logică", ["info_target", "trigger_multiple", "trigger_no_wards", "logic_relay", "logic_auto",
            "dota_minimap_boundary", "world_bounds", "info_world_layer", "ent_dota_game_events", "ent_dota_halloffame"],
            [("Clasă", C), ("Nume", N), ("Poziție", pos)])

    # resurse referite de hartă care nu mai există în clientul curent
    current = set()
    for p in LISTINGS:
        if os.path.exists(p):
            for line in open(p, encoding="utf-8-sig", errors="replace"):
                current.add(line.split(" CRC:")[0].strip().lower())
    refs = collections.Counter()
    for e in ents:
        for k, v in e.items():
            if isinstance(v, str):
                for m in RES_RE.findall(re.sub(r"[\\/]+", "/", v)):
                    refs[m.lower()] += 1
    if os.path.exists(VMAP):
        data = open(VMAP, "rb").read().decode("latin-1")
        for m in RES_RE.findall(data):
            refs[m.lower()] += 1
    local = ("maps/dota/", "maps/dota_688/")
    missing = sorted(r for r in refs if not r.startswith(local) and (r + "_c") not in current)
    md += ["## Resurse care nu mai există în clientul curent", ""]
    if not current:
        md += ["Listarea clientului curent lipsește (`build/pak01_listing.txt`); verificarea nu s-a făcut.", ""]
    else:
        md += [f"Verificate {len(refs)} resurse distincte (modele, materiale, particule, texturi) referite de entități și de",
               "`dota_688.vmap`, față de `game/dota/pak01_dir.vpk` + `game/core/pak01_dir.vpk` ale clientului curent (doar citire).",
               "Numele evenimentelor de sunet nu se pot verifica offline.", ""]
        if missing:
            sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
            from import_harta_688 import RESOURCE_FIXES
            fixes = {k.decode(): v.decode() for k, v in RESOURCE_FIXES.items()}
            md += table([(f"`{m}`", refs[m], f"`{fixes[m]}`" if m in fixes else "de rezolvat în Hammer")
                         for m in missing], ["Resursă", "Referințe", "Înlocuită în dota_688.vmap cu"])
        else:
            md += ["Nicio resursă lipsă."]
        md.append("")
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(md))
    print(f"{OUT}: {len(ents)} entitati, {len(by)} clase, {len(refs)} resurse, {len(missing)} lipsa")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else r"C:\dota688_depot\ents")
