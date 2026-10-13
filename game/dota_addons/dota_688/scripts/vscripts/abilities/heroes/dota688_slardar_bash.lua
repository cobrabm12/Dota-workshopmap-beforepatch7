-- Bash (6.88): 10/15/20/25% sansa (PRD) de stun 1 s (2 s pe creepi) si +60/80/100/120 daune fizice.
require("dota688/val")
LinkLuaModifier("modifier_dota688_slardar_bash", "abilities/heroes/dota688_slardar_bash", LUA_MODIFIER_MOTION_NONE)
dota688_slardar_bash = class({})
function dota688_slardar_bash:GetIntrinsicModifierName() return "modifier_dota688_slardar_bash" end

modifier_dota688_slardar_bash = class({})
function modifier_dota688_slardar_bash:IsHidden() return true end
function modifier_dota688_slardar_bash:IsPurgable() return false end
function modifier_dota688_slardar_bash:DeclareFunctions() return { MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL, MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_slardar_bash:GetModifierProcAttack_BonusDamage_Physical(params)
	if not IsServer() then return 0 end
	local parent = self:GetParent()
	local target = params.target
	if parent:PassivesDisabled() or not target or target:IsBuilding() or target:IsOther() then return 0 end
	if RollPseudoRandomPercentage(Dota688Val(self, "chance"), DOTA_PSEUDO_RANDOM_SLARDAR_BASH, parent) then
		self.bashTarget = target
		return Dota688Val(self, "bonus_damage")
	end
	return 0
end
function modifier_dota688_slardar_bash:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() or params.target ~= self.bashTarget then return end
	self.bashTarget = nil
	local a = self:GetAbility()
	if not a or a:IsNull() then return end
	local d = params.target:IsHero() and a:GetSpecialValueFor("duration") or a:GetSpecialValueFor("duration_creep")
	params.target:AddNewModifier(self:GetParent(), a, "modifier_stunned", { duration = d })
	params.target:EmitSound("Hero_Slardar.Bash")
end
