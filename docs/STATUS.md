# STATUS – maparea 6.88f peste motorul curent

_Generat automat de `tools/gen_overrides.py`. Nu edita manual._

## Eroi

* Eroi din 6.88f activați: **112**
* Eroi apăruți după 6.88 (dezactivați): **15** – dark_willow, dawnbreaker, grimstroke, hoodwink, kez, largo, marci, mars, monkey_king, muerta, pangolier, primal_beast, ringmaster, snapfire, void_spirit
* Eroi cu toate abilitățile mapate (built‑in sau Lua): **112/112**

| Erou | OK (built‑in) | Lua (custom) | Lipsă → fallback la abilitatea curentă |
|---|---|---|---|
| antimage | 4 | 0 | — |
| axe | 2 | 2 | — |
| bane | 1 | 4 | — |
| bloodseeker | 1 | 3 | — |
| crystal_maiden | 2 | 2 | — |
| drow_ranger | 2 | 2 | — |
| earthshaker | 4 | 0 | — |
| juggernaut | 3 | 1 | — |
| mirana | 2 | 2 | — |
| nevermore | 4 | 2 | — |
| morphling | 3 | 5 | — |
| phantom_lancer | 4 | 0 | — |
| puck | 4 | 1 | — |
| pudge | 2 | 2 | — |
| razor | 2 | 2 | — |
| sand_king | 1 | 3 | — |
| storm_spirit | 3 | 1 | — |
| sven | 3 | 1 | — |
| tiny | 1 | 3 | — |
| vengefulspirit | 2 | 2 | — |
| windrunner | 2 | 2 | — |
| zuus | 2 | 2 | — |
| kunkka | 4 | 1 | — |
| lina | 2 | 2 | — |
| lich | 2 | 2 | — |
| lion | 3 | 1 | — |
| shadow_shaman | 4 | 0 | — |
| slardar | 2 | 2 | — |
| tidehunter | 3 | 1 | — |
| witch_doctor | 4 | 0 | — |
| riki | 0 | 4 | — |
| enigma | 1 | 3 | — |
| tinker | 1 | 3 | — |
| sniper | 2 | 2 | — |
| necrolyte | 2 | 2 | — |
| warlock | 4 | 0 | — |
| beastmaster | 2 | 3 | — |
| queenofpain | 3 | 1 | — |
| venomancer | 3 | 1 | — |
| faceless_void | 2 | 2 | — |
| skeleton_king | 1 | 3 | — |
| death_prophet | 3 | 1 | — |
| phantom_assassin | 2 | 2 | — |
| pugna | 2 | 2 | — |
| templar_assassin | 5 | 0 | — |
| viper | 2 | 2 | — |
| luna | 2 | 2 | — |
| dragon_knight | 3 | 1 | — |
| dazzle | 2 | 2 | — |
| rattletrap | 4 | 0 | — |
| leshrac | 3 | 1 | — |
| furion | 4 | 0 | — |
| life_stealer | 6 | 2 | — |
| dark_seer | 3 | 1 | — |
| clinkz | 2 | 2 | — |
| omniknight | 1 | 3 | — |
| enchantress | 4 | 0 | — |
| huskar | 2 | 2 | — |
| night_stalker | 1 | 3 | — |
| broodmother | 3 | 1 | — |
| bounty_hunter | 0 | 4 | — |
| weaver | 4 | 0 | — |
| jakiro | 3 | 1 | — |
| batrider | 4 | 0 | — |
| chen | 2 | 3 | — |
| spectre | 5 | 0 | — |
| doom_bringer | 5 | 1 | — |
| ancient_apparition | 2 | 3 | — |
| ursa | 3 | 1 | — |
| spirit_breaker | 2 | 2 | — |
| gyrocopter | 3 | 1 | — |
| alchemist | 4 | 1 | — |
| invoker | 15 | 1 | — |
| silencer | 2 | 2 | — |
| obsidian_destroyer | 1 | 3 | — |
| lycan | 2 | 2 | — |
| brewmaster | 2 | 2 | — |
| shadow_demon | 4 | 1 | — |
| lone_druid | 2 | 4 | — |
| chaos_knight | 2 | 2 | — |
| meepo | 3 | 1 | — |
| treant | 1 | 4 | — |
| ogre_magi | 0 | 5 | — |
| undying | 3 | 1 | — |
| rubick | 8 | 2 | — |
| disruptor | 3 | 1 | — |
| nyx_assassin | 5 | 1 | — |
| naga_siren | 2 | 3 | — |
| keeper_of_the_light | 6 | 3 | — |
| wisp | 6 | 1 | — |
| visage | 3 | 1 | — |
| slark | 2 | 2 | — |
| medusa | 3 | 1 | — |
| troll_warlord | 3 | 2 | — |
| centaur | 2 | 2 | — |
| magnataur | 3 | 1 | — |
| shredder | 7 | 0 | — |
| bristleback | 2 | 2 | — |
| tusk | 5 | 1 | — |
| skywrath_mage | 3 | 1 | — |
| abaddon | 2 | 2 | — |
| elder_titan | 4 | 1 | — |
| legion_commander | 0 | 4 | — |
| ember_spirit | 5 | 0 | — |
| earth_spirit | 6 | 0 | — |
| terrorblade | 3 | 1 | — |
| phoenix | 8 | 0 | — |
| oracle | 3 | 1 | — |
| techies | 0 | 6 | — |
| winter_wyvern | 4 | 0 | — |
| arc_warden | 4 | 0 | — |
| abyssal_underlord | 5 | 0 | — |

