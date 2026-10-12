// Ascunde elementele de HUD aparute dupa 6.88 (talente, backpack, slot neutru, slot TP, timere, fatete, ghiduri...)
// si afiseaza panoul cu reguli.
// ID-urile/tipurile/clasele sunt cele din HUD-ul Valve (verificate in layout-urile clientului curent: hud_reborn.xml,
// dota_hud_*.xml, context_menu_*.xml, tooltip_unit_damage_armor.xml) si se pot schimba la patch-uri: cautam
// defensiv si reincercam periodic.
"use strict";

// 1) Panouri unice, cautate in tot HUD-ul (FindChildTraverse intoarce doar PRIMUL panou cu id-ul dat)
var HIDE_IDS = [
	"StatBranch",
	"inventory_backpack_list",
	"inventory_neutral_slot",
	"inventory_tpscroll_container", "inventory_tpscroll_slot",
	"AghanimsStatus", "ShardStatus", "inventory_shard_status", "inventory_aghanims_status",
	"AttributeBonusButton",
	// indicatorul Aghanim's Scepter/Shard (dota_hud_aghs_status_display, 7.x) - in 6.88 nu exista
	"AghsStatusScepterContainer", "AghsStatusShard",
];
// panouri identificate dupa clasa (fara ID stabil): fatetele/abilitatea innate din 7.36 (dota_hud_innate_display)
var HIDE_CLASSES = [ "RootInnateDisplay" ];
// panouri fara ID ascunse prin parintele unui copil cunoscut: arborele de talente (DOTAHudTalentDisplay,
// dota_hud_talentdisplay) aparea de la nivelul 10 peste prima abilitate
var HIDE_PARENT_OF = [ "StatBranchBG" ];
// in bara de abilitati (cautate in tot subarborele, toate aparitiile): arborele de talente (DOTAHudTalentDisplay are id
// "StatBranch"; un panou cu acelasi id exista si in toast-ul de talente al spectatorilor, deci cautarea globala il
// gasea pe acela), indicatorul Aghanim (doua "AghsStatusContainer": unul normal si unul in containerul lui Invoker,
// care e tot indicatorul Aghanim 7.x cu orbele) si butonul de level-up al talentelor (dota_hud_level_stats_frame,
// aparea de la nivelul 10 peste prima abilitate)
var BAR_HIDE = [ "StatBranch", "AghsStatusContainer", "InvokerAghsStatusContainer",
	"DOTAHUDLevelStatsFrame", "DOTAHudTalentDisplay" ];
// panoul extins cu talentele (dota_hud_stat_branch)
HIDE_IDS.push("DOTAStatBranch", "StatBranchOuter");
// iteme neutre (7.23) si crafting-ul cu Madstone ("0/6" langa slotul neutru, hud_reborn.xml), plus ajutoarele 7.x
// de pe harta: timpii de pull ai camp-urilor si aurul neutralilor
HIDE_IDS.push("inventory_neutral_slot_container", "inventory_neutral_craft_holder", "inventory_neutral_level_up",
	"neutral_item_picker", "NeutralCampPullTimes", "NeutralCreepGoldBounty");
// timerele 7.x: rune pe harta (DOTAHUDRuneSpawnTimes) si Roshan/Tormentor langa minimap
HIDE_IDS.push("RuneSpawnTimes", "RoshanTimerContainer", "TormentorTimerContainer");
// aurul creep-urilor de linie, sfaturile contextuale, Dota Plus pe portret (kill graph, insigna eroului),
// hotkey-ul talentelor, roata de ping
HIDE_IDS.push("LaneCreepGoldBounty", "ContextualTips", "KillGraphButton", "unitbadge", "StatBranchHotkey", "PingWheel");
// tooltip-ul de damage/armura (tooltip_unit_damage_armor): rezistenta la status si la slow nu existau in 6.88
// (tooltip-ul 6.88 avea doar attack speed/damage/range, move speed, armura, rezistenta magica, spell amp)
HIDE_IDS.push("StatusResistRow", "SlowResistRow");

