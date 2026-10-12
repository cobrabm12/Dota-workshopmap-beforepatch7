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
- [ ] Rescris în Lua cele 11 abilități dispărute (`docs/STATUS.md`)
- [ ] Trecut prin cele ~300 de abilități cu valori fără corespondent și rescris cele cu mecanici schimbate
  (prioritate: eroii reworkați după 6.88 – Techies, Lycan, Necrophos, Treant, Viper, Io, Lifestealer, Doom, Riki, Sniper…)
- [ ] Scos upgrade‑urile de Aghanim adăugate după 6.88
- [ ] Diffusal Blade nivel 2, Necronomicon, Poor Man's Shield, Iron Talon, Ring of Aquila – verificat că mai funcționează built‑in

## Faza 4 – harta
- [ ] Construit `dota_688.vmap` în Hammer după `docs/HARTA.md`
- [ ] Side shop‑uri, secret shop‑uri, Roshan, rune, jungle, efigii

## Faza 5 – finisaje
- [ ] Panorama: ascuns UI‑ul de talente/backpack/iteme neutre, ecran cu regulile
- [ ] Timing neutrali 0:30 + la fiecare minut
- [ ] Durate rune (Haste 25 s), viteză maximă 522, bounty iluzii
- [ ] Publicare în Workshop
