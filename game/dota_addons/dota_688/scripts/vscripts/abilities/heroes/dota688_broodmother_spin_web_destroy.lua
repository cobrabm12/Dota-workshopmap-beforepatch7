-- Destroy Spin Web (6.88): abilitatea unitatii panzei (npc_dota688_broodmother_web); distruge panza selectata.
dota688_broodmother_spin_web_destroy = class({})
function dota688_broodmother_spin_web_destroy:OnSpellStart()
	local web = self:GetCaster()
	local m = web:FindModifierByName("modifier_dota688_spin_web_thinker")
	if m then m:Destroy() elseif web:IsAlive() then web:ForceKill(false) end
end
