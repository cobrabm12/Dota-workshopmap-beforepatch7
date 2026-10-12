#!/usr/bin/env python3
"""Generează fișierele de override ale addon-ului „Dota 6.88” pornind de la
fișierele originale Valve din 6.88f (reference/6.88f) și de la cele curente
(reference/current).

Produce:
  game/dota_addons/dota_688/scripts/npc/npc_heroes_custom.txt
  game/dota_addons/dota_688/scripts/npc/npc_abilities_override.txt
  game/dota_addons/dota_688/scripts/npc/npc_items_generated.txt
  game/dota_addons/dota_688/scripts/npc/npc_units_custom.txt
  game/dota_addons/dota_688/scripts/npc/herolist.txt
  docs/STATUS.md            – raport (ce se mapează 1:1, ce trebuie rescris în Lua)
  build/report.json         – același raport, pentru unelte

Rulare:  python3 tools/gen_overrides.py
"""
from __future__ import annotations

import glob
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kv  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF_OLD = os.path.join(ROOT, "reference", "6.88f")
REF_NOW = os.path.join(ROOT, "reference", "current")
ADDON = os.path.join(ROOT, "game", "dota_addons", "dota_688")
NPC = os.path.join(ADDON, "scripts", "npc")
DOCS = os.path.join(ROOT, "docs")
BUILD = os.path.join(ROOT, "build")

HEADER = "GENERAT AUTOMAT de tools/gen_overrides.py – NU EDITA MANUAL.\nSursa: reference/6.88f (Valve, 6.88f) vs reference/current."

# Chei de statistici de erou copiate din 6.88 (valoarea efectivă: a eroului sau a bazei)
HERO_STAT_KEYS = [
    "ArmorPhysical", "MagicalResistance",
    "AttackCapabilities", "AttackDamageMin", "AttackDamageMax", "AttackRate",
    "AttackAnimationPoint", "AttackAcquisitionRange", "AttackRange", "ProjectileSpeed",
    "AttributePrimary", "AttributeBaseStrength", "AttributeStrengthGain",
    "AttributeBaseIntelligence", "AttributeIntelligenceGain",
    "AttributeBaseAgility", "AttributeAgilityGain",
    "MovementSpeed", "MovementTurnRate",
    "StatusHealth", "StatusHealthRegen", "StatusMana", "StatusManaRegen",
    "VisionDaytimeRange", "VisionNighttimeRange",
    "AbilityLayout", "Legs",
]

# Chei numerice de nivel superior ale abilităților, comparate 6.88 vs curent
ABILITY_TOP_KEYS = [
    "AbilityCastRange", "AbilityCastPoint", "AbilityCooldown", "AbilityManaCost",
    "AbilityDamage", "AbilityDuration", "AbilityChannelTime", "AbilityCharges",
    "AbilityChargeRestoreTime", "RequiredLevel", "LevelsBetweenUpgrades", "MaxLevel",
    "AbilityCastRangeBuffer", "AbilityModifierSupportValue", "AbilityModifierSupportBonus",
]

ITEM_TOP_KEYS = ABILITY_TOP_KEYS + [
    "ItemCost", "ItemInitialCharges", "ItemStockMax", "ItemStockInitial", "ItemStockTime",
    "ItemInitialStockTime", "ItemShareability", "ItemSellable", "ItemDroppable", "ItemKillable",
    "ItemPurchasable", "ItemDisassembleRule", "ItemPermanent", "ItemAlertable", "ItemStackable",
    "ItemRequiresCharges", "ItemQuality", "SideShop", "SecretShop", "ItemShopTags",
]

# Unități ale căror statistici le readucem la 6.88 (restul rămân cum sunt în joc)
UNIT_PREFIXES = (
    "npc_dota_goodguys_", "npc_dota_badguys_",
    "npc_dota_creep_goodguys_", "npc_dota_creep_badguys_",
    "npc_dota_neutral_", "npc_dota_roshan", "npc_dota_courier", "npc_dota_flying_courier",
    "npc_dota_fort", "npc_dota_observer_wards", "npc_dota_sentry_wards",
)
UNIT_STAT_KEYS = [
    "Level", "StatusHealth", "StatusHealthRegen", "StatusMana", "StatusManaRegen",
    "ArmorPhysical", "MagicalResistance",
    "AttackDamageMin", "AttackDamageMax", "AttackRate", "AttackRange", "AttackAcquisitionRange",
    "AttackAnimationPoint", "ProjectileSpeed", "AttackSpeedActivityModifiers",
    "BountyXP", "BountyGoldMin", "BountyGoldMax",
    "MovementSpeed", "MovementTurnRate",
    "VisionDaytimeRange", "VisionNighttimeRange",
]

# Sloturi de abilitate pe care le golim (talente 10‑17, inate, etc.)
MAX_ABILITY_SLOT = 24

