#!/usr/bin/env python3
"""Genereaza docs/patchnotes/index.html – „patch notes” in stilul paginilor Valve pentru patch-urile mari:
fiecare erou (portret) cu abilitatile lui, fiecare item (iconita), si toate schimbarile 6.88 Classic fata de
clientul curent, calculate din reference/6.88f vs reference/current + build/report.json (produs de gen_overrides.py).

Rulare: python tools/gen_overrides.py && python tools/gen_patchnotes.py
Imaginile vin de pe CDN-ul Valve (cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react/...).
Textele din pagina sunt in engleza (mod public). Fisierul generat NU se editeaza manual.
"""
from __future__ import annotations

import datetime
import html
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import kv  # noqa: E402
import gen_overrides as G  # noqa: E402

OUT = os.path.join(G.DOCS, "patchnotes", "index.html")
CDN = "https://cdn.cloudflare.steamstatic.com/apps/dota2/images/dota_react"
WORKSHOP = "https://steamcommunity.com/sharedfiles/filedetails/?id=3818931233"
GITHUB = "https://github.com/cobrabm12/Dota-workshopmap-beforepatch7"

NEW_HERO_NAMES = {
    "dark_willow": "Dark Willow", "dawnbreaker": "Dawnbreaker", "grimstroke": "Grimstroke", "hoodwink": "Hoodwink",
    "kez": "Kez", "largo": "Largo", "marci": "Marci", "mars": "Mars", "monkey_king": "Monkey King", "muerta": "Muerta",
    "pangolier": "Pangolier", "primal_beast": "Primal Beast", "ringmaster": "Ringmaster", "snapfire": "Snapfire",
    "void_spirit": "Void Spirit",
}
NEW_ITEM_NAMES = {
    "item_ultimate_scepter_2": "Aghanim's Blessing", "item_aghanims_shard": "Aghanim's Shard", "item_gungir": "Gleipnir",
    "item_angels_demise": "Angel's Demise", "item_revenants_brooch": "Revenant's Brooch",
    "item_specialists_array": "Specialist's Array", "item_hydras_breath": "Hydra's Breath",
    "item_crellas_crozier": "Crella's Crozier", "item_kaya_and_sange": "Kaya and Sange", "item_yasha_and_kaya": "Yasha and Kaya",
}
STAT_LABELS = [
    ("AttributePrimary", "Primary attribute"), ("AttributeBaseStrength", "Base Strength"), ("AttributeStrengthGain", "Strength gain"),
    ("AttributeBaseAgility", "Base Agility"), ("AttributeAgilityGain", "Agility gain"),
    ("AttributeBaseIntelligence", "Base Intelligence"), ("AttributeIntelligenceGain", "Intelligence gain"),
    ("AttackDamage", "Base damage"), ("ArmorPhysical", "Base armor"), ("MagicalResistance", "Base magic resistance"),
    ("AttackRate", "Base attack time"), ("AttackAnimationPoint", "Attack point"), ("AttackRange", "Attack range"),
    ("ProjectileSpeed", "Projectile speed"), ("AttackCapabilities", "Attack type"), ("MovementSpeed", "Movement speed"),
    ("MovementTurnRate", "Turn rate"), ("StatusHealth", "Base health"), ("StatusHealthRegen", "Base health regen"),
    ("StatusMana", "Base mana"), ("StatusManaRegen", "Base mana regen"),
    ("VisionDaytimeRange", "Day vision"), ("VisionNighttimeRange", "Night vision"),
]
TOP_LABELS = {
    "AbilityCooldown": "Cooldown", "AbilityManaCost": "Mana cost", "AbilityCastRange": "Cast range", "AbilityCastPoint": "Cast point",
    "AbilityDamage": "Damage", "AbilityDuration": "Duration", "AbilityChannelTime": "Channel time", "AbilityCharges": "Charges",
    "AbilityChargeRestoreTime": "Charge restore time", "RequiredLevel": "Required level", "LevelsBetweenUpgrades": "Levels between upgrades",
    "MaxLevel": "Max level", "ItemInitialCharges": "Initial charges", "ItemStockMax": "Max stock", "ItemStockInitial": "Initial stock",
    "ItemStockTime": "Restock time", "ItemInitialStockTime": "Initial stock time", "ItemShareability": "Shareability",
    "ItemSellable": "Sellable", "ItemDroppable": "Droppable", "ItemDisassembleRule": "Disassemble", "ItemStackable": "Stackable",
    "ItemPermanent": "Permanent", "ItemRequiresCharges": "Requires charges", "ItemKillable": "Killable",
    "AbilityUnitDamageType": "Damage type", "SpellImmunityType": "Pierces spell immunity", "SpellDispellableType": "Dispellable",
    "AbilityUnitTargetTeam": "Target team", "AbilityUnitTargetType": "Target type", "AbilityUnitTargetFlags": "Target flags",
}
ENUM_VALUES = {
    "SPELL_IMMUNITY_ENEMIES_NO": "No", "SPELL_IMMUNITY_ENEMIES_YES": "Yes", "SPELL_IMMUNITY_ALLIES_NO": "No (allies)",
    "SPELL_IMMUNITY_ALLIES_YES": "Yes (allies)", "SPELL_IMMUNITY_ALLIES_YES_ENEMIES_NO": "Allies yes, enemies no",
    "SPELL_DISPELLABLE_YES": "Yes", "SPELL_DISPELLABLE_NO": "No", "SPELL_DISPELLABLE_YES_STRONG": "Strong dispels only",
    "DAMAGE_TYPE_MAGICAL": "Magical", "DAMAGE_TYPE_PHYSICAL": "Physical", "DAMAGE_TYPE_PURE": "Pure",
}
SKIP_TOP = {"ItemCost", "ItemShopTags", "SideShop", "SecretShop", "ItemQuality", "ItemPurchasable", "ItemAlertable",
            "AbilityCastRangeBuffer", "AbilityModifierSupportValue", "AbilityModifierSupportBonus",
            "RequiredLevel", "LevelsBetweenUpgrades", "ItemAliases", "ItemDeclarations", "AbilityBehavior",
            "ItemDisplayCharges", "ItemHideCharges", "ItemBaseLevel", "AbilityTextureName", "FightRecapLevel"}
