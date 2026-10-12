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

function HudRoot() {
	var p = $.GetContextPanel();
	while (p.GetParent() !== null) { p = p.GetParent(); }
	return p;
}

function HideKnownPanels() {
	var root = HudRoot();
	for (var i = 0; i < HIDE_IDS.length; i++) {
		var el = root.FindChildTraverse(HIDE_IDS[i]);
		if (el !== null && el.visible) { el.visible = false; }
	}
	for (var c = 0; c < HIDE_CLASSES.length; c++) {
		var list = root.FindChildrenWithClassTraverse(HIDE_CLASSES[c]);
		for (var k = 0; k < list.length; k++) { if (list[k].visible) { list[k].visible = false; } }
	}
	$.Schedule(2.0, HideKnownPanels);
}

function Dota688ToggleRules() {
	var panel = $("#Dota688Rules");
	if (panel !== null) { panel.ToggleClass("Visible"); }
}

(function () {
	HideKnownPanels();
	// panoul cu reguli apare singur la inceput si dispare dupa 25 s
	var panel = $("#Dota688Rules");
	if (panel !== null) {
		panel.AddClass("Visible");
		$.Schedule(25.0, function () { panel.RemoveClass("Visible"); });
	}
})();