# Abilități din 6.88 care nu mai există, dar care erau doar placeholder-e sau au echivalent direct
RENAME = {
    "wisp_empty1": "generic_hidden",
    "wisp_empty2": "generic_hidden",
    "phoenix_sun_ray_toggle_move_empty": "generic_hidden",
    "morphling_morph": "generic_hidden",                              # doar urmărea nivelul perechii morph_agi/str
    "keeper_of_the_light_spirit_form_illuminate": "generic_hidden",     # motorul curent gestionează Illuminate în Spirit Form
    "keeper_of_the_light_spirit_form_illuminate_end": "generic_hidden",
}
# Ordinea sloturilor pentru eroii ale căror sub-abilități ascunse s-au reorganizat (6.88 -> acum)
SLOT_OVERRIDES = {
    "npc_dota_hero_wisp": ["wisp_tether", "wisp_spirits", "wisp_overcharge", "wisp_spirits_in", "wisp_spirits_out", "wisp_relocate", "wisp_tether_break"],
    "npc_dota_hero_phoenix": ["phoenix_icarus_dive", "phoenix_fire_spirits", "phoenix_sun_ray", "phoenix_sun_ray_toggle_move", "phoenix_supernova", "phoenix_launch_fire_spirit", "phoenix_icarus_dive_stop", "phoenix_sun_ray_stop"],
}


# ---------------------------------------------------------------------------
# încărcare
# ---------------------------------------------------------------------------

def load_old():
    heroes = kv.load(os.path.join(REF_OLD, "npc_heroes.txt"))["DOTAHeroes"]
    abilities = kv.load(os.path.join(REF_OLD, "npc_abilities.txt"))["DOTAAbilities"]
    items = kv.load(os.path.join(REF_OLD, "items.txt"))["DOTAAbilities"]
    units = kv.load(os.path.join(REF_OLD, "npc_units.txt"))["DOTAUnits"]
    return heroes, abilities, items, units


def load_now():
    heroes = kv.KV()
    abilities = kv.load(os.path.join(REF_NOW, "npc_abilities.txt"))["DOTAAbilities"]
    base = kv.load(os.path.join(REF_NOW, "npc_heroes.txt"), follow_base=False)
    for p in sorted(glob.glob(os.path.join(REF_NOW, "heroes", "*.txt"))):
        doc = kv.load(p)
        h = doc.get_kv("DOTAHeroes")
        if h is None:
            continue
        for name, blk in h.blocks():
            heroes[name] = blk
            defs = blk.get_kv("AbilityDefinitions")
            if defs is not None:
                for an, ab in defs.blocks():
                    abilities[an] = ab
    items = kv.load(os.path.join(REF_NOW, "items.txt"))["DOTAAbilities"]
    units = kv.load(os.path.join(REF_NOW, "npc_units.txt"))["DOTAUnits"]
    return heroes, abilities, items, units


CUSTOM_ABILITY_PREFIX = "dota688_"
CUSTOM_ITEM_PREFIX = "item_dota688_"


def custom_name_for(name: str) -> str:
    """Numele reimplementării Lua pentru o abilitate/un item built-in."""
    if name.startswith("item_"):
        return CUSTOM_ITEM_PREFIX + name[len("item_"):]
    return CUSTOM_ABILITY_PREFIX + name


def resolve(name: str, custom: set[str]) -> str:
    """Dacă există o reimplementare Lua pentru `name`, întoarce numele ei; altfel `name`."""
    c = custom_name_for(name)
    return c if c in custom else name


def load_custom_names() -> set[str]:
    """Abilitățile/itemele pe care le-am reimplementat deja în addon (Lua)."""
    names: set[str] = set()
    for fn in ("npc_abilities_custom.txt", "npc_items_custom.txt"):
        p = os.path.join(NPC, fn)
        if os.path.exists(p):
            doc = kv.load(p, follow_base=False)  # fara #base: npc_items_generated.txt e produs de noi
            root = doc.get_kv("DOTAAbilities")
            if root is not None:
                for n, _ in root.blocks():
                    names.add(n)
    return names


# ---------------------------------------------------------------------------
# utilitare
# ---------------------------------------------------------------------------

def norm_num_list(s: str) -> list[str]:
    parts = s.replace(",", " ").split()
    out = []
    for p in parts:
        try:
            f = float(p)
            out.append(("%g" % f))
        except ValueError:
            out.append(p)
    return out


def same_value(a: str, b: str) -> bool:
    if a.strip() == b.strip():
        return True
    la, lb = norm_num_list(a), norm_num_list(b)
    if not la or not lb:
        return False
    # "12" == "12 12 12 12"
    if len(set(la)) == 1 and len(set(lb)) == 1:
        return la[0] == lb[0]
    if len(la) != len(lb):
        n = max(len(la), len(lb))
        la = la + [la[-1]] * (n - len(la))
        lb = lb + [lb[-1]] * (n - len(lb))
    return la == lb


