-- Rearm (6.88): canalizare 3/1.5/0.75 s (fara cooldown); daca nu e intrerupta, reseteaza cooldown-ul tuturor abilitatilor lui
-- Tinker si al itemelor din cele 6 sloturi ale inventarului, cu exceptia celor exceptate in 6.88: Black King Bar, Arcane Boots,
-- Helm of the Dominator, Hand of Midas, Refresher Orb, Linken's Sphere, Pipe of Insight si Necronomicon (si variantele lor
-- item_dota688_*). Fara rezistenta la magie / armura moderna din timpul canalizarii.
local EXCLUDED = {
	item_black_king_bar = true,
	item_arcane_boots = true,
	item_helm_of_the_dominator = true,
	item_hand_of_midas = true,
	item_refresher = true,
	item_sphere = true,
	item_pipe = true,
	item_necronomicon = true,
	item_necronomicon_2 = true,
	item_necronomicon_3 = true,
}

dota688_tinker_rearm = class({})
function dota688_tinker_rearm:GetChannelAnimation()
	-- animatiile 6.88 de Rearm, cate una pe nivel (3 / 1.5 / 0.75 s)
	return ACT_DOTA_TINKER_REARM1 + math.max(0, math.min(self:GetLevel(), 3) - 1)
end
function dota688_tinker_rearm:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_Tinker.Rearm")
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_tinker/tinker_rearm.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
end
function dota688_tinker_rearm:OnChannelFinish(interrupted)
	local caster = self:GetCaster()
	if self.fx then
		ParticleManager:DestroyParticle(self.fx, false)
		ParticleManager:ReleaseParticleIndex(self.fx)
		self.fx = nil
	end
	if interrupted then return end
	for i = 0, caster:GetAbilityCount() - 1 do
		local ab = caster:GetAbilityByIndex(i)
		if ab and not ab:IsNull() and ab ~= self then ab:EndCooldown() end
	end
	for slot = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
		local item = caster:GetItemInSlot(slot)
		if item and not item:IsNull() then
			local name = string.gsub(item:GetAbilityName(), "^item_dota688_", "item_")
			if not EXCLUDED[name] then item:EndCooldown() end
		end
	end
end
