-- Permanent Invisibility (6.88, ultimate): Riki devine invizibil dupa 6/5/4/3 s fara sa atace/caste;
-- Backstab: atacurile din spate (105 grade) fac +0.5/0.75/1.0/1.25 x AGI daune fizice.
LinkLuaModifier("modifier_dota688_riki_permanent_invisibility", "abilities/heroes/dota688_riki_permanent_invisibility", LUA_MODIFIER_MOTION_NONE)
dota688_riki_permanent_invisibility = class({})
function dota688_riki_permanent_invisibility:GetIntrinsicModifierName() return "modifier_dota688_riki_permanent_invisibility" end

modifier_dota688_riki_permanent_invisibility = class({})
function modifier_dota688_riki_permanent_invisibility:IsHidden() return false end
function modifier_dota688_riki_permanent_invisibility:IsPurgable() return false end
function modifier_dota688_riki_permanent_invisibility:OnCreated()
	self.lastAction = GameRules:GetGameTime()
	self.invis = false
	if IsServer() then self:StartIntervalThink(0.1) end
end
function modifier_dota688_riki_permanent_invisibility:OnIntervalThink()
	local parent = self:GetParent()
	local delay = self:GetAbility():GetSpecialValueFor("fade_delay")
	local shouldInvis = (GameRules:GetGameTime() - self.lastAction >= delay) and not parent:PassivesDisabled()
	if shouldInvis ~= self.invis then
		self.invis = shouldInvis
		self:SetStackCount(shouldInvis and 1 or 0)
	end
end
function modifier_dota688_riki_permanent_invisibility:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK, MODIFIER_EVENT_ON_ABILITY_EXECUTED, MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL }
end
function modifier_dota688_riki_permanent_invisibility:OnAttack(params)
	if params.attacker == self:GetParent() then self.lastAction = GameRules:GetGameTime() end
end
function modifier_dota688_riki_permanent_invisibility:OnAbilityExecuted(params)
	if params.unit == self:GetParent() then self.lastAction = GameRules:GetGameTime() end
end
function modifier_dota688_riki_permanent_invisibility:CheckState()
	if self:GetStackCount() == 1 then return { [MODIFIER_STATE_INVISIBLE] = true } end
	return {}
end
function modifier_dota688_riki_permanent_invisibility:GetModifierInvisibilityLevel() return self:GetStackCount() end
function modifier_dota688_riki_permanent_invisibility:GetModifierProcAttack_BonusDamage_Physical(params)
	local parent = self:GetParent()
	if parent:PassivesDisabled() then return 0 end
	local target = params.target
	if not target or target:IsBuilding() or target:IsOther() then return 0 end
	local toTarget = (target:GetAbsOrigin() - parent:GetAbsOrigin()):Normalized()
	local facing = target:GetForwardVector()
	local angle = math.deg(math.acos(math.max(-1, math.min(1, toTarget:Dot(facing)))))
	if angle <= self:GetAbility():GetSpecialValueFor("backstab_angle") / 2 then
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_backstab.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:ReleaseParticleIndex(fx)
		return parent:GetAgility() * self:GetAbility():GetSpecialValueFor("damage_multiplier")
	end
	return 0
end