// 2) Panouri cautate doar in interiorul unui panou cunoscut. scope = lant de id-uri pornind de la radacina HUD-ului.
//    ids     - un singur panou cu acel id in scope (FindChildTraverse)
//    classes - toate panourile cu acea clasa (FindChildrenWithClassTraverse)
//    all     - toate panourile cu acel id SAU tip (paneltype), prin parcurgerea subarborelui (CollapseAll): pentru
//              panourile repetate pe jucator (randurile din scoreboard, sloturile din top bar), din care
//              FindChildTraverse il gasea doar pe primul
//    skip    - id-uri de subarbori mari, fara nimic de ascuns, peste care parcurgerea sare
//    depth   - adancimea maxima a parcurgerii (implicit WALK_DEPTH); panourile cautate sunt la adancimea din comentariu,
//              limita are o marja ca sa nu coboram in interiorul imaginilor/particulelor din fiecare slot
var SCOPED = [
	// top bar: timerele 7.x (DOTATimers: rune, shrine, lotus, tabere), fateta, rolul ales (lane) si TP-ul fiecarui jucator
	// (DOTAFacetIcon e la adancimea 8: topbar > ... > TopBarRadiantPlayersContainer > slot > SlantedContainerPanel)
	{ scope: [ "topbar" ], depth: 11, classes: [ "TPIndicator" ],
		all: [ "DOTATimers", "TimersContainer", "DOTAFacetIcon", "PlayerRole" ] },
	// shop: ghidurile, sugestiile, itemele populare, tab-ul de neutre, protectia la buyback. Raman cautarea, quickbuy,
	// sticky si tab-urile side/secret shop (existau in 6.88)
	{ scope: [ "shop" ], ids: [ "GuidesButton", "GuidesButtonV2", "GuideFlyout", "ItemPlusGuide", "RequestSuggestion",
		"PopularItems", "GridNeutralsTab", "BuybackProtection" ], classes: [ "GridNeutralsTabContainer" ] },
	// quickbuy + curier (#courier e in quickbuy): itemul sugerat, protectia la buyback, scutul curierului (7.x) si
	// indicatorul "A" de auto-deliver (curierul echipei din addon nu are auto-deliver)
	// si livrarea catre alt erou (OtherHeroDeliver, 7.x)
	{ scope: [ "quickbuy" ], ids: [ "SuggestItems", "BuybackProtection", "CourierShieldButton", "CourierShieldHotkey",
		"OtherHeroDeliver" ], classes: [ "CourierAutoStatus" ] },
	// scoreboard: arborele de talente si indicatorul Aghanim din fiecare rand; coloanele talente/tips/cadouri/bounty
	// (antet + randuri; TalentTree si AghsStatusContainer sunt la adancimea 5: scoreboard > Background >
	// RadiantTeamContainer > rand > coloana)
	{ scope: [ "scoreboard" ], depth: 8, classes: [ "TalentColumn", "TippingColumn", "GiftingColumn", "BountyColumn" ],
		all: [ "DOTAHudTalentDisplay", "TalentTree", "DOTAAghsStatusDisplay" ],
		skip: [ "TeamInventories", "SharedUnitControl", "SharedContent", "ScoreboardCoaches" ] },
	// popup-ul de alegere a fatetei (popup_hero_facet_picker)
	{ scope: [ "PopupManager" ], all: [ "DOTAUIHeroFacetPicker" ] },
];
// ecranul de alegere a eroului / strategie (dota_hud_pregame.xml): doar inainte de PRE_GAME
var SCOPED_PREGAME = [
	{ scope: [ "PreGame" ], ids: [ "TeamPurchasesStrategyControl", "StartingItemsBackpackRow", "AllyHeroesStrategyControl",
		"PredictEnemyHeroesStrategyControl", "DesiredWardPlacementStrategyControl", "PlusWaiting" ],
		all: [ "DOTAFacetIcon", "DOTAUIHeroFacetPicker" ],
		skip: [ "HeroGrid", "HeroModel", "HeroModelLoadout", "HeroCosmeticPicker", "GlobalCosmeticPicker", "GuideBrowser",
			"PregameBG", "StrategyMinimap", "HeroPickMinimap", "PlayerDraft", "AbilityDraft", "SpectateHeroSelection" ] },
];
// #AttackSpeed si #MagicResist din #stats (langa portret si in query unit): NU se stie daca HUD-ul 6.88 le afisa
// langa portret (reference/6.88f are doar localizarea; acolo apar doar in tooltip). Pune true dupa verificare.
var HIDE_STATS_ATTACKSPEED_MAGICRESIST = false;
if (HIDE_STATS_ATTACKSPEED_MAGICRESIST) {
	SCOPED.push({ scope: [ "center_block", "stats" ], ids: [ "AttackSpeed", "MagicResist" ] },
		{ scope: [ "QueryUnit", "stats" ], ids: [ "AttackSpeed", "MagicResist" ] });
}

