-- Copie "reala" a unui erou (cu abilitatile lui, fara iteme) pentru Vengeance Illusion (Venge + scepter) si Hybrid (Morphling + scepter).
-- Spre deosebire de o iluzie, copia poate folosi abilitati. Nu da aur/XP la moarte si nu reinvie.
LinkLuaModifier("modifier_dota688_herocopy", "dota688/herocopy", LUA_MODIFIER_MOTION_NONE)

-- noUltimates: Hybrid (6.88: "can cast all of that hero's current, non-ultimate abilities"); Vengeance Illusion le are pe toate
function Dota688CreateHeroCopy(source, owner, pos, duration, outPct, inPct, noUltimates)
	-- npc_spawned vine chiar in timpul CreateUnitByName: indicatorul ii spune lui OnNPCSpawned ca unitatea e o copie
	Dota688HeroCopySpawning = true
	local ok, u = pcall(CreateUnitByName, source:GetUnitName(), pos, true, owner, owner:GetPlayerOwner(), owner:GetTeamNumber())
	Dota688HeroCopySpawning = false
	if not ok or not u then return nil end
	u.dota688_copy = true
	u:SetOwner(owner)
	u:SetControllableByPlayer(owner:GetPlayerOwnerID(), true)
	if u.SetBaseStrength then
		u:SetBaseStrength(source:GetBaseStrength()); u:SetBaseAgility(source:GetBaseAgility()); u:SetBaseIntellect(source:GetBaseIntellect())
	end
	for i = 0, 15 do
		local sa = source:GetAbilityByIndex(i)
		if sa and sa:GetLevel() > 0 and not (noUltimates and sa:GetAbilityType() == ABILITY_TYPE_ULTIMATE) then
			local ua = u:FindAbilityByName(sa:GetName()) or u:AddAbility(sa:GetName())
			if ua then ua:SetLevel(sa:GetLevel()); ua:SetHidden(sa:IsHidden()) end
		end
	end
	if u.SetAbilityPoints then u:SetAbilityPoints(0) end
	u:SetDeathXP(0); u:SetMinimumGoldBounty(0); u:SetMaximumGoldBounty(0)
	if u.SetUnitCanRespawn then u:SetUnitCanRespawn(false) end
	u:AddNewModifier(owner, nil, "modifier_dota688_herocopy", { duration = duration, out = outPct or 0, inc = inPct or 0, owner = owner:entindex() })
	u:SetHealth(u:GetMaxHealth()); u:SetMana(u:GetMaxMana())
	u:SetForwardVector(source:GetForwardVector())
	FindClearSpaceForUnit(u, pos, true)
	return u
end

modifier_dota688_herocopy = class({})
function modifier_dota688_herocopy:IsHidden() return false end
function modifier_dota688_herocopy:IsPurgable() return false end
function modifier_dota688_herocopy:RemoveOnDeath() return false end
function modifier_dota688_herocopy:GetTexture() return "item_ultimate_scepter" end
function modifier_dota688_herocopy:OnCreated(kv)
	if not IsServer() then return end
	self.out, self.inc = kv.out or 0, kv.inc or 0
	self.owner = EntIndexToHScript(kv.owner)
	self:SetStackCount((self.out + 500) * 1000 + (self.inc + 500))
	self:StartIntervalThink(0.5)
end
function modifier_dota688_herocopy:Values()
	local v = self:GetStackCount()
	return math.floor(v / 1000) - 500, (v % 1000) - 500
end
function modifier_dota688_herocopy:OnIntervalThink()
	local p = self:GetParent()
	if not p:IsAlive() then self:Destroy() return end
end
function modifier_dota688_herocopy:DeclareFunctions() return { MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_dota688_herocopy:GetModifierDamageOutgoing_Percentage() local o = self:Values(); return o end
function modifier_dota688_herocopy:GetModifierIncomingDamage_Percentage() local _, i = self:Values(); return i end
function modifier_dota688_herocopy:OnDestroy()
	if not IsServer() then return end
	local p = self:GetParent()
	if p:IsNull() then return end
	if p:IsAlive() then p:ForceKill(false) end
	Dota688Timers:After(1.0, function() if not p:IsNull() then UTIL_Remove(p) end end)
end