PRIMARY = {"DOTA_ATTRIBUTE_STRENGTH": "Strength", "DOTA_ATTRIBUTE_AGILITY": "Agility", "DOTA_ATTRIBUTE_INTELLECT": "Intelligence",
           "DOTA_ATTRIBUTE_ALL": "Universal"}
PRIMARY_ICON = {"DOTA_ATTRIBUTE_STRENGTH": "hero_strength", "DOTA_ATTRIBUTE_AGILITY": "hero_agility", "DOTA_ATTRIBUTE_INTELLECT": "hero_intelligence"}


# ---------------------------------------------------------------------------
# texte 6.88

def load_tokens() -> dict[str, str]:
    doc = kv.load(os.path.join(G.REF_OLD, "dota_english.txt"), follow_base=False)
    tokens = doc["lang"]["Tokens"]
    out: dict[str, str] = {}
    for k, v in tokens.scalars():
        out.setdefault(k.lower(), v)
    return out


TXT: dict[str, str] = {}


def T(key: str, default: str | None = None) -> str | None:
    return TXT.get(key.lower(), default)


def esc(s: str) -> str:
    return html.escape(s, quote=True)


def humanize(key: str) -> str:
    s = key
    for p in ("Ability", "Item"):
        if s.startswith(p) and s[len(p):len(p) + 1].isupper():
            s = s[len(p):]
    s = re.sub(r"(?<=[a-z])(?=[A-Z])", " ", s).replace("_", " ").strip()
    s = re.sub(r"\btooltip\b", "", s).strip()
    return s[:1].upper() + s[1:] if s else key


def label_for(ability: str, key: str) -> str:
    if key in TOP_LABELS:
        return TOP_LABELS[key]
    t = T(f"DOTA_Tooltip_ability_{ability}_{key}")
    if t and "$" not in t:
        t = re.sub(r"<[^>]+>", "", t).replace("\\n", " ").replace("\n", " ")
        t = re.sub(r"\s+", " ", t).strip().strip("%").strip().rstrip(":").strip()
        if t:
            t = t.lower()
            t = re.sub(r"\b(hp|agi|str|int|xp|ms|as|aoe|dps|bat)\b", lambda m: m.group(1).upper(), t)
            return t[:1].upper() + t[1:]
    return humanize(key)


def fmtv(v: str | None) -> str:
    if v is None:
        return "—"
    v = v.strip()
    nums = G._nums(v)
    if nums is not None and nums:
        # „12 12 12 12” -> 12
        if len(set(nums)) == 1:
            return G._fmt(nums[0])
        return "/".join(G._fmt(x) for x in nums)
    if re.fullmatch(r"[A-Z][A-Z0-9_|\s]+", v):
        parts = []
        for tok in v.split("|"):
            tok = tok.strip()
            if tok in ENUM_VALUES:
                parts.append(ENUM_VALUES[tok])
                continue
            for pre in ("DOTA_UNIT_CAP_", "DOTA_ABILITY_BEHAVIOR_", "DOTA_UNIT_TARGET_TEAM_", "DOTA_UNIT_TARGET_FLAG_",
                        "DOTA_UNIT_TARGET_", "DAMAGE_TYPE_", "SPELL_IMMUNITY_", "SPELL_DISPELLABLE_", "DOTA_"):
                if tok.startswith(pre):
                    tok = tok[len(pre):]
                    break
            parts.append(tok.replace("_", " ").title())
        return ", ".join(parts)
    return v


def is_pct(ability: str, key: str) -> bool:
    """Tooltip-ul 6.88 marca procentele cu `%` la inceputul etichetei („%CRITICAL CHANCE:”)."""
    t = T(f"DOTA_Tooltip_ability_{ability}_{key}")
    return bool(t) and t.strip().startswith("%")


def pct(ability: str, key: str, v: str) -> str:
    return v + "%" if is_pct(ability, key) and G._nums(v) else v


def text_block(desc: str, vals: dict[str, str]) -> str:
    """Descriere 6.88 cu %var% inlocuite cu valorile 6.88; fara tag-uri HTML (in afara de <br>)."""
    def sub(m):
        k = m.group(1)
        v = vals.get(k)
        if v is None:
            return ""
        return fmtv(v)
    s = re.sub(r"%([A-Za-z0-9_]+)%", sub, desc)
    s = s.replace("%%", "%")
    s = re.sub(r"<\s*br\s*/?\s*>", "\n", s, flags=re.I)
    s = re.sub(r"\\n", "\n", s)
    s = re.sub(r"<[^>]+>", "", s)
    return esc(s).replace("\n", "<br>")


# ---------------------------------------------------------------------------
# markdown-ul din PATCH_NOTES.md (sectiunile generale) -> HTML

def md_inline(s: str) -> str:
    s = esc(s)
    s = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", s)
    s = re.sub(r"`([^`]+)`", r"<code>\1</code>", s)
    s = re.sub(r"\[([^\]]+)\]\((https?://[^)]+)\)", r'<a href="\2">\1</a>', s)
    s = re.sub(r"(?<![\"'>])(https://\S+?)(?=[\s)*]|$)", r'<a href="\1">\1</a>', s)
    return s


