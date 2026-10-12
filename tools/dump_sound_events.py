#!/usr/bin/env python3
"""Lista evenimentelor de sunet din clientul Dota 2 curent -> build/sound_events.txt (citit de tools/check_addon.py).

Pași (doar citire din instalarea Dota; nu modifică nimic în Steam):
  1. extrage și decompilează toate soundevents/*.vsndevts_c din game/dota/pak01_dir.vpk și game/core/pak01_dir.vpk
     cu Source2Viewer-CLI în DEPOT/sounds/all și DEPOT/sounds/core (KV3 text);
  2. citește cheile de pe primul nivel din fiecare .vsndevts (= numele evenimentelor) și scrie
     build/sound_events.txt:  <eveniment>\\t<fișierul sursă>  (sortat, o linie per eveniment).

Rulare (după fiecare patch Dota care schimbă sunetele):
    python tools/dump_sound_events.py              # extrage + scrie lista
    python tools/dump_sound_events.py --no-extract # doar re-citește extragerile existente

Căi (suprascrise prin variabile de mediu):
    DOTA_DIR  = C:\\Program Files (x86)\\Steam\\steamapps\\common\\dota 2 beta
    S2V_CLI   = C:\\dota688_tools\\S2V-CLI\\Source2Viewer-CLI.exe
    DEPOT_DIR = C:\\dota688_depot
"""
import glob
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DOTA = os.environ.get("DOTA_DIR", r"C:\Program Files (x86)\Steam\steamapps\common\dota 2 beta")
S2V = os.environ.get("S2V_CLI", r"C:\dota688_tools\S2V-CLI\Source2Viewer-CLI.exe")
DEPOT = os.environ.get("DEPOT_DIR", r"C:\dota688_depot")
SOURCES = [  # (vpk, folder de extragere)
    (os.path.join(DOTA, "game", "dota", "pak01_dir.vpk"), os.path.join(DEPOT, "sounds", "all")),
    (os.path.join(DOTA, "game", "core", "pak01_dir.vpk"), os.path.join(DEPOT, "sounds", "core")),
]
OUT = os.path.join(ROOT, "build", "sound_events.txt")


def top_level_keys(text):
    """Cheile de pe nivelul 1 dintr-un fișier KV3 text (decompilat de Source2Viewer)."""
    keys, depth, i, n = [], 0, 0, len(text)
    pending = None        # ultimul token (candidat de cheie) de pe nivelul 1
    value = False         # după "=" pe nivelul 1 urmează valoarea, nu o cheie
    token = re.compile(r"[^\s={}\[\]]+")
    while i < n:
        c = text[i]
        if c == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            if depth == 1:
                if value:
                    value = False
                elif pending is None:
                    pending = text[i + 1:j]
            i = j + 1
            continue
        if c == "/" and text.startswith("//", i):
            i = text.find("\n", i)
            i = n if i < 0 else i
            continue
        if c == "/" and text.startswith("/*", i):
            i = text.find("*/", i)
            i = n if i < 0 else i + 2
            continue
        if c == "<" and text.startswith("<!--", i):
            i = text.find("-->", i)
            i = n if i < 0 else i + 3
            continue
        if c in "{[":
            depth += 1
            value = False
        elif c in "}]":
            depth -= 1
        elif depth == 1:
            if c == "=":
                if pending:
                    keys.append(pending)
                pending, value = None, True
            elif not c.isspace():
                m = token.match(text, i)
                if value:
                    value = False
                elif pending is None:
                    pending = m.group(0)
                i = m.end()
                continue
        if depth != 1:
            pending = None
        i += 1
    return keys


def extract():
    if not os.path.exists(S2V):
        sys.exit(f"lipsește {S2V} (Source2Viewer-CLI)")
    for vpk, out in SOURCES:
        if not os.path.exists(vpk):
            sys.exit(f"lipsește {vpk}")
        os.makedirs(out, exist_ok=True)
        r = subprocess.run([S2V, "-i", vpk, "-f", "soundevents/", "-e", "vsndevts_c", "-d", "--threads", "8", "-o", out],
                           capture_output=True, text=True, errors="replace")
        if r.returncode != 0:
            print(r.stdout[-3000:], r.stderr[-3000:])
            sys.exit(f"extragerea din {vpk} a eșuat")


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if "--no-extract" not in sys.argv:
        extract()
    events = {}
    nfiles = 0
    for _, out in SOURCES:
        for p in sorted(glob.glob(os.path.join(out, "**", "*.vsndevts"), recursive=True)):
            nfiles += 1
            rel = os.path.relpath(p, out).replace(os.sep, "/")
            for k in top_level_keys(open(p, encoding="utf-8", errors="replace").read()):
                events.setdefault(k, rel)
    if not events:
        sys.exit("niciun eveniment găsit (extragerea lipsește?)")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write("# evenimente de sunet din clientul curent; regenerare: python tools/dump_sound_events.py\n")
        for k in sorted(events, key=str.lower):
            f.write(f"{k}\t{events[k]}\n")
    print(f"{len(events)} evenimente din {nfiles} fișiere .vsndevts -> {OUT}")


if __name__ == "__main__":
    main()