## Reimplementate în Lua (6.88 fidel)

* Abilități de erou: **193** – `abaddon_borrowed_time`, `abaddon_frostmourne`, `alchemist_goblins_greed`, `ancient_apparition_chilling_touch`, `ancient_apparition_ice_blast`, `ancient_apparition_ice_blast_release`, `attribute_bonus`, `axe_counter_helix`, `axe_culling_blade`, `bane_enfeeble`, `bane_fiends_grip`, `bane_nightmare`, `bane_nightmare_end`, `beastmaster_call_of_the_wild`, `beastmaster_call_of_the_wild_boar`, `beastmaster_inner_beast`, `bloodseeker_bloodrage`, `bloodseeker_rupture`, `bloodseeker_thirst`, `bounty_hunter_jinada`, `bounty_hunter_shuriken_toss`, `bounty_hunter_track`, `bounty_hunter_wind_walk`, `brewmaster_drunken_brawler`, `brewmaster_drunken_haze`, `bristleback_viscous_nasal_goo`, `bristleback_warpath`, `broodmother_spin_web`, `broodmother_spin_web_destroy`, `centaur_return`, `centaur_stampede`, `chaos_knight_chaos_strike`, `chaos_knight_reality_rift`, `chen_holy_persuasion`, `chen_penitence`, `chen_test_of_faith`, `clinkz_death_pact`, `clinkz_strafe`, `crystal_maiden_brilliance_aura`, `crystal_maiden_freezing_field`, `dark_seer_wall_of_replica`, `dazzle_poison_touch`, `dazzle_weave`, `death_prophet_silence`, `death_prophet_witchcraft`, `disruptor_static_storm`, `doom_bringer_doom`, `dragon_knight_dragon_blood`, `drow_ranger_marksmanship`, `drow_ranger_trueshot`, `elder_titan_earth_splitter`, `enigma_black_hole`, `enigma_demonic_conversion`, `enigma_midnight_pulse`, `faceless_void_time_dilation`, `faceless_void_time_lock`, `gyrocopter_call_down`, `huskar_berserkers_blood`, `huskar_life_break`, `invoker_attribute_bonus`, `invoker_invoke`, `jakiro_macropyre`, `juggernaut_omni_slash`, `keeper_of_the_light_blinding_light`, `keeper_of_the_light_chakra_magic`, `keeper_of_the_light_spirit_form`, `kunkka_ghostship`, `legion_commander_duel`, `legion_commander_moment_of_courage`, `legion_commander_overwhelming_odds`, `legion_commander_press_the_attack`, `leshrac_pulse_nova`, `lich_chain_frost`, `lich_dark_ritual`, `life_stealer_feast`, `life_stealer_rage`, `lina_fiery_soul`, `lina_laguna_blade`, `lion_finger_of_death`, `lone_druid_spirit_bear`, `lone_druid_spirit_bear_demolish`, `lone_druid_spirit_bear_entangle`, `lone_druid_spirit_bear_return`, `lone_druid_true_form`, `lone_druid_true_form_battle_cry`, `lone_druid_true_form_druid`, `luna_eclipse`, `luna_lunar_blessing`, `lycan_feral_impulse`, `lycan_howl`, `magnataur_empower`, `medusa_mana_shield`, `meepo_geostrike`, `mirana_leap`, `mirana_starfall`, `morphling_adaptive_strike`, `morphling_hybrid`, `morphling_morph`, `morphling_morph_replicate`, `morphling_replicate`, `naga_siren_rip_tide`, `naga_siren_song_of_the_siren`, `naga_siren_song_of_the_siren_cancel`, `necrolyte_reapers_scythe`, `necrolyte_sadist`, `nevermore_necromastery`, `nevermore_requiem`, `night_stalker_crippling_fear`, `night_stalker_darkness`, `night_stalker_hunter_in_the_night`, `nyx_assassin_mana_burn`, `obsidian_destroyer_arcane_orb`, `obsidian_destroyer_essence_aura`, `obsidian_destroyer_sanity_eclipse`, `ogre_magi_bloodlust`, `ogre_magi_fireblast`, `ogre_magi_ignite`, `ogre_magi_multicast`, `ogre_magi_unrefined_fireblast`, `omniknight_degen_aura`, `omniknight_guardian_angel`, `omniknight_repel`, `oracle_purifying_flames`, `phantom_assassin_blur`, `phantom_assassin_coup_de_grace`, `puck_dream_coil`, `pudge_flesh_heap`, `pudge_meat_hook`, `pugna_decrepify`, `pugna_life_drain`, `queenofpain_sonic_wave`, `razor_eye_of_the_storm`, `razor_unstable_current`, `riki_blink_strike`, `riki_permanent_invisibility`, `riki_smoke_screen`, `riki_tricks_of_the_trade`, `rubick_fade_bolt`, `rubick_null_field`, `sandking_burrowstrike`, `sandking_caustic_finale`, `sandking_sand_storm`, `shadow_demon_soul_catcher`, `silencer_glaives_of_wisdom`, `silencer_last_word`, `skeleton_king_mortal_strike`, `skeleton_king_reincarnation`, `skeleton_king_vampiric_aura`, `skywrath_mage_mystic_flare`, `slardar_bash`, `slardar_sprint`, `slark_essence_shift`, `slark_shadow_dance`, `sniper_assassinate`, `sniper_take_aim`, `spirit_breaker_empowering_haste`, `spirit_breaker_nether_strike`, `storm_spirit_electric_vortex`, `sven_warcry`, `techies_focused_detonate`, `techies_land_mines`, `techies_minefield_sign`, `techies_remote_mines`, `techies_stasis_trap`, `techies_suicide`, `terrorblade_reflection`, `tidehunter_anchor_smash`, `tinker_heat_seeking_missile`, `tinker_laser`, `tinker_rearm`, `tiny_craggy_exterior`, `tiny_grow`, `tiny_toss`, `treant_eyes_in_the_forest`, `treant_leech_seed`, `treant_living_armor`, `treant_natures_guise`, `troll_warlord_battle_trance`, `troll_warlord_berserkers_rage`, `tusk_walrus_punch`, `undying_flesh_golem`, `ursa_enrage`, `vengefulspirit_command_aura`, `vengefulspirit_nether_swap`, `venomancer_poison_nova`, `viper_nethertoxin`, `viper_poison_attack`, `visage_gravekeepers_cloak`, `windrunner_focusfire`, `windrunner_windrun`, `wisp_overcharge`, `zuus_static_field`, `zuus_thundergods_wrath`
* Iteme: **142** – `item_abyssal_blade`, `item_aether_lens`, `item_ancient_janggo`, `item_armlet`, `item_bfury`, `item_blight_stone`, `item_bloodstone`, `item_bloodthorn`, `item_buckler`, `item_butterfly`, `item_crimson_guard`, `item_dagon`, `item_dagon_2`, `item_dagon_3`, `item_dagon_4`, `item_dagon_5`, `item_desolator`, `item_diffusal_blade`, `item_diffusal_blade_2`, `item_dust`, `item_echo_sabre`, `item_ethereal_blade`, `item_force_staff`, `item_glimmer_cape`, `item_guardian_greaves`, `item_hand_of_midas`, `item_headdress`, `item_heart`, `item_heavens_halberd`, `item_helm_of_the_dominator`, `item_hurricane_pike`, `item_iron_talon`, `item_javelin`, `item_lifesteal`, `item_lotus_orb`, `item_manta`, `item_mask_of_madness`, `item_medallion_of_courage`, `item_mekansm`, `item_monkey_king_bar`, `item_null_talisman`, `item_oblivion_staff`, `item_octarine_core`, `item_orb_of_venom`, `item_pers`, `item_phase_boots`, `item_pipe`, `item_power_treads`, `item_quelling_blade`, `item_rapier`, `item_recipe_abyssal_blade`, `item_recipe_aether_lens`, `item_recipe_ancient_janggo`, `item_recipe_armlet`, `item_recipe_bfury`, `item_recipe_bloodstone`, `item_recipe_bloodthorn`, `item_recipe_buckler`, `item_recipe_butterfly`, `item_recipe_crimson_guard`, `item_recipe_dagon`, `item_recipe_dagon_2`, `item_recipe_dagon_3`, `item_recipe_dagon_4`, `item_recipe_dagon_5`, `item_recipe_desolator`, `item_recipe_diffusal_blade`, `item_recipe_diffusal_blade_2`, `item_recipe_echo_sabre`, `item_recipe_ethereal_blade`, `item_recipe_force_staff`, `item_recipe_glimmer_cape`, `item_recipe_guardian_greaves`, `item_recipe_hand_of_midas`, `item_recipe_headdress`, `item_recipe_heart`, `item_recipe_heavens_halberd`, `item_recipe_helm_of_the_dominator`, `item_recipe_hurricane_pike`, `item_recipe_iron_talon`, `item_recipe_lotus_orb`, `item_recipe_manta`, `item_recipe_mask_of_madness`, `item_recipe_medallion_of_courage`, `item_recipe_mekansm`, `item_recipe_monkey_king_bar`, `item_recipe_null_talisman`, `item_recipe_oblivion_staff`, `item_recipe_octarine_core`, `item_recipe_pers`, `item_recipe_phase_boots`, `item_recipe_pipe`, `item_recipe_power_treads`, `item_recipe_rapier`, `item_recipe_ring_of_aquila`, `item_recipe_ring_of_basilius`, `item_recipe_rod_of_atos`, `item_recipe_sange`, `item_recipe_sange_and_yasha`, `item_recipe_satanic`, `item_recipe_sheepstick`, `item_recipe_shivas_guard`, `item_recipe_silver_edge`, `item_recipe_skadi`, `item_recipe_solar_crest`, `item_recipe_soul_booster`, `item_recipe_soul_ring`, `item_recipe_sphere`, `item_recipe_tranquil_boots`, `item_recipe_travel_boots`, `item_recipe_travel_boots_2`, `item_recipe_ultimate_scepter`, `item_recipe_urn_of_shadows`, `item_recipe_veil_of_discord`, `item_recipe_vladmir`, `item_recipe_wraith_band`, `item_ring_of_aquila`, `item_ring_of_basilius`, `item_rod_of_atos`, `item_sange`, `item_sange_and_yasha`, `item_satanic`, `item_shadow_amulet`, `item_sheepstick`, `item_shivas_guard`, `item_silver_edge`, `item_skadi`, `item_solar_crest`, `item_soul_booster`, `item_soul_ring`, `item_sphere`, `item_tango`, `item_tango_single`, `item_tranquil_boots`, `item_travel_boots`, `item_travel_boots_2`, `item_ultimate_scepter`, `item_urn_of_shadows`, `item_veil_of_discord`, `item_vladmir`, `item_wind_lace`, `item_wraith_band`

