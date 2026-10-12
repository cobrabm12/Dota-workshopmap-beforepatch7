# Roadmap

## Faza 1 – fundația (această versiune)
- [x] Date de referință 6.88f și curente
- [x] Parser KV + generator de override‑uri
- [x] Eroi (112), abilități, iteme, unități cu valori 6.88
- [x] Reguli de joc în Lua (aur, XP, respawn, buyback, rune, zi/noapte, Roshan, backpack, curier)
- [x] Documentație

## Faza 2 – testare în joc
- [ ] Instalare în Workshop Tools și pornire pe harta standard (`dota_launch_custom_game dota_688 dota`)
- [ ] Verificat: sloturile golite scot talentele/inatele; fațeta unică funcționează (7.36+); Attribute Bonus apare în HUD
- [ ] Verificat: filtrele de aur/XP, respawn, buyback, rune
- [ ] Verificat: itemele scoase din shop, curierul cumpărat, fără backpack
- [ ] Corectat ce nu merge (API‑urile marcate `Dota688SafeCall` pot lipsi)

## Faza 3 – abilități
- [x] Rescris în Lua cele 11 abilități dispărute (`docs/STATUS.md`)
- [x] Rescris în Lua abilitățile cu rework major (90+; lista în `docs/STATUS.md`)
- [x] Iteme cu mecanica 6.88 (64) + shop-ul 6.88
- [x] Override-uri manuale pentru mecanicile moderne ale abilităților păstrate built-in (`tools/manual_overrides.json`)
- [x] Trecut prin abilitățile cu „valori speciale dispărute”: 79 override-uri manuale + Lua; au rămas ~65 cu diferențe minore/Aghanim (`docs/STATUS.md`)
- [ ] Scos upgrade‑urile de Aghanim adăugate după 6.88 (sunt în C++; de verificat per erou)
- [ ] Invoker (Quas/Wex/Exort în 6.88 dădeau +2/4/…/14 pe instanță), Ogre Multicast, Medusa Split Shot – de verificat în joc

## Faza 4 – harta
- [ ] Construit `dota_688.vmap` în Hammer după `docs/HARTA.md`
- [ ] Side shop‑uri, secret shop‑uri, Roshan, rune, jungle, efigii

## Faza 5 – finisaje
- [x] Panorama: ascuns UI‑ul de talente/backpack/iteme neutre (ID-urile HUD de verificat la fiecare patch)
- [x] Panorama: panou cu regulile 6.88 (buton „6.88” sus, apare automat la start)
- [x] Timing neutrali 0:30 (încercare prin input pe `npc_dota_neutral_spawner`; de verificat în joc)
- [ ] Durate rune (Haste 25 s), viteză maximă 522, bounty iluzii
- [ ] Publicare în Workshop
