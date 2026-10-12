-- Death Pact (6.88): consuma un creep; +50/65/80% din HP-ul lui ca HP maxim si +5/6.5/8% ca daune, 35 s.
LinkLuaModifier("modifier_dota688_clinkz_death_pact", "abilities/heroes/dota688_clinkz_death_pact", LUA_MODIFIER_MOTION_NONE)
dota688_clinkz_death_pact = class({})
function dota688_clinkz_death_pact:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if not target or not target:IsAlive() then return end
	local hp = target:GetHealth()
	caster:EmitSound("Hero_Clinkz.DeathPact")
	target:Kill(self, caster)
	caster:AddNewModifier(caster, self, "modifier_dota688_clinkz_death_pact", { duration = self:GetSpecialValueFor("duration"),
		hp = hp * self:GetSpecialValueFor("health_gain_pct") / 100, dmg = hp * self:GetSpecialValueFor("damage_gain_pct") / 100 })
end
modifier_dota688_clinkz_death_pact = class({})
function modifier_dota688_clinkz_death_pact:IsPurgable() return false end
function modifier_dota688_clinkz_death_pact:OnCreated(kv)
	self.hp = kv.hp or 0; self.dmg = kv.dmg or 0
	if IsServer() then self:GetParent():CalculateStatBonus(true); self:GetParent():Heal(self.hp, self:GetAbility()) end
end
function modifier_dota688_clinkz_death_pact:OnRefresh(kv) self.hp = kv.hp or self.hp; self.dmg = kv.dmg or self.dmg end
function modifier_dota688_clinkz_death_pact:DeclareFunctions() return { MODIFIER_PROPERTY_HEALTH_BONUS, MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE } end
function modifier_dota688_clinkz_death_pact:GetModifierHealthBonus() return self.hp end
function modifier_dota688_clinkz_death_pact:GetModifierPreAttack_BonusDamage() return self.dmg end