def effective(blk: kv.KV, base: kv.KV | None, key: str) -> str | None:
    v = blk.get_str(key)
    if v is None and base is not None:
        v = base.get_str(key)
    return v


def where_defined(cur: kv.KV, key: str) -> str:
    """'top' | 'values' | 'none' – unde definește abilitatea curentă cheia."""
    if cur.get_str(key) is not None:
        return "top"
    av = cur.get_kv("AbilityValues")
    if av is not None and key in av:
        return "values"
    return "none"


def cur_value(cur: kv.KV, key: str) -> str | None:
    v = cur.get_str(key)
    if v is not None:
        return v
    av = cur.get_kv("AbilityValues")
    if av is not None:
        x = av.get(key)
        if isinstance(x, kv.KV):
            return x.get_str("value")
        if isinstance(x, str):
            return x
    return None


def special_index(cur: kv.KV, key: str) -> tuple[str, str] | None:
    """Pentru abilități curente în format vechi AbilitySpecial: (index, var_type)."""
    sp = cur.get_kv("AbilitySpecial")
    if sp is None:
        return None
    for idx, blk in sp.blocks():
        if key in blk:
            return idx, blk.get_str("var_type", "FIELD_FLOAT")
    return None


def slot_abilities(hero: kv.KV) -> list[tuple[int, str]]:
    out = []
    for k, v in hero.scalars():
        m = re.fullmatch(r"Ability(\d+)", k)
        if m:
            out.append((int(m.group(1)), v))
    return sorted(out)


# ---------------------------------------------------------------------------
# generare
# ---------------------------------------------------------------------------

def build_ability_override(name: str, old: kv.KV, cur: kv.KV, top_keys: list[str], report: dict) -> kv.KV | None:
    """Întoarce blocul de override (sau None dacă nu e nimic de schimbat)."""
    out = kv.KV()
    values = kv.KV()
    specials = kv.KV()
    missing: list[str] = []
    changed: list[str] = []

    old_vals = kv.values_of(old)
    cur_vals = kv.values_of(cur)
    cur_uses_values = cur.get_kv("AbilityValues") is not None

    for key in top_keys:
        ov = old.get_str(key)
        if ov is None:
            continue
        cv = cur_value(cur, key)
        if cv is not None and same_value(ov, cv):
            continue
        if cv is None and key in ("AbilityCastRange", "AbilityCastPoint", "AbilityCooldown", "AbilityManaCost") and set(norm_num_list(ov)) <= {"0"}:
            continue  # 0 implicit
        loc = where_defined(cur, key)
        if loc == "values":
            values[key] = ov
        else:
            out[key] = ov
        changed.append(key)

    for key, ov in old_vals.items():
        if key in cur_vals:
            if same_value(ov, cur_vals[key]):
                continue
            if cur_uses_values:
                values[key] = ov
            else:
                si = special_index(cur, key)
                if si is None:
                    missing.append(key)
                    continue
                idx, vt = si
                blk = kv.KV([("var_type", vt), (key, ov)])
                specials[idx] = blk
            changed.append(key)
        else:
            missing.append(key)

    # ItemRequirements (rețete): copiem blocul din 6.88 dacă diferă
    if "ItemRequirements" in top_keys or name.startswith("item_"):
        oreq = old.get_kv("ItemRequirements")
        creq = cur.get_kv("ItemRequirements")
        if oreq is not None:
            if creq is None or kv.dumps(oreq) != kv.dumps(creq):
                out["ItemRequirements"] = oreq.copy()
                changed.append("ItemRequirements")

    ob = old.get_str("AbilityBehavior")
    cb = cur.get_str("AbilityBehavior")
    behavior_diff = None
    if ob and cb:
        so = {x.strip() for x in ob.split("|")}
        sc = {x.strip() for x in cb.split("|")}
        if so != sc:
            behavior_diff = {"6.88": sorted(so - sc), "acum": sorted(sc - so)}

    report[name] = {
        "schimbate": sorted(set(changed)),
        "speciale_lipsa": sorted(set(missing)),
        "comportament": behavior_diff,
    }

    if len(values):
        out["AbilityValues"] = values
    if len(specials):
        out["AbilitySpecial"] = specials
    return out if len(out) else None


