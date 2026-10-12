// Ascunde elementele de HUD aparute dupa 6.88 (talente, backpack, slot neutru, slot TP) si afiseaza panoul cu reguli.
// ID-urile sunt cele din HUD-ul Valve si se pot schimba la patch-uri: cautam defensiv si reincercam periodic.
"use strict";

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
var BAR_HIDE_IDS = [ "StatBranch", "AghsStatusContainer" ];
// butonul de level-up al talentelor (dota_hud_level_stats_frame), aparea de la nivelul 10 peste prima abilitate
var BAR_HIDE_TYPES = [ "DOTAHUDLevelStatsFrame", "DOTAHudTalentDisplay" ];
// panoul extins cu talentele (dota_hud_stat_branch)
HIDE_IDS.push("DOTAStatBranch", "StatBranchOuter");
// iteme neutre (7.23) si crafting-ul cu Madstone ("0/6" langa slotul neutru, hud_reborn.xml), plus ajutoarele 7.x
// de pe harta: timpii de pull ai camp-urilor si aurul neutralilor
HIDE_IDS.push("inventory_neutral_slot_container", "inventory_neutral_craft_holder", "inventory_neutral_level_up",
	"neutral_item_picker", "NeutralCampPullTimes", "NeutralCreepGoldBounty");

function HudRoot() {
	var p = $.GetContextPanel();
	while (p.GetParent() !== null) { p = p.GetParent(); }
	return p;
}

// HUD-ul Valve reface "visible" (ex. arborele de talente la nivelul 10, peste prima abilitate): pe langa visible
// colapsam panoul prin stiluri inline, pe care HUD-ul nu le reseteaza
function Collapse(el) {
	if (el === null) { return; }
	el.visible = false;
	el.hittest = false;
	el.style.opacity = "0";
	el.style.width = "0px";
	el.style.height = "0px";
}

// panouri fara ID cautate dupa tip (paneltype), in bara de abilitati
function CollapseByType(p, type, depth) {
	if (p === null || depth > 8) { return; }
	if (p.paneltype === type) { Collapse(p); return; }
	for (var i = 0; i < p.GetChildCount(); i++) { CollapseByType(p.GetChild(i), type, depth + 1); }
}

function HideKnownPanels() {
	var root = HudRoot();
	for (var i = 0; i < HIDE_IDS.length; i++) {
		Collapse(root.FindChildTraverse(HIDE_IDS[i]));
	}
	for (var j = 0; j < HIDE_PARENT_OF.length; j++) {
		var child = root.FindChildTraverse(HIDE_PARENT_OF[j]);
		if (child !== null) { Collapse(child.GetParent()); }
	}
	// in bara de abilitati: arborele de talente (DOTAHudTalentDisplay are id "StatBranch"; un panou cu acelasi id
	// exista si in alte parti ale HUD-ului, deci cautarea globala il gasea pe altul) si containerul Aghanim
	var bar = root.FindChildTraverse("AbilitiesAndStatBranch");
	if (bar !== null) {
		for (var b = 0; b < BAR_HIDE_IDS.length; b++) { Collapse(bar.FindChildTraverse(BAR_HIDE_IDS[b])); }
		for (var t = 0; t < BAR_HIDE_TYPES.length; t++) { CollapseByType(bar.GetParent(), BAR_HIDE_TYPES[t], 0); }
	}
	for (var c = 0; c < HIDE_CLASSES.length; c++) {
		var list = root.FindChildrenWithClassTraverse(HIDE_CLASSES[c]);
		for (var k = 0; k < list.length; k++) { Collapse(list[k]); }
	}
	$.Schedule(1.0, HideKnownPanels);
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
	GameEvents.Subscribe("dota_player_update_selected_unit", SendSelection);
	GameEvents.Subscribe("dota_player_update_query_unit", SendSelection);
	// panoul cu reguli apare singur la inceput si dispare dupa 25 s
	var panel = $("#Dota688Rules");
	if (panel !== null) {
		panel.AddClass("Visible");
		$.Schedule(25.0, function () { panel.RemoveClass("Visible"); });
	}
})();