## Abilități de erou care nu mai există în joc (trebuie rescrise în Lua)

Total: **0**


## Abilități existente, dar cu valori speciale dispărute (comportament probabil schimbat)

Aceste abilități există încă, însă unele valori din 6.88 nu mai au corespondent; 
de verificat în joc dacă mecanica s‑a schimbat și, dacă da, de rescris în Lua.

Rezolvate prin override manual (`tools/manual_overrides.json`): **195** – `abaddon_death_coil`, `abyssal_underlord_pit_of_malice`, `alchemist_unstable_concoction`, `ancient_apparition_cold_feet`, `ancient_apparition_ice_blast`, `ancient_apparition_ice_vortex`, `antimage_blink`, `antimage_mana_break`, `arc_warden_magnetic_field`, `arc_warden_spark_wraith`, `arc_warden_tempest_double`, `axe_culling_blade`, `bane_fiends_grip`, `bane_nightmare`, `batrider_firefly`, `batrider_flamebreak`, `batrider_flaming_lasso`, `batrider_sticky_napalm`, `beastmaster_primal_roar`, `beastmaster_wild_axes`, `big_thunder_lizard_wardrums_aura`, `bloodseeker_rupture`, `bloodseeker_thirst`, `bounty_hunter_track`, `brewmaster_earth_spell_immunity`, `brewmaster_primal_split`, `brewmaster_storm_cyclone`, `broodmother_incapacitating_bite`, `broodmother_insatiable_hunger`, `broodmother_spawn_spiderlings`, `broodmother_spin_web`, `centaur_double_edge`, `centaur_stampede`, `chaos_knight_phantasm`, `chen_hand_of_god`, `clinkz_wind_walk`, `crystal_maiden_frostbite`, `dark_seer_wall_of_replica`, `dark_troll_warlord_raise_dead`, `dazzle_shallow_grave`, `death_prophet_spirit_siphon`, `disruptor_glimpse`, `disruptor_thunder_strike`, `doom_bringer_devour`, `dragon_knight_dragon_tail`, `dragon_knight_elder_dragon_form`, `drow_ranger_frost_arrows`, `drow_ranger_wave_of_silence`, `earth_spirit_boulder_smash`, `earth_spirit_geomagnetic_grip`, `earth_spirit_rolling_boulder`, `earth_spirit_stone_caller`, `earthshaker_enchant_totem`, `earthshaker_fissure`, `ember_spirit_fire_remnant`, `ember_spirit_flame_guard`, `ember_spirit_searing_chains`, `enchantress_enchant`, `enchantress_impetus`, `furion_force_of_nature`, `furion_sprout`, `furion_teleportation`, `gnoll_assassin_envenomed_weapon`, `gyrocopter_homing_missile`, `huskar_burning_spear`, `invoker_emp`, `invoker_exort`, `invoker_ghost_walk`, `invoker_quas`, `invoker_wex`, `item_arcane_boots`, `item_black_king_bar`, `item_blade_mail`, `item_blink`, `item_bottle`, `item_bracer`, `item_clarity`, `item_cyclone`, `item_desolator`, `item_flask`, `item_gem`, `item_moon_shard`, `item_orchid`, `item_quelling_blade`, `item_radiance`, `item_refresher`, `item_smoke_of_deceit`, `item_sobi_mask`, `item_tango`, `item_tango_single`, `item_tome_of_knowledge`, `item_vanguard`, `item_void_stone`, `jakiro_dual_breath`, `jakiro_ice_path`, `jakiro_liquid_fire`, `jakiro_macropyre`, `juggernaut_blade_fury`, `juggernaut_healing_ward`, `keeper_of_the_light_illuminate`, `keeper_of_the_light_recall`, `kunkka_tidebringer`, `kunkka_x_marks_the_spot`, `leshrac_lightning_storm`, `lich_frost_nova`, `life_stealer_assimilate`, `life_stealer_infest`, `lion_finger_of_death`, `lion_mana_drain`, `lycan_shapeshift`, `lycan_summon_wolves`, `magnataur_shockwave`, `magnataur_skewer`, `medusa_mystic_snake`, `medusa_split_shot`, `medusa_stone_gaze`, `meepo_divided_we_stand`, `mirana_invis`, `morphling_morph_agi`, `morphling_morph_str`, `mud_golem_hurl_boulder`, `naga_siren_song_of_the_siren`, `necrolyte_heartstopper_aura`, `necronomicon_archer_aoe`, `nevermore_necromastery`, `nevermore_shadowraze1`, `nevermore_shadowraze2`, `nevermore_shadowraze3`, `nyx_assassin_spiked_carapace`, `nyx_assassin_vendetta`, `obsidian_destroyer_astral_imprisonment`, `obsidian_destroyer_sanity_eclipse`, `phantom_lancer_doppelwalk`, `phantom_lancer_phantom_edge`, `puck_illusory_orb`, `puck_phase_shift`, `puck_waning_rift`, `pudge_dismember`, `pudge_meat_hook`, `pugna_nether_ward`, `queenofpain_blink`, `queenofpain_scream_of_pain`, `rattletrap_power_cogs`, `rattletrap_rocket_flare`, `razor_plasma_field`, `roshan_devotion`, `roshan_spell_block`, `rubick_spell_steal`, `sandking_epicenter`, `satyr_soulstealer_mana_burn`, `shadow_demon_demonic_purge`, `shadow_demon_disruption`, `shadow_shaman_shackles`, `shredder_reactive_armor`, `shredder_timber_chain`, `shredder_whirling_death`, `silencer_curse_of_the_silent`, `slardar_amplify_damage`, `slardar_slithereen_crush`, `slark_dark_pact`, `slark_pounce`, `sniper_headshot`, `sniper_shrapnel`, `spirit_breaker_charge_of_darkness`, `storm_spirit_static_remnant`, `sven_gods_strength`, `sven_great_cleave`, `templar_assassin_psi_blades`, `templar_assassin_psionic_trap`, `tidehunter_kraken_shell`, `tiny_avalanche`, `treant_overgrowth`, `tusk_snowball`, `tusk_walrus_kick`, `undying_decay`, `undying_tombstone`, `undying_tombstone_zombie_deathstrike`, `ursa_earthshock`, `ursa_overpower`, `vengefulspirit_wave_of_terror`, `venomancer_poison_nova`, `viper_corrosive_skin`, `viper_viper_strike`, `visage_grave_chill`, `visage_summon_familiars`, `warlock_rain_of_chaos`, `warlock_shadow_word`, `warlock_upheaval`, `weaver_geminate_attack`, `windrunner_powershot`, `winter_wyvern_arctic_burn`, `winter_wyvern_winters_curse`, `wisp_tether`, `witch_doctor_death_ward`, `witch_doctor_paralyzing_cask`

