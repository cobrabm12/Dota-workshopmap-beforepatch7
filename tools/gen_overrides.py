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

HEADER = "GENERAT AUTOMAT de tools/gen_overrides.py - NU EDITA MANUAL.\nSursa: reference/6.88f (Valve, 6.88f) vs reference/current."

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
    "npc_dota_dark_troll_warlord_skeleton_warrior", "dota_fountain",
    # unitati invocate care exista si azi cu acelasi nume (statisticile si abilitatile lor 6.88)
    "npc_dota_necronomicon_", "npc_dota_lycan_wolf", "npc_dota_broodmother_spider", "npc_dota_lesser_eidolon",
    "npc_dota_eidolon", "npc_dota_greater_eidolon", "npc_dota_dire_eidolon", "npc_dota_furion_treant",
    "npc_dota_shadow_shaman_ward", "npc_dota_invoker_forged_spirit", "npc_dota_witch_doctor_death_ward",
    "npc_dota_brewmaster_", "npc_dota_unit_tombstone", "npc_dota_unit_undying_zombie", "npc_dota_visage_familiar",
    "npc_dota_gyrocopter_homing_missile",
)
UNIT_STAT_KEYS = [
    "Level", "StatusHealth", "StatusHealthRegen", "StatusMana", "StatusManaRegen",
    "ArmorPhysical", "MagicalResistance",
    "AttackDamageMin", "AttackDamageMax", "AttackRate", "AttackRange", "AttackAcquisitionRange",
    "AttackAnimationPoint", "ProjectileSpeed", "AttackSpeedActivityModifiers",
    "BountyXP", "BountyGoldMin", "BountyGoldMax",
    "MovementSpeed", "MovementTurnRate",
    "VisionDaytimeRange", "VisionNighttimeRange",
    "BaseAttackSpeed", "CanBeDominated",
]
# 6.88 nu avea BaseAttackSpeed (viteza de atac de baza era 100 pentru toate unitatile); 7.31 a dat neutralilor
# BaseAttackSpeed 110-200 (si AttackRate 2) -> cu AttackRate-ul 6.88 atacau de 1.25-2x mai repede (turnurile 1.1x)
UNIT_DEFAULTS_688 = {"BaseAttackSpeed": "100"}
# Unitati care in 6.88 aveau 0 daune in KV si primeau daunele de la abilitate; motorul curent ia daunele din unitate
# (verificat in joc: Serpent Wards faceau 0 daune). (unitate, abilitate 6.88, index nivel, cheie min, cheie max)
UNIT_DAMAGE_FROM_ABILITY_688 = [
    ("npc_dota_shadow_shaman_ward_1", "shadow_shaman_mass_serpent_ward", 0, "damage_min", "damage_max"),
    ("npc_dota_shadow_shaman_ward_2", "shadow_shaman_mass_serpent_ward", 1, "damage_min", "damage_max"),
    ("npc_dota_shadow_shaman_ward_3", "shadow_shaman_mass_serpent_ward", 2, "damage_min", "damage_max"),
]

# Sloturi de abilitate pe care le golim (talente 10‑17, inate, etc.)
MAX_ABILITY_SLOT = 24

