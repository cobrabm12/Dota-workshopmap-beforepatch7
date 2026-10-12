# Aghanim's Scepter – paritate cu 6.88

Scepter‑ul din addon este un item propriu, `item_dota688_ultimate_scepter` (+10 toate atributele, +175 HP,
+175 mana, rețeta 6.88: Point Booster + Staff of Wizardry + Ogre Axe + Blade of Alacrity = 4200). Itemul built‑in
nu mai este cumpărabil, deci upgrade‑urile moderne din C++ **nu** se mai activează de la sine: `HasScepter()` este fals
pentru toți eroii, cu excepția celor din lista „built‑in” de mai jos, cărora Lua le adaugă
`modifier_item_ultimate_scepter_consumed` cât timp țin itemul.

Logica: `scripts/vscripts/dota688/aghanim.lua` (listele `BUILTIN`, `GRANT`, `HOOKS`), itemul în
`scripts/vscripts/items/item_dota688_ultimate_scepter.lua`. Abilitățile reimplementate în Lua verifică singure
`Dota688HasScepter(caster)`.

Alchemist (ca în 6.86–6.88) poate folosi itemul pe un erou aliat: itemul dispare, iar aliatul primește permanent
upgrade‑urile lui de scepter (modifierul vizibil „Aghanim's Scepter (from Alchemist)”).

## Legenda

* **✅ identic** – comportamentul 6.88 este reprodus (built‑in identic sau Lua).
* **≈ apropiat** – upgrade‑ul modern built‑in este folosit; diferă doar cifre/detalii față de 6.88 (notate).
* **◐ parțial** – doar partea reproductibilă din Lua (cooldown / mana / cast range / attack range); restul lipsește.
* **✖ lipsă** – upgrade‑ul 6.88 nu există în joc și nu se poate reproduce fără reimplementarea întregii abilități.

## Tabel pe eroi (toți eroii care aveau upgrade în 6.88)

| Erou | Upgrade 6.88 | Stare | Cum / ce lipsește |
|---|---|---|---|
| Abaddon | Borrowed Time 5/6/7 s, 50 % din daunele aliaților din 900 sunt redirecționate la Abaddon | ≈ apropiat | built‑in modern (durată mărită + Mist Coil automat pe aliații loviți, în loc de redirecționare) |
| Alchemist | Dă scepter‑ul unui aliat | ✅ identic | itemul se aruncă pe aliat (Lua) |
| Ancient Apparition | Frostbite 17 s la Ice Blast | ✖ lipsă | – |
| Axe | Culling Blade: cd 6, prag 300/425/550, viteză 10 s | ◐ parțial | cooldown 6 (Lua); pragul și durata vitezei sunt în C++ |
| Bane | Fiend's Grip: 155/215/270 dps, 10 % mana, 7 s, Nightmare pe atacatori | ✖ lipsă | modernul face iluzii – nu se folosește |
| Batrider | Lasso prinde și cel mai apropiat erou aliat (400), 100 dps | ≈ apropiat | built‑in modern (fără cele 100 dps) |
| Beastmaster | Primal Roar: cd 45, rază 950 | ✅ identic | Lua (HOOKS) |
| Bloodseeker | Rupture: 2 încărcături / 40 s | ≈ apropiat | built‑in modern (încărcături + daune inițiale mărite) |
| Brewmaster | Earth: Thunder Clap, Storm: Drunken Haze, Fire: Drunken Brawler | ✖ lipsă | modernul dă +nivel la Primal Split – nu se folosește |
| Bristleback | Nasal Goo fără țintă, 700 rază | ✖ lipsă | – |
| Centaur | Stampede: 60 % reducere daune, trece prin copaci/dealuri | ✖ lipsă | – |
| Chen | Holy Persuasion pe creepi Ancient | ✖ lipsă | – |
| Clockwerk | Hookshot cd 12 | ✅ identic | Lua (HOOKS) |
| Crystal Maiden | Freezing Field 170/250/310 daune, slow 50 % | ✖ lipsă | modernul permite mișcarea – nu se folosește |
| Dark Seer | Wall of Replica: iluzii cu +20/40 % daune | ✖ lipsă | – |
| Dazzle | Weave rază 775, 24 s, 1.25/1.5/1.75 armură/s | ✖ lipsă | – |
| Disruptor | Static Storm 7 s + mute la iteme | ≈ apropiat | built‑in modern (mute; durata este cea modernă) |
| Doom | Doom 16 s, pauzează durata în 900 rază, purge + break | ✖ lipsă | modernul aplică break + Doom în zonă – nu se folosește |
| Drow Ranger | Marksmanship: atacurile lovesc încă 2 unități din 375 cu 50 % daune | ✅ identic | Lua |
| Earth Spirit | Enchant Remnant (abilitate nouă), Grip trage aliați | ✅ identic | built‑in (abilitate oferită de scepter) |
| Earthshaker | Enchant Totem: săritură 900 | ✅ identic | built‑in modern (950) |
| Elder Titan | Earth Splitter slow 4/5/6 s + disarm | ✖ lipsă | – |
| Enchantress | Impetus: +190 rază de atac și cast | ✅ identic | Lua (HOOKS) |
| Enigma | Black Hole aplică Midnight Pulse | ✅ identic | Lua |
| Faceless Void | Chronosphere cd 60 | ✅ identic | Lua (HOOKS) |
| Gyrocopter | Side Gunner (atac aleator la 1.2 s în 600) | ✖ lipsă | – |
| Huskar | Life Break 65 % HP, cd 4 | ◐ parțial | cd 4 (Lua); procentul e în C++ |
| Invoker | Invoke cd 16/8/4/2 fără mana, +1 nivel la Q/W/E pe spell‑urile invocate | ◐ parțial | cd + mana 0 (Lua); +1 nivel lipsă |
| Jakiro | Macropyre mai lung (1800), 30 s, 125/175/225 dps | ✖ lipsă | modernul face daune pure + ziduri de gheață – nu se folosește |
| Juggernaut | Omnislash 6/9/12 sărituri, cd 70 | ✅ identic | Lua |
| Keeper of the Light | Spirit Form permanent, Illuminate vindecă | ✖ lipsă | – |
| Kunkka | Ghostship trage inamicii cu corabia | ✖ lipsă | modernul face flotă – nu se folosește |
| Legion Commander | Duel 6/7/8 s, cei doi iau daune doar unul de la altul | ✖ lipsă | – |
| Leshrac | Pulse Nova 160/190/220 dps | ✖ lipsă | – |
| Lich | Chain Frost 370/460/550, rază 850, sărituri nelimitate | ◐ parțial | rază 850 (Lua); daunele/sărituri în C++ |
| Lifestealer | Assimilate (abilitate nouă) | ✅ identic | deblocată din Lua (fără upgrade‑ul modern la Infest) |
| Lina | Laguna Blade: daune pure, trece prin BKB | ✖ lipsă | – |
| Lion | Finger 725/875/1025, cd 100/60/20, mana 200/420/625, zonă 300 | ≈ apropiat | built‑in modern (zonă) + cd/mana 6.88 (Lua); daunele sunt cele moderne |
| Lone Druid | Ursul atacă la orice distanță și supraviețuiește morții lui Lone Druid | ✖ lipsă | – |
| Luna | Eclipse pe aliat/zonă, 6/12/18 raze la 0.3 s | ≈ apropiat | built‑in modern (aproape identic; durata totală diferă) |
| Magnus | Empower devine aură pe eroii aliați; cei la distanță jumătate + splash | ✅ identic | Lua (rază 900) |
| Meepo | Un Meepo în plus, 100 % din atribute | ✖ lipsă | – |
| Mirana | Starstorm pasiv la 10 s | ✖ lipsă | – |
| Morphling | Hybrid (abilitate nouă) | ✅ identic* | deblocată din Lua; *abilitatea C++ veche – de testat în joc |
| Naga Siren | Song of the Siren vindecă 10 %/s | ✖ lipsă | – |
| Necrophos | Reaper's Scythe cd 70, mana 150 lvl1, 0.6/0.9/1.2 daune/HP, fără buyback | ◐ parțial | cd, mana și „fără buyback” (Lua); multiplicatorul e în C++ |
| Night Stalker | Viziune neobstrucționată noaptea | ✅ identic | Lua (viziune de zbor pe timp de noapte) |
| Nyx Assassin | Burrow (abilitate nouă) | ✅ identic | built‑in (abilitate oferită de scepter) |
| Ogre Magi | Unrefined Fireblast (abilitate nouă, 60 % mana) | ✅ identic | deblocată din Lua |
| Omniknight | Guardian Angel 8/9/10 s, global, clădiri | ≈ apropiat | built‑in modern (global + clădiri + vindecare amplificată; durata modernă) |
| Oracle | Purifying Flames cd 1, cast point 0.1 | ◐ parțial | cd 1 (Lua) |
| Outworld Devourer | Sanity's Eclipse aplică Astral Imprisonment | ✖ lipsă | – |
| Phoenix | Supernova pe aliat, 7/10/13 atacuri | ✅ identic | built‑in modern |
| Puck | Dream Coil 8 s, 200/250/300 daune, stun 1.5/3/4.5 prin BKB | ✖ lipsă | modernul atacă țintele – nu se folosește |
| Pudge | Meat Hook cd 4, 180/270/360/450 daune | ◐ parțial | cd 4 (Lua); daunele în C++ |
| Pugna | Life Drain 180/240/300 /s, fără cooldown | ◐ parțial | fără cooldown (Lua); drenajul e în C++ |
| Queen of Pain | Sonic Wave cd 40, 325/440/555 | ◐ parțial | cd 40 (Lua) |
| Razor | Eye of the Storm lovește mai des și lovește clădiri | ≈ apropiat | built‑in modern (2 ținte în loc de interval mai mic; lovește clădiri) |
| Rubick | Spell Steal cd 2, rază 1400, versiunea cu scepter a spell‑ului | ◐ parțial | cd + rază (Lua); versiunea cu scepter a spell‑ului furat depinde de C++ |
| Sand King | Burrowstrike rază dublă + Caustic Finale pe eroi | ◐ parțial | rază 700/900/1100/1300 (Lua) |
| Shadow Demon | Demonic Purge 3 încărcături / 40 s + break | ✅ identic | built‑in modern |
| Shadow Fiend | Requiem se întoarce (40 % daune, vindecă 100 %), +10 suflete | ≈ apropiat | built‑in modern (valul de întoarcere vindecă; cd redus); sufletele în plus lipsesc |
| Shadow Shaman | Serpent Wards 85–90/105–110/125–130 | ✖ lipsă | – |
| Silencer | Global Silence aplică Arcane Curse | ✅ identic | built‑in modern |
| Skywrath Mage | Mystic Flare cd 20/10/5, 12 s | ◐ parțial | cd (Lua); durata în C++ |
| Spirit Breaker | Nether Strike: bash în 250, cd 20, rază 850 | ◐ parțial | cd + rază (Lua); bash‑ul în zonă lipsește |
| Storm Spirit | Electric Vortex fără țintă, 475 rază | ✅ identic | Lua |
| Sven | God's Strength: +75/100/125 daune aliaților din 900 | ✖ lipsă | – |
| Techies | Remote Mines 450/600/750, rază de plantare 700; Minefield Sign ascunde minele de True Sight | ◐ parțial | Remote Mines (Lua); Minefield Sign lipsă |
| Tidehunter | Gush în linie, cd 7 | ✅ identic | built‑in modern |
| Timbersaw | A doua Chakram | ✅ identic | deblocată din Lua (fără upgrade‑ul modern la Reactive Armor) |
| Tinker | Laser se refractă; Missiles 4 ținte | ◐ parțial | rază 650 la Laser (Lua); refracția și țintele în plus lipsesc |
| Tiny | Copac: +85 rază, cleave 50 % în 400, +75 % la clădiri, Toss +50/65/80 % | ◐ parțial | rază, cleave, clădiri (Lua); bonusul la Toss e în C++; fără modelul cu copac |
| Treant Protector | Eyes in the Forest (abilitate nouă); Overgrowth lângă ochi face 175 dps | ◐ parțial | Eyes deblocat din Lua; Overgrowth lângă ochi lipsă |
| Tusk | Walrus Kick (abilitate nouă) | ✅ identic | deblocată din Lua |
| Undying | Decay fură 10 STR | ✅ identic | built‑in modern |
| Ursa | Enrage cd 30/24/18, utilizabil și dezactivat | ◐ parțial | cd (Lua); folosirea sub stun nu se poate din Lua |
| Vengeful Spirit | Nether Swap cd 10, pe non‑eroi, iluzie la moarte | ◐ parțial | cd 10 (Lua) |
| Venomancer | Poison Nova cd 140/120/60, 16 s, 60/85/110 dps | ◐ parțial | cd (Lua) |
| Viper | Viper Strike mana 125, cd 10, rază 900 | ✅ identic | Lua (HOOKS) |
| Visage | 3 familiari | ✖ lipsă | – |
| Warlock | 2 golemi cu statistici reduse | ≈ apropiat | built‑in modern (2 golemi cu statistici normale) |
| Weaver | Time Lapse pe aliat, cd 16 | ✅ identic | built‑in modern + cd 16 (Lua) |
| Windranger | Focus Fire cd 15, reducere 30/15/0 % | ◐ parțial | cd 15 (Lua) |
| Winter Wyvern | Arctic Burn toggle | ✅ identic | built‑in modern |
| Witch Doctor | Death Ward sare între inamici | ✅ identic | built‑in modern |
| Zeus | Thundergod's Wrath 440/540/640 | ✖ lipsă | – |

Eroii care **nu** aveau upgrade în 6.88 (Anti‑Mage, Phantom Lancer, Sniper, Riki, Slark, Medusa, Troll, Lycan, Spectre,
Death Prophet, Templar Assassin, Ember, Arc Warden, Underlord, Io, Chaos Knight, Broodmother, Bounty Hunter, Slardar,
Dragon Knight, Antimage…) nu primesc nimic de la scepter în afară de statistici, exact ca în 6.88.

## Note de implementare

* `HOOKS` aplică cooldown‑ul 6.88 imediat după cast (păstrând proporțional reducerile de cooldown, ex. Octarine),
  rambursează diferența de mana și dă bonus de cast range doar pentru abilitatea respectivă
  (`GetModifierCastRangeBonusStacking` primește abilitatea în `params`).
* Abilitățile „oferite de scepter” deblocate din Lua au în override `IsGrantedByScepter 0` (resp. `IsGrantedByShard 0`
  pentru Eyes in the Forest) și sunt ascunse/dezactivate cât timp eroul nu are scepter.
* Încărcăturile (charges) adăugate după 6.88 la abilități care nu le aveau sunt scoase generic de generator
  (`AbilityCharges 0`): Leap, Toss, Phantom Strike, Curse of the Silent, Disruption, Eyes in the Forest.
* De verificat în joc (nu se poate offline): `modifier_item_ultimate_scepter_consumed` adăugat din Lua activează
  upgrade‑urile built‑in; `SetHidden/SetLevel` pe abilitățile deblocate; `GetBehavior` dinamic pe item pentru Alchemist.