def md_sections(path: str) -> dict[str, list[str]]:
    out: dict[str, list[str]] = {}
    cur = None
    with open(path, encoding="utf-8") as f:
        for line in f.read().splitlines():
            if line.startswith("## "):
                cur = line[3:].strip()
                out[cur] = []
            elif cur is not None:
                out[cur].append(line)
    return out


def md_to_html(lines: list[str]) -> str:
    """Suporta paragrafe si liste cu `* ` imbricate (2 spatii per nivel); sare peste imagini/tabele/separatori."""
    items: list[tuple[int, str]] = []  # (nivel, text)
    paras: list[str] = []
    out: list[str] = []

    def flush_list():
        nonlocal items
        if not items:
            return
        depth = 0
        for lvl, txt in items:
            while depth < lvl + 1:
                out.append("<ul>")
                depth += 1
            while depth > lvl + 1:
                out.append("</ul>")
                depth -= 1
            out.append(f"<li>{md_inline(txt)}</li>")
        while depth > 0:
            out.append("</ul>")
            depth -= 1
        items = []

    def flush_para():
        nonlocal paras
        if paras:
            out.append(f"<p>{md_inline(' '.join(paras))}</p>")
            paras = []

    for raw in lines:
        line = raw.rstrip()
        m = re.match(r"^( *)\* (.*)$", line)
        if m:
            flush_para()
            lvl = len(m.group(1)) // 2
            items.append((lvl, m.group(2)))
        elif line.startswith("  ") and items and line.strip() and not line.lstrip().startswith(("|", "!")):
            lvl, txt = items[-1]
            items[-1] = (lvl, txt + " " + line.strip())
        elif not line.strip():
            flush_list()
            flush_para()
        elif line.startswith(("![", "|", "---", "*Dota 6.88 Classic is a community")) or line.lstrip().startswith(("|", "![")):
            flush_list()
            flush_para()
        else:
            flush_list()
            paras.append(line.strip())
    flush_list()
    flush_para()
    return "\n".join(out)


# ---------------------------------------------------------------------------
# diferente

def change_bullets(name: str, old: kv.KV, cur: kv.KV | None, changed: list[str], manual: dict[str, str] | None,
                   prefix: str = "") -> list[str]:
    """Bullet-uri „Label: acum → 6.88” pentru cheile schimbate (din report) si override-urile manuale."""
    out: list[str] = []
    seen: set[str] = set()
    old_vals = kv.values_of(old)
    cur_vals = kv.values_of(cur) if cur is not None else {}
    rename = G.KEY_RENAME_688.get(name, {})
    rev = {nk: ok for ok, nks in rename.items() for nk in nks}
    for key in changed:
        if key in seen or key in SKIP_TOP or "tooltip" in key.lower():
            continue
        seen.add(key)
        is_special = key in old_vals or key in cur_vals or key in rev
        if is_special:
            cv = cur_vals.get(key)
            ov = old_vals.get(key)
            if ov is None and key in rev:
                ov = old_vals.get(rev[key])
            if ov is not None:
                ov = G.value_688(name, rev.get(key, key), ov, cv)
        else:
            cv = G.cur_value(cur, key) if cur is not None else None
            ov = old.get_str(key)
        if key == "AbilityCharges" and ov is None:
            out.append(f"{prefix}Charges removed (single cooldown)")
            continue
        if key == "AbilityChargeRestoreTime" and ov is None:
            continue
        if ov is None or cv is None:
            continue  # cheia nu mai exista in clientul curent: nu e o „schimbare” de aratat
        if G.same_value(ov, cv):
            continue
        if key == "AbilityCastRange" and not (set(G.norm_num_list(ov)) - {"0"}):
            continue  # 0 = raza in alta cheie (ex. Blink)
        if key == "MaxLevel" and ov.strip() == "1":
            continue  # sub-abilitati ascunse (Spirits In/Out etc.)
        on, cn = G._nums(ov), G._nums(cv)
        if key == "AbilityCastPoint" and on and cn and abs(on[0] - cn[0]) < 0.01:
            continue
        line = f"{prefix}{esc(label_for(name, key))}: {esc(pct(name, key, fmtv(cv)))} <span class=arr>→</span> <b>{esc(pct(name, key, fmtv(ov)))}</b>"
        if line not in out:
            out.append(line)
    if manual:
        for key, val in manual.items():
            if key.startswith("_") or key in seen or "tooltip" in key.lower() or not isinstance(val, str):
                continue
            cv = cur_vals.get(key)
            if cv is None and cur is not None:
                cv = G.cur_value(cur, key)
            if cv is not None and G.same_value(val, cv):
                continue
            seen.add(key)
            lbl = label_for(name, key)
            if cv is None:
                line = f"{prefix}{esc(lbl)}: <b>{esc(pct(name, key, fmtv(val)))}</b>"
            else:
                line = f"{prefix}{esc(lbl)}: {esc(pct(name, key, fmtv(cv)))} <span class=arr>→</span> <b>{esc(pct(name, key, fmtv(val)))}</b>"
            if line not in out:
                out.append(line)
    return out


def tooltip_values(name: str, blk: kv.KV) -> str:
    """Linia „Cooldown: … · Mana: … · Radius: …” cu valorile 6.88 (doar cheile care aveau eticheta in tooltip-ul 6.88)."""
    parts = []
    for key in ("AbilityCastRange", "AbilityCooldown", "AbilityManaCost"):
        v = blk.get_str(key)
        if v and set(G.norm_num_list(v)) - {"0"}:
            parts.append(f"<span>{TOP_LABELS[key]}: <b>{esc(fmtv(v))}</b></span>")
    for key, v in kv.values_of(blk).items():
        t = T(f"DOTA_Tooltip_ability_{name}_{key}")
        if not t or "$" in t or "tooltip" in key.lower():
            continue
        parts.append(f"<span>{esc(label_for(name, key))}: <b>{esc(pct(name, key, fmtv(v)))}</b></span>")
    return " · ".join(parts)


