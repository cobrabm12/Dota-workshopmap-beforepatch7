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
];

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