def gen_heroes(H0, HN, A0, AN, custom: set[str], report: dict) -> tuple[kv.KV, list[str]]:
    base0 = H0.get_kv("npc_dota_hero_base")
    baseN = HN.get_kv("npc_dota_hero_base")
    out = kv.KV()
    hero_list: list[str] = []

    old_heroes = [(n, b) for n, b in H0.blocks() if n != "npc_dota_hero_base" and b.get_str("Enabled") == "1"]
    now_names = {n for n, _ in HN.blocks()}

    for name, h in old_heroes:
        if name not in now_names:
            report["erou_disparut"].append(name)
            continue
        hero_list.append(name)
        cur = HN.get_kv(name)
        o = kv.KV()
        o["override_hero"] = name
        o["Enabled"] = "1"
        for key in HERO_STAT_KEYS:
            v = effective(h, base0, key)
            if v is not None:
                o[key] = v

        # --- abilități -----------------------------------------------------
        old_slots = slot_abilities(h)
        if name in SLOT_OVERRIDES:
            old_slots = list(enumerate(SLOT_OVERRIDES[name], start=1))
        cur_slots = [(i, a) for i, a in slot_abilities(cur) if a and not a.startswith("special_bonus")]
        cur_real = [a for _, a in cur_slots if a not in ("generic_hidden", "") and not AN.get_kv(a) or (AN.get_kv(a) and AN.get_kv(a).get_str("Innate") != "1")]
        cur_real = [a for a in cur_real if a not in ("generic_hidden", "")]
        hero_rep = {"abilitati_ok": [], "abilitati_custom": [], "abilitati_lipsa": [], "fallback": {}}
        used_slots: list[str] = []
        for _, aname in old_slots:
            if aname == "":
                continue
            if aname == "attribute_bonus":
                continue  # îl adăugăm la final
            if aname in RENAME:
                aname = RENAME[aname]
            if custom_name_for(aname) in custom:
                hero_rep["abilitati_custom"].append(aname)
                used_slots.append(custom_name_for(aname))
            elif aname in custom:
                hero_rep["abilitati_custom"].append(aname)
                used_slots.append(aname)
            elif aname in AN:
                hero_rep["abilitati_ok"].append(aname)
                used_slots.append(aname)
            else:
                hero_rep["abilitati_lipsa"].append(aname)
                # fallback: abilitatea curentă din același slot (dacă există și nu e deja folosită)
                idx = len(used_slots)
                fb = None
                if idx < len(cur_real) and cur_real[idx] not in used_slots:
                    fb = cur_real[idx]
                if fb:
                    hero_rep["fallback"][aname] = fb
                    used_slots.append(fb)
                else:
                    used_slots.append("dota688_empty")
        used_slots.append("dota688_attribute_bonus")  # Attribute Bonus clasic, implementat in Lua
        for i, aname in enumerate(used_slots, start=1):
            o[f"Ability{i}"] = aname
        for i in range(len(used_slots) + 1, MAX_ABILITY_SLOT + 1):
            o[f"Ability{i}"] = ""
        # Fără AbilityDraftAbilities/talente/fațete (7.36+) – un singur „facet” neutru.
        facets = kv.KV()
        facets["dota688_classic"] = kv.KV([("Icon", "sword"), ("Color", "Gray"), ("GradientID", "0")])
        o["Facets"] = facets
        out[name] = o
        report["eroi"][name] = hero_rep

    for name, cur in HN.blocks():
        if name == "npc_dota_hero_base" or name in dict(old_heroes):
            continue
        if cur.get_str("Enabled") != "1":
            continue
        o = kv.KV()
        o["override_hero"] = name
        o["Enabled"] = "0"
        o["CMEnabled"] = "0"
        o["new_player_enable"] = "0"
        out[name] = o
        report["eroi_noi_dezactivati"].append(name)
    return out, hero_list


def gen_abilities(A0, AN, custom: set[str], report: dict) -> kv.KV:
    out = kv.KV()
    for name, old in A0.blocks():
        if name.startswith("special_bonus") or name in ("Version",):
            continue
        if name in custom or custom_name_for(name) in custom:
            report["abilitati"][name] = {"schimbate": [], "speciale_lipsa": [], "comportament": None, "lua": True}
            continue
        cur = AN.get_kv(name)
        if cur is None:
            report["abilitati_inexistente"].append(name)
            continue
        if old.get_str("AbilityType") == "DOTA_ABILITY_TYPE_ATTRIBUTES":
            continue
        blk = build_ability_override(name, old, cur, ABILITY_TOP_KEYS, report["abilitati"])
        if blk is not None:
            out[name] = blk
    return out


def item_requirements_resolved(blk: kv.KV, custom: set[str]) -> kv.KV | None:
    """Copie a blocului ItemRequirements cu componentele înlocuite de reimplementările Lua."""
    req = blk.get_kv("ItemRequirements")
    if req is None:
        return None
    out = kv.KV()
    for idx, line in req.scalars():
        parts = [p.strip() for p in line.split(";") if p.strip()]
        parts = [resolve_item(x, custom) for x in parts]
        out[idx] = ";".join(parts)
    return out


def resolve_item(name: str, custom: set[str]) -> str:
    """Un item built-in -> reimplementarea lui Lua (dacă există); rețeta lui -> rețeta custom."""
    if name.startswith("item_recipe_"):
        base = "item_" + name[len("item_recipe_"):]
        if custom_name_for(base) in custom:
            return "item_recipe_dota688_" + name[len("item_recipe_"):]
        return name
    return resolve(name, custom)


