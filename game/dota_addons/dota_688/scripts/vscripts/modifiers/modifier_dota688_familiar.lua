-- Familiarii lui Visage (6.88): acumuleaza pana la 7 incarcaturi de daune (+8/14/22 fiecare) cand nu ataca; fiecare atac consuma toate incarcaturile? Nu: una.
-- 6.88: incarcaturile se refac in 15 s (7 incarcaturi) si se consuma cate una la fiecare atac.
modifier_dota688_familiar = class({})
function modifier_dota688_familiar:IsHidden() return false end
function modifier_dota688_familiar:IsPurgable() return false end
function modifier_dota688_familiar:Values()
	local owner = self:GetParent():GetOwnerEntity()
	local a = owner and owner.FindAbilityByName and owner:FindAbilityByName("visage_summon_familiars")
	if not a then return 0, 7, 15 end
	return a:GetSpecialValueFor("damage_per_charge"), a:GetSpecialValueFor("max_damage_charges"), a:GetSpecialValueFor("damage_charge_time")
end
function modifier_dota688_familiar:OnCreated()
	if not IsServer() then return end
	local _, maxc, t = self:Values()
	self:SetStackCount(maxc)
	self:StartIntervalThink(t / maxc)
end
function modifier_dota688_familiar:OnIntervalThink()
	local _, maxc = self:Values()
	if self:GetStackCount() < maxc then self:IncrementStackCount() end
end
function modifier_dota688_familiar:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_familiar:GetModifierPreAttack_BonusDamage()
	local per = self:Values()
	return per * self:GetStackCount()
end
function modifier_dota688_familiar:OnAttackLanded(params)
	if IsServer() and params.attacker == self:GetParent() and self:GetStackCount() > 0 then self:DecrementStackCount() end
end
