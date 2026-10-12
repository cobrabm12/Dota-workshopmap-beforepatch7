#!/usr/bin/env python3
"""Verificări de consistență ale addon-ului (fără joc):
  * toate fișierele KV se parsează
  * fiecare abilitate din sloturile eroilor există (built-in curent, generată sau custom)
  * fiecare ScriptFile al abilităților/itemelor Lua există și definește clasa cu numele respectiv
  * fiecare LinkLuaModifier arată către un fișier existent care definește modifierul
  * itemele din shops.txt și din rețete există
  * sintaxa Lua (dacă modulul luaparser este instalat)
Rulare: python3 tools/check_addon.py
"""
import glob
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kv  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADDON = os.path.join(ROOT, "game", "dota_addons", "dota_688")
NPC = os.path.join(ADDON, "scripts", "npc")
VS = os.path.join(ADDON, "scripts", "vscripts")
REF_NOW = os.path.join(ROOT, "reference", "current")

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
            for m in re.finditer(r'"((?:particles|models)/[^"]+\.(?:vpcf|vmdl))"', text):
                r = m.group(1).lower()
                if r not in files and (r + "_c") not in files:
                    err(f"{path}.lua: resursa {m.group(1)} nu există în clientul curent")
    else:
        warn("build/pak01_listing.txt lipsă: particulele/modelele referite din Lua nu au fost verificate")

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

    for w in warnings:
        print("AVERTISMENT:", w)
    for e in errors:
        print("EROARE:", e)
    print(f"{len(errors)} erori, {len(warnings)} avertismente")
    sys.exit(1 if errors else 0)


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