# Abilități din 6.88 care nu mai există, dar care erau doar placeholder-e sau au echivalent direct
RENAME = {
    "wisp_empty1": "generic_hidden",
    "wisp_empty2": "generic_hidden",
    "phoenix_sun_ray_toggle_move_empty": "generic_hidden",
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

# Chei 6.88 pe care codul C++ curent le citeste sub alt nume (valoarea 6.88 scrisa sub numele vechi era ignorata):
# AbilityDamage/AbilityDuration de top au devenit valori numite, iar unitatile invocate isi iau statisticile din valori
# care in 6.88 erau doar "_tooltip". Gasite de auditul din 2026-10-12 (docs/TEST_LOG.md, sectiunea 6).
KEY_RENAME_688 = {
    "lina_dragon_slave": {"AbilityDamage": ["dragon_slave_damage"]},
    "lina_light_strike_array": {"AbilityDamage": ["light_strike_array_damage"]},
    "kunkka_torrent": {"AbilityDamage": ["torrent_damage"]},
    "lion_impale": {"AbilityDamage": ["damage"]},
    "beastmaster_wild_axes": {"AbilityDamage": ["axe_damage"]},
    "dragon_knight_breathe_fire": {"AbilityDamage": ["damage"]},
    "dragon_knight_dragon_tail": {"AbilityDamage": ["damage"]},
    "earthshaker_echo_slam": {"AbilityDamage": ["echo_slam_initial_damage"]},
    "earthshaker_aftershock": {"AbilityDamage": ["aftershock_damage"]},
    "juggernaut_blade_fury": {"AbilityDamage": ["blade_fury_damage"]},
    "crystal_maiden_crystal_nova": {"AbilityDamage": ["nova_damage"]},
    "axe_battle_hunger": {"AbilityDamage": ["damage_per_second"]},
    "death_prophet_carrion_swarm": {"AbilityDamage": ["damage"]},
    "leshrac_diabolic_edict": {"AbilityDamage": ["damage"]},
    "gyrocopter_rocket_barrage": {"AbilityDamage": ["rocket_damage"]},
    "disruptor_thunder_strike": {"AbilityDamage": ["strike_damage"]},
    "dazzle_shallow_grave": {"AbilityDuration": ["duration"]},
    "enchantress_enchant": {"AbilityDuration": ["slow_duration"]},
    "enchantress_natures_attendants": {"AbilityDuration": ["heal_duration"]},
    "huskar_burning_spear": {"AbilityDuration": ["duration"]},
    "jakiro_ice_path": {"AbilityDuration": ["stun_duration", "path_duration"]},
    "ancient_apparition_ice_vortex": {"AbilityDuration": ["vortex_duration"]},
    "nevermore_shadowraze1": {"AbilityDamage": ["shadowraze_damage"]},
    "nevermore_shadowraze2": {"AbilityDamage": ["shadowraze_damage"]},
    "nevermore_shadowraze3": {"AbilityDamage": ["shadowraze_damage"]},
    "puck_waning_rift": {"AbilityDamage": ["damage"]},
    "windrunner_powershot": {"AbilityDamage": ["powershot_damage"]},
    "shadow_demon_demonic_purge": {"AbilityDamage": ["purge_damage"]},
    "shadow_demon_shadow_poison": {"AbilityDamage": ["hit_damage"]},
    "zuus_arc_lightning": {"AbilityDamage": ["arc_damage"]},
    "zuus_lightning_bolt": {"AbilityDamage": ["damage"]},
    "meepo_poof": {"AbilityDamage": ["poof_damage"]},
    "night_stalker_void": {"AbilityDamage": ["damage"]},
    "phantom_lancer_spirit_lance": {"AbilityDamage": ["lance_damage"]},
    "storm_spirit_overload": {"AbilityDamage": ["overload_damage"]},
    "vengefulspirit_magic_missile": {"AbilityDamage": ["magic_missile_damage"]},
    "vengefulspirit_wave_of_terror": {"AbilityDamage": ["damage"]},
    "slardar_slithereen_crush": {"AbilityDamage": ["crush_damage"]},
    "tidehunter_gush": {"AbilityDamage": ["gush_damage"]},
    "sniper_shrapnel": {"AbilityDamage": ["shrapnel_damage"]},
    "sniper_headshot": {"AbilityDamage": ["damage"]},
    "queenofpain_scream_of_pain": {"AbilityDamage": ["damage"]},
    "queenofpain_shadow_strike": {"AbilityDuration": ["duration"]},
    "skeleton_king_hellfire_blast": {"AbilityDamage": ["damage"]},
    "pugna_nether_blast": {"AbilityDamage": ["blast_damage"]},
    "ogre_magi_fireblast": {"AbilityDamage": ["fireblast_damage"]},
    "nyx_assassin_impale": {"AbilityDamage": ["impale_damage"]},
    "winter_wyvern_splinter_blast": {"AbilityDamage": ["damage"]},
    "tinker_march_of_the_machines": {"AbilityDamage": ["damage"]},
    "templar_assassin_meld": {"AbilityDuration": ["debuff_duration"]},
    "venomancer_plague_ward": {"ward_hp_tooltip": ["ward_max_health"], "ward_damage_tooltip": ["ward_base_damage"]},
    "warlock_rain_of_chaos": {"golem_hp_tooltip": ["golem_hp"], "golem_dmg_tooltip": ["golem_dmg"],
                              "golem_armor_tooltip": ["golem_armor", "tooltip_golem_armor"],
                              "golem_regen_tooltip": ["golem_health_regen"]},
    "visage_summon_familiars": {"familiar_speed": ["familiar_base_movespeed"]},
}
# valori 6.88 scrise ca fractie, citite acum ca procent
FRACTION_TO_PERCENT = {
    ("windrunner_powershot", "damage_reduction"), ("pugna_nether_blast", "structure_damage_mod"),
    ("wisp_tether", "tether_heal_amp"), ("ogre_magi_unrefined_fireblast", "scepter_mana"),
}
# steaguri de comportament aparute dupa 6.88 care fac o abilitate de baza "innate"/ascunsa/neinvatabila
MODERN_HIDE_FLAGS = {"DOTA_ABILITY_BEHAVIOR_HIDDEN", "DOTA_ABILITY_BEHAVIOR_NOT_LEARNABLE",
                     "DOTA_ABILITY_BEHAVIOR_INNATE_UI", "DOTA_ABILITY_BEHAVIOR_SKIP_FOR_KEYBINDS"}
# campuri de tintire/damage copiate din 6.88 cand difera (imunitate la vraji, tipul de damage)
TARGETING_KEYS = ("SpellImmunityType", "AbilityUnitDamageType", "AbilityUnitTargetTeam", "AbilityUnitTargetType",
                  "AbilityUnitTargetFlags")


def _nums(v: str) -> list[float] | None:
    try:
        return [float(x) for x in norm_num_list(v)]
    except ValueError:
        return None


def _fmt(x: float) -> str:
    return str(int(x)) if x == int(x) else ("%g" % x)


def sign_fixed(ov: str, cv: str) -> str:
    """6.88 scria incetinirile ca valori negative; codul curent le vrea pozitive si le neaga singur (altfel o
    incetinire devine accelerare, ex. Viper Strike, Battle Hunger)."""
    o, c = _nums(ov), _nums(cv)
    if not o or not c:
        return ov
    if all(x <= 0 for x in o) and any(x < 0 for x in o) and all(x >= 0 for x in c) and any(x > 0 for x in c):
        return " ".join(_fmt(abs(x)) for x in o)
    return ov


def value_688(name: str, key: str, ov: str, cv: str | None) -> str:
    if (name, key) in FRACTION_TO_PERCENT:
        o = _nums(ov)
        if o:
            return " ".join(_fmt(round(x * 100, 4)) for x in o)
    if cv is not None:
        return sign_fixed(ov, cv)
    return ov


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

    rename = KEY_RENAME_688.get(name, {})
    for key in top_keys:
        ov = old.get_str(key)
        if ov is None:
            continue
        for nk in rename.get(key, []):
            if nk in cur_vals and not same_value(ov, cur_vals[nk]):
                values[nk] = ov
                changed.append(nk)
        cv = cur_value(cur, key)
        if cv is not None and same_value(ov, cv):
            continue
        if cv is None and key in ("AbilityCastRange", "AbilityCastPoint", "AbilityCooldown", "AbilityManaCost") and set(norm_num_list(ov)) <= {"0"}:
            continue  # 0 implicit
        if key == "AbilityCastRange" and set(norm_num_list(ov)) <= {"0"}:
            # 6.88 lasa raza 0 cand o definea in alta cheie (ex. Blink Dagger: blink_range 1200); motorul curent
            # foloseste AbilityCastRange, iar 0 facea Blink-ul sa sara pe loc (raportat de jucatori din Arcade)
            continue
        loc = where_defined(cur, key)
        if loc == "values":
            values[key] = ov
        else:
            out[key] = ov
        changed.append(key)

    # incarcaturi (charges) adaugate dupa 6.88: revenim la cooldown simplu
    # (nu si pentru abilitatile care aveau incarcaturi in 6.88 prin chei speciale, ex. Shrapnel max_charges)
    had_charges = any("charge" in k for k in old_vals)
    for key in ("AbilityCharges", "AbilityChargeRestoreTime"):
        if not had_charges and old.get_str(key) is None and cur_value(cur, key) not in (None, "0"):
            if where_defined(cur, key) == "values":
                values[key] = "0"
            else:
                out[key] = "0"
            changed.append(key)

    for key, ov in old_vals.items():
        for nk in rename.get(key, []):
            if nk in cur_vals and not same_value(ov, cur_vals[nk]):
                values[nk] = ov
                changed.append(nk)
        if key in cur_vals:
            ov = value_688(name, key, ov, cur_vals[key])
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
            # cheia nu mai exista in motor: o pastram in AbilityValues cu valoarea 6.88, ca extra-urile Lua
            # (dota688/extras_688.lua) sa o poata citi; motorul o ignora
            if cur_uses_values and not name.startswith("item_") and key.lower() not in SPECIAL_META:
                values[key] = ov

    # ItemRequirements (rețete): copiem blocul din 6.88 dacă diferă
    if "ItemRequirements" in top_keys or name.startswith("item_"):
        oreq = old.get_kv("ItemRequirements")
        creq = cur.get_kv("ItemRequirements")
        if oreq is not None:
            if creq is None or kv.dumps(oreq) != kv.dumps(creq):
                out["ItemRequirements"] = oreq.copy()
                changed.append("ItemRequirements")

    # costuri aparute dupa 6.88: mana (ex. BKB 50, Liquid Fire 20); cooldown doar la pasive
    passive_688 = "DOTA_ABILITY_BEHAVIOR_PASSIVE" in (old.get_str("AbilityBehavior") or "")
    for key in ("AbilityManaCost", "AbilityCooldown"):
        if key == "AbilityCooldown" and not passive_688:
            continue
        if old.get_str(key) is None and not any(k.lower() in ("mana_cost", "manacost", "cooldown") for k in old_vals):
            cv = cur_value(cur, key)
            if cv is not None and set(norm_num_list(cv)) - {"0", "0.0"}:
                if where_defined(cur, key) == "values":
                    values[key] = "0"
                else:
                    out[key] = "0"
                changed.append(key)

    for key in TARGETING_KEYS:
        ov, cv = old.get_str(key), cur.get_str(key)
        if ov is not None and cv is not None and ov.replace(" ", "") != cv.replace(" ", ""):
            out[key] = ov
            changed.append(key)
        elif key == "AbilityUnitTargetFlags" and ov is None and cv and "MAGIC_IMMUNE" in cv:
            out[key] = "DOTA_UNIT_TARGET_FLAG_NONE"
            changed.append(key)

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
        # 6.88 nu avea viteză de atac de bază per erou (toți 100); motorul curent are 85-125 (ex. Techies 90)
        o["BaseAttackSpeed"] = "100"

        # --- abilități -----------------------------------------------------
        old_slots = slot_abilities(h)
        if name in SLOT_OVERRIDES:
            old_slots = list(enumerate(SLOT_OVERRIDES[name], start=1))
        cur_slots = [(i, a) for i, a in slot_abilities(cur) if a and not a.startswith("special_bonus")]
        cur_real = [a for _, a in cur_slots if a not in ("generic_hidden", "") and not AN.get_kv(a) or (AN.get_kv(a) and AN.get_kv(a).get_str("Innate") != "1")]
        cur_real = [a for a in cur_real if a not in ("generic_hidden", "")]
        hero_rep = {"abilitati_ok": [], "abilitati_custom": [], "abilitati_lipsa": [], "fallback": {}}
        used_slots: list[str] = []
        own_attribute_bonus = False
        for _, aname in old_slots:
            if aname == "":
                continue
            if aname == "attribute_bonus":
                continue  # îl adăugăm la final
            if aname == "invoker_attribute_bonus":
                # 6.88: Invoker nu avea Attribute Bonus-ul obisnuit (21 puncte in orbi + Invoke), ci acesta: +6 la nivelul 25
                used_slots.append("dota688_invoker_attribute_bonus")
                own_attribute_bonus = True
                continue
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
        if not own_attribute_bonus:
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
        blk = abilities_flags_688(name, old, cur, blk if blk is not None else kv.KV())
        if old.get_str("AbilityType") == "DOTA_ABILITY_TYPE_ULTIMATE":
            ultimate_levels_688(old, blk)
        if blk is not None and len(blk):
            out[name] = blk
    return out


SCEPTER_688: set[str] = set()   # abilitati cu upgrade de Aghanim in 6.88 (din tooltip-urile 6.88), umplut in main()


def abilities_flags_688(name: str, old: kv.KV, cur: kv.KV, blk: kv.KV) -> kv.KV:
    """Tipul, nivelurile si vizibilitatea unei abilitati built-in ca in 6.88. Dupa 6.88 unele abilitati de baza au
    devenit innate/ascunse cu un singur nivel (Mana Shield, Static Field, Essence Shift, Mana Leak...), ultimate-uri
    au devenit de baza si invers (Wind Walk, Untouchable, Spawn Spiderlings), iar aproape toate au Shard/Scepter."""
    ob = {x.strip() for x in (old.get_str("AbilityBehavior") or "").split("|") if x.strip()}
    cb_raw = cur.get_str("AbilityBehavior") or ""
    cb = [x.strip() for x in cb_raw.split("|") if x.strip()]
    extra = [f for f in cb if f in MODERN_HIDE_FLAGS and f not in ob]
    became_innate = cur.get_str("Innate") == "1" and old.get_str("Innate") != "1"
    if extra:
        blk["AbilityBehavior"] = " | ".join(f for f in cb if f not in extra)
    if became_innate:
        blk["Innate"] = "0"
    old_type = (old.get_str("AbilityType") or "DOTA_ABILITY_TYPE_BASIC").replace("DOTA_ABILITY_TYPE", "ABILITY_TYPE")
    cur_type = (cur.get_str("AbilityType") or "ABILITY_TYPE_BASIC").replace("DOTA_ABILITY_TYPE", "ABILITY_TYPE")
    if old_type != cur_type and old_type != "ABILITY_TYPE_ATTRIBUTES":
        blk["AbilityType"] = old_type
    if extra or became_innate or old_type != cur_type:
        default_max = "3" if old_type == "ABILITY_TYPE_ULTIMATE" else "4"
        old_max = old.get_str("MaxLevel") or default_max
        if (cur.get_str("MaxLevel") or default_max) != old_max:
            blk["MaxLevel"] = old_max
    if cur.get_str("HasShardUpgrade") == "1":
        blk["HasShardUpgrade"] = "0"
    if cur.get_str("HasScepterUpgrade") == "1" and name not in SCEPTER_688:
        blk["HasScepterUpgrade"] = "0"
    return blk


def ultimate_levels_688(old: kv.KV, blk: kv.KV) -> None:
    """Ultimate-urile 6.88 se invatau la nivelurile 6/11/16 (implicit: RequiredLevel 6, pas 5); motorul curent
    are implicit pasul 6 (6/12/18). Punem explicit valorile 6.88 cand KV-ul 6.88 nu le specifica."""
    blk["RequiredLevel"] = old.get_str("RequiredLevel") or "6"
    blk["LevelsBetweenUpgrades"] = old.get_str("LevelsBetweenUpgrades") or "5"


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


# iteme built-in al caror comportament (tinta/flag-uri) s-a schimbat dupa 6.88: Gem a primit o activa, TP-ul e oprit
# de root (ROOT_DISABLES), Refresher se poate folosi in timpul canalizarii
ITEM_BEHAVIOR_688 = {"item_gem", "item_tpscroll", "item_refresher"}


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
                    # o rețetă built-in gratuită se combină singură (ex. Aghanim's Scepter din componente) înaintea
                    # celei Lua: o facem să dea tot itemul Lua, cu componentele 6.88
                    override[name]["ItemResult"] = resolve(old.get_str("ItemResult", ""), custom)
                    req = item_requirements_resolved(old, custom)
                    if req is not None:
                        override[name]["ItemRequirements"] = req
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
        # stocul: cheile adaugate dupa 6.88 raman active daca nu le suprascriem. In 6.88 lipsa lui ItemStockMax
        # insemna fara limita (tango, clarity, salve, mango, sentry; acum 10/5/5/4/8 cu refacere la 120/70 s), iar
        # lipsa lui ItemStockInitial insemna stoc plin la inceput (Smoke 3, Gem 1, curier 1). "0" = valoarea implicita.
        # marcaje aparute dupa 6.88: Ring of Health / Void Stone au devenit iteme de secret shop, Poor Man's Shield
        # item neutru (nevandabil), Vanguard/Radiance se pot dezasambla
        for key, modern, value in (("SecretShop", "1", "0"), ("SideShop", "1", "0"), ("ItemIsNeutralDrop", "1", "0"),
                                   ("ItemIsNeutralActiveDrop", "1", "0"), ("ItemIsNeutralPassiveDrop", "1", "0")):
            if old.get_str(key) is None and cur.get_str(key) == modern:
                blk[key] = value
        if old.get_str("ItemSellable") is None and cur.get_str("ItemSellable") == "0":
            blk["ItemSellable"] = "1"
        if old.get_str("ItemDisassembleRule") is None and cur.get_str("ItemDisassembleRule") == "DOTA_ITEM_DISASSEMBLE_ALWAYS":
            blk["ItemDisassembleRule"] = "DOTA_ITEM_DISASSEMBLE_NEVER"
        if name in ITEM_BEHAVIOR_688 and old.get_str("AbilityBehavior") and old.get_str("AbilityBehavior") != cur.get_str("AbilityBehavior"):
            blk["AbilityBehavior"] = old.get_str("AbilityBehavior")
        stock_max = old.get_str("ItemStockMax")
        if stock_max is None:
            if cur.get_str("ItemStockMax", "0") != "0":
                for key in ("ItemStockMax", "ItemStockInitial", "ItemStockTime"):
                    blk[key] = "0"
        elif old.get_str("ItemStockInitial") is None and cur.get_str("ItemStockInitial") != stock_max:
            blk["ItemStockInitial"] = stock_max
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


# Ajustări KV pentru reimplementările Lua (peste blocul copiat din 6.88)
CUSTOM_KV_PATCH = {
    # Aghanim's Scepter: Alchemist îl poate da unui aliat (Lua GetBehavior îl ține pasiv pentru ceilalți eroi)
    "item_dota688_ultimate_scepter": {
        "AbilityBehavior": "DOTA_ABILITY_BEHAVIOR_UNIT_TARGET",
        "AbilityCastPoint": "0.1",
        "ItemDeclarations": "DECLARE_PURCHASES_TO_TEAMMATES | DECLARE_PURCHASES_IN_SPEECH | DECLARE_PURCHASES_TO_SPECTATORS",
    },
    # abilitate oferită de scepter în 6.88, deblocată din Lua (dota688/aghanim.lua), nu de motor
    "dota688_treant_eyes_in_the_forest": {"IsGrantedByScepter": "0"},
    "dota688_morphling_hybrid": {"IsGrantedByScepter": "0"},
    "dota688_ogre_magi_unrefined_fireblast": {"IsGrantedByScepter": "0"},
    # in KV-ul 6.88 Battle Cry avea DOTA_ABILITY_TYPE_ULTIMATE scris gresit in AbilityBehavior
    "dota688_lone_druid_true_form_battle_cry": {"AbilityBehavior": "DOTA_ABILITY_BEHAVIOR_NO_TARGET | DOTA_ABILITY_BEHAVIOR_HIDDEN | DOTA_ABILITY_BEHAVIOR_NOT_LEARNABLE"},
    # Ice Blast 6.88 se țintește oriunde pe hartă (raza reală e dată de Lua)
    "dota688_ancient_apparition_ice_blast": {"AbilityCastRange": "0"},
}


# iconite 6.88 care nu mai exista in clientul curent -> cele mai apropiate actuale (verificat de check_addon.py)
ICON_REMAP = {
    "beastmaster_call_of_the_wild_boar": "beastmaster_call_of_the_wild",
    "lich_dark_ritual": "lich_dark_sorcery",
    "meepo_geostrike": "meepo_geostrike_scavenger",
    "morphling_adaptive_strike": "morphling_adaptive_strike_agi",
    "morphling_morph": "morphling_morph_agi",
    "shadow_demon_soul_catcher": "shadow_demon_disseminate",
    "skeleton_king_vampiric_aura": "leoric_lifesteal_aura",
    "item_diffusal_blade_2": "item_diffusal_blade",
}


# chei auxiliare dintr-un bloc AbilitySpecial (nu sunt valori); in AbilityValues devin sub-chei ale valorii
SPECIAL_META = {"levelkey", "calculatespelldamagetooltip", "requiresscepter", "linkedspecialbonus", "damagetypetooltip"}


def specials_to_values(blk: kv.KV) -> None:
    """Motorul curent citeste valorile doar din AbilityValues: GetSpecialValueFor() intoarce 0 pentru cheile
    din formatul vechi AbilitySpecial (verificat in joc). Convertim blocul 6.88 pe loc."""
    sp = blk.get_kv("AbilitySpecial")
    if sp is None:
        return
    values = blk.get_kv("AbilityValues") or kv.KV()
    for _, entry in sp.blocks():
        scalars = [(k, v) for k, v in entry.scalars() if k.lower() != "var_type"]
        main = [(k, v) for k, v in scalars if k.lower() not in SPECIAL_META]
        meta = [(k, v) for k, v in scalars if k.lower() in SPECIAL_META]
        for k, v in main:
            if meta:
                sub = kv.KV([("value", v)])
                for mk, mv in meta:
                    sub[mk] = mv
                values[k] = sub
            else:
                values[k] = v
    del blk["AbilitySpecial"]
    blk["AbilityValues"] = values


def modernize_block(blk: kv.KV) -> None:
    """Formatul KV 6.88 -> cel citit de motorul curent (blocurile copiate pentru reimplementarile Lua)."""
    specials_to_values(blk)
    # 6.88: DOTA_ABILITY_TYPE_ULTIMATE; motorul curent recunoaste doar ABILITY_TYPE_ULTIMATE, altfel ultimate-ul
    # devine abilitate de baza (4 niveluri, invatabila de la nivelul 1) - verificat in joc pe Remote Mines
    t = blk.get_str("AbilityType")
    if t and t.startswith("DOTA_ABILITY_TYPE_"):
        blk["AbilityType"] = t[len("DOTA_"):]
    if t == "DOTA_ABILITY_TYPE_ULTIMATE":
        ultimate_levels_688(blk, blk)


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
            blk["AbilityTextureName"] = ICON_REMAP.get(orig, orig)
            modernize_block(blk)
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
            for k, v in CUSTOM_KV_PATCH.get(cname, {}).items():
                blk[k] = v
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
            blk["AbilityTextureName"] = ICON_REMAP.get(orig, orig)
            if orig in SCEPTER_688:
                blk["HasScepterUpgrade"] = "1"   # HUD-ul arata textul de Aghanim doar cu acest flag
            modernize_block(blk)
            for k, v in CUSTOM_KV_PATCH.get(cname, {}).items():
                blk[k] = v
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
    for lang in ("english",):   # doar engleza in joc (decizia proiectului)
        if os.path.exists(os.path.join(REF_OLD, f"dota_{lang}.txt")):
            gen_localization_lang(lang, scripts, hero_abilities, item_names)


def gen_localization_lang(lang: str, scripts: dict[str, str], hero_abilities: set[str], item_names: set[str]) -> None:
    """Scrie resource/addon_<lang>.txt: tokenii manuali (addon_<lang>.base.txt) + tooltip-urile 6.88 în limba respectivă."""
    src = kv.load(os.path.join(REF_OLD, f"dota_{lang}.txt"))
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
    base_path = os.path.join(ADDON, "resource", f"addon_{lang}.base.txt")
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
    # runele si glyph-ul cu textul 6.88 (motorul curent: "Amplify Damage", Arcane 25/30 %, glyph 7 s)
    for k, v in tokens.scalars():
        if k.startswith(("DOTA_Chat_Rune_", "DOTA_Tooltip_rune_", "DOTA_Hotkeys_Tooltip_ActivateGlyph")) and k not in out:
            out[k] = v
    # textul 6.88 al upgrade-ului de Aghanim: HUD-ul curent citeste <abilitate>_scepter_description
    for k, v in list(out.scalars()):
        if k.lower().endswith("_aghanim_description"):
            nk = k[: -len("_aghanim_description")] + "_scepter_description"
            out[nk] = v
    kv.dump_file(kv.KV([("lang", kv.KV([("Language", lang.capitalize()), ("Tokens", out)]))]),
                 os.path.join(ADDON, "resource", f"addon_{lang}.txt"),
                 f"GENERAT de tools/gen_overrides.py din reference/6.88f/dota_{lang}.txt + addon_{lang}.base.txt. NU EDITA MANUAL.")


# Unități din 6.88 care nu mai există, dar de care au nevoie reimplementările Lua (copiate integral din 6.88)
EXTRA_UNITS = [
    "npc_dota_beastmaster_boar_1", "npc_dota_beastmaster_boar_2", "npc_dota_beastmaster_boar_3", "npc_dota_beastmaster_boar_4",
    "npc_dota_beastmaster_hawk_1", "npc_dota_beastmaster_hawk_2", "npc_dota_beastmaster_hawk_3", "npc_dota_beastmaster_hawk_4",
]


# Unitati 6.88 copiate integral chiar daca exista si azi (statisticile si nivelurile lor sunt in Lua):
# ursul lui Lone Druid pe 4 niveluri (azi exista doar bear1, care creste cu eroul)
FORCED_UNITS_688 = ["npc_dota_lone_druid_bear1", "npc_dota_lone_druid_bear2", "npc_dota_lone_druid_bear3", "npc_dota_lone_druid_bear4"]


# Unități 6.88 copiate sub alt nume (pentru reimplementările Lua), fără abilitățile originale (logica e în Lua)
RENAMED_UNITS = {
    "npc_dota688_techies_land_mine": "npc_dota_techies_land_mine",
    "npc_dota688_techies_stasis_trap": "npc_dota_techies_stasis_trap",
    "npc_dota688_techies_remote_mine": "npc_dota_techies_remote_mine",
    "npc_dota688_techies_minefield_sign": "npc_dota_techies_minefield_sign",
    "npc_dota688_treant_eyes": "npc_dota_treant_eyes",
    "npc_dota688_broodmother_web": "npc_dota_broodmother_web",
}

# Unitati moderne pe care motorul le spawneaza in locul celor 6.88 -> unitatea 6.88 a carei statistici/abilitati le iau.
# Flagbearer (7.34): un creep melee din fiecare val, cu aura care da aur in plus inamicilor din jur la moarte
# ("aurul de 2 ori" la last hit) si bounty 7.x.
MODERN_UNIT_ALIASES = {
    f"npc_dota_creep_{team}_flagbearer{sfx}": f"npc_dota_creep_{team}_melee{sfx}"
    for team in ("goodguys", "badguys") for sfx in ("", "_upgraded", "_upgraded_mega")
}


# abilitati moderne care emuleaza tabelul de tipuri de atac/armura scos din motor (6.88 il avea in C++): raman
UNIT_DAMAGE_TYPE_ABILITIES = {"creep_piercing", "creep_irresolute", "creep_siege"}
# abilitati 6.88 al caror C++ modern contrazice 6.88 si care sunt reimplementate in Lua:
#   roshan_inherent_buffs - in 6.88 pasiv fara valori; acum impune HP 6000 + 130/min la fiecare frame (testat) ->
#   cresterea 6.88 o face modifiers/modifier_dota688_roshan.lua
UNIT_ABILITIES_REPLACED = {"roshan_inherent_buffs"}
# 7.31 a facut toti neutralii "standard" (fara tip de atac) si le-a rescalat damage-ul; noi readucem damage-ul 6.88,
# deci si tipul de atac 6.88 trebuie emulat (Basic 75% si Pierce 50% damage in eroi), ca la creepii de lane
ATTACK_CLASS_ABILITY = {
    "DOTA_COMBAT_CLASS_ATTACK_BASIC": "creep_irresolute",
    "DOTA_COMBAT_CLASS_ATTACK_PIERCE": "creep_piercing",
    "DOTA_COMBAT_CLASS_ATTACK_SIEGE": "creep_siege",
}
ATTACK_CLASS_EMULATED = ("npc_dota_neutral_", "npc_dota_dark_troll_warlord_skeleton_warrior")


def unit_abilities_688(old: kv.KV, cur: kv.KV, AN, attack_class: str = "") -> tuple[list[str], list[str], list[str], list[str]]:
    """Abilitatile unei unitati ca in 6.88: cele din KV-ul 6.88 care mai exista in joc + emularile tipurilor de
    atac/armura. Intoarce (lista finala, scoase, lipsa, lista curenta)."""
    def slots(b):
        return [v for k, v in sorted(((k, v) for k, v in b.scalars() if re.fullmatch(r"Ability\d+", k)),
                                     key=lambda kv_: int(kv_[0][7:])) if v]
    old_ab, cur_ab = slots(old), slots(cur)
    keep = [a for a in old_ab if (AN.get_kv(a) is not None or a in cur_ab) and a not in UNIT_ABILITIES_REPLACED]
    missing = [a for a in old_ab if a not in keep]
    keep += [a for a in cur_ab if a in UNIT_DAMAGE_TYPE_ABILITIES and a not in keep]
    emul = ATTACK_CLASS_ABILITY.get(attack_class)
    if emul and emul not in keep and AN.get_kv(emul) is not None:
        keep.append(emul)
    removed = [a for a in cur_ab if a not in keep]
    return keep, removed, missing, cur_ab


def gen_units(U0, UN, report: dict, AN=None, A0=None) -> kv.KV:
    out = kv.KV()
    base0 = U0.get_kv("npc_dota_units_base")
    for new, old_name in RENAMED_UNITS.items():
        old = U0.get_kv(old_name)
        if old is None:
            continue
        blk = old.copy()
        for k in list(blk.keys()):
            if re.fullmatch(r"Ability\d+", k):
                del blk[k]
        blk["Ability1"] = ""
        blk["BaseClass"] = "npc_dota_creature"   # fara clasa C++ a minelor moderne; logica e in Lua
        blk["IsSummoned"] = "1"
        blk["ConsideredHero"] = "0"
        out[new] = blk
        report["unitati"][new] = [f"(copiat din 6.88: {old_name}, fara abilitati)"]
    for name in EXTRA_UNITS:
        old = U0.get_kv(name)
        if old is not None and UN.get_kv(name) is None:
            out[name] = old.copy()
            report["unitati"][name] = ["(copiat integral din 6.88)"]
    for name in FORCED_UNITS_688:
        old = U0.get_kv(name)
        if old is None:
            continue
        blk = old.copy()
        for k in list(blk.keys()):
            if re.fullmatch(r"Ability\d+", k):
                del blk[k]
        blk["Ability1"] = ""   # abilitatile le pune Lua pe nivel (6.88 avea bear_empty, care nu mai exista)
        out[name] = blk
        report["unitati"][name] = ["(copiat integral din 6.88, abilitati din Lua)"]
    aliases = [(new, U0.get_kv(old_name)) for new, old_name in MODERN_UNIT_ALIASES.items() if U0.get_kv(old_name) is not None]
    for name, old in list(U0.blocks()) + aliases:
        if not name.startswith(UNIT_PREFIXES):
            continue
        cur = UN.get_kv(name)
        if cur is None:
            report["unitati_inexistente"].append(name)
            continue
        blk = cur.copy()
        changed = []
        if name in MODERN_UNIT_ALIASES and old.get_str("Model") and old.get_str("Model") != cur.get_str("Model"):
            blk["Model"] = old.get_str("Model")   # creep melee obisnuit, fara steag
            changed.append("Model")
        for key in UNIT_STAT_KEYS:
            # valorile lipsa din bloc se mostenesc din npc_dota_units_base al lui 6.88 (ex. MovementTurnRate 0.5)
            ov = old.get(key)
            if ov is None and base0 is not None:
                ov = base0.get(key)
            if ov is None:
                ov = UNIT_DEFAULTS_688.get(key)
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
        if AN is not None:
            attack_class = ""
            if name.startswith(ATTACK_CLASS_EMULATED):
                attack_class = old.get_str("CombatClassAttack") or (base0.get_str("CombatClassAttack", "") if base0 else "")
            keep, removed, missing, cur_ab = unit_abilities_688(old, cur, AN, attack_class)
            if keep != cur_ab:
                for k in list(blk.keys()):
                    if re.fullmatch(r"Ability\d+", k):
                        del blk[k]
                for i, a in enumerate(keep, start=1):
                    blk[f"Ability{i}"] = a
                if not keep:
                    blk["Ability1"] = ""
                changed.append("abilitati 6.88" + (f" (scoase: {', '.join(removed)})" if removed else "")
                               + (f" (lipsa in joc: {', '.join(missing)})" if missing else ""))
        for uname, aname, idx, kmin, kmax in UNIT_DAMAGE_FROM_ABILITY_688:
            ab = A0.get_kv(aname) if (A0 is not None and uname == name) else None
            if ab is not None:
                vals = kv.values_of(ab)
                for ukey, akey in (("AttackDamageMin", kmin), ("AttackDamageMax", kmax)):
                    lv = norm_num_list(vals[akey])
                    blk[ukey] = lv[min(idx, len(lv) - 1)]
                changed.append(f"daune din {aname} (6.88)")
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
    def real_keys(keys):
        return [k for k in keys if "tooltip" not in k and not k.endswith("_scepter") and "scepter" not in k]
    manual_path = os.path.join(ROOT, "tools", "manual_overrides.json")
    manual = set()
    if os.path.exists(manual_path):
        with open(manual_path, encoding="utf-8") as f:
            manual = {k for k in json.load(f) if not k.startswith("_")}
    rows = [(n, d) for n, d in report["abilitati"].items() if real_keys(d["speciale_lipsa"]) and not d.get("lua") and n not in manual]
    L.append(f"Rezolvate prin override manual (`tools/manual_overrides.json`): **{len(manual)}** – " + ", ".join(f"`{n}`" for n in sorted(manual)) + "\n")
    only_cosmetic = [n for n, d in report["abilitati"].items() if d["speciale_lipsa"] and not real_keys(d["speciale_lipsa"]) and not d.get("lua")]
    L.append(f"Total cu valori reale lipsă: **{len(rows)}** (alte {len(only_cosmetic)} au doar chei de tooltip/Aghanim lipsă – irelevante)\n")
    for n, d in sorted(rows):
        L.append(f"* `{n}`: " + ", ".join(real_keys(d["speciale_lipsa"])))
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

def neutralize_hero_levelup(merged: kv.KV, AN: kv.KV, IN: kv.KV) -> int:
    """Clientul curent are valori care cresc cu nivelul eroului ("hero_levelup", ex. Desolate +1.5 daune / nivel,
    Poison Sting, Hunter in the Night, incarcaturile Stone Remnant). Override-ul inlocuieste doar "value", iar motorul
    pastreaza cresterea. In 6.88 nicio abilitate nu crestea cu nivelul eroului: pentru fiecare cheie pe care o
    suprascriem, daca definitia curenta are hero_levelup, scriem un bloc cu "hero_levelup" "0"."""
    n = 0
    for name, blk in merged.blocks():
        cur = AN.get_kv(name) or IN.get_kv(name)
        oav = blk.get_kv("AbilityValues")
        cav = cur.get_kv("AbilityValues") if cur is not None else None
        if oav is None or cav is None:
            continue
        for key, val in list(oav.items):
            cdef = cav.get(key)
            if not isinstance(cdef, kv.KV) or not any(sk.lower() in ("hero_levelup", "levelup_interval") for sk, _ in cdef.items):
                continue
            value = val if isinstance(val, str) else (val.get_str("value") or "0")
            oav[key] = kv.KV([("value", value), ("hero_levelup", "0")])
            n += 1
    return n


def load_scepter_688() -> set[str]:
    """Abilitatile care aveau upgrade de Aghanim in 6.88 (au token-ul _aghanim_description in tooltip-urile 6.88)."""
    out = set()
    with open(os.path.join(REF_OLD, "dota_english.txt"), encoding="utf-8", errors="replace") as f:
        for m in re.finditer(r'"DOTA_Tooltip_ability_(\w+?)_aghanim_description"', f.read(), re.IGNORECASE):
            out.add(m.group(1))
    return out


def main() -> None:
    H0, A0, I0, U0 = load_old()
    HN, AN, IN, UN = load_now()
    SCEPTER_688.update(load_scepter_688())
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
    units = gen_units(U0, UN, report, AN, A0)

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
    # corecții manuale (tools/manual_overrides.json): mecanici moderne de dezactivat / valori cu semn schimbat
    manual_path = os.path.join(ROOT, "tools", "manual_overrides.json")
    if os.path.exists(manual_path):
        with open(manual_path, encoding="utf-8") as f:
            manual = json.load(f)
        for name, vals in manual.items():
            if name.startswith("_"):
                continue
            blk = merged.get_kv(name)
            if blk is None:
                blk = kv.KV()
                merged[name] = blk
            cur = AN.get_kv(name) or IN.get_kv(name)
            for key, val in vals.items():
                if cur is not None and where_defined(cur, key) == "values":
                    av = blk.get_kv("AbilityValues")
                    if av is None:
                        av = kv.KV()
                        blk["AbilityValues"] = av
                    av[key] = str(val)
                else:
                    blk[key] = str(val)
    neutralize_hero_levelup(merged, AN, IN)
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
