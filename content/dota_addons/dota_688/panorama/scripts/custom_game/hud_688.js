// Ascunde elementele de HUD aparute dupa 6.88: arborele de talente, backpack-ul, slotul de iteme neutre,
// slotul dedicat de TP (7.07) si butonul de Aghanim's Shard. ID-urile sunt cele din HUD-ul Valve si pot
// sa se schimbe la patch-uri: de aceea cautam defensiv si reincercam periodic.
"use strict";

var HIDE_IDS = [
	"StatBranch",                 // arborele de talente (sub abilitati)
	"inventory_backpack_list",    // backpack (sloturile 7-9)
	"inventory_neutral_slot",     // item neutru
	"inventory_tpscroll_container", "inventory_tpscroll_slot", // slotul de TP
	"AghanimsStatus", "ShardStatus", "inventory_shard_status", "inventory_aghanims_status",
	"AttributeBonusButton",       // "+" de atribute din HUD-ul modern (noi folosim abilitatea clasica)
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
		if (el !== null && el.visible) {
			el.visible = false;
		}
	}
	$.Schedule(2.0, HideKnownPanels);
}

(function () {
	// Elementele standard pe care le putem opri direct din API
	try { GameUI.SetDefaultUIEnabled(DotaDefaultUIElement_t.DOTA_DEFAULT_UI_INVENTORY_SHOP, true); } catch (e) {}
	HideKnownPanels();
})();
