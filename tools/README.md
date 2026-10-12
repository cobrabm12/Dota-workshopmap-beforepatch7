# Unelte

* `kv.py` – parser/serializer pentru formatul Valve KeyValues (fără dependențe).
* `gen_overrides.py` – generatorul de override‑uri (vezi README‑ul principal).

## Actualizarea referinței „current”

Fișierele curente Valve se iau din repo‑ul public [SteamDatabase/GameTracking-Dota2](https://github.com/SteamDatabase/GameTracking-Dota2):

```
git clone --filter=blob:none --no-checkout https://github.com/SteamDatabase/GameTracking-Dota2 gt
cd gt
git show HEAD:game/dota/pak01_dir/scripts/npc/npc_abilities.txt > ../reference/current/npc_abilities.txt
git show HEAD:game/dota/pak01_dir/scripts/npc/items.txt         > ../reference/current/items.txt
git show HEAD:game/dota/pak01_dir/scripts/npc/npc_units.txt     > ../reference/current/npc_units.txt
git show HEAD:game/dota/pak01_dir/scripts/npc/npc_heroes.txt    > ../reference/current/npc_heroes.txt
for f in $(git ls-tree -r --name-only HEAD game/dota/pak01_dir/scripts/npc/heroes/); do
  git show HEAD:$f > ../reference/current/heroes/$(basename $f)
done
git log -1 --format='%H %ad' > ../reference/current/SOURCE_COMMIT.txt
```

Referința 6.88f vine din commit‑ul `6aa033b2` (11 dec 2016) al aceluiași repo – primul commit, exact
build‑ul 6.88f dinaintea lui 7.00 (12 dec 2016).

## Verificarea resurselor (particule/modele) și a localizării

`tools/check_addon.py` verifică și căile de particule/modele din Lua dacă există `build/pak01_listing.txt`
(nu este comis; se obține cu `git show HEAD:game/dota/pak01_dir.txt > build/pak01_listing.txt` din clona GameTracking-Dota2).
Numele evenimentelor de sunet (`EmitSound`) nu pot fi verificate offline (fișierele `.vsndevts` sunt compilate); un nume
greșit produce doar un avertisment în consolă, nu o eroare.

Localizarea se generează doar în engleză (jocul rămâne în engleză), din `reference/6.88f/dota_english.txt` + `resource/addon_english.base.txt`.
