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
            if aname in custom:
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
        if name in custom:
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


def gen_items(I0, IN, custom: set[str], report: dict) -> tuple[kv.KV, kv.KV]:
    override = kv.KV()
    recreate = kv.KV()
    old_names = {n for n, _ in I0.blocks()}
    for name, old in I0.blocks():
        if name == "Version" or name in custom:
            continue
        cur = IN.get_kv(name)
        if cur is None:
            if re.search(r"halloween|winter|mystery|greevil|present|banana|candy|diretide|frostivus", name):
                continue  # iteme de eveniment, irelevante pentru joc
            # item dispărut: trebuie reimplementat în Lua
            blk = old.copy()
            if "ID" in blk:
                del blk["ID"]
            if not name.startswith("item_recipe_"):
                blk["BaseClass"] = "item_lua"
                blk["ScriptFile"] = f"items/{name}"
            blk["ItemPurchasable"] = "0"   # devine 1 când scriptul Lua există (vezi docs/STATUS.md)
            blk["_TODO"] = "reimplementare Lua necesara"
            recreate[name] = blk
            report["iteme_disparute"].append(name)
            continue
        blk = build_ability_override(name, old, cur, ITEM_TOP_KEYS, report["iteme"])
        if blk is None:
            blk = kv.KV()
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


def gen_units(U0, UN, report: dict) -> kv.KV:
    out = kv.KV()
    base0 = U0.get_kv("npc_dota_units_base")
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
    L.append("## Abilități de erou care nu mai există în joc (trebuie rescrise în Lua)\n")
    missing_by_hero = [(n.replace("npc_dota_hero_", ""), a) for n, h in heroes.items() for a in h["abilitati_lipsa"]]
    L.append(f"Total: **{len(missing_by_hero)}**\n")
    for hero, ab in sorted(missing_by_hero):
        L.append(f"* `{ab}` ({hero})")
    L.append("")
    L.append("## Abilități existente, dar cu valori speciale dispărute (comportament probabil schimbat)\n")
    L.append("Aceste abilități există încă, însă unele valori din 6.88 nu mai au corespondent; ")
    L.append("de verificat în joc dacă mecanica s‑a schimbat și, dacă da, de rescris în Lua.\n")
    rows = [(n, d) for n, d in report["abilitati"].items() if d["speciale_lipsa"]]
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
    custom = load_custom_names()
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

    kv.dump_file(kv.KV([("DOTAAbilities", item_recreate)]), os.path.join(NPC, "npc_items_generated.txt"),
                 HEADER + "\nIteme din 6.88 care nu mai exista in joc. Inclus din npc_items_custom.txt prin #base.")
    kv.dump_file(kv.KV([("DOTAUnits", units)]), os.path.join(NPC, "npc_units_custom.txt"), HEADER)

    wl = kv.KV([(n, "1") for n in hero_list])
    kv.dump_file(kv.KV([("whitelist", wl)]), os.path.join(NPC, "herolist.txt"), HEADER)

    write_status(report, hero_list)
    print(f"eroi: {len(hero_list)} activi, {len(report['eroi_noi_dezactivati'])} dezactivați")
    print(f"abilități override: {len(abilities)}; inexistente: {len(report['abilitati_inexistente'])}")
    print(f"iteme override: {len(item_over)}; de reimplementat: {len(report['iteme_disparute'])}; noi dezactivate: {len(report['iteme_noi_dezactivate'])}")
    print(f"unități: {len(units)}; inexistente: {len(report['unitati_inexistente'])}")


if __name__ == "__main__":
    main()
