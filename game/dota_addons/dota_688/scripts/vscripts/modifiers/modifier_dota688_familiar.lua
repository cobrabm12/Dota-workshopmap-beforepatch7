-- Familiarii lui Visage (6.88): pornesc cu 7 incarcaturi de daune (+8/14/22 fiecare); fiecare atac consuma una, iar o
-- incarcatura se reface la fiecare 15 s ("DAMAGE RECHARGE TIME"). In Stone Form familiarul isi recapata toate incarcaturile.
-- Abilitatea curenta nu mai are incarcaturi (familiar_attack_damage = 0 in override), deci daunele vin de aici.
modifier_dota688_familiar = class({})
local THINK = 0.25
function modifier_dota688_familiar:IsHidden() return false end
function modifier_dota688_familiar:IsPurgable() return false end
function modifier_dota688_familiar:GetTexture() return "visage_summon_familiars" end
function modifier_dota688_familiar:Values()
	local owner = self:GetParent():GetOwnerEntity()
	local a = owner and owner.FindAbilityByName and owner:FindAbilityByName("visage_summon_familiars")
	if not a then return 0, 7, 15 end
	return a:GetSpecialValueFor("damage_per_charge"), a:GetSpecialValueFor("max_damage_charges"), a:GetSpecialValueFor("damage_charge_time")
end
function modifier_dota688_familiar:OnCreated()
	if not IsServer() then return end
	local _, maxc = self:Values()
	self:SetStackCount(maxc)
	self.recharge = 0
	self:StartIntervalThink(THINK)
end
local function InStoneForm(u)
	for i = 0, u:GetModifierCount() - 1 do
		if string.find(u:GetModifierNameByIndex(i), "stone_form", 1, true) then return true end
	end
	return false
end
function modifier_dota688_familiar:OnIntervalThink()
	local _, maxc, t = self:Values()
	if InStoneForm(self:GetParent()) then
		self.recharge = 0
		if self:GetStackCount() < maxc then self:SetStackCount(maxc) end
		return
	end
	if self:GetStackCount() >= maxc then self.recharge = 0; return end
	self.recharge = self.recharge + THINK
	if self.recharge >= t then
		self.recharge = self.recharge - t
		self:IncrementStackCount()
	end
end
function modifier_dota688_familiar:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_familiar:GetModifierPreAttack_BonusDamage()
	local per = self:Values()
	return per * self:GetStackCount()
end
function modifier_dota688_familiar:OnAttackLanded(params)
	if IsServer() and params.attacker == self:GetParent() and self:GetStackCount() > 0 then self:DecrementStackCount() end
end