def gen_items(I0, IN, custom: set[str], report: dict) -> tuple[kv.KV, kv.KV]:
    override = kv.KV()
    recreate = kv.KV()
    old_names = {n for n, _ in I0.blocks()}
    for name, old in I0.blocks():
        if name == "Version" or name in custom:
            continue
        has_custom = custom_name_for(name) in custom
        is_recipe = name.startswith("item_recipe_")
        recipe_of_custom = is_recipe and custom_name_for("item_" + name[len("item_recipe_"):]) in custom
        cur = IN.get_kv(name)

        if has_custom or recipe_of_custom:
            # built-in-ul iese din shop; varianta Lua (și rețeta ei) sunt generate mai jos
            if cur is not None:
                override[name] = kv.KV([("ItemPurchasable", "0"), ("ShouldBeSuggested", "0")])
            if recipe_of_custom:
                blk = old.copy()
                if "ID" in blk:
                    del blk["ID"]
                blk["ItemResult"] = resolve(old.get_str("ItemResult", ""), custom)
                req = item_requirements_resolved(old, custom)
                if req is not None:
                    blk["ItemRequirements"] = req
                blk["AbilityTextureName"] = "item_recipe"
                recreate[resolve_item(name, custom)] = blk
            report["iteme"][name] = {"schimbate": [], "speciale_lipsa": [], "comportament": None, "lua": True}
            continue

        if cur is None:
            if re.search(r"halloween|winter|mystery|greevil|present|banana|candy|diretide|frostivus", name):
                continue  # iteme de eveniment, irelevante pentru joc
            report["iteme_disparute"].append(name)
            continue

        blk = build_ability_override(name, old, cur, ITEM_TOP_KEYS, report["iteme"])
        if blk is None:
            blk = kv.KV()
        # rețetele care folosesc componente reimplementate în Lua
        req = item_requirements_resolved(old, custom)
        if req is not None and (kv.dumps(req) != kv.dumps(old.get_kv("ItemRequirements")) or "ItemRequirements" in blk):
            blk["ItemRequirements"] = req
        # itemele din 6.88 trebuie să fie cumpărabile (unele au fost scoase din shop între timp)
        if old.get_str("ItemCost") and old.get_str("ItemPurchasable", "1") != "0" and cur.get_str("ItemPurchasable", "1") == "0":
            blk["ItemPurchasable"] = "1"
        if len(blk):
            override[name] = blk
    for name, cur in IN.blocks():
        if name == "Version" or name in old_names:
            continue
        if cur.get_str("ItemPurchasable", "1") == "0":
            continue
        if not cur.get_str("ItemCost") or cur.get_str("ItemCost") == "0":
            continue
        blk = kv.KV([("ItemPurchasable", "0"), ("ShouldBeSuggested", "0")])
        override[name] = blk
        report["iteme_noi_dezactivate"].append(name)
    return override, recreate


def lua_scripts() -> dict[str, str]:
    """{nume_custom: cale ScriptFile} pentru fiecare fișier Lua dota688_* / item_dota688_* din vscripts."""
    out: dict[str, str] = {}
    base = os.path.join(ADDON, "scripts", "vscripts")
    for p in glob.glob(os.path.join(base, "abilities", "**", "*.lua"), recursive=True) + \
             glob.glob(os.path.join(base, "items", "**", "*.lua"), recursive=True):
        n = os.path.splitext(os.path.basename(p))[0]
        if n.startswith(CUSTOM_ABILITY_PREFIX) or n.startswith(CUSTOM_ITEM_PREFIX):
            out[n] = os.path.relpath(p, base).replace(os.sep, "/")[:-4]
    return out


def gen_custom_defs(A0, I0, scripts: dict[str, str], custom: set[str]) -> tuple[kv.KV, kv.KV]:
    """Blocurile KV de bază (din 6.88) pentru reimplementările Lua: BaseClass + ScriptFile + textura originală."""
    abilities = kv.KV()
    items = kv.KV()
    for cname, script in sorted(scripts.items()):
        if cname.startswith(CUSTOM_ITEM_PREFIX):
            orig = "item_" + cname[len(CUSTOM_ITEM_PREFIX):]
            src = I0.get_kv(orig)
            if src is None:
                print(f"[gen] avertisment: {cname} nu are corespondent în items.txt 6.88 ({orig})")
                continue
            blk = src.copy()
            if "ID" in blk:
                del blk["ID"]
            blk["BaseClass"] = "item_lua"
            blk["ScriptFile"] = script
            blk["AbilityTextureName"] = orig
            req = item_requirements_resolved(src, custom)
            if req is not None:
                blk["ItemRequirements"] = req
            for key in ("UpgradesItems",):
                v = blk.get_str(key)
                if v:
                    blk[key] = ";".join(resolve(x.strip(), custom) for x in v.split(";") if x.strip())
            v = blk.get_str("UpgradeRecipe")
            if v:
                blk["UpgradeRecipe"] = resolve_item(v, custom)
            items[cname] = blk
        else:
            orig = cname[len(CUSTOM_ABILITY_PREFIX):]
            src = A0.get_kv(orig)
            if src is None:
                # abilitate complet nouă (nu are KV în 6.88) – se definește manual în npc_abilities_custom.txt
                continue
            blk = src.copy()
            if "ID" in blk:
                del blk["ID"]
            blk["BaseClass"] = "ability_lua"
            blk["ScriptFile"] = script
            blk["AbilityTextureName"] = orig
            abilities[cname] = blk
    return abilities, items


