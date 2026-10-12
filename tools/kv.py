#!/usr/bin/env python3
"""Parser și serializer minimal pentru formatul Valve KeyValues (KV1), așa cum este
folosit de fișierele npc_heroes.txt / npc_abilities.txt / items.txt din Dota 2.

Caracteristici:
  * comentarii `//` până la sfârșitul liniei
  * chei/valori cu sau fără ghilimele
  * directive `#base "fisier"` (rezolvate relativ la fișierul curent)
  * condiționale `[$WIN32]` după valori (ignorate)
  * chei duplicate păstrate în ordine (KV este o listă ordonată de perechi)

Structura rezultată: `KV` = listă ordonată de (cheie, valoare), unde valoarea este
fie `str`, fie un alt `KV`.
"""
from __future__ import annotations

import os
import sys
from typing import Iterator, Optional, Union

Value = Union[str, "KV"]


class KV:
    """Un bloc KeyValues: listă ordonată de perechi (cheie, valoare)."""

    __slots__ = ("items",)

    def __init__(self, items: Optional[list[tuple[str, Value]]] = None):
        self.items: list[tuple[str, Value]] = list(items) if items else []

    # --- acces tip dict (prima apariție a cheii, case-insensitive) ---------
    def _find(self, key: str) -> int:
        lk = key.lower()
        for i, (k, _) in enumerate(self.items):
            if k.lower() == lk:
                return i
        return -1

    def __contains__(self, key: str) -> bool:
        return self._find(key) >= 0

    def __getitem__(self, key: str) -> Value:
        i = self._find(key)
        if i < 0:
            raise KeyError(key)
        return self.items[i][1]

    def get(self, key: str, default=None):
        i = self._find(key)
        return self.items[i][1] if i >= 0 else default

    def get_str(self, key: str, default: Optional[str] = None) -> Optional[str]:
        v = self.get(key)
        return v if isinstance(v, str) else default

    def get_kv(self, key: str) -> Optional["KV"]:
        v = self.get(key)
        return v if isinstance(v, KV) else None

    def __setitem__(self, key: str, value: Value) -> None:
        i = self._find(key)
        if i >= 0:
            self.items[i] = (self.items[i][0], value)
        else:
            self.items.append((key, value))

    def __delitem__(self, key: str) -> None:
        self.items = [(k, v) for k, v in self.items if k.lower() != key.lower()]

    def __iter__(self) -> Iterator[tuple[str, Value]]:
        return iter(self.items)

    def __len__(self) -> int:
        return len(self.items)

    def __bool__(self) -> bool:
        return True

    def keys(self) -> list[str]:
        return [k for k, _ in self.items]

    def blocks(self) -> Iterator[tuple[str, "KV"]]:
        for k, v in self.items:
            if isinstance(v, KV):
                yield k, v

    def scalars(self) -> Iterator[tuple[str, str]]:
        for k, v in self.items:
            if isinstance(v, str):
                yield k, v

    def merge(self, other: "KV") -> None:
        """Suprapune `other` peste self (semantica #base: valorile din fișierul
        curent câștigă, blocurile se îmbină recursiv)."""
        for k, v in other.items:
            if isinstance(v, KV):
                mine = self.get_kv(k)
                if mine is not None:
                    mine.merge(v)
                else:
                    self.items.append((k, v.copy()))
            else:
                if k not in self:
                    self.items.append((k, v))

    def copy(self) -> "KV":
        return KV([(k, v.copy() if isinstance(v, KV) else v) for k, v in self.items])

    def __repr__(self) -> str:
        return f"KV({self.items!r})"


# ---------------------------------------------------------------------------
# Tokenizer / parser
# ---------------------------------------------------------------------------

class _Tok:
    __slots__ = ("kind", "text", "line")

    def __init__(self, kind: str, text: str, line: int):
        self.kind = kind  # 'str' | '{' | '}' | 'cond' | 'eof'
        self.text = text
        self.line = line


def _tokenize(text: str) -> Iterator[_Tok]:
    i, n, line = 0, len(text), 1
    while i < n:
        c = text[i]
        if c == "\n":
            line += 1
            i += 1
        elif c in " \t\r﻿":
            i += 1
        elif c == "/" and i + 1 < n and text[i + 1] == "/":
            j = text.find("\n", i)
            i = n if j < 0 else j
        elif c == "{":
            yield _Tok("{", c, line)
            i += 1
        elif c == "}":
            yield _Tok("}", c, line)
            i += 1
        elif c == "[":
            j = text.find("]", i)
            if j < 0:
                raise SyntaxError(f"linia {line}: '[' fără ']'")
            yield _Tok("cond", text[i : j + 1], line)
            i = j + 1
        elif c == '"':
            j = i + 1
            buf = []
            while j < n and text[j] != '"':
                if text[j] == "\\" and j + 1 < n and text[j + 1] in '"\\':
                    # fișierele Valve nu folosesc escape-uri în mod normal; păstrăm literal
                    buf.append(text[j])
                    j += 1
                if text[j] == "\n":
                    line += 1
                buf.append(text[j])
                j += 1
            if j >= n:
                raise SyntaxError(f"linia {line}: șir neterminat")
            yield _Tok("str", "".join(buf), line)
            i = j + 1
        else:
            j = i
            while j < n and text[j] not in ' \t\r\n{}"[]' and not (text[j] == "/" and j + 1 < n and text[j + 1] == "/"):
                j += 1
            yield _Tok("str", text[i:j], line)
            i = j
    yield _Tok("eof", "", line)