// 3) Meniuri contextuale, create la deschidere (deci verificate des):
// - curierul (context_menu_courier, click dreapta pe curier/livrare): randul auto-deliver si randurile cu coechipierii
//   (curierul echipei din addon nu are auto-deliver)
// - itemele din inventar (context_menu_inventory_item): optiunile 7.x ale caror ordine le respinge serverul (blocarea
//   combinarii, marcarea pentru vanzare, drop la fantana) si trimiterea in stash-ul de neutre
var COURIER_MENU_HIDE = [ "ToggleAutoDeliver", "Teammates" ];
var INVENTORY_MENU_HIDE = [ "CombineLock", "CombineUnlock", "MarkForSell", "UnmarkForSell", "DropAtFountain",
	"TeleportToNeutralStash" ];
function HideCourierMenu(menu) {
	CollapseIds(menu, COURIER_MENU_HIDE);
	HookCourierPanels(menu, COURIER_MENU_ROWS, true);
}
function HideInventoryMenu(menu) { CollapseIds(menu, INVENTORY_MENU_HIDE); }
// daca meniurile nu sunt sub #ContextMenuManager, verificarea lenta le gaseste dupa un rand cunoscut (id unic in HUD)
var MENU_FALLBACK = [ { row: "ToggleAutoDeliver", hide: HideCourierMenu }, { row: "CombineLock", hide: HideInventoryMenu } ];

// 4) Curierul echipei (6.88). Butoanele din panoul shop-ului (dota_hud_courier.xml: livrare, burst), randurile din
// meniul de click dreapta (fantana, secret shop) si hotkey-urile lor cauta curierul personal al jucatorului (7.23+) si
// nu trimit nimic pentru curierul echipei. Le trimitem serverului (scripts/vscripts/dota688/courier.lua,
// OnHudCommand), care comanda curierul echipei. Selectarea (buton + hotkey) o facem direct pe client, tot pe curierul
// echipei, ca sa mearga si pentru coechipierii celui care l-a cumparat.
var COURIER_BUTTONS = [
	{ id: "DeliverItemsButton", cmd: "courier_take_stash_and_transfer_items" },
	{ id: "CourierBurstButton", cmd: "courier_burst" },
	{ id: "SelectCourierButton", fn: SelectCourier },
];
var COURIER_MENU_ROWS = [
	{ id: "Home", cmd: "courier_return_to_base" },
	{ id: "SecretShop", cmd: "courier_go_to_secretshop" },
];
var COURIER_HOTKEYS = [
	{ keybind: "DOTA_KEYBIND_COURIER_DELIVER", command: "dota688_courier_deliver", cmd: "courier_take_stash_and_transfer_items" },
	{ keybind: "DOTA_KEYBIND_COURIER_BURST", command: "dota688_courier_burst", cmd: "courier_burst" },
	{ keybind: "DOTA_KEYBIND_COURIER_SELECT", command: "dota688_courier_select", fn: SelectCourier },
];

function CourierCommand(cmd) {
	GameEvents.SendCustomGameEventToServer("dota688_courier_command", { cmd: cmd });
}

function CourierHandler(cmd, closeMenu) {
	return function () {
		CourierCommand(cmd);
		if (closeMenu) { $.DispatchEvent("DismissAllContextMenus"); }
	};
}

// curierul echipei jucatorului local (-1 daca nu exista / e mort)
function TeamCourier() {
	var team = Players.GetTeam(Players.GetLocalPlayer());
	var list = Entities.GetAllEntitiesByClassname("npc_dota_courier");
	for (var i = 0; i < list.length; i++) {
		if (Entities.GetTeamNumber(list[i]) === team && Entities.IsAlive(list[i])) { return list[i]; }
	}
	return -1;
}

// "Select Courier": selecteaza curierul echipei (al doilea click il centreaza); butonul Valve cauta curierul personal
function SelectCourier() {
	try {
		var c = TeamCourier();
		if (c < 0) { return; }
		if (Players.GetLocalPlayerPortraitUnit() === c) { GameUI.MoveCameraToEntity(c); return; }
		GameUI.SelectUnit(c, false);
	} catch (e) {
		LogOnce(e);
	}
}

// SetPanelEvent inlocuieste actiunea din layout (onactivate="DOTAHUDCourierDeliverLeftClick();" etc.)
function HookCourierPanels(scope, list, closeMenu) {
	if (scope === null) { return; }
	for (var i = 0; i < list.length; i++) {
		var p = scope.FindChildTraverse(list[i].id);
		if (p !== null) { p.SetPanelEvent("onactivate", list[i].fn || CourierHandler(list[i].cmd, closeMenu)); }
	}
}