Total cu valori reale lipsă: **27** (alte 49 au doar chei de tooltip/Aghanim lipsă – irelevante)

* `abyssal_underlord_firestorm`: first_wave_delay
* `alchemist_unstable_concoction_throw`: movement_speed, vision_range
* `beastmaster_hawk_invisibility`: idle_invis_delay
* `black_dragon_splash_attack`: damage_percent_close, damage_percent_far, damage_percent_mid, range_close, range_far, range_mid
* `brewmaster_thunder_clap`: duration_creeps
* `broodmother_poison_sting`: damage_per_second
* `drow_ranger_silence`: duration
* `enigma_malefice`: duration
* `faceless_void_time_walk`: radius
* `greevil_miniboss_black_nightmare`: nightmare_dot_interval
* `gyrocopter_flak_cannon`: fire_rate
* `invoker_ice_wall`: num_wall_elements, wall_element_radius, wall_element_spacing
* `magnataur_reverse_polarity`: creep_stun_duration
* `nyx_assassin_impale`: cooldown_upgrade
* `phantom_assassin_phantom_strike`: bonus_max_attack_count
* `phoenix_sun_ray`: beam_range
* `razor_static_link`: vision_radius
* `roshan_slam`: slow_duration_hero, slow_duration_unit
* `rubick_telekinesis`: max_land_distance_allied
* `shadow_shaman_mass_serpent_ward`: damage_max, damage_min, splash_damage, splash_radius
* `templar_assassin_refraction`: damage_threshold
* `templar_assassin_self_trap`: movement_speed_bonus, movement_speed_bonus_stage, trap_duration, trap_radius
* `templar_assassin_trap`: movement_speed_bonus, movement_speed_bonus_stage, trap_duration, trap_radius
* `tidehunter_gush`: armor_bonus
* `undying_tombstone_zombie_aura`: bonus_speed
* `visage_summon_familiars_stone_form`: max_damage_charges
* `winter_wyvern_splinter_blast`: duration

