#!/usr/bin/env python3
"""Verificări de consistență ale addon-ului (fără joc):
  * toate fișierele KV se parsează
  * fiecare abilitate din sloturile eroilor există (built-in curent, generată sau custom)
  * fiecare ScriptFile al abilităților/itemelor Lua există și definește clasa cu numele respectiv
  * fiecare LinkLuaModifier arată către un fișier existent care definește modifierul
  * itemele din shops.txt și din rețete există
  * particulele/modelele din Lua și particulele din KV-urile npc/ există în clientul curent (build/pak01_listing.txt)
  * evenimentele de sunet din Lua (EmitSound*, StopSound, StartSoundEvent*, EmitGlobalSound, PrecacheScriptSound...
    și orice alt literal "Prefix.Nume" din cod) există în clientul curent (build/sound_events.txt) sau în
    content/dota_addons/dota_688/soundevents/*.vsndevts; fișierele .vsndevts ale addon-ului: precache în Lua,
    compilate (.vsndevts_c), fișierele audio (vsnd_files) și straturile (soundevent_layerN) există
  * sintaxa Lua (dacă modulul luaparser este instalat)
Rulare: python3 tools/check_addon.py

Fișiere opționale din build/ (în .gitignore; fără ele verificările respective dau doar un avertisment):
  build/pak01_listing.txt   – lista fișierelor din game/dota/pak01_dir.vpk (vezi tools/README.md)
  build/sound_events.txt    – evenimentele de sunet ale clientului: python tools/dump_sound_events.py
                              (extrage soundevents/*.vsndevts_c din pak01_dir.vpk cu Source2Viewer-CLI;
                              de regenerat după fiecare patch Dota)
  build/vscript_api_*.txt   – ieșirea script_help2 / cl_script_help2
"""
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kv  # noqa: E402
from dump_sound_events import top_level_keys  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON = os.path.join(ROOT, "game", "dota_addons", "dota_688")
CONTENT = os.path.join(ROOT, "content", "dota_addons", "dota_688")
NPC = os.path.join(ADDON, "scripts", "npc")
VS = os.path.join(ADDON, "scripts", "vscripts")
REF_NOW = os.path.join(ROOT, "reference", "current")

# funcțiile VScript care primesc un nume de eveniment de sunet
SOUND_CALL = re.compile(r"\b(EmitSound\w*|StopSound\w*|StartSoundEvent\w*|StopGlobalSound|EmitGlobalSound|"
                        r"EmitAnnouncerSound\w*|PrecacheScriptSound)\s*\(")
# literal care arată ca un nume de eveniment ("Hero_Axe.Culling_Blade_Success"), nu ca un fișier
SOUND_LIT = re.compile(r'"([A-Za-z_][\w\-]*(?:\.[\w\-]+)+)"')
FILE_EXT = (".lua", ".vpcf", ".vmdl", ".vtex", ".vsndevts", ".vsnd", ".txt", ".png", ".xml", ".js", ".css", ".kv3")

errors: list[str] = []
warnings: list[str] = []


def err(msg): errors.append(msg)
def warn(msg): warnings.append(msg)


def load_all_now():
    abilities = kv.load(os.path.join(REF_NOW, "npc_abilities.txt"))["DOTAAbilities"]
    for p in glob.glob(os.path.join(REF_NOW, "heroes", "*.txt")):
        for _, blk in kv.load(p)["DOTAHeroes"].blocks():
            defs = blk.get_kv("AbilityDefinitions")
            if defs:
                for an, ab in defs.blocks():
                    abilities[an] = ab
    items = kv.load(os.path.join(REF_NOW, "items.txt"))["DOTAAbilities"]
    return abilities, items


