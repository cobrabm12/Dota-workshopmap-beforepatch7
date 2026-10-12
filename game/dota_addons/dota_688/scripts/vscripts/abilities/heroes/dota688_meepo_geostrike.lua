-- Geostrike (6.88): atacurile aplica un debuff de 2 s cu daune magice pe secunda si incetinire; fiecare Meepo are propriul debuff.
LinkLuaModifier("modifier_dota688_meepo_geostrike", "abilities/heroes/dota688_meepo_geostrike", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_meepo_geostrike_debuff", "abilities/heroes/dota688_meepo_geostrike", LUA_MODIFIER_MOTION_NONE)

dota688_meepo_geostrike = class({})
function dota688_meepo_geostrike:GetIntrinsicModifierName() return "modifier_dota688_meepo_geostrike" end

modifier_dota688_meepo_geostrike = class({})
function modifier_dota688_meepo_geostrike:IsHidden() return true end
function modifier_dota688_meepo_geostrike:IsPurgable() return false end
function modifier_dota688_meepo_geostrike:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_meepo_geostrike:OnAttackLanded(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	if params.attacker ~= parent or parent:PassivesDisabled() then return end
	local target = params.target
	if not target or target:IsBuilding() or target:IsOther() or target:GetTeamNumber() == parent:GetTeamNumber() then return end
	target:AddNewModifier(parent, self:GetAbility(), "modifier_dota688_meepo_geostrike_debuff", { duration = self:GetAbility():GetDuration() })
end

modifier_dota688_meepo_geostrike_debuff = class({})
function modifier_dota688_meepo_geostrike_debuff:IsDebuff() return true end
function modifier_dota688_meepo_geostrike_debuff:IsPurgable() return true end
function modifier_dota688_meepo_geostrike_debuff:OnCreated()
	self.slow = self:GetAbility():GetSpecialValueFor("slow")
	self.tick = 0.5
	if IsServer() then   -- GetAbilityDamage exista doar pe server (OnCreated ruleaza si pe client)
		self.dps = self:GetAbility():GetAbilityDamage()
		self:StartIntervalThink(self.tick)
	end
end
function modifier_dota688_meepo_geostrike_debuff:OnRefresh() self:OnCreated() end
function modifier_dota688_meepo_geostrike_debuff:OnIntervalThink()
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = self.dps * self.tick,
		damage_type = DAMAGE_TYPE_MAGICAL, ability = self:GetAbility() })
end
function modifier_dota688_meepo_geostrike_debuff:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_meepo_geostrike_debuff:GetModifierMoveSpeedBonus_Percentage() return self.slow end