## Abilități cu comportament (AbilityBehavior) diferit

Total: **84** (doar informativ; nu suprascriem comportamentul automat)

* `antimage_blink`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_OVERSHOOT']
* `arc_warden_magnetic_field`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_CAN_SELF_CAST']
* `arc_warden_tempest_double`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_NO_TARGET']; acum are în plus ['DOTA_ABILITY_BEHAVIOR_POINT']
* `batrider_sticky_napalm`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_DONT_PROC_OTHER_ABILITIES']
* `bristleback_quill_spray`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_AUTOCAST']
* `centaur_double_edge`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_AOE']
* `centaur_hoof_stomp`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_IMMEDIATE']
* `doom_bringer_devour`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ALT_CASTABLE']
* `earth_spirit_petrify`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `earth_spirit_rolling_boulder`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `earth_spirit_stone_caller`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `elder_titan_return_spirit`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_IGNORE_INVISIBLE', 'DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE', 'DOTA_ABILITY_BEHAVIOR_IGNORE_SILENCE', 'DOTA_ABILITY_BEHAVIOR_UNRESTRICTED']
* `ember_spirit_activate_fire_remnant`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `ember_spirit_sleight_of_fist`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `enraged_wildkin_tornado`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_UNIT_TARGET']
* `faceless_void_backtrack`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_INNATE_UI']
* `faceless_void_time_walk`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `furion_teleportation`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_AOE']
* `gyrocopter_homing_missile`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING']
* `healing_campfire`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ITEM']
* `invoker_alacrity`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_DIRECT_KEYBIND', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `invoker_chaos_meteor`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_DIRECT_KEYBIND', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `invoker_cold_snap`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_DIRECT_KEYBIND', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `invoker_deafening_blast`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_DIRECT_KEYBIND', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `invoker_emp`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_DIRECT_KEYBIND', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `invoker_exort`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL', 'DOTA_ABILITY_BEHAVIOR_IGNORE_INVISIBLE']
* `invoker_forge_spirit`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_DIRECT_KEYBIND', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `invoker_ghost_walk`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_DIRECT_KEYBIND', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `invoker_ice_wall`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_DIRECT_KEYBIND', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `invoker_quas`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL', 'DOTA_ABILITY_BEHAVIOR_IGNORE_INVISIBLE']
* `invoker_sun_strike`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_DIRECT_KEYBIND', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `invoker_tornado`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_DIRECT_KEYBIND', 'DOTA_ABILITY_BEHAVIOR_OVERSHOOT', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `invoker_wex`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL', 'DOTA_ABILITY_BEHAVIOR_IGNORE_INVISIBLE']
* `jakiro_liquid_fire`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_AOE']
* `keeper_of_the_light_mana_leak`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_HIDDEN', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `keeper_of_the_light_recall`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_CHANNELLED']; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ALT_CASTABLE', 'DOTA_ABILITY_BEHAVIOR_HIDDEN', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `lone_druid_savage_roar_bear`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_HIDDEN']; acum are în plus ['DOTA_ABILITY_BEHAVIOR_NOT_LEARNABLE']
* `magnataur_skewer`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `medusa_split_shot`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_IGNORE_INVISIBLE', 'DOTA_ABILITY_BEHAVIOR_IGNORE_SILENCE']
* `meepo_poof`: 6.88 avea ['']; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ALT_CASTABLE', 'DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `morphling_morph_agi`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE']; acum are în plus —
* `morphling_morph_str`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE']; acum are în plus —
* `morphling_waveform`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_OVERSHOOT', 'DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `nyx_assassin_burrow`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `obsidian_destroyer_astral_imprisonment`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_AOE']
* `phantom_assassin_phantom_strike`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `phantom_lancer_doppelwalk`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `phantom_lancer_phantom_edge`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_PASSIVE']; acum are în plus ['DOTA_ABILITY_BEHAVIOR_IGNORE_SILENCE', 'DOTA_ABILITY_BEHAVIOR_IMMEDIATE', 'DOTA_ABILITY_BEHAVIOR_NO_TARGET', 'DOTA_ABILITY_BEHAVIOR_TOGGLE']
* `phoenix_icarus_dive`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `phoenix_sun_ray_toggle_move`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_HIDDEN']; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `puck_ethereal_jaunt`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `puck_illusory_orb`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ALT_CASTABLE']
* `puck_phase_shift`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']; acum are în plus —
* `puck_waning_rift`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_NO_TARGET']; acum are în plus ['DOTA_ABILITY_BEHAVIOR_AOE', 'DOTA_ABILITY_BEHAVIOR_POINT']
* `queenofpain_blink`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_OVERSHOOT']
* `rattletrap_battery_assault`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_IMMEDIATE']
* `rubick_telekinesis`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING']
* `rubick_telekinesis_land`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_CHANNEL', 'DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_MOVEMENT', 'DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL', 'DOTA_ABILITY_BEHAVIOR_IMMEDIATE']
* `sandking_epicenter`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_CHANNELLED']; acum are în plus —
* `shadow_shaman_mass_serpent_ward`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_AOE']
* `shoot_firework`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ITEM']
* `shredder_chakram_2`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_HIDDEN']; acum are în plus ['DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `shredder_timber_chain`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `slark_pounce`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `spectre_desolate`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_FORCE_NO_INNATE_UI', 'DOTA_ABILITY_BEHAVIOR_HIDDEN']
* `spectre_reality`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `storm_spirit_ball_lightning`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_CAN_SELF_CAST', 'DOTA_ABILITY_BEHAVIOR_OPTIONAL_UNIT_TARGET', 'DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `templar_assassin_trap`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ALT_CASTABLE']
* `throw_coal`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ITEM']
* `throw_snowball`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ITEM']
* `tidehunter_kraken_shell`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_PASSIVE']; acum are în plus ['DOTA_ABILITY_BEHAVIOR_IMMEDIATE', 'DOTA_ABILITY_BEHAVIOR_NO_TARGET']
* `troll_warlord_whirling_axes_melee`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_HIDDEN']; acum are în plus —
* `tusk_frozen_sigil`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_HIDDEN', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `tusk_snowball`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES']
* `tusk_walrus_kick`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES', 'DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING']
* `ursa_earthshock`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_IMMEDIATE']
* `venomancer_poison_sting`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_FORCE_NO_INNATE_UI', 'DOTA_ABILITY_BEHAVIOR_HIDDEN']
* `visage_summon_familiars_stone_form`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_AOE']; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ALT_CASTABLE', 'DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL', 'DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE', 'DOTA_ABILITY_BEHAVIOR_IMMEDIATE', 'DOTA_ABILITY_BEHAVIOR_NOT_LEARNABLE']
* `warlock_fatal_bonds`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_DONT_PROC_OTHER_ABILITIES']
* `weaver_geminate_attack`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_PASSIVE']; acum are în plus ['DOTA_ABILITY_BEHAVIOR_ATTACK', 'DOTA_ABILITY_BEHAVIOR_AUTOCAST', 'DOTA_ABILITY_BEHAVIOR_UNIT_TARGET']
* `winter_wyvern_winters_curse`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_DONT_PROC_OTHER_ABILITIES']
* `wisp_spirits`: 6.88 avea —; acum are în plus ['DOTA_ABILITY_BEHAVIOR_IMMEDIATE']
* `wisp_spirits_in`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_NO_TARGET']; acum are în plus ['DOTA_ABILITY_BEHAVIOR_FORCE_KEYBIND', 'DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING', 'DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL', 'DOTA_ABILITY_BEHAVIOR_IMMEDIATE', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']
* `wisp_spirits_out`: 6.88 avea ['DOTA_ABILITY_BEHAVIOR_NO_TARGET']; acum are în plus ['DOTA_ABILITY_BEHAVIOR_FORCE_KEYBIND', 'DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING', 'DOTA_ABILITY_BEHAVIOR_IGNORE_CHANNEL', 'DOTA_ABILITY_BEHAVIOR_IMMEDIATE', 'DOTA_ABILITY_BEHAVIOR_SHOW_IN_GUIDES']