def main():
    AN, IN = load_all_now()
    custom_ab = kv.load(os.path.join(NPC, "npc_abilities_custom.txt"))["DOTAAbilities"]
    custom_it = kv.load(os.path.join(NPC, "npc_items_custom.txt"))["DOTAAbilities"]
    heroes = kv.load(os.path.join(NPC, "npc_heroes_custom.txt"))["DOTAHeroes"]
    override = kv.load(os.path.join(NPC, "npc_abilities_override.txt"))["DOTAAbilities"]
    units = kv.load(os.path.join(NPC, "npc_units_custom.txt"))["DOTAUnits"]
    shops = kv.load(os.path.join(ADDON, "scripts", "shops.txt"))["dota_shops"]

    # addoninfo.txt in formatul Valve: "maps" text cu numele hartilor (nu bloc), IsPlayable 1, harta compilata exista.
    # Cu "maps" ca bloc, Arcade-ul nu vedea nicio harta (Create Lobby fara harti, Play nu pornea nimic).
    info = kv.load(os.path.join(ADDON, "addoninfo.txt"), follow_base=False)["AddonInfo"]
    maps = info.get("maps")
    if not isinstance(maps, str) or not maps.split():
        err('addoninfo.txt: "maps" trebuie sa fie un text cu numele hartilor (ex. "maps" "dota_688"), nu un bloc')
    else:
        for m in maps.split():
            if not os.path.exists(os.path.join(ADDON, "maps", m + ".vpk")):
                err(f"addoninfo.txt: harta {m} nu are maps/{m}.vpk compilat")
            if info.get_kv(m) is None:
                warn(f'addoninfo.txt: harta {m} nu are bloc propriu cu "MaxPlayers"')
    if info.get_str("IsPlayable") != "1":
        err('addoninfo.txt: lipseste "IsPlayable" "1" (necesar ca jocul sa poata fi pornit din Arcade)')

    known_ab = {n for n, _ in AN.blocks()} | {n for n, _ in custom_ab.blocks()}
    known_it = {n for n, _ in IN.blocks()} | {n for n, _ in custom_it.blocks()}

    # sloturile eroilor
    for hero, blk in heroes.blocks():
        if blk.get_str("Enabled") != "1":
            continue
        for k, v in blk.scalars():
            if re.fullmatch(r"Ability\d+", k) and v and v not in known_ab:
                err(f"{hero}: slotul {k} = {v!r} nu există în nicio definiție de abilități")

    # script files + clase Lua
    lua_text: dict[str, str] = {}
    for p in glob.glob(os.path.join(VS, "**", "*.lua"), recursive=True):
        if "dota688_test" in p:   # scripturi de test locale (ignorate de git), rulate din consola
            continue
        lua_text[os.path.relpath(p, VS).replace(os.sep, "/")[:-4]] = open(p, encoding="utf-8").read()

    def check_script(name, blk, kind):
        sf = blk.get_str("ScriptFile")
        bc = blk.get_str("BaseClass")
        if bc in ("ability_lua", "item_lua"):
            if not sf:
                err(f"{kind} {name}: BaseClass {bc} fără ScriptFile"); return
            if sf not in lua_text:
                err(f"{kind} {name}: ScriptFile {sf} nu există"); return
            # clasa trebuie definită în fișier sau în unul inclus (require)
            if not class_defined(name, sf, lua_text, set()):
                err(f"{kind} {name}: clasa Lua {name} nu este definită în {sf} (nici în require-urile lui)")

    for name, blk in custom_ab.blocks():
        if name != "Version":
            check_script(name, blk, "abilitate")
    for name, blk in custom_it.blocks():
        if name != "Version":
            check_script(name, blk, "item")

    # LinkLuaModifier
    for path, text in lua_text.items():
        for m in re.finditer(r'LinkLuaModifier\(\s*"([^"]+)"\s*,\s*"([^"]+)"', text):
            mod, target = m.group(1), m.group(2)
            if target not in lua_text:
                err(f"{path}.lua: LinkLuaModifier {mod} -> {target} (fișier inexistent)")
            elif not class_defined(mod, target, lua_text, set()):
                err(f"{path}.lua: modifierul {mod} nu este definit în {target}")
        for m in re.finditer(r'LinkLuaModifier\(\s*"([^"]+)"\s*,\s*F\s*,', text):
            fm = re.search(r'local F = "([^"]+)"', text)
            if fm and not class_defined(m.group(1), fm.group(1), lua_text, set()):
                err(f"{path}.lua: modifierul {m.group(1)} nu este definit în {fm.group(1)}")

    # shop + rețete
    for cat, blk in shops.blocks():
        for _, v in blk.scalars():
            if v not in known_it:
                err(f"shops.txt/{cat}: itemul {v} nu există")
    for name, blk in list(custom_it.blocks()) + list(override.blocks()):
        req = blk.get_kv("ItemRequirements")
        if req:
            for _, line in req.scalars():
                for comp in [x.strip() for x in line.split(";") if x.strip()]:
                    if comp not in known_it:
                        err(f"{name}: componenta {comp} din rețetă nu există")

    # unități referite de Lua (CreateUnitByName)
    known_units = {n for n, _ in units.blocks()} | {n for n, _ in kv.load(os.path.join(REF_NOW, "npc_units.txt"))["DOTAUnits"].blocks()}
    for path, text in lua_text.items():
        for m in re.finditer(r'CreateUnitByName\(\s*"([^"]+)"(\s*\.\.)?', text):
            name = m.group(1)
            if m.group(2):  # nume construit dinamic (prefix)
                if not any(u.startswith(name) for u in known_units):
                    err(f"{path}.lua: nicio unitate nu începe cu {name}")
            elif name not in known_units:
                err(f"{path}.lua: unitatea {name} nu există")

    # particule/modele referite din Lua (opțional: build/pak01_listing.txt = `git show HEAD:game/dota/pak01_dir.txt` din GameTracking-Dota2)
    listing = os.path.join(ROOT, "build", "pak01_listing.txt")
    if os.path.exists(listing):
        files = set(re.findall(r"^(\S+)", open(listing, encoding="utf-8", errors="replace").read().lower(), re.M))
        for path, text in lua_text.items():
            for m in re.finditer(r'"((?:particles|models)/[^"]+\.(?:vpcf|vmdl))"|\'((?:particles|models)/[^\']+\.(?:vpcf|vmdl))\'', text):
                res = m.group(1) or m.group(2)
                r = res.lower()
                if r not in files and (r + "_c") not in files:
                    err(f"{path}.lua: resursa {res} nu există în clientul curent")
            # cale construită dinamic: "particles/.../prefix_" .. x
            for m in re.finditer(r'"((?:particles|models)/[^"]*)"\s*\.\.', text):
                pre = m.group(1).lower()
                if not any(f.startswith(pre) for f in files):
                    err(f"{path}.lua: nicio resursă din clientul curent nu începe cu {m.group(1)}")
        # particulele din KV-urile addon-ului (proiectile, precache, ambient)
        for p in sorted(glob.glob(os.path.join(NPC, "*.txt"))):
            t = open(p, encoding="utf-8", errors="replace").read()
            name = os.path.basename(p)
            for res in sorted(set(re.findall(r'"(particles/[^"]+\.vpcf)"', t))):
                if res.lower() + "_c" not in files and res.lower() not in files:
                    err(f"{name}: particula {res} nu există în clientul curent")
            for folder in sorted(set(re.findall(r'"particle_folder"\s+"([^"]+)"', t))):
                pre = folder.lower().rstrip("/") + "/"
                if not any(f.startswith(pre) for f in files):
                    warn(f"{name}: particle_folder {folder} nu există în clientul curent")
        # iconitele abilitatilor/itemelor custom (AbilityTextureName)
        for kind, defs in (("abilitate", custom_ab), ("item", custom_it)):
            for name, blk in defs.blocks():
                tex = blk.get_str("AbilityTextureName")
                if not tex:
                    continue
                t = tex.lower()
                if kind == "item":
                    cands = [f"panorama/images/items/{t[5:] if t.startswith('item_') else t}_png.vtex_c"]
                else:
                    cands = [f"panorama/images/spellicons/{t}_png.vtex_c"]
                if not any(c in files for c in cands):
                    warn(f"{kind} {name}: iconita {tex} nu există în clientul curent ({cands[0]})")
    else:
        files = None
        warn("build/pak01_listing.txt lipsă: particulele/modelele referite din Lua nu au fost verificate")

    # evenimentele de sunet (Lua + soundevents/*.vsndevts ale addon-ului)
    check_sounds(lua_text, files)

    # API VScript (opțional: build/vscript_api_server.txt / _client.txt = ieșirea comenzilor script_help2 /
    # cl_script_help2 din consola jocului). Fiecare apel :Metoda(, funcție globală Majuscula( și constantă
    # MAJUSCULE trebuie să existe în API sau să fie definită în Lua-ul addon-ului.
    api_files = [os.path.join(ROOT, "build", f"vscript_api_{s}.txt") for s in ("server", "client")]
    if all(os.path.exists(p) for p in api_files):
        api_names, api_consts = set(), set()
        for p in api_files:
            t = open(p, encoding="utf-8", errors="replace").read()
            api_names |= set(re.findall(r"function (?:\w+[:.])?(\w+)\s*\(", t))
            api_consts |= set(re.findall(r"\b([A-Z][A-Z0-9_]+) = -?\d", t))
        ours, our_consts = set(), set()
        code = {}
        for path, text in lua_text.items():
            c = re.sub(r"--\[(=*)\[.*?\]\1\]", "", text, flags=re.S)
            c = re.sub(r"--[^\n]*", "", c)
            c = re.sub(r'"(?:\\.|[^"\\\n])*"|\'(?:\\.|[^\'\\\n])*\'', '""', c)
            code[path] = c
            ours |= set(re.findall(r"function\s+(?:[\w.]+[:.])?(\w+)\s*\(", c))
            ours |= set(re.findall(r"(\w+)\s*=\s*function\b", c))
            ours |= set(re.findall(r"(\w+)\s*=\s*class\s*\(", c))
            our_consts |= set(re.findall(r"\b([A-Z][A-Z0-9_]+)\s*=[^=]", c))
        # definite de bibliotecile Lua ale jocului (nu apar în script_help2): Vector, string, IsNull, Dynamic_Wrap, class
        lua_std = {"print", "require", "pairs", "ipairs", "type", "tostring", "tonumber", "class", "Vector", "QAngle",
                   "Dynamic_Wrap", "IsNull", "Length", "Length2D", "Normalized", "Dot", "Cross", "Lerp",
                   "find", "match", "gmatch", "sub", "gsub", "lower", "upper", "format", "len", "rep", "byte"}
        api_names |= lua_std
        missing_api: dict[str, set[str]] = {}
        for path, c in code.items():
            for n in set(re.findall(r":(\w+)\s*\(", c)):
                if n not in api_names and n not in ours:
                    missing_api.setdefault(f":{n}()", set()).add(path)
            for n in set(re.findall(r"(?<![\w.:])([A-Z]\w*[a-z]\w*)\s*\(", c)):
                if n not in api_names and n not in ours and n not in lua_std:
                    missing_api.setdefault(f"{n}()", set()).add(path)
            for n in set(re.findall(r"(?<![\w.])([A-Z][A-Z0-9]*_[A-Z0-9_]+)\b", c)):
                if n not in api_consts and n not in our_consts:
                    missing_api.setdefault(n, set()).add(path)
        for n, paths in sorted(missing_api.items()):
            err(f"API inexistent în jocul curent: {n} (în {', '.join(sorted(paths)[:4])}{'…' if len(paths) > 4 else ''})")
        # cod care rulează și pe client (modifieri: OnCreated, GetModifier*, CheckState...; abilități: GetCastRange...)
        # nu are voie să apeleze metode existente doar pe server, în afara blocurilor `if IsServer()`
        def names_in(p):
            t = open(p, encoding="utf-8", errors="replace").read()
            return set(re.findall(r"function (?:\w+[:.])?(\w+)\s*\(", t))
        server_only = names_in(api_files[0]) - names_in(api_files[1]) - lua_std
        client_fn = re.compile(r"^function \w+[:.](OnCreated|OnRefresh|GetModifier(?!PreAttack_CriticalStrike|ProcAttack_)\w*|CheckState|IsHidden|GetTexture|GetEffectName|"
                               r"GetStatusEffectName|IsAura|GetAura(?!EntityReject)\w*|GetCastRange|GetAOERadius|GetBehavior|GetManaCost|GetCooldown|"
                               r"GetIntrinsicModifierName|CastFilter\w*|GetCustomCastError\w*|GetAbilityTextureName)\s*\(")
        for path, c in code.items():
            lines = c.split("\n")
            i = 0
            while i < len(lines):
                if not client_fn.match(lines[i]):
                    i += 1
                    continue
                fname = lines[i]
                if re.search(r"\bend\s*$", lines[i]):   # functie pe o singura linie
                    body = [(i, lines[i].split(")", 1)[1] if ")" in lines[i] else "")]
                    if not re.search(r"IsServer\(\)", lines[i]):
                        for n in re.findall(r":(\w+)\s*\(", body[0][1]):
                            if n in server_only and n not in ours:
                                warn(f"{path}.lua:{i + 1}: {n}() există doar pe server, dar e apelat în "
                                     f"{fname.split('(')[0][9:]} (rulează și pe client) – pune-l sub IsServer()")
                    i += 1
                    continue
                j, skip_indent = i + 1, None
                while j < len(lines) and not lines[j].startswith("end"):
                    ln = lines[j]
                    ind = len(ln) - len(ln.lstrip())
                    if skip_indent is not None:
                        if ln.strip() == "end" and ind == skip_indent:
                            skip_indent = None
                        j += 1
                        continue
                    if re.match(r"\s*if not IsServer\(\) then return", ln):   # restul functiei ruleaza doar pe server
                        skip_indent = -1
                        j += 1
                        continue
                    if re.match(r"\s*if (?:not )?IsServer\(\)", ln):
                        if not re.search(r"\bend\s*$", ln) and "return" not in ln:
                            skip_indent = ind
                        j += 1
                        continue
                    for n in re.findall(r":(\w+)\s*\(", ln):
                        if re.search(r"\." + n + r"\s+and", ln):   # apel protejat: obj.Metoda and obj:Metoda()
                            continue
                        if n in server_only and n not in ours:
                            warn(f"{path}.lua:{j + 1}: {n}() există doar pe server, dar e apelat în "
                                 f"{fname.split('(')[0][9:]} (rulează și pe client) – pune-l sub IsServer()")
                    j += 1
                # funcție pe o singură linie: function X:Y() return ... end
                if j == i + 1 and re.search(r"\bend\s*$", lines[i]):
                    pass
                i = j + 1

        # Dota688SafeCall(obj, "Metoda"): tolerează lipsa, dar semnalăm metodele care nu mai există
        for path, text in lua_text.items():
            for m in re.finditer(r'Dota688SafeCall\(\s*\w+\s*,\s*"(\w+)"', text):
                if m.group(1) not in api_names:
                    warn(f"{path}.lua: Dota688SafeCall pe {m.group(1)}, care nu există în API (apelul nu are efect)")
    else:
        warn("build/vscript_api_server.txt / _client.txt lipsă: apelurile API din Lua nu au fost verificate "
             "(script_help2 / cl_script_help2 în consola jocului)")

    # sintaxă Lua
    try:
        from luaparser import ast  # type: ignore
        for path, text in lua_text.items():
            try:
                ast.parse(text)
            except Exception as e:  # noqa: BLE001
                err(f"{path}.lua: eroare de sintaxă: {str(e)[:200]}")
    except ImportError:
        warn("luaparser nu este instalat: sintaxa Lua nu a fost verificată (pip install luaparser)")

    if hasattr(sys.stdout, "reconfigure"):   # consola Windows cp1252: diacriticele nu opresc scriptul
        sys.stdout.reconfigure(errors="replace")
    for w in warnings:
        print("AVERTISMENT:", w)
    for e in errors:
        print("EROARE:", e)
    print(f"{len(errors)} erori, {len(warnings)} avertismente")
    sys.exit(1 if errors else 0)