def gen_shops(custom: set[str]) -> None:
    """scripts/shops.txt: layout-ul shop-ului din 6.88, cu itemele reimplementate in Lua in locul celor built-in."""
    src = os.path.join(REF_OLD, "shops.txt")
    if not os.path.exists(src):
        return
    doc = kv.load(src)
    shops = doc.get_kv("dota_shops")
    out = kv.KV()
    for cat, items in shops.blocks():
        blk = kv.KV()
        for k, v in items.scalars():
            blk.items.append((k, resolve_item(v, custom)))
        out[cat] = blk
    kv.dump_file(kv.KV([("dota_shops", out)]), os.path.join(ADDON, "scripts", "shops.txt"),
                 HEADER + "\nLayout-ul shop-ului din 6.88 (reference/6.88f/shops.txt).")


def gen_localization(scripts: dict[str, str], hero_abilities: set[str], item_names: set[str]) -> None:
    """Scrie resource/addon_english.txt: tokenii manuali (addon_english.base.txt) + tooltip-urile 6.88."""
    src = kv.load(os.path.join(REF_OLD, "dota_english.txt"))
    tokens = src["lang"]["Tokens"]
    by_lower: dict[str, list[tuple[str, str]]] = {}
    for k, v in tokens.scalars():
        kl = k.lower()
        for pref in ("dota_tooltip_ability_", "dota_tooltip_modifier_"):
            if kl.startswith(pref):
                rest = kl[len(pref):]
                # numele abilității = cel mai lung prefix urmat de _Description / _Note0 / nimic
                by_lower.setdefault(rest, []).append((k, v))
    out = kv.KV()
    base_path = os.path.join(ADDON, "resource", "addon_english.base.txt")
    if os.path.exists(base_path):
        for k, v in kv.load(base_path)["lang"]["Tokens"].scalars():
            out[k] = v

    def copy_tokens(orig: str, target: str) -> None:
        ol = orig.lower()
        for rest, pairs in by_lower.items():
            if rest == ol or rest.startswith(ol + "_"):
                for k, v in pairs:
                    nk = k[: len(k) - len(rest)] + target + k[len(k) - len(rest) + len(orig):]
                    if nk not in out:
                        out[nk] = v

    for cname in sorted(scripts):
        if cname.startswith(CUSTOM_ITEM_PREFIX):
            copy_tokens("item_" + cname[len(CUSTOM_ITEM_PREFIX):], cname)
        else:
            copy_tokens(cname[len(CUSTOM_ABILITY_PREFIX):], cname)
    # rețetele custom
    for cname in sorted(scripts):
        if cname.startswith(CUSTOM_ITEM_PREFIX):
            r = "item_recipe_" + cname[len("item_"):]
            copy_tokens("item_recipe_" + cname[len(CUSTOM_ITEM_PREFIX):], r)
    # tooltip-urile 6.88 pentru abilitățile și itemele built-in pe care le suprascriem
    for n in sorted(hero_abilities | item_names):
        copy_tokens(n, n)
    kv.dump_file(kv.KV([("lang", kv.KV([("Language", "English"), ("Tokens", out)]))]),
                 os.path.join(ADDON, "resource", "addon_english.txt"),
                 "GENERAT de tools/gen_overrides.py din reference/6.88f/dota_english.txt + addon_english.base.txt. NU EDITA MANUAL.")


# Unități din 6.88 care nu mai există, dar de care au nevoie reimplementările Lua (copiate integral din 6.88)
EXTRA_UNITS = [
    "npc_dota_beastmaster_boar_1", "npc_dota_beastmaster_boar_2", "npc_dota_beastmaster_boar_3", "npc_dota_beastmaster_boar_4",
    "npc_dota_beastmaster_hawk_1", "npc_dota_beastmaster_hawk_2", "npc_dota_beastmaster_hawk_3", "npc_dota_beastmaster_hawk_4",
]