def hero_stat_bullets(h0: kv.KV, hN: kv.KV, base0: kv.KV, baseN: kv.KV) -> list[str]:
    out = []
    for key, lbl in STAT_LABELS:
        if key == "AttackDamage":
            keys = ("AttackDamageMin", "AttackDamageMax")
            if not any(h0.get_str(k) is not None or hN.get_str(k) is not None for k in keys):
                continue
            o = [G.effective(h0, base0, k) for k in keys]
            c = [G.effective(hN, baseN, k) for k in keys]
            if None in o or None in c:
                continue
            if all(G.same_value(a, b) for a, b in zip(o, c)):
                continue
            out.append(f"Base damage: {fmtv(c[0])}–{fmtv(c[1])} <span class=arr>→</span> <b>{fmtv(o[0])}–{fmtv(o[1])}</b>")
            continue
        if h0.get_str(key) is None and hN.get_str(key) is None:
            continue  # ambele mostenesc din npc_dota_hero_base: regula generala, nu a eroului
        ov = G.effective(h0, base0, key)
        cv = G.effective(hN, baseN, key)
        if ov is None or cv is None or G.same_value(ov, cv):
            continue
        if key == "AttributePrimary":
            out.append(f"{lbl}: {PRIMARY.get(cv, cv)} <span class=arr>→</span> <b>{PRIMARY.get(ov, ov)}</b>")
        else:
            out.append(f"{lbl}: {esc(fmtv(cv))} <span class=arr>→</span> <b>{esc(fmtv(ov))}</b>")
    bas = hN.get_str("BaseAttackSpeed")
    if bas and bas != "100":
        out.append(f"Base attack speed: {esc(bas)} <span class=arr>→</span> <b>100</b>")
    return out


def hero_slots(name: str, h0: kv.KV) -> list[str]:
    slots = [a for _, a in G.slot_abilities(h0)]
    if name in G.SLOT_OVERRIDES:
        slots = list(G.SLOT_OVERRIDES[name])
    out = []
    for a in slots:
        if not a or a in ("attribute_bonus", "invoker_attribute_bonus"):
            continue
        a = G.RENAME.get(a, a)
        if a == "generic_hidden" or a in out:
            continue
        out.append(a)
    return out


# ---------------------------------------------------------------------------
# HTML

CSS = """
:root{--bg:#0f1216;--panel:#171c23;--panel2:#1e252e;--line:#2a333f;--text:#d9dde3;--muted:#8f9aa8;--accent:#e0b35a;--red:#c23b3b;--green:#3d9a4a}
*{box-sizing:border-box}html{scroll-behavior:smooth}
body{margin:0;background:var(--bg);color:var(--text);font:15px/1.5 "Segoe UI",Roboto,Helvetica,Arial,sans-serif}
a{color:var(--accent);text-decoration:none}a:hover{text-decoration:underline}
code{background:#000;padding:0 4px;border-radius:3px;font-size:13px}
.wrap{max-width:1100px;margin:0 auto;padding:0 16px}
header.hero{background:linear-gradient(180deg,rgba(0,0,0,.25),var(--bg)),url(../img/mid_lane.jpg) center/cover;border-bottom:1px solid var(--line)}
header.hero .wrap{padding:70px 16px 40px}
h1{font-size:44px;margin:0 0 6px;letter-spacing:.5px;text-shadow:0 2px 12px #000}
h1 small{display:block;font-size:18px;color:var(--accent);font-weight:400;letter-spacing:2px;text-transform:uppercase}
.lead{max-width:760px;font-size:17px;color:#e9ecf0;text-shadow:0 1px 8px #000}
.links a{display:inline-block;margin:10px 10px 0 0;padding:8px 14px;border:1px solid var(--accent);border-radius:4px;background:rgba(0,0,0,.5)}
nav.top{position:sticky;top:0;z-index:5;background:rgba(15,18,22,.95);border-bottom:1px solid var(--line);backdrop-filter:blur(6px)}
nav.top .wrap{display:flex;gap:4px;flex-wrap:wrap;align-items:center;padding:6px 16px}
nav.top a{padding:6px 10px;color:var(--text);border-radius:4px}nav.top a:hover{background:var(--panel2);text-decoration:none}
nav.top input{margin-left:auto;background:var(--panel2);border:1px solid var(--line);color:var(--text);padding:6px 10px;border-radius:4px;min-width:220px}
section{padding:36px 0 10px}
h2{font-size:30px;margin:0 0 16px;padding-bottom:8px;border-bottom:2px solid var(--accent);display:flex;align-items:baseline;gap:12px;flex-wrap:wrap}
h2 .count{font-size:14px;color:var(--muted);font-weight:400}
h3{font-size:20px;margin:26px 0 10px;color:var(--accent)}
.gallery{display:grid;grid-template-columns:repeat(auto-fit,minmax(240px,1fr));gap:10px;margin:18px 0}
.gallery img{width:100%;border-radius:6px;border:1px solid var(--line)}
.notes ul{padding-left:22px;margin:6px 0}.notes li{margin:5px 0}.notes ul ul{margin:4px 0}
.summary{background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:14px 18px;margin-bottom:18px}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(96px,1fr));gap:8px;margin:12px 0 24px}
.grid a{display:block;text-align:center;font-size:11px;color:var(--muted);line-height:1.2}
.grid a:hover{color:#fff;text-decoration:none}
.grid img{width:100%;aspect-ratio:16/9;object-fit:cover;border-radius:4px;border:1px solid var(--line);display:block;margin-bottom:3px}
.grid.items{grid-template-columns:repeat(auto-fill,minmax(78px,1fr))}
.grid.items img{aspect-ratio:88/64}
.grid.off img{filter:grayscale(1) brightness(.6)}
.attr-h{display:flex;align-items:center;gap:8px;margin:16px 0 4px;color:var(--muted);font-size:14px;text-transform:uppercase;letter-spacing:1px}
.attr-h img{width:22px}
.card{background:var(--panel);border:1px solid var(--line);border-radius:8px;margin:14px 0;overflow:hidden}
.card .head{display:flex;gap:16px;align-items:center;padding:12px 16px;background:var(--panel2);border-bottom:1px solid var(--line)}
.card .head img.portrait{width:128px;height:72px;object-fit:cover;border-radius:4px;flex:none}
.card .head img.item{width:88px;height:64px;object-fit:cover;border-radius:4px;flex:none}
.card .head .name{font-size:24px;font-weight:600;line-height:1.1}
.card .head .sub{color:var(--muted);font-size:13px;margin-top:4px;display:flex;align-items:center;gap:6px;flex-wrap:wrap}
.card .head .sub img{width:16px}
.card .body{padding:10px 16px 14px}
.kit{display:flex;gap:6px;flex-wrap:wrap;margin:4px 0 10px}
.kit img{width:40px;height:40px;border-radius:4px;border:1px solid var(--line)}
.kit img.chg{border-color:var(--accent);box-shadow:0 0 0 1px var(--accent)}
.kit img.lua{border-color:var(--red);box-shadow:0 0 0 1px var(--red)}
ul.ch{margin:4px 0 4px;padding-left:22px}ul.ch li{margin:3px 0}
.arr{color:var(--muted);padding:0 2px}
.ab{display:flex;gap:12px;padding:10px 0;border-top:1px solid var(--line)}
.ab img{width:48px;height:48px;border-radius:5px;flex:none;margin-top:2px}
.ab .t{font-weight:600;font-size:16px}
.badge{display:inline-block;font-size:11px;padding:1px 7px;border-radius:10px;margin-left:8px;vertical-align:middle;text-transform:uppercase;letter-spacing:.5px;font-weight:600}
.badge.lua{background:var(--red);color:#fff}.badge.back{background:var(--green);color:#fff}
.desc{color:#c3c9d1;margin:4px 0 6px;font-size:14px}
.vals{color:var(--muted);font-size:13px}.vals b{color:var(--text);font-weight:600}
.scep{color:#b9a0e8}.scep b{color:#d6c6ff}
.muted{color:var(--muted)}
.empty{color:var(--muted);font-style:italic}
footer{border-top:1px solid var(--line);margin-top:40px;padding:24px 0 40px;color:var(--muted);font-size:13px}
.hidden{display:none!important}
@media (max-width:700px){h1{font-size:30px}.card .head img.portrait{width:96px;height:54px}.card .head .name{font-size:19px}nav.top input{min-width:0;width:100%;margin:4px 0 0}}
"""

