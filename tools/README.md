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
Numele evenimentelor de sunet din Lua (`EmitSound*`, `StopSound`, `StartSoundEvent*`...) se verifică față de
`build/sound_events.txt` (nu este comis), generat cu `python tools/dump_sound_events.py`: extrage (doar citire) toate
`soundevents/*.vsndevts_c` din `game/dota/pak01_dir.vpk` și `game/core/pak01_dir.vpk` cu Source2Viewer-CLI în
`C:\dota688_depot\sounds\` și listează evenimentele. Se regenerează după fiecare patch Dota. Un nume care nu există nici
în client, nici în `content/dota_addons/dota_688/soundevents/dota688_sounds.vsndevts` este eroare (abilitatea ar fi mută).
Evenimentele scoase/redenumite în 7.x se definesc în `dota688_sounds.vsndevts` cu numele vechi (copiate din evenimentul
modern care folosește același fișier audio), apoi fișierul se compilează:
`resourcecompiler.exe -nop4 -i "<dota 2 beta>\content\dota_addons\dota_688\soundevents\dota688_sounds.vsndevts"`.

Localizarea se generează doar în engleză (jocul rămâne în engleză), din `reference/6.88f/dota_english.txt` + `resource/addon_english.base.txt`.