def lua_strip_comments(text):
    """Codul Lua fără comentarii (-- și --[[ ]]); șirurile rămân neatinse, liniile își păstrează numerotarea."""
    out, i, n = [], 0, len(text)
    while i < n:
        c = text[i]
        if c in "\"'":
            j = i + 1
            while j < n and text[j] != c and text[j] != "\n":
                j += 2 if text[j] == "\\" else 1
            out.append(text[i:j + 1])
            i = j + 1
        elif c == "[" and re.match(r"\[=*\[", text[i:i + 64]):
            eq = re.match(r"\[(=*)\[", text[i:]).group(1)
            j = text.find("]" + eq + "]", i)
            j = n if j < 0 else j + len(eq) + 2
            out.append(text[i:j])
            i = j
        elif text.startswith("--", i):
            m = re.match(r"--\[(=*)\[", text[i:i + 64])
            if m:
                j = text.find("]" + m.group(1) + "]", i)
                j = n if j < 0 else j + len(m.group(1)) + 2
            else:
                j = text.find("\n", i)
                j = n if j < 0 else j
            out.append("\n" * text.count("\n", i, j))
            i = j
        else:
            out.append(c)
            i += 1
    return "".join(out)


def call_args(code, start):
    """Argumentele unui apel (de la poziția de după '(' până la ')' corespunzătoare), fără apelurile imbricate:
    în EmitSound(self:GetSpecialValueFor("x")) literalul "x" nu este un nume de sunet."""
    depth, i, n, top = 1, start, len(code), []
    while i < n and depth:
        c = code[i]
        if c in "\"'":
            j = i + 1
            while j < n and code[j] != c and code[j] != "\n":
                j += 2 if code[j] == "\\" else 1
            if depth == 1:
                top.append(code[i:j + 1])
            i = j + 1
            continue
        if c == "(":
            depth += 1
        elif c == ")":
            depth -= 1
        if depth == 1 and c != ")":
            top.append(c)
        i += 1
    return "".join(top)