JS = """
(function(){
  var q=document.getElementById('q');if(!q)return;
  var cards=[].slice.call(document.querySelectorAll('.card[data-name]'));
  var tiles=[].slice.call(document.querySelectorAll('.grid a[data-name]'));
  function norm(s){return (s||'').toLowerCase()}
  q.addEventListener('input',function(){
    var v=norm(q.value).trim();
    cards.forEach(function(c){c.classList.toggle('hidden',!!v&&norm(c.getAttribute('data-name')).indexOf(v)<0)});
    tiles.forEach(function(c){c.classList.toggle('hidden',!!v&&norm(c.getAttribute('data-name')).indexOf(v)<0)});
  });
})();
"""


def main() -> None:
    global TXT
    TXT = load_tokens()
    H0, A0, I0, _ = G.load_old()
    HN, AN, IN, _ = G.load_now()
    with open(os.path.join(G.BUILD, "report.json"), encoding="utf-8") as f:
        report = json.load(f)
    manual_path = os.path.join(G.ROOT, "tools", "manual_overrides.json")
    manual: dict = {}
    if os.path.exists(manual_path):
        with open(manual_path, encoding="utf-8") as f:
            manual = {k: v for k, v in json.load(f).items() if not k.startswith("_") and isinstance(v, dict)}
    md = md_sections(os.path.join(G.DOCS, "PATCH_NOTES.md"))

    base0 = H0.get_kv("npc_dota_hero_base")
    baseN = HN.get_kv("npc_dota_hero_base")

    def hero_name(n: str) -> str:
        return T(n) or NEW_HERO_NAMES.get(n.replace("npc_dota_hero_", ""), humanize(n.replace("npc_dota_hero_", "")))

    def item_name(n: str) -> str:
        return T(f"DOTA_Tooltip_ability_{n}") or NEW_ITEM_NAMES.get(n) or humanize(n[5:]).title().replace(" Of ", " of ").replace(" And ", " and ")

    def ability_name(a: str) -> str:
        return T(f"DOTA_Tooltip_ability_{a}") or humanize(a)

    # ------------------------------------------------------------------ eroi
    hero_list = sorted(report["eroi"].keys(), key=hero_name)
    hero_cards: list[str] = []
    n_ab_changed = 0
    n_ab_lua = 0
    for name in hero_list:
        short = name.replace("npc_dota_hero_", "")
        h0, hN = H0.get_kv(name), HN.get_kv(name)
        rep = report["eroi"][name]
        prim = G.effective(h0, base0, "AttributePrimary")
        stat_b = hero_stat_bullets(h0, hN, base0, baseN)
        abilities = hero_slots(name, h0)
        ab_html: list[str] = []
        kit: list[str] = []
        for a in abilities:
            old = A0.get_kv(a)
            if old is None:
                continue
            cur = AN.get_kv(a)
            arep = report["abilitati"].get(a, {})
            lua = bool(arep.get("lua")) or a in rep["abilitati_custom"]
            missing = a in rep["abilitati_lipsa"]
            bullets: list[str] = []
            desc = ""
            vals = ""
            if lua:
                n_ab_lua += 1
                d = T(f"DOTA_Tooltip_ability_{a}_Description")
                if d:
                    merged = dict(kv.values_of(old))
                    for k in ("AbilityCastRange", "AbilityCooldown", "AbilityManaCost", "AbilityDamage", "AbilityDuration"):
                        v = old.get_str(k)
                        if v:
                            merged.setdefault(k.lower(), v)
                            merged.setdefault(k, v)
                    desc = text_block(d, merged)
                vals = tooltip_values(a, old)
            else:
                bullets = change_bullets(a, old, cur, arep.get("schimbate", []), manual.get(a))
                if missing:
                    fb = rep["fallback"].get(a)
                    bullets.append("Not available in the current engine" + (f"; replaced by {esc(ability_name(fb))}" if fb else ""))
            scep = T(f"DOTA_Tooltip_ability_{a}_aghanim_description")
            if scep:
                bullets.append(f"<span class=scep><b>Aghanim's Scepter (6.88):</b> {text_block(scep, kv.values_of(old))}</span>")
            hidden = "DOTA_ABILITY_BEHAVIOR_HIDDEN" in (old.get_str("AbilityBehavior") or "") and old.get_str("AbilityType") != "DOTA_ABILITY_TYPE_ULTIMATE"
            changed = lua or bool(bullets)
            if changed and not lua:
                n_ab_changed += 1
            cls = "lua" if lua else ("chg" if bullets else "")
            title = ability_name(a) + (" — rewritten with the 6.88 mechanics" if lua else (" — values restored to 6.88" if bullets else " — unchanged"))
            if not (hidden and not changed):
                kit.append(f'<img src="{CDN}/abilities/{a}.png" alt="" title="{esc(title)}" class="{cls}" loading="lazy" onerror="this.style.display=\'none\'">')
            if not changed:
                continue
            badge = '<span class="badge lua">6.88 rework</span>' if lua else ""
            parts = [f'<div class=ab><img src="{CDN}/abilities/{a}.png" alt="" loading="lazy" onerror="this.style.visibility=\'hidden\'"><div>'
                     f'<div class=t>{esc(ability_name(a))}{badge}</div>']
            if desc:
                parts.append(f"<div class=desc>{desc}</div>")
            if vals:
                parts.append(f"<div class=vals>{vals}</div>")
            if bullets:
                parts.append("<ul class=ch>" + "".join(f"<li>{b}</li>" for b in bullets) + "</ul>")
            parts.append("</div></div>")
            ab_html.append("".join(parts))
        picon = PRIMARY_ICON.get(prim or "")
        sub = (f'<img src="{CDN}/icons/{picon}.png" alt="">' if picon else "") + esc(PRIMARY.get(prim, prim or ""))
        body = []
        body.append("<div class=kit>" + "".join(kit) + "</div>")
        if stat_b:
            body.append("<ul class=ch>" + "".join(f"<li>{b}</li>" for b in stat_b) + "</ul>")
        if ab_html:
            body.extend(ab_html)
        if not stat_b and not ab_html:
            body.append("<p class=empty>No changes other than the general rules (talents, Attribute Bonus, 6.88 attributes).</p>")
        hero_cards.append(
            f'<div class=card id="hero-{short}" data-name="{esc(hero_name(name))}">'
            f'<div class=head><img class=portrait src="{CDN}/heroes/{short}.png" alt="" loading="lazy">'
            f'<div><div class=name>{esc(hero_name(name))}</div><div class=sub>{sub}</div></div></div>'
            f'<div class=body>{"".join(body)}</div></div>')

    # grila de eroi pe atribut
    hero_grid = []
    for attr, lbl in (("DOTA_ATTRIBUTE_STRENGTH", "Strength"), ("DOTA_ATTRIBUTE_AGILITY", "Agility"), ("DOTA_ATTRIBUTE_INTELLECT", "Intelligence")):
        names = [n for n in hero_list if G.effective(H0.get_kv(n), base0, "AttributePrimary") == attr]
        hero_grid.append(f'<div class=attr-h><img src="{CDN}/icons/{PRIMARY_ICON[attr]}.png" alt="">{lbl} ({len(names)})</div><div class=grid>')
        for n in names:
            s = n.replace("npc_dota_hero_", "")
            hero_grid.append(f'<a href="#hero-{s}" data-name="{esc(hero_name(n))}"><img src="{CDN}/heroes/{s}.png" alt="" loading="lazy">{esc(hero_name(n))}</a>')
        hero_grid.append("</div>")
    disabled = report["eroi_noi_dezactivati"]
    off_grid = ['<div class="grid off">']
    for n in sorted(disabled, key=hero_name):
        s = n.replace("npc_dota_hero_", "")
        off_grid.append(f'<a title="Added after 6.88 – not available"><img src="{CDN}/heroes/{s}.png" alt="" loading="lazy">{esc(hero_name(n))}</a>')
    off_grid.append("</div>")

    # ----------------------------------------------------------------- iteme
    def is_shop_item(n: str, b: kv.KV) -> bool:
        return (not n.startswith("item_recipe_") and b.get_str("ItemPurchasable", "1") == "1"
                and b.get_str("ItemCost", "0") not in ("0", None))

    old_items = {n: b for n, b in I0.blocks() if is_shop_item(n, b)}
    variants: dict[str, list[str]] = {}
    bases: list[str] = []
    for n in old_items:
        m = re.fullmatch(r"(item_.+)_(\d)", n)
        if m and m.group(1) in old_items:
            variants.setdefault(m.group(1), []).append(n)
        else:
            bases.append(n)
    bases.sort(key=item_name)

    def recipe_of(items: kv.KV, n: str) -> tuple[list[str], str | None]:
        r = items.get_kv("item_recipe_" + n[5:])
        if r is None:
            return [], None
        req = r.get_kv("ItemRequirements")
        comps = []
        if req is not None:
            first = req.get_str("01") or ""
            comps = [c.strip().rstrip("*") for c in first.split(";") if c.strip()]
        cost = r.get_str("ItemCost")
        return comps, (cost if cost not in (None, "0") else None)

    def recipe_text(comps: list[str], rcost: str | None) -> str:
        parts = [esc(item_name(c)) for c in comps]
        if rcost:
            parts.append(f"Recipe ({esc(rcost)})")
        return " + ".join(parts)

    item_cards: list[str] = []
    card_ids: set[str] = set()
    n_items_changed = 0
    n_items_lua = 0
    n_items_back = 0
    for n in bases:
        old = old_items[n]
        cur = IN.get_kv(n)
        irep = report["iteme"].get(n, {})
        lua = bool(irep.get("lua"))
        back = cur is None or cur.get_str("ItemPurchasable", "1") == "0" or cur.get_str("ItemCost", "0") in ("0", None)
        bullets: list[str] = []
        oc, cc = old.get_str("ItemCost"), (cur.get_str("ItemCost") if cur is not None else None)
        if cc and oc and not G.same_value(oc, cc) and not back:
            bullets.append(f"Total cost: {esc(cc)} <span class=arr>→</span> <b>{esc(oc)}</b>")
        ocomp, orc = recipe_of(I0, n)
        ccomp, crc = recipe_of(IN, n)
        if ocomp and (sorted(ocomp) != sorted(ccomp) or (orc or "0") != (crc or "0")) and not back:
            was = recipe_text(ccomp, crc) if ccomp else "no recipe"
            bullets.append(f"Recipe: <b>{recipe_text(ocomp, orc)}</b> <span class=muted>(was: {was})</span>")
        bullets += change_bullets(n, old, cur, irep.get("schimbate", []), manual.get(n))
        for v in sorted(variants.get(n, [])):
            lvl = v.rsplit("_", 1)[1]
            vo, vc = old_items[v], IN.get_kv(v)
            vrep = report["iteme"].get(v, {})
            voc, vcc = vo.get_str("ItemCost"), (vc.get_str("ItemCost") if vc is not None else None)
            if voc and vcc and not G.same_value(voc, vcc):
                bullets.append(f"Level {lvl} – Total cost: {esc(vcc)} <span class=arr>→</span> <b>{esc(voc)}</b>")
            bullets += change_bullets(v, vo, vc, vrep.get("schimbate", []), manual.get(v), prefix=f"Level {lvl} – ")
        desc = ""
        if lua or back:
            d = T(f"DOTA_Tooltip_ability_{n}_Description")
            if d:
                merged = dict(kv.values_of(old))
                for k in ("AbilityCastRange", "AbilityCooldown", "AbilityManaCost"):
                    v = old.get_str(k)
                    if v:
                        merged.setdefault(k, v)
                desc = text_block(d, merged)
        if not (lua or back or bullets):
            continue
        n_items_changed += 1
        n_items_lua += int(lua)
        n_items_back += int(back)
        badges = ""
        if back:
            badges += '<span class="badge back">Back in the shop</span>'
        if lua:
            badges += '<span class="badge lua">6.88 rework</span>'
        sub = f"{esc(oc)} gold" + (f" · {recipe_text(ocomp, orc)}" if ocomp else "")
        body = []
        if desc:
            body.append(f"<div class=desc>{desc}</div>")
        if lua:
            body.append(f"<div class=vals>{tooltip_values(n, old)}</div>")
        if bullets:
            body.append("<ul class=ch>" + "".join(f"<li>{b}</li>" for b in bullets) + "</ul>")
        card_ids.add(n)
        item_cards.append(
            f'<div class=card id="item-{n[5:]}" data-name="{esc(item_name(n))}">'
            f'<div class=head><img class=item src="{CDN}/items/{n[5:]}.png" alt="" loading="lazy">'
            f'<div><div class=name>{esc(item_name(n))}{badges}</div><div class=sub>{sub}</div></div></div>'
            f'<div class=body>{"".join(body)}</div></div>')

    item_grid = ['<div class="grid items">']
    for n in bases:
        if n in card_ids:
            item_grid.append(f'<a href="#item-{n[5:]}" data-name="{esc(item_name(n))}"><img src="{CDN}/items/{n[5:]}.png" alt="" loading="lazy">{esc(item_name(n))}</a>')
    item_grid.append("</div>")
    removed = [n for n in report["iteme_noi_dezactivate"] if not n.startswith("item_recipe_")]
    removed_grid = ['<div class="grid items off">']
    for n in sorted(removed, key=item_name):
        removed_grid.append(f'<a title="Added after 6.88 – removed from the shop"><img src="{CDN}/items/{n[5:]}.png" alt="" loading="lazy">{esc(item_name(n))}</a>')
    removed_grid.append("</div>")

    # ------------------------------------------------------------------ pagina
    with open(os.path.join(G.REF_OLD, "SOURCE_COMMIT.txt"), encoding="utf-8", errors="replace") as f:
        src_old = f.readline().strip()
    with open(os.path.join(G.REF_NOW, "SOURCE_COMMIT.txt"), encoding="utf-8", errors="replace") as f:
        src_now = f.readline().strip()
    today = datetime.date.today().isoformat()

    def section(id_: str, title: str, count: str, inner: str) -> str:
        return f'<section id="{id_}"><div class=wrap><h2>{esc(title)}<span class=count>{esc(count)}</span></h2>{inner}</div></section>'

    general = md_to_html(md.get("General", []))
    economy = md_to_html(md.get("Economy", []))
    mapn = md_to_html(md.get("Map", []))
    items_sum = md_to_html(md.get("Items", []))
    heroes_sum = md_to_html(md.get("Heroes", []))
    notchg = ""
    for k in md:
        if k.lower().startswith("not changed"):
            notchg = md_to_html(md[k])

    gallery = ('<div class=gallery><img src="../img/hero_pick.jpg" alt="Hero pick: 112 heroes, no facets">'
               '<img src="../img/shop_688.jpg" alt="The 6.88 shop"><img src="../img/techies_mine.jpg" alt="Techies Land Mines">'
               '<img src="../img/radiant_jungle.jpg" alt="The 6.88 Radiant jungle"></div>')
    items_count = f"{n_items_changed} items changed · {n_items_lua} rewritten with 6.88 mechanics · {n_items_back} back in the shop · {len(removed)} removed"
    heroes_count = f"{len(hero_list)} heroes · {n_ab_lua} abilities rewritten with 6.88 mechanics · {n_ab_changed} abilities with 6.88 values · {len(disabled)} heroes disabled"
    items_inner = ('<div class="summary notes">' + items_sum + '</div>'
                   '<h3>Items removed (added after 6.88)</h3>' + "".join(removed_grid) +
                   '<h3>Items changed</h3><p class=muted>Values are shown as <i>current → 6.88</i>. '
                   'Items marked <span class="badge lua">6.88 rework</span> were rewritten in Lua with the original mechanics; '
                   '<span class="badge back">Back in the shop</span> marks items that no longer exist in the current game. Click an icon to jump to it.</p>'
                   + "".join(item_grid) + "".join(item_cards))
    heroes_inner = ('<div class="summary notes">' + heroes_sum + '</div>'
                    '<h3>Heroes disabled (added after 6.88)</h3>' + "".join(off_grid) +
                    '<h3>All heroes</h3><p class=muted>Every hero uses its 6.88 kit. In each card the icon row shows the whole kit: '
                    '<span style="color:var(--red)">red border</span> = rewritten in Lua with the 6.88 mechanics, '
                    '<span style="color:var(--accent)">gold border</span> = 6.88 values restored, no border = identical to today. '
                    'Attribute Bonus (+2 to all attributes) is not shown. Values are <i>current → 6.88</i>; the Scepter line is the 6.88 upgrade.</p>'
                    + "".join(hero_grid) + "".join(hero_cards))

    page = f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Dota 6.88 Classic – Patch Notes</title>
