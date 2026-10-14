# Roadmap

## Faza 1 – fundația (această versiune)
- [x] Date de referință 6.88f și curente
- [x] Parser KV + generator de override‑uri
- [x] Eroi (112), abilități, iteme, unități cu valori 6.88
- [x] Reguli de joc în Lua (aur, XP, respawn, buyback, rune, zi/noapte, Roshan, backpack, curier)
- [x] Documentație

## Faza 2 – testare în joc
- [x] Instalare în Workshop Tools și pornire pe harta 6.88 (`dota_launch_custom_game dota_688 dota_688`)
- [x] Verificat: sloturile golite scot talentele/inatele; fațeta unică funcționează (7.36+); Attribute Bonus apare în HUD (TEST_LOG §1)
- [x] Verificat: filtrele de aur/XP, respawn, buyback, rune (TEST_LOG §2, §7)
- [x] Verificat: itemele scoase din shop, fără backpack (curierul: excepție decisă, vezi README)
- [ ] Corectat ce nu merge (API‑urile marcate `Dota688SafeCall` pot lipsi)

## Faza 3 – abilități
- [x] Rescris în Lua cele 11 abilități dispărute (`docs/STATUS.md`)
- [x] Rescris în Lua abilitățile cu rework major (90+; lista în `docs/STATUS.md`)
- [x] Iteme cu mecanica 6.88 (64) + shop-ul 6.88
- [x] Override-uri manuale pentru mecanicile moderne ale abilităților păstrate built-in (`tools/manual_overrides.json`)
- [x] Trecut prin abilitățile cu „valori speciale dispărute”: 79 override-uri manuale + Lua; au rămas ~65 cu diferențe minore/Aghanim (`docs/STATUS.md`)
- [x] Aghanim's Scepter 6.88: item propriu, upgrade‑urile moderne nu se mai activează; upgrade‑urile 6.88 per erou (`docs/AGHANIM.md`)
- [x] Aghanim: ultimate‑urile cu upgrade în 6.88 rescrise în Lua (Hook, Chain Frost, Ghostship, Ice Blast, Requiem, Duel, Doom…) – inclusiv Invoker/Rubick/Ursa/Venge/Hybrid/Meepo; imposibil doar Lone Druid
- [ ] Invoker (Quas/Wex/Exort în 6.88 dădeau +2/4/…/14 pe nivelul orbului), Ogre Multicast, Medusa Split Shot – de verificat în joc

## Faza 4 – harta
- [x] Harta 6.88 importată și compilată (`docs/HARTA.md`, TEST_LOG §5)
- [x] Side shop‑uri, secret shop‑uri, Roshan, rune, jungle, efigii (TEST_LOG §5, §7)

## Faza 5 – finisaje
- [x] Panorama: ascuns UI‑ul de talente/backpack/iteme neutre (ID-urile HUD de verificat la fiecare patch)
- [x] Panorama: panou cu regulile 6.88 (buton „6.88” sus, apare automat la start)
- [x] Timing neutrali 0:30 (încercare prin input pe `npc_dota_neutral_spawner`; de verificat în joc)
- [x] Durate rune (Haste 25 s), bounty iluzii
- [ ] Viteză maximă 522 (motorul: 550, fără API)
- [x] Publicare în Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=3818931233 (2026‑10‑13; Workshop Tools → Asset Browser → Tools → Workshop Manager; imaginea: `content/dota_addons/dota_688/workshop/preview.jpg`)
