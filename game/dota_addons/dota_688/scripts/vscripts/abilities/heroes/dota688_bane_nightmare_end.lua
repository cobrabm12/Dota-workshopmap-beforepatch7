-- Nightmare End (6.88): sub-abilitate a lui Nightmare (apare in locul ei cat timp exista un Nightmare al lui Bane);
-- termina toate Nightmare-urile lui Bane. Se poate folosi si cand Bane doarme (se trezeste singur).
dota688_bane_nightmare_end = class({})
function dota688_bane_nightmare_end:GetBehavior()
	-- comportamentul KV 6.88 + UNRESTRICTED (Bane adormit de propriul Nightmare isi poate termina Nightmare-ul)
	return DOTA_ABILITY_BEHAVIOR_HIDDEN + DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_TOGGLE
		+ DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE + DOTA_ABILITY_BEHAVIOR_UNRESTRICTED
end
function dota688_bane_nightmare_end:EndNightmares()
	local n = self:GetCaster():FindAbilityByName("dota688_bane_nightmare")
	if n then n:EndAll() end
end
function dota688_bane_nightmare_end:OnToggle()
	if self.busy then return end
	self.busy = true
	self:EndNightmares()
	if self:GetToggleState() then self:ToggleAbility() end
	self.busy = false
end
function dota688_bane_nightmare_end:OnSpellStart() self:EndNightmares() end
