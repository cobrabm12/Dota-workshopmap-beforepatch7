-- Drunken Brawler (6.88): 10/15/20/25% evaziune si 10/15/20/25% sansa de critic 200%; garantat o data la 16/14/12/10 s fara proc.
LinkLuaModifier("modifier_dota688_brewmaster_drunken_brawler", "abilities/heroes/dota688_brewmaster_drunken_brawler", LUA_MODIFIER_MOTION_NONE)
dota688_brewmaster_drunken_brawler = class({})
function dota688_brewmaster_drunken_brawler:GetIntrinsicModifierName() return "modifier_dota688_brewmaster_drunken_brawler" end
modifier_dota688_brewmaster_drunken_brawler = class({})
function modifier_dota688_brewmaster_drunken_brawler:IsHidden() return true end
function modifier_dota688_brewmaster_drunken_brawler:IsPurgable() return false end
function modifier_dota688_brewmaster_drunken_brawler:OnCreated() self.lastCrit = GameRules:GetGameTime(); self.lastDodge = GameRules:GetGameTime() end
function modifier_dota688_brewmaster_drunken_brawler:DeclareFunctions() return { MODIFIER_PROPERTY_EVASION_CONSTANT, MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE, MODIFIER_EVENT_ON_ATTACKED, MODIFIER_EVENT_ON_ATTACK } end
-- cronometrele 6.88: evaziune garantata daca nu a fost atacat de last_proc s, crit garantat daca nu a atacat de last_proc s
function modifier_dota688_brewmaster_drunken_brawler:OnAttacked(params)
	if IsServer() and params.target == self:GetParent() then self.lastDodge = GameRules:GetGameTime() end
end
function modifier_dota688_brewmaster_drunken_brawler:OnAttack(params)
	if IsServer() and params.attacker == self:GetParent() and not self.critNow then self.lastCrit = GameRules:GetGameTime() end
	self.critNow = nil
end
function modifier_dota688_brewmaster_drunken_brawler:GetModifierEvasion_Constant()
	if self:GetParent():PassivesDisabled() then return 0 end
	local a = self:GetAbility()
	if not a or a:IsNull() then return 0 end
	if GameRules:GetGameTime() - (self.lastDodge or 0) >= a:GetSpecialValueFor("last_proc") then return 100 end
	return a:GetSpecialValueFor("dodge_chance")
end
function modifier_dota688_brewmaster_drunken_brawler:GetModifierPreAttack_CriticalStrike(params)
	local parent, a = self:GetParent(), self:GetAbility()
	if parent:PassivesDisabled() or not params.target or params.target:IsBuilding() or params.target:IsOther() then return nil end
	local forced = GameRules:GetGameTime() - (self.lastCrit or 0) >= a:GetSpecialValueFor("last_proc")
	if forced or RollPseudoRandomPercentage(a:GetSpecialValueFor("crit_chance"), DOTA_PSEUDO_RANDOM_BREWMASTER_CRIT, parent) then
		self.lastCrit = GameRules:GetGameTime()
		self.critNow = true
		return a:GetSpecialValueFor("crit_multiplier")
	end
	return nil
end