def gen_units(U0, UN, report: dict) -> kv.KV:
    out = kv.KV()
    base0 = U0.get_kv("npc_dota_units_base")
    for name in EXTRA_UNITS:
        old = U0.get_kv(name)
        if old is not None and UN.get_kv(name) is None:
            out[name] = old.copy()
            report["unitati"][name] = ["(copiat integral din 6.88)"]
    for name, old in U0.blocks():
        if not name.startswith(UNIT_PREFIXES):
            continue
        cur = UN.get_kv(name)
        if cur is None:
            report["unitati_inexistente"].append(name)
            continue
        blk = cur.copy()
        changed = []
        for key in UNIT_STAT_KEYS:
            ov = old.get(key)
            if ov is None:
                continue
            cv = blk.get(key)
            if isinstance(ov, kv.KV):
                if cv is None or kv.dumps(ov) != kv.dumps(cv):
                    blk[key] = ov.copy()
                    changed.append(key)
            else:
                if cv is None or not isinstance(cv, str) or not same_value(ov, cv):
                    blk[key] = ov
                    changed.append(key)
        if changed:
            out[name] = blk
            report["unitati"][name] = sorted(changed)
    return out


# ---------------------------------------------------------------------------
# raport
# ---------------------------------------------------------------------------

def write_status(report: dict, hero_list: list[str]) -> None:
    os.makedirs(DOCS, exist_ok=True)
    os.makedirs(BUILD, exist_ok=True)
    with open(os.path.join(BUILD, "report.json"), "w", encoding="utf-8") as f:
        json.dump(report, f, indent=1, ensure_ascii=False, sort_keys=True)

    L: list[str] = []
    L.append("# STATUS – maparea 6.88f peste motorul curent\n")
    L.append("_Generat automat de `tools/gen_overrides.py`. Nu edita manual._\n")
    heroes = report["eroi"]
    n_ok = sum(1 for h in heroes.values() if not h["abilitati_lipsa"])
    L.append("## Eroi\n")
    L.append(f"* Eroi din 6.88f activați: **{len(hero_list)}**")
    L.append(f"* Eroi apăruți după 6.88 (dezactivați): **{len(report['eroi_noi_dezactivati'])}** – " + ", ".join(n.replace("npc_dota_hero_", "") for n in report["eroi_noi_dezactivati"]))
    L.append(f"* Eroi cu toate abilitățile mapate (built‑in sau Lua): **{n_ok}/{len(hero_list)}**")
    L.append("")
    L.append("| Erou | OK (built‑in) | Lua (custom) | Lipsă → fallback la abilitatea curentă |")
    L.append("|---|---|---|---|")
    for name in hero_list:
        h = heroes[name]
        fb = ", ".join(f"`{a}` → `{h['fallback'].get(a, '—')}`" for a in h["abilitati_lipsa"]) or "—"
        L.append(f"| {name.replace('npc_dota_hero_', '')} | {len(h['abilitati_ok'])} | {len(h['abilitati_custom'])} | {fb} |")
    L.append("")
    lua_ab = sorted(n for n, d in report["abilitati"].items() if d.get("lua"))
    lua_it = sorted(n for n, d in report["iteme"].items() if d.get("lua"))
    L.append("## Reimplementate în Lua (6.88 fidel)\n")
    L.append(f"* Abilități de erou: **{len(lua_ab)}** – " + ", ".join(f"`{n}`" for n in lua_ab))
    L.append(f"* Iteme: **{len(lua_it)}** – " + ", ".join(f"`{n}`" for n in lua_it))
    L.append("")
    L.append("## Abilități de erou care nu mai există în joc (trebuie rescrise în Lua)\n")
    missing_by_hero = [(n.replace("npc_dota_hero_", ""), a) for n, h in heroes.items() for a in h["abilitati_lipsa"]]
    L.append(f"Total: **{len(missing_by_hero)}**\n")
    for hero, ab in sorted(missing_by_hero):
        L.append(f"* `{ab}` ({hero})")
    L.append("")
    L.append("## Abilități existente, dar cu valori speciale dispărute (comportament probabil schimbat)\n")
    L.append("Aceste abilități există încă, însă unele valori din 6.88 nu mai au corespondent; ")
    L.append("de verificat în joc dacă mecanica s‑a schimbat și, dacă da, de rescris în Lua.\n")
    rows = [(n, d) for n, d in report["abilitati"].items() if d["speciale_lipsa"] and not d.get("lua")]
    L.append(f"Total: **{len(rows)}**\n")
    for n, d in sorted(rows):
        L.append(f"* `{n}`: " + ", ".join(d["speciale_lipsa"]))
    L.append("")
    L.append("## Abilități cu comportament (AbilityBehavior) diferit\n")
    rows = [(n, d["comportament"]) for n, d in report["abilitati"].items() if d["comportament"]]
    L.append(f"Total: **{len(rows)}** (doar informativ; nu suprascriem comportamentul automat)\n")
    for n, d in sorted(rows)[:400]:
        L.append(f"* `{n}`: 6.88 avea {d['6.88'] or '—'}; acum are în plus {d['acum'] or '—'}")
    L.append("")
    L.append("## Iteme\n")
    L.append(f"* Iteme din 6.88 care nu mai există (de reimplementat în Lua, generate în `npc_items_generated.txt` cu `ItemPurchasable 0`): **{len(report['iteme_disparute'])}**")
    for n in report["iteme_disparute"]:
        L.append(f"  * `{n}`")
    L.append(f"* Iteme noi (apărute după 6.88) scoase din shop: **{len(report['iteme_noi_dezactivate'])}**")
    L.append("  * " + ", ".join(f"`{n}`" for n in report["iteme_noi_dezactivate"]))
    rows = [(n, d) for n, d in report["iteme"].items() if d["speciale_lipsa"]]
    L.append(f"* Iteme existente cu valori speciale dispărute: **{len(rows)}**")
    for n, d in sorted(rows):
        L.append(f"  * `{n}`: " + ", ".join(d["speciale_lipsa"]))
    L.append("")
    L.append("## Unități (turnuri, creepi, neutrali, Roshan, curieri)\n")
    L.append(f"* Unități cu statistici readuse la 6.88: **{len(report['unitati'])}**")
    L.append(f"* Unități din 6.88 care nu mai există în joc: **{len(report['unitati_inexistente'])}** – " + ", ".join(f"`{n}`" for n in report["unitati_inexistente"]))
    L.append("")
    with open(os.path.join(DOCS, "STATUS.md"), "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")