// tasta aleasa de jucator pentru livrare / burst ruleaza comanda noastra
function BindCourierHotkeys() {
	for (var i = 0; i < COURIER_HOTKEYS.length; i++) {
		var h = COURIER_HOTKEYS[i];
		try {
			var key = Game.GetKeybindForCommand(DOTAKeybindCommand_t[h.keybind]);
			// comenzile legate de taste au forma +comanda (apasare) / -comanda (eliberare)
			Game.AddCommand("+" + h.command, h.fn || CourierHandler(h.cmd, false), "", 0);
			Game.AddCommand("-" + h.command, function () {}, "", 0);
			if (key !== undefined && key !== null && key !== "") { Game.CreateCustomKeyBind(key, "+" + h.command); }
		} catch (e) {
			$.Msg("[dota688] hud_688.js: tasta pentru " + h.keybind + ": " + e);
		}
	}
}

function CollapseIds(scope, ids) {
	for (var i = 0; i < ids.length; i++) { Collapse(scope.FindChildTraverse(ids[i])); }
}

var WALK_DEPTH = 25;

function ToSet(list) {
	var s = Object.create(null);
	if (list !== undefined) {
		for (var i = 0; i < list.length; i++) { s[list[i]] = true; }
	}
	return s;
}

function Matcher(all, skip, depth, inside) {
	var handlers = null;
	if (inside) {
		handlers = Object.create(null);
		for (var type in inside) { handlers[type] = inside[type]; }
	}
	return { match: ToSet(all), skip: ToSet(skip), depth: depth, inside: handlers };
}

var BAR_MATCH = Matcher(BAR_HIDE, [], 8, null);
var MENU_MATCH = Matcher([], [], WALK_DEPTH,
	{ DOTACourierContextMenu: HideCourierMenu, DOTAContextMenuInventoryItem: HideInventoryMenu });
function PrepareScoped(list) {
	for (var i = 0; i < list.length; i++) {
		var s = list[i];
		s.matcher = (s.all !== undefined) ? Matcher(s.all, s.skip, s.depth || WALK_DEPTH, null) : null;
	}
}
PrepareScoped(SCOPED);
PrepareScoped(SCOPED_PREGAME);

function HudRoot() {
	var p = $.GetContextPanel();
	while (p.GetParent() !== null) { p = p.GetParent(); }
	return p;
}

// HUD-ul Valve reface "visible" (ex. arborele de talente la nivelul 10, peste prima abilitate): pe langa visible
// colapsam panoul prin stiluri inline, pe care HUD-ul nu le reseteaza
function Collapse(el) {
	if (el === null || el === undefined) { return; }
	el.visible = false;
	el.hittest = false;
	el.style.opacity = "0";
	el.style.width = "0px";
	el.style.height = "0px";
}

// colapseaza in subarborele lui p TOATE panourile al caror id sau tip (paneltype) e in m.match; nu coboara in
// panourile deja colapsate, in cele din m.skip si sub m.depth niveluri. m.inside[tip] = functie apelata pentru
// panourile de acel tip (in loc sa le colapseze)
function CollapseAll(p, m) { Walk(p, m, 0); }

function Walk(p, m, depth) {
	if (p === null || depth > m.depth) { return; }
	var id = p.id;
	if (depth > 0 && m.skip[id] === true) { return; }
	var type = p.paneltype;
	if (m.match[id] === true || m.match[type] === true) { Collapse(p); return; }
	if (m.inside !== null && m.inside[type] !== undefined) { m.inside[type](p); return; }
	var n = p.GetChildCount();
	for (var i = 0; i < n; i++) { Walk(p.GetChild(i), m, depth + 1); }
}

function FindScope(root, path) {
	var p = root;
	for (var i = 0; i < path.length && p !== null; i++) { p = p.FindChildTraverse(path[i]); }
	return p;
}

function HideScoped(root, list) {
	for (var i = 0; i < list.length; i++) {
		var s = list[i];
		var scope = FindScope(root, s.scope);
		if (scope === null) { continue; }
		if (s.ids !== undefined) {
			for (var j = 0; j < s.ids.length; j++) { Collapse(scope.FindChildTraverse(s.ids[j])); }
		}
		if (s.classes !== undefined) {
			for (var c = 0; c < s.classes.length; c++) {
				var found = scope.FindChildrenWithClassTraverse(s.classes[c]);
				for (var k = 0; k < found.length; k++) { Collapse(found[k]); }
			}
		}
		if (s.matcher !== null) { CollapseAll(scope, s.matcher); }
	}
}

