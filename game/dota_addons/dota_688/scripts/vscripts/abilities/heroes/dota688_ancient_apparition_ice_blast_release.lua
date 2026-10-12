-- Ice Blast Release (6.88): marcheaza locul exploziei pentru Ice Blast (abilitate ascunsa, vizibila doar cat timp trasorul e in aer).
dota688_ancient_apparition_ice_blast_release = class({})
function dota688_ancient_apparition_ice_blast_release:OnSpellStart()
	local blast = self:GetCaster():FindAbilityByName("dota688_ancient_apparition_ice_blast")
	if blast then blast:Release() end
end
