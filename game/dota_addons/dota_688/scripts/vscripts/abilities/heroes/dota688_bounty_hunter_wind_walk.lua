-- Shadow Walk (6.88): invizibil 20/25/30/35 s (fade 1 s); atacul din invizibilitate: +30/60/90/120 daune.
LinkLuaModifier("modifier_dota688_bh_wind_walk", "abilities/heroes/dota688_bounty_hunter_wind_walk", LUA_MODIFIER_MOTION_NONE)
dota688_bounty_hunter_wind_walk = class({})
function dota688_bounty_hunter_wind_walk:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_dota688_bh_wind_walk", { duration = self:GetSpecialValueFor("duration") })
	self:GetCaster():EmitSound("Hero_BountyHunter.WindWalk")
end
modifier_dota688_bh_wind_walk = class({})
function modifier_dota688_bh_wind_walk:IsPurgable() return false end
function modifier_dota688_bh_wind_walk:OnCreated() self.start = GameRules:GetGameTime() end
function modifier_dota688_bh_wind_walk:Faded() return GameRules:GetGameTime() - self.start >= self:GetAbility():GetSpecialValueFor("fade_time") end
function modifier_dota688_bh_wind_walk:CheckState() return { [MODIFIER_STATE_INVISIBLE] = self:Faded() } end
function modifier_dota688_bh_wind_walk:DeclareFunctions() return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL, MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL, MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
function modifier_dota688_bh_wind_walk:GetModifierInvisibilityLevel() return self:Faded() and 1 or 0 end
function modifier_dota688_bh_wind_walk:GetModifierProcAttack_BonusDamage_Physical(params)
	if params.target and not params.target:IsBuilding() and not params.target:IsOther() then return self:GetAbility():GetSpecialValueFor("bonus_damage") end
	return 0
end
function modifier_dota688_bh_wind_walk:OnAttackLanded(params) if IsServer() and params.attacker == self:GetParent() then self:Destroy() end end
function modifier_dota688_bh_wind_walk:OnAbilityExecuted(params)
	if IsServer() and params.unit == self:GetParent() and params.ability ~= self:GetAbility() then self:Destroy() end
end
