# Aghanim's Scepter – paritate cu 6.88

Scepter‑ul din addon este un item propriu, `item_dota688_ultimate_scepter` (+10 toate atributele, +175 HP,
+175 mana, rețeta 6.88: Point Booster + Staff of Wizardry + Ogre Axe + Blade of Alacrity = 4200). Itemul built‑in
nu mai este cumpărabil, deci upgrade‑urile moderne din C++ **nu** se mai activează de la sine: `HasScepter()` este fals
pentru toți eroii, cu excepția celor din lista „built‑in” de mai jos, cărora Lua le adaugă
`modifier_item_ultimate_scepter_consumed` cât timp țin itemul.

Logica: `scripts/vscripts/dota688/aghanim.lua` (listele `BUILTIN`, `GRANT`, `HOOKS`, `EXTRA`), extrasele în
`dota688/aghanim_extras.lua`, itemul în `scripts/vscripts/items/item_dota688_ultimate_scepter.lua`. Abilitățile
rescrise în Lua verifică singure `Dota688HasScepter(caster)` și citesc valorile `*_scepter` din KV‑ul 6.88.

Alchemist (ca în 6.86–6.88) poate folosi itemul pe un erou aliat: itemul dispare, iar aliatul primește permanent
upgrade‑urile lui de scepter (modifierul vizibil „Aghanim's Scepter (from Alchemist)”).

## Legenda

* **✅** – comportamentul 6.88 este reprodus (built‑in identic sau rescris în Lua).
* **✖** – nu se poate reproduce din Lua (logica este în C++); ce lipsește este notat.

## Tabel pe eroi (toți eroii care aveau upgrade în 6.88)

| Erou | Upgrade 6.88 | Stare | Implementare / note |
|---|---|---|---|
| Abaddon | Borrowed Time 5/6/7 s; 50 % din daunele aliaților din 900 sunt redirecționate la Abaddon | ✅ | Lua: `dota688_abaddon_borrowed_time` (auto‑activare sub 400 HP, purge, aură de redirecționare) |
| Alchemist | Dă scepter‑ul unui aliat | ✅ | itemul se aruncă pe aliat |
| Ancient Apparition | Frostbite 17 s | ✅ | Lua: `dota688_ancient_apparition_ice_blast` + `_release` (trasor, bulgăre, explozie care crește cu distanța) |
| Axe | Culling Blade: cd 6, prag 300/425/550, viteză 10 s | ✅ | Lua: `dota688_axe_culling_blade` |
| Bane | Fiend's Grip 7 s, 155/215/270 dps, 10 % mana; Nightmare pe cine atacă Bane | ✅ | Lua: `dota688_bane_fiends_grip` (Nightmare = `dota688_bane_nightmare`, Lua) |
| Batrider | Lasso prinde și cel mai apropiat erou aliat (400); 100 dps | ✅ | built‑in modern (al doilea erou) + 100 dps din `aghanim_extras` |
| Beastmaster | Primal Roar cd 45, rază 950 | ✅ | HOOKS (C++) |
| Bloodseeker | Rupture: 2 încărcături / 40 s | ✅ | Lua: `dota688_bloodseeker_rupture` (încărcături gestionate în Lua) |
| Brewmaster | Earth: Thunder Clap, Storm: Drunken Haze, Fire: Drunken Brawler | ✅ | `aghanim_extras`: brewlingii primesc abilitățile la nivelul lui Brewmaster când apar |
| Bristleback | Nasal Goo fără țintă, 700 | ✅ | Lua: `dota688_bristleback_viscous_nasal_goo` |
| Centaur | Stampede: 60 % reducere daune, trece prin copaci/dealuri | ✅ | Lua: `dota688_centaur_stampede` (flying pathing) |
| Chen | Holy Persuasion pe creepi Ancient (max = nivelul Hand of God) | ✅ | Lua: `dota688_chen_holy_persuasion` |
| Clockwerk | Hookshot cd 12 | ✅ | HOOKS (C++) |
| Crystal Maiden | Freezing Field 170/250/310, slow 50 % | ✅ | Lua: `dota688_crystal_maiden_freezing_field` |
| Dark Seer | Wall of Replica: iluzii cu 100/120/140 % daune | ✅ | Lua: `dota688_dark_seer_wall_of_replica` |
| Dazzle | Weave 775, 24 s, 1.25/1.5/1.75 armură/s | ✅ | Lua: `dota688_dazzle_weave` |
| Disruptor | Static Storm 7 s, 28 pulsuri, mute | ✅ | Lua: `dota688_disruptor_static_storm` |
| Doom | Doom 16 s, pauzat în 900 rază, purge + break | ✅ | Lua: `dota688_doom_bringer_doom` |
| Drow Ranger | Split shot: 2 unități din 375, 50 % daune | ✅ | Lua: `dota688_drow_ranger_marksmanship` |
| Earth Spirit | Enchant Remnant; Grip trage aliați | ✅ | built‑in (abilitate oferită de scepter) |
| Earthshaker | Enchant Totem: săritură 900 | ✅ | built‑in modern (950) |
| Elder Titan | Earth Splitter slow 4/5/6 s + disarm | ✅ | Lua: `dota688_elder_titan_earth_splitter` |
| Enchantress | Impetus +190 rază | ✅ | HOOKS (C++) |
| Enigma | Black Hole aplică Midnight Pulse | ✅ | Lua: `dota688_enigma_black_hole` |
| Faceless Void | Chronosphere cd 60 | ✅ | HOOKS (C++) |
| Gyrocopter | Side Gunner (atac aleator la 1.2 s în 600) | ✅ | `aghanim_extras` |
| Huskar | Life Break 65 % HP, cd 4 | ✅ | Lua: `dota688_huskar_life_break` |
| Invoker | Invoke cd 16/8/4/2 fără mana; +1 nivel la Q/W/E pe spell‑urile invocate | (de retestat) | Lua: `dota688_invoker_invoke` (cd/mana cu scepter); `aghanim_extras` ridică Quas/Wex/Exort cu un nivel cât timp are scepter (atributele orbelor rămân la nivelul de bază) |
| Jakiro | Macropyre 1800, 30 s, 125/175/225 dps | ✅ | Lua: `dota688_jakiro_macropyre` |
| Juggernaut | Omnislash 6/9/12 sărituri, cd 70 | ✅ | Lua: `dota688_juggernaut_omni_slash` |
| Keeper of the Light | Spirit Form permanent; ziua Illuminate vindecă aliații | ✅ | Lua: `dota688_keeper_of_the_light_spirit_form`; vindecarea este un val lansat la sfârșitul canalizării Illuminate, pe direcția și distanța undei originale |
| Kunkka | Ghostship trage inamicii cu corabia | ✅ | Lua: `dota688_kunkka_ghostship` (inclusiv Rum) |
| Legion Commander | Duel 6/7/8 s, cei doi iau daune doar unul de la altul | ✅ | Lua: `dota688_legion_commander_duel` |
| Leshrac | Pulse Nova 160/190/220 dps | ✅ | Lua: `dota688_leshrac_pulse_nova` |
| Lich | Chain Frost 370/460/550, rază 850, slow 50 %, sărituri nelimitate | ✅ | Lua: `dota688_lich_chain_frost` |
| Lifestealer | Assimilate | ✅ | abilitatea C++ deblocată din Lua (fără upgrade‑ul modern la Infest) |
| Lina | Laguna Blade pure, trece prin BKB | ✅ | Lua: `dota688_lina_laguna_blade` |
| Lion | Finger 725/875/1025, cd 100/60/20, mana 200/420/625, zonă 300 | ✅ | Lua: `dota688_lion_finger_of_death` |
| Lone Druid | Ursul atacă la orice distanță și supraviețuiește morții lui Lone Druid | (de testat) | Lua: `dota688_lone_druid_spirit_bear` (ursul 6.88 pe 4 niveluri, lesa 1100 și moartea odată cu druidul sunt acum în Lua, deci scepter‑ul le poate scoate) |
| Luna | Eclipse pe aliat/zonă, 6/12/18 raze la 0.3 s, fără limită pe unitate | ✅ | Lua: `dota688_luna_eclipse` (razele folosesc Lucent Beam la nivelul curent) |
| Magnus | Empower aură pe eroii aliați; cei la distanță jumătate + splash | ✅ | Lua: `dota688_magnataur_empower` |
| Meepo | Un Meepo în plus; clonele primesc 100 % din atributele bonus (în loc de 20 %) | ✅ | `aghanim_extras`: Divided We Stand nivel 4 (clona în plus moare la pierderea scepter‑ului); clonele primesc 20 %/100 % din atributele bonus ale lui Meepo printr‑un modifier care se autocorectează |
| Mirana | Starstorm pasiv la 10 s | ✅ | Lua: `dota688_mirana_starfall` |
| Morphling | Hybrid | ✅ | Lua: `dota688_morphling_hybrid` (copie a unui erou aliat cu abilitățile lui, 80 % daune, 20 s) |
| Naga Siren | Song of the Siren vindecă aliații 10 %/s | ✅ | Lua: `dota688_naga_siren_song_of_the_siren` + `_cancel` |
| Necrophos | Scythe cd 70, mana 150, 0.6/0.9/1.2 daune/HP, fără buyback | ✅ | Lua: `dota688_necrolyte_reapers_scythe` + `respawn_buyback.lua` |
| Night Stalker | Viziune neobstrucționată noaptea | ✅ | Lua: `dota688_night_stalker_darkness` |
| Nyx Assassin | Burrow | ✅ | built‑in (abilitate oferită de scepter) |
| Ogre Magi | Unrefined Fireblast (60 % mana) | (de retestat) | Lua: `dota688_ogre_magi_unrefined_fireblast` (deblocată de scepter, cu Multicast 6.88) |
| Omniknight | Guardian Angel 8/9/10 s, global, clădiri | ✅ | Lua: `dota688_omniknight_guardian_angel` |
| Oracle | Purifying Flames cd 1, cast point 0.1 | ✅ | Lua: `dota688_oracle_purifying_flames` |
| Outworld Devourer | Sanity's Eclipse aplică Astral Imprisonment | ✅ | Lua: `dota688_obsidian_destroyer_sanity_eclipse` (modifierul built‑in de Astral) |
| Phoenix | Supernova pe aliat, 7/10/13 atacuri | ✅ | built‑in modern |
| Puck | Dream Coil 8 s, 200/250/300, stun 1.5/3/4.5 prin BKB | ✅ | Lua: `dota688_puck_dream_coil` |
| Pudge | Meat Hook cd 4, 180/270/360/450 | ✅ | Lua: `dota688_pudge_meat_hook` |
| Pugna | Life Drain 180/240/300 /s, fără cooldown | ✅ | Lua: `dota688_pugna_life_drain` |
| Queen of Pain | Sonic Wave cd 40, 325/440/555 | ✅ | Lua: `dota688_queenofpain_sonic_wave` |
| Razor | Eye of the Storm 0.6/0.5/0.4 s, lovește clădiri | ✅ | Lua: `dota688_razor_eye_of_the_storm` |
| Rubick | Spell Steal cd 2, rază 1400, versiunea cu scepter a spell‑ului furat | ✅ | cd + rază (HOOKS); spell‑urile furate rescrise în Lua văd scepter‑ul lui Rubick direct, cele C++ cu upgrade built‑in primesc modifierul „consumed” cât timp sunt furate (`aghanim_extras`) |
| Sand King | Burrowstrike rază dublă + Caustic Finale pe eroi | ✅ | Lua: `dota688_sandking_burrowstrike` |
| Shadow Demon | Demonic Purge 3 încărcături / 40 s + break | ✅ | built‑in modern |
| Shadow Fiend | Requiem se întoarce (40 % daune, vindecă 100 %); +4/6/8/10 suflete | ✅ | Lua: `dota688_nevermore_requiem` + `dota688_nevermore_necromastery` |
| Shadow Shaman | Serpent Wards +45 daune | ✅ | `aghanim_extras` (modifier pe wards la spawn) |
| Silencer | Global Silence aplică Arcane Curse | ✅ | built‑in modern |
| Skywrath Mage | Mystic Flare cd 20/10/5, 12 s | ✅ | Lua: `dota688_skywrath_mage_mystic_flare` |
| Spirit Breaker | Nether Strike: bash în 250, cd 20, rază 850 | ✅ | Lua: `dota688_spirit_breaker_nether_strike` (Greater Bash aplicat din Lua cu valorile abilității) |
| Storm Spirit | Electric Vortex fără țintă, 475 | ✅ | Lua: `dota688_storm_spirit_electric_vortex` |
| Sven | God's Strength: +75/100/125 % daune aliaților din 900 | ✅ | `aghanim_extras` (aură) |
| Techies | Remote Mines 450/600/750, rază 700; Minefield Sign ascunde minele de True Sight | ✅ | Lua: `dota688_techies_remote_mines`, `dota688_techies_minefield_sign` |
| Tidehunter | Gush în linie, cd 7 | ✅ | built‑in modern |
| Timbersaw | A doua Chakram | ✅ | abilitatea C++ deblocată din Lua |
| Tinker | Laser se refractă; Missiles 4 ținte | ✅ | Lua: `dota688_tinker_laser`, `dota688_tinker_heat_seeking_missile` |
| Tiny | Copac: +85 rază, cleave 50 % în 400, +75 % la clădiri; Toss +50/65/80 % | ✅ | Lua: `dota688_tiny_grow` (copacul este atașat în mână), `dota688_tiny_toss` |
| Treant Protector | Eyes in the Forest; Overgrowth în 800 de fiecare ochi, 175 dps | ✅ | Lua: `dota688_treant_eyes_in_the_forest` (Overgrowth = modifierul built‑in + daune din Lua) |
| Tusk | Walrus Kick | ✅ | abilitatea C++ deblocată din Lua |
| Undying | Decay fură 10 STR | ✅ | built‑in modern |
| Ursa | Enrage cd 30/24/18; utilizabil și dezactivat | ✅ | cd (Lua); sub stun/hex, ordinul de cast este prins în filtrul de ordine și Enrage se aplică direct (`aghanim_extras`) |
| Vengeful Spirit | Nether Swap cd 10, pe non‑eroi; Vengeance Illusion la moarte | ✅ | Lua: `dota688_vengefulspirit_nether_swap`; „iluzia” este o copie a eroului cu abilitățile ei (fără iteme), 50 % daune date / 150 % primite, până la respawn |
| Venomancer | Poison Nova cd 140/120/60, 60/85/110 dps | ✅ | Lua: `dota688_venomancer_poison_nova` |
| Viper | Viper Strike mana 125, cd 10, rază 900 | ✅ | HOOKS (C++) |
| Visage | 3 familiari | ✅ | `aghanim_extras` (al treilea familiar creat după cast) |
| Warlock | 2 golemi cu −25 % statistici, −50 % bounty | ✅ | `aghanim_extras` (al doilea golem copiat din primul) |
| Weaver | Time Lapse pe aliat, cd 16 | ✅ | built‑in modern + HOOKS |
| Windranger | Focus Fire cd 15, reducere 30/15/0 % | ✅ | Lua: `dota688_windrunner_focusfire` |
| Winter Wyvern | Arctic Burn toggle | ✅ | built‑in modern |
| Witch Doctor | Death Ward sare între inamici | ✅ | built‑in modern |
| Wraith King | Reincarnation: Wraith Delay – aliații din 1200 devin spirite 7 s în loc să moară | (de testat) | Lua: `dota688_skeleton_king_reincarnation` |
| Zeus | Thundergod's Wrath 440/540/640 | ✅ | Lua: `dota688_zuus_thundergods_wrath` |

Eroii care **nu** aveau upgrade în 6.88 (Anti‑Mage, Phantom Lancer, Sniper, Riki, Slark, Medusa, Troll, Lycan, Spectre,
Death Prophet, Templar Assassin, Ember, Arc Warden, Underlord, Io, Chaos Knight, Broodmother, Bounty Hunter, Slardar,
Dragon Knight…) nu primesc nimic de la scepter în afară de statistici, exact ca în 6.88.

Bilanț: toate upgrade‑urile din 6.88 sunt reproduse (ursul lui Lone Druid a fost rescris în Lua pe PC‑ul de test); de (re)testat în joc: Invoker, Lone Druid, Ogre Magi, Wraith King (rândurile marcate).

## Note de implementare

* `HOOKS` aplică cooldown‑ul 6.88 imediat după cast (păstrând proporțional reducerile de cooldown, ex. Octarine),
  rambursează diferența de mana și dă bonus de cast range doar pentru abilitatea respectivă.
* Abilitățile „oferite de scepter” deblocate din Lua au în override `IsGrantedByScepter 0` (Recall are și
  `IsGrantedByShard 0`) și sunt ascunse/dezactivate cât timp eroul nu are scepter.
* Ultimate‑urile rescrise folosesc particulele și sunetele originale (verificate față de listarea clientului curent);
  `dota688/stun.lua` oferă stun/knockback generic.
* Încărcăturile (charges) adăugate după 6.88 la abilități care nu le aveau sunt scoase generic de generator.
* De verificat în joc (nu se poate offline): `modifier_item_ultimate_scepter_consumed` adăugat din Lua activează
  upgrade‑urile built‑in; `SetHidden/SetLevel` pe abilitățile deblocate; `GetBehavior` dinamic pe item pentru Alchemist;
  modifierii built‑in aplicați din Lua (Overgrowth, Astral Imprisonment, Nightmare); `SetCurrentAbilityCharges` la Rupture;
  filtrul de ordine primește ordinul de cast al unei unități stunate (Ursa); `CreateUnitByName` cu numele unui erou pentru copii (Venge, Morphling).