def parse(text: str, base_dir: Optional[str] = None, follow_base: bool = True) -> KV:
    """Parsează un document KV complet (poate conține mai multe chei rădăcină)."""
    toks = _tokenize(text)
    root = KV()
    bases: list[str] = []

    def next_tok() -> _Tok:
        return next(toks)

    def parse_block(into: KV, terminator: str) -> None:
        while True:
            t = next_tok()
            if t.kind == terminator:
                return
            if t.kind == "cond":
                continue
            if t.kind != "str":
                raise SyntaxError(f"linia {t.line}: neașteptat {t.text!r}")
            key = t.text
            if key.lower() in ("#base", "#include") and into is root:
                v = next_tok()
                if v.kind != "str":
                    raise SyntaxError(f"linia {v.line}: #base fără cale")
                bases.append(v.text)
                continue
            v = next_tok()
            while v.kind == "cond":
                v = next_tok()
            if v.kind == "{":
                child = KV()
                parse_block(child, "}")
                into.items.append((key, child))
            elif v.kind == "str":
                into.items.append((key, v.text))
            else:
                raise SyntaxError(f"linia {v.line}: valoare lipsă pentru {key!r}")

    parse_block(root, "eof")

    if follow_base and bases and base_dir is not None:
        merged = KV()
        for b in bases:
            p = os.path.join(base_dir, b)
            if os.path.exists(p):
                merged.merge(load(p))
            else:
                print(f"[kv] avertisment: #base lipsă: {p}", file=sys.stderr)
        # fișierul curent are prioritate
        root_copy = root
        root = merged
        for k, v in root_copy.items:
            if isinstance(v, KV) and root.get_kv(k) is not None:
                # îmbinare: cheile din fișierul curent câștigă
                tmp = v.copy()
                tmp.merge(root.get_kv(k))
                root[k] = tmp
            else:
                root[k] = v
    return root


def load(path: str, follow_base: bool = True) -> KV:
    with open(path, "r", encoding="utf-8-sig", errors="replace") as f:
        text = f.read()
    return parse(text, os.path.dirname(os.path.abspath(path)), follow_base)


# ---------------------------------------------------------------------------
# Serializer
# ---------------------------------------------------------------------------

def _q(s: str) -> str:
    return '"' + s.replace('"', "'") + '"'


def dumps(kv: KV, indent: int = 0, comments: Optional[dict[str, str]] = None) -> str:
    """Serializează un KV în textul formatului Valve (tab-uri, chei cu ghilimele).

    `comments` – dict cheie -> comentariu, afișat deasupra cheii respective (doar la
    nivelul curent)."""
    out: list[str] = []
    pad = "\t" * indent
    for k, v in kv.items:
        if comments and k in comments:
            for line in comments[k].splitlines():
                out.append(f"{pad}// {line}")
        if isinstance(v, KV):
            out.append(f"{pad}{_q(k)}")
            out.append(f"{pad}{{")
            out.append(dumps(v, indent + 1))
            out.append(f"{pad}}}")
        else:
            out.append(f"{pad}{_q(k)}\t\t{_q(v)}")
    return "\n".join(out)


def dump_file(kv: KV, path: str, header: str = "") -> None:
    os.makedirs(os.path.dirname(os.path.abspath(path)), exist_ok=True)
    # UTF-8 cu BOM, ca fisierele Valve: fara BOM motorul respinge fisierele de localizare
    # ("LOCFAIL: Ignoring unsupported encoding") si poate esua la detectarea codificarii KV
    with open(path, "w", encoding="utf-8-sig", newline="\n") as f:
        if header:
            for line in header.splitlines():
                f.write(f"// {line}\n")
        f.write(dumps(kv))
        f.write("\n")


# ---------------------------------------------------------------------------
# Utilitare specifice Dota
# ---------------------------------------------------------------------------

def values_of(ability: KV) -> dict[str, str]:
    """Returnează {nume_special: valoare} indiferent dacă abilitatea folosește
    formatul vechi `AbilitySpecial` (6.88) sau cel nou `AbilityValues` (7.x)."""
    out: dict[str, str] = {}
    sp = ability.get_kv("AbilitySpecial")
    if sp is not None:
        for _, blk in sp.blocks():
            for k, v in blk.scalars():
                if k.lower() in ("var_type", "levelkey", "calculatespelldamagetooltip", "requiresscepter", "damagetypetooltip"):
                    continue
                out[k] = v
    av = ability.get_kv("AbilityValues")
    if av is not None:
        for k, v in av.items:
            if isinstance(v, KV):
                val = v.get_str("value")
                if val is not None:
                    out[k] = val
            else:
                out[k] = v
    return out


if __name__ == "__main__":
    # test rapid: round-trip pe un fișier
    if len(sys.argv) > 1:
        kv = load(sys.argv[1])
        print(dumps(kv)[:2000])