<meta name="description" content="Everything that Dota 6.88 Classic changes relative to the current Dota 2 client: every hero, every item, the map and the rules, back to patch 6.88f.">
<meta property="og:title" content="Dota 6.88 Classic – Patch Notes"><meta property="og:image" content="../img/mid_lane.jpg">
<link rel="icon" href="{CDN}/items/ultimate_scepter.png">
<style>{CSS}</style></head>
<body>
<header class=hero><div class=wrap>
<h1><small>Dota 2 custom game</small>Dota 6.88 Classic – Patch Notes</h1>
<p class=lead>Dota 2 as it was in <b>6.88f</b> (December 2016), the last patch before 7.00. Written the way Valve writes a gameplay
patch, but in reverse: everything that 7.00 and later changed is undone. Below is every hero and every item with what differs
from the current client.</p>
<div class=links><a href="{WORKSHOP}">Steam Workshop</a><a href="{GITHUB}">Source on GitHub</a><a href="{GITHUB}/blob/main/docs/PATCH_NOTES.md">Text version</a></div>
</div></header>
<nav class=top><div class=wrap>
<a href="#general">General</a><a href="#economy">Economy</a><a href="#map">Map</a><a href="#items">Items</a><a href="#heroes">Heroes</a><a href="#notchanged">Not changed</a>
<input id=q type=search placeholder="Filter heroes / items…" aria-label="Filter">
</div></nav>