## Iteme

* Iteme din 6.88 care nu mai există (de reimplementat în Lua, generate în `npc_items_generated.txt` cu `ItemPurchasable 0`): **0**
* Iteme noi (apărute după 6.88) scoase din shop: **72**
  * `item_overwhelming_blink`, `item_swift_blink`, `item_arcane_blink`, `item_recipe_arcane_blink`, `item_recipe_swift_blink`, `item_recipe_overwhelming_blink`, `item_splintmail`, `item_crown`, `item_diadem`, `item_blitz_knuckles`, `item_voodoo_mask`, `item_shawl`, `item_blood_grenade`, `item_ring_of_tarrasque`, `item_tiara_of_selemene`, `item_fluffy_hat`, `item_wizard_hat`, `item_recipe_phylactery`, `item_phylactery`, `item_angels_demise`, `item_recipe_witch_blade`, `item_witch_blade`, `item_recipe_holy_locket`, `item_holy_locket`, `item_caster_rapier`, `item_recipe_wind_waker`, `item_wind_waker`, `item_recipe_ultimate_scepter_2`, `item_ultimate_scepter_2`, `item_aghanims_shard`, `item_recipe_meteor_hammer`, `item_meteor_hammer`, `item_nullifier`, `item_recipe_aeon_disk`, `item_aeon_disk`, `item_recipe_kaya`, `item_kaya`, `item_recipe_spirit_vessel`, `item_spirit_vessel`, `item_recipe_essence_distiller`, `item_essence_distiller`, `item_recipe_consecrated_wraps`, `item_consecrated_wraps`, `item_recipe_crellas_crozier`, `item_crellas_crozier`, `item_kaya_and_sange`, `item_yasha_and_kaya`, `item_recipe_helm_of_the_overlord`, `item_helm_of_the_overlord`, `item_recipe_gungir`, `item_gungir`, `item_recipe_disperser`, `item_disperser`, `item_orb_of_corrosion`, `item_orb_of_frost`, `item_recipe_falcon_blade`, `item_falcon_blade`, `item_mage_slayer`, `item_boots_of_bearing`, `item_recipe_pavise`, `item_pavise`, `item_recipe_revenants_brooch`, `item_revenants_brooch`, `item_recipe_devastator`, `item_devastator`, `item_recipe_harpoon`, `item_harpoon`, `item_recipe_specialists_array`, `item_specialists_array`, `item_recipe_hydras_breath`, `item_hydras_breath`, `item_chasm_stone`
* Iteme existente cu valori speciale dispărute: **11**
  * `item_bottle`: movement_speed_percent_bonus
  * `item_clarity`: total_mana
  * `item_cyclone`: cast_range_tooltip
  * `item_flask`: total_health
  * `item_infused_raindrop`: bonus_armor, bonus_magical_armor
  * `item_necronomicon`: archer_attack_speed, archer_attack_speed_radius
  * `item_necronomicon_2`: archer_attack_speed, archer_attack_speed_radius
  * `item_necronomicon_3`: archer_attack_speed, archer_attack_speed_radius
  * `item_tpscroll`: minimun_distance
  * `item_ward_dispenser`: creation_delay
  * `item_ward_observer`: vision_range

## Unități (turnuri, creepi, neutrali, Roshan, curieri)

* Unități cu statistici readuse la 6.88: **171**
* Unități din 6.88 care nu mai există în joc: **2** – `npc_dota_neutral_blue_dragonspawn_sorcerer`, `npc_dota_neutral_blue_dragonspawn_overseer`