def check_sounds(lua_text, files):
    """Evenimentele de sunet folosite în Lua trebuie să existe în client (build/sound_events.txt) sau în
    content/dota_addons/dota_688/soundevents/*.vsndevts (compilate și precache-uite)."""
    client: set[str] = set()
    path_events = os.path.join(ROOT, "build", "sound_events.txt")
    if os.path.exists(path_events):
        for line in open(path_events, encoding="utf-8", errors="replace"):
            if line.strip() and not line.startswith("#"):
                client.add(line.split("\t", 1)[0].strip())

    # evenimentele addon-ului
    ours: dict[str, str] = {}          # nume -> fișier .vsndevts
    bodies: list[tuple[str, str]] = []  # (fișier, text)
    all_lua = "\n".join(lua_text.values())
    for p in sorted(glob.glob(os.path.join(CONTENT, "soundevents", "**", "*.vsndevts"), recursive=True)):
        rel = os.path.relpath(p, CONTENT).replace(os.sep, "/")
        text = open(p, encoding="utf-8", errors="replace").read()
        bodies.append((rel, text))
        for k in top_level_keys(text):
            if k in ours:
                err(f"{rel}: evenimentul {k} este definit de două ori (și în {ours[k]})")
            elif k in client:
                warn(f"{rel}: evenimentul {k} redefinește un eveniment existent în client")
            ours.setdefault(k, rel)
        if not re.search(r'PrecacheResource\(\s*"soundfile"\s*,\s*"' + re.escape(rel) + '"', all_lua):
            err(f"{rel}: lipsește PrecacheResource(\"soundfile\", \"{rel}\", context) în Lua – evenimentele nu se încarcă")
        compiled = os.path.join(ADDON, rel + "_c")
        if not os.path.exists(compiled):
            err(f"{rel}: nu este compilat ({os.path.relpath(compiled, ROOT)} lipsă) – resourcecompiler -nop4 -i <fișier>")
        elif os.path.getmtime(compiled) + 1 < os.path.getmtime(p):
            warn(f"{rel}: compilatul {os.path.basename(compiled)} este mai vechi decât sursa – recompilează-l")

    if not client:
        warn("build/sound_events.txt lipsă: evenimentele de sunet din Lua nu au fost verificate "
             "(python tools/dump_sound_events.py)")
        return
    known = client | set(ours)
    known_lower = {k.lower(): k for k in known}

    # fișierele audio și straturile referite de evenimentele addon-ului
    for rel, text in bodies:
        for v in sorted(set(re.findall(r'"(sounds/[^"]+\.vsnd)"', text))):
            in_addon = any(os.path.exists(os.path.join(d, v + s)) for d in (CONTENT, ADDON) for s in ("", "_c"))
            if not in_addon and files is not None and v.lower() + "_c" not in files:
                err(f"{rel}: fișierul audio {v} nu există nici în client, nici în addon")
        for layer in sorted(set(re.findall(r'soundevent_layer\d*\s*=\s*"([^"]+)"', text))):
            if layer not in known:
                err(f"{rel}: stratul soundevent_layer {layer} nu există")

    used: set[str] = set()
    missing: dict[tuple[str, bool], set[str]] = {}   # (nume, eroare?) -> fișiere Lua
    case_only: dict[tuple[str, str], set[str]] = {}
    for path, text in lua_text.items():
        code = lua_strip_comments(text)
        hard = path.startswith(("abilities/", "items/"))
        direct: set[str] = set()
        for m in SOUND_CALL.finditer(code):
            args = call_args(code, m.end())
            for lm in re.finditer(r'(?:"([^"\\\n]*)"|\'([^\'\\\n]*)\')(\s*\.\.)?', args):
                s = lm.group(1) if lm.group(1) is not None else lm.group(2)
                if not s or "/" in s or " " in s or s.lower().endswith(FILE_EXT):
                    continue
                direct.add(s)
                if lm.group(3):   # nume construit: "Hero_OgreMagi.Fireblast.x" .. n
                    used.update(k for k in known if k.lower().startswith(s.lower()))
                    if not any(k.startswith(s.lower()) for k in known_lower):
                        missing.setdefault((s + "…", True), set()).add(path)
                    continue
                used.add(known_lower.get(s.lower(), s))
                if s not in known:
                    if s.lower() in known_lower:
                        case_only.setdefault((s, known_lower[s.lower()]), set()).add(path)
                    else:
                        missing.setdefault((s, True), set()).add(path)
        # literali "Prefix.Nume" transmiși indirect (ex. Dota688Techies.Explode(..., "Hero_Techies.RemoteMine.Detonate"))
        for lm in SOUND_LIT.finditer(code):
            s = lm.group(1)
            if s in direct or s.lower().endswith(FILE_EXT):
                continue
            if code[lm.end():lm.end() + 8].lstrip().startswith(".."):
                continue
            used.add(known_lower.get(s.lower(), s))
            if s not in known:
                if s.lower() in known_lower:
                    case_only.setdefault((s, known_lower[s.lower()]), set()).add(path)
                else:
                    missing.setdefault((s, hard), set()).add(path)

    def where(paths):
        paths = sorted(paths)
        return ", ".join(p + ".lua" for p in paths[:4]) + ("…" if len(paths) > 4 else "")
    for (s, hard), paths in sorted(missing.items()):
        msg = (f"sunetul {s} nu există în clientul curent și nici în soundevents/*.vsndevts ale addon-ului "
               f"(în {where(paths)}) – definește-l în content/dota_addons/dota_688/soundevents/dota688_sounds.vsndevts")
        (err if hard else warn)(msg)
    for (s, real), paths in sorted(case_only.items()):
        warn(f"sunetul {s} există în client doar ca {real} (în {where(paths)})")
    used_lower = {u.lower() for u in used}
    for k, rel in sorted(ours.items()):
        if k.lower() not in used_lower:
            warn(f"{rel}: evenimentul {k} nu este folosit în Lua")


def class_defined(name, path, lua_text, seen):
    if path in seen or path not in lua_text:
        return False
    seen.add(path)
    text = lua_text[path]
    if re.search(rf'(^|\n)\s*{re.escape(name)}\s*=', text):
        return True
    # definit prin factory: Dota688DefineItem("nume", ...) creeaza nume + modifier_nume; Dota688DefineAura("nume", ...) creeaza nume + nume_effect
    if f'"{name}"' in text and "Dota688Define" in text:
        return True
    if name.startswith("modifier_") and f'"{name[len("modifier_"):]}"' in text and "Dota688DefineItem" in text:
        return True
    if name.endswith("_effect") and f'"{name[:-len("_effect")]}"' in text and "Dota688DefineAura" in text:
        return True
    for m in re.finditer(r'require\(\s*"([^"]+)"\s*\)', text):
        if class_defined(name, m.group(1), lua_text, seen):
            return True
    return False


if __name__ == "__main__":
    main()