# ---------------------------------------------------------------------------

def main() -> None:
    H0, A0, I0, U0 = load_old()
    HN, AN, IN, UN = load_now()
    scripts = lua_scripts()
    custom = load_custom_names() | set(scripts)
    report = {
        "eroi": {}, "eroi_noi_dezactivati": [], "erou_disparut": [],
        "abilitati": {}, "abilitati_inexistente": [],
        "iteme": {}, "iteme_disparute": [], "iteme_noi_dezactivate": [],
        "unitati": {}, "unitati_inexistente": [],
    }

    heroes, hero_list = gen_heroes(H0, HN, A0, AN, custom, report)
    abilities = gen_abilities(A0, AN, custom, report)
    item_over, item_recreate = gen_items(I0, IN, custom, report)
    units = gen_units(U0, UN, report)

    # abilități de erou lipsă (din report) -> și ele în lista "inexistente"
    for h in report["eroi"].values():
        for a in h["abilitati_lipsa"]:
            if a not in report["abilitati_inexistente"]:
                report["abilitati_inexistente"].append(a)
    report["abilitati_inexistente"].sort()

    os.makedirs(NPC, exist_ok=True)
    kv.dump_file(kv.KV([("DOTAHeroes", heroes)]), os.path.join(NPC, "npc_heroes_custom.txt"), HEADER)

    # override-urile de abilități și iteme merg în același fișier (Valve le încarcă din npc_abilities_override.txt)
    merged = kv.KV([("Version", "1")])
    for k, v in abilities.items:
        merged[k] = v
    for k, v in item_over.items:
        merged[k] = v
    kv.dump_file(kv.KV([("DOTAAbilities", merged)]), os.path.join(NPC, "npc_abilities_override.txt"), HEADER)

    custom_abilities, custom_items = gen_custom_defs(A0, I0, scripts, custom)
    for k, v in item_recreate.items:
        custom_items[k] = v
    kv.dump_file(kv.KV([("DOTAAbilities", custom_items)]), os.path.join(NPC, "npc_items_generated.txt"),
                 HEADER + "\nBlocurile de baza (KV 6.88) ale itemelor reimplementate in Lua + retetele lor. Inclus din npc_items_custom.txt prin #base.")
    kv.dump_file(kv.KV([("DOTAAbilities", custom_abilities)]), os.path.join(NPC, "npc_abilities_generated.txt"),
                 HEADER + "\nBlocurile de baza (KV 6.88) ale abilitatilor reimplementate in Lua. Inclus din npc_abilities_custom.txt prin #base.")
    hero_abils = {a for h in report["eroi"].values() for a in h["abilitati_ok"]}
    gen_shops(custom)
    gen_localization(scripts, hero_abils, {n for n, _ in I0.blocks() if IN.get_kv(n) is not None})
    kv.dump_file(kv.KV([("DOTAUnits", units)]), os.path.join(NPC, "npc_units_custom.txt"), HEADER)

    wl = kv.KV([(n, "1") for n in hero_list])
    kv.dump_file(kv.KV([("whitelist", wl)]), os.path.join(NPC, "herolist.txt"), HEADER)

    write_status(report, hero_list)
    print(f"eroi: {len(hero_list)} activi, {len(report['eroi_noi_dezactivati'])} dezactivați")
    print(f"abilități override: {len(abilities)}; inexistente: {len(report['abilitati_inexistente'])}")
    print(f"iteme override: {len(item_over)}; disparute: {len(report['iteme_disparute'])}; noi dezactivate: {len(report['iteme_noi_dezactivate'])}")
    print(f"reimplementari Lua: {len(scripts)} ({sum(1 for n in scripts if n.startswith(CUSTOM_ITEM_PREFIX))} iteme)")
    print(f"unități: {len(units)}; inexistente: {len(report['unitati_inexistente'])}")


if __name__ == "__main__":
    main()
