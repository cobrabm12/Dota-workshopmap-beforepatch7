"""Compileaza harta 6.88 fara Hammer, cu resourcecompiler.exe din Workshop Tools.

Ordinea conteaza: texturile flow/fog si world node-urile (modele folosite ca prop-uri) se compileaza intai,
altfel compilarea hartii (-fshallow) nu le gaseste ("Failed to load model for prop maps/dota_688/worldnodes/...").
Rezultat: game/dota_addons/dota_688/maps/dota_688.vpk (in .gitignore), cu entitatile, trigger-ele compilate din
mesh-urile vmap-ului (maps/dota_688/entities/*.vmdl, fizica in formatul curent) si world layer-ele bazelor; world
node-urile si texturile flow/fog raman fisiere separate in game/dota_addons/dota_688/maps/dota_688/.
Sursa (content/dota_addons/dota_688/maps/dota_688.vmap + maps/dota_688/) o scrie tools/import_harta_688.py.
Avertismentul "Duplicate Bone" la world node-uri este inofensiv.

    python tools/compile_harta_688.py
"""
import os
import subprocess
import sys

DOTA = os.environ.get("DOTA_DIR", r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta")
RC = os.path.join(DOTA, "game", "bin", "win64", "resourcecompiler.exe")
# prin junction-ul din content\dota_addons: resourcecompiler deduce mod-ul (dota_688) din cale
MAPS = os.path.join(DOTA, "content", "dota_addons", "dota_688", "maps")
STEPS = [
    ("texturi flow/fog", [os.path.join(MAPS, "dota_688", "*.vtex")], []),
    ("world nodes", [os.path.join(MAPS, "dota_688", "worldnodes", "*.vmdl")], []),
    ("harta", [os.path.join(MAPS, "dota_688.vmap")], ["-fshallow"]),
]


def main():
    if not os.path.exists(RC):
        sys.exit(f"lipseste {RC} (Dota 2 Workshop Tools)")
    for label, inputs, extra in STEPS:
        r = subprocess.run([RC, "-nop4", *extra, "-i", *inputs], capture_output=True, text=True, errors="replace")
        summary = [l.strip() for l in r.stdout.splitlines() if " compiled, " in l]
        print(f"{label}: {summary[-1] if summary else '?'}")
        if r.returncode != 0 or (summary and " 0 failed" not in summary[-1]):
            print(r.stdout[-3000:])
            sys.exit(f"compilarea a esuat la pasul: {label}")
    vpk = os.path.join(DOTA, "game", "dota_addons", "dota_688", "maps", "dota_688.vpk")
    print(f"{vpk}: {os.path.getsize(vpk) / 1e6:.1f} MB")


if __name__ == "__main__":
    main()