// ecranul de alegere/strategie exista doar inainte de PRE_GAME; daca enum-ul lipseste, il verificam mereu
function InHeroSelection() {
	try {
		return Game.GameStateIsBefore(DOTA_GameState.DOTA_GAMERULES_STATE_PRE_GAME);
	} catch (e) {
		return true;
	}
}

// panourile managerilor de meniuri contextuale si tooltip-uri (hud_reborn.xml), folosite de verificarea rapida
var g_menus = null;
var g_tooltips = null;
var g_errorLogged = false;

function LogOnce(e) {
	if (!g_errorLogged) {
		g_errorLogged = true;
		$.Msg("[dota688] hud_688.js: " + e);
	}
}

function HideKnownPanels() {
	$.Schedule(1.0, HideKnownPanels);
	try {
		var root = HudRoot();
		for (var i = 0; i < HIDE_IDS.length; i++) {
			Collapse(root.FindChildTraverse(HIDE_IDS[i]));
		}
		for (var j = 0; j < HIDE_PARENT_OF.length; j++) {
			var child = root.FindChildTraverse(HIDE_PARENT_OF[j]);
			if (child !== null) { Collapse(child.GetParent()); }
		}
		var bar = root.FindChildTraverse("AbilitiesAndStatBranch");
		if (bar !== null) { CollapseAll(bar.GetParent(), BAR_MATCH); }
		for (var c = 0; c < HIDE_CLASSES.length; c++) {
			var list = root.FindChildrenWithClassTraverse(HIDE_CLASSES[c]);
			for (var k = 0; k < list.length; k++) { Collapse(list[k]); }
		}
		HideScoped(root, SCOPED);
		if (InHeroSelection()) { HideScoped(root, SCOPED_PREGAME); }
		HookCourierPanels(root.FindChildTraverse("quickbuy"), COURIER_BUTTONS, false);
		// meniurile contextuale, daca nu sunt sub #ContextMenuManager (verificarea rapida nu le-ar gasi)
		for (var f = 0; f < MENU_FALLBACK.length; f++) {
			var row = root.FindChildTraverse(MENU_FALLBACK[f].row);
			if (row !== null && row.GetParent() !== null) { MENU_FALLBACK[f].hide(row.GetParent()); }
		}
		g_menus = root.FindChildTraverse("ContextMenuManager");
		g_tooltips = root.FindChildTraverse("Tooltips");
	} catch (e) {
		LogOnce(e);
	}
}

// verificare rapida pentru panourile create la cerere (meniurile contextuale, tooltip-ul de damage/armura), ca
// randurile ascunse sa nu apara o secunda
function HideTransientPanels() {
	$.Schedule(0.1, HideTransientPanels);
	try {
		if (g_menus !== null) { CollapseAll(g_menus, MENU_MATCH); }
		if (g_tooltips !== null) {
			Collapse(g_tooltips.FindChildTraverse("StatusResistRow"));
			Collapse(g_tooltips.FindChildTraverse("SlowResistRow"));
		}
	} catch (e) {
		g_menus = null;
		g_tooltips = null;
	}
}

// selectia curenta -> server (scripts/vscripts/dota688/selection.lua): cu mai multe Remote Mines selectate, clientul
// trimite ordinul de detonare doar pentru unitatea principala; serverul le detoneaza si pe celelalte, ca in 6.88
function SendSelection() {
	var pid = Players.GetLocalPlayer();
	if (pid < 0) { return; }
	GameEvents.SendCustomGameEventToServer("dota688_selection", { units: Players.GetSelectedEntities(pid) });
}

function Dota688ToggleRules() {
	var panel = $("#Dota688Rules");
	if (panel !== null) { panel.ToggleClass("Visible"); }
}

(function () {
	HideKnownPanels();
	HideTransientPanels();
	BindCourierHotkeys();
	GameEvents.Subscribe("dota_player_update_selected_unit", SendSelection);
	GameEvents.Subscribe("dota_player_update_query_unit", SendSelection);
	// panoul cu reguli apare singur la inceput si dispare dupa 25 s
	var panel = $("#Dota688Rules");
	if (panel !== null) {
		panel.AddClass("Visible");
		$.Schedule(25.0, function () { panel.RemoveClass("Visible"); });
	}
})();
