-- Gravekeeper's Cloak (6.88): 4 straturi; fiecare strat +1.5/3/4.5/6 armura si +5/10/15/20% rezistenta magica; un strat cade la fiecare lovitura (de la jucatori) si revine dupa 3 s.
LinkLuaModifier("modifier_dota688_visage_gravekeepers_cloak", "abilities/heroes/dota688_visage_gravekeepers_cloak", LUA_MODIFIER_MOTION_NONE)
dota688_visage_gravekeepers_cloak = class({})
function dota688_visage_gravekeepers_cloak:GetIntrinsicModifierName() return "modifier_dota688_visage_gravekeepers_cloak" end
modifier_dota688_visage_gravekeepers_cloak = class({})
function modifier_dota688_visage_gravekeepers_cloak:IsHidden() return false end
function modifier_dota688_visage_gravekeepers_cloak:IsPurgable() return false end
function modifier_dota688_visage_gravekeepers_cloak:OnCreated()
	self.max = self:GetAbility():GetSpecialValueFor("max_layers")
	self:SetStackCount(self.max)
	self.lastHit = 0
	if IsServer() then self:StartIntervalThink(0.1) end
end
function modifier_dota688_visage_gravekeepers_cloak:OnIntervalThink()
	if self:GetStackCount() < self.max and GameRules:GetGameTime() - self.lastHit >= self:GetAbility():GetSpecialValueFor("recovery_time") then
		self:IncrementStackCount()
		self.lastHit = GameRules:GetGameTime()
	end
end
function modifier_dota688_visage_gravekeepers_cloak:DeclareFunctions() return { MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS } end
function modifier_dota688_visage_gravekeepers_cloak:OnTakeDamage(params)
	if not IsServer() or params.unit ~= self:GetParent() or params.damage <= 0 then return end
	local attacker = params.attacker
	if not attacker or not attacker:IsControllableByAnyPlayer() or attacker:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
	if self:GetStackCount() > 0 then self:DecrementStackCount() end
	self.lastHit = GameRules:GetGameTime()
end
function modifier_dota688_visage_gravekeepers_cloak:GetModifierPhysicalArmorBonus()
	if self:GetParent():PassivesDisabled() then return 0 end
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("bonus_armor")
end
function modifier_dota688_visage_gravekeepers_cloak:GetModifierMagicalResistanceBonus()
	if self:GetParent():PassivesDisabled() then return 0 end
	return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("bonus_resist")
end
