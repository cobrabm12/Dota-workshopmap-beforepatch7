-- Tricks of the Trade (6.88): Riki devine invulnerabil si ataca inamici aleatori din raza 500, de 4/5/6 ori in 3/4/5 s de channel.
LinkLuaModifier("modifier_dota688_riki_tricks_of_the_trade", "abilities/heroes/dota688_riki_tricks_of_the_trade", LUA_MODIFIER_MOTION_NONE)
dota688_riki_tricks_of_the_trade = class({})
function dota688_riki_tricks_of_the_trade:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_dota688_riki_tricks_of_the_trade", { duration = self:GetChannelTime() })
	caster:EmitSound("Hero_Riki.TricksOfTheTrade")
end
function dota688_riki_tricks_of_the_trade:OnChannelFinish(interrupted)
	self:GetCaster():RemoveModifierByName("modifier_dota688_riki_tricks_of_the_trade")
end

modifier_dota688_riki_tricks_of_the_trade = class({})
function modifier_dota688_riki_tricks_of_the_trade:IsPurgable() return false end
function modifier_dota688_riki_tricks_of_the_trade:OnCreated()
	if not IsServer() then return end
	local a = self:GetAbility()
	self.interval = a:GetChannelTime() / a:GetSpecialValueFor("attack_count")
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_tricks.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:SetParticleControl(self.fx, 0, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.fx, 1, Vector(a:GetSpecialValueFor("range"), 1, 1))
	self:StartIntervalThink(self.interval)
end
function modifier_dota688_riki_tricks_of_the_trade:OnDestroy()
	if IsServer() then ParticleManager:DestroyParticle(self.fx, false) end
end
function modifier_dota688_riki_tricks_of_the_trade:OnIntervalThink()
	local parent = self:GetParent()
	local enemies = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil, self:GetAbility():GetSpecialValueFor("range"),
		DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	if #enemies == 0 then return end
	local target = enemies[RandomInt(1, #enemies)]
	parent:PerformAttack(target, true, true, true, false, false, false, false)
end
function modifier_dota688_riki_tricks_of_the_trade:CheckState()
	return { [MODIFIER_STATE_INVULNERABLE] = true, [MODIFIER_STATE_NO_HEALTH_BAR] = true, [MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_OUT_OF_GAME] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true }
end