{section("general", "General", "", gallery + '<div class=notes>' + general + '</div>')}
{section("economy", "Economy", "", '<div class=notes>' + economy + '</div>')}
{section("map", "Map", "", '<div class=notes>' + mapn + '</div>')}
{section("items", "Items", items_count, items_inner)}
{section("heroes", "Heroes", heroes_count, heroes_inner)}
{section("notchanged", "Not changed (engine limitations)", "", '<div class=notes>' + notchg + '</div>')}
<footer><div class=wrap>Generated by <code>tools/gen_patchnotes.py</code> on {today} from Valve's 6.88f game files ({esc(src_old)}) and the current client files ({esc(src_now[:40])}).
Hero, ability and item images are served from Valve's CDN. Dota 6.88 Classic is a community project (GPL‑3.0); Dota 2 is a trademark of Valve Corporation.
<br><a href="{WORKSHOP}">Steam Workshop</a> · <a href="{GITHUB}">GitHub</a></div></footer>
<script>{JS}</script>
</body></html>
"""
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(page)
    print(f"{OUT}: {os.path.getsize(OUT)//1024} KB; heroes {len(hero_list)}, "
          f"abilities lua {n_ab_lua} / changed {n_ab_changed}; items changed {n_items_changed} (lua {n_items_lua}, back {n_items_back}), removed {len(removed)}")


if __name__ == "__main__":
    main()
