-- Freezing Field (6.88): canalizare 10 s; la fiecare 0.1 s o explozie (raza 300) la 195-785 de CM cu 105/170/250 daune magice;
-- inamicii din 835 sunt incetiniti -30% miscare/atac. Scepter: 170/250/310 daune, -50% incetinire.
require("dota688/aghanim")
local F = "abilities/heroes/dota688_crystal_maiden_freezing_field"
LinkLuaModifier("modifier_dota688_freezing_field", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_freezing_field_slow", F, LUA_MODIFIER_MOTION_NONE)
dota688_crystal_maiden_freezing_field = class({})
function dota688_crystal_maiden_freezing_field:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_Crystal.CrystalNova")
	caster:EmitSound("hero_Crystal.freezingField.wind")
	self.mod = caster:AddNewModifier(caster, self, "modifier_dota688_freezing_field", { duration = self:GetChannelTime() })
end
function dota688_crystal_maiden_freezing_field:OnChannelFinish(interrupted)
	self:GetCaster():StopSound("hero_Crystal.freezingField.wind")
	if self.mod and not self.mod:IsNull() then self.mod:Destroy() end
	self.mod = nil
end
modifier_dota688_freezing_field = class({})
function modifier_dota688_freezing_field:IsHidden() return true end
function modifier_dota688_freezing_field:IsPurgable() return false end
function modifier_dota688_freezing_field:OnCreated()
	if not IsServer() then return end
	local a, p = self:GetAbility(), self:GetParent()
	self.scepter = Dota688HasScepter(p)
	self.dmg = self.scepter and a:GetSpecialValueFor("damage_scepter") or a:GetSpecialValueFor("damage")
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_snow.vpcf", PATTACH_ABSORIGIN_FOLLOW, p)
	ParticleManager:SetParticleControl(self.fx, 1, Vector(a:GetSpecialValueFor("radius"), 0, 0))
	self:StartIntervalThink(a:GetSpecialValueFor("explosion_interval"))
end
function modifier_dota688_freezing_field:OnIntervalThink()
	local a, p = self:GetAbility(), self:GetParent()
	local pos = p:GetAbsOrigin() + RandomVector(RandomFloat(a:GetSpecialValueFor("explosion_min_dist"), a:GetSpecialValueFor("explosion_max_dist")))
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_crystalmaiden/maiden_freezing_field_explosion.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fx, 0, pos)
	ParticleManager:ReleaseParticleIndex(fx)
	EmitSoundOnLocationWithCaster(pos, "hero_Crystal.freezingField.explosion", p)
	for _, e in ipairs(FindUnitsInRadius(p:GetTeamNumber(), pos, nil, a:GetSpecialValueFor("explosion_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		ApplyDamage({ victim = e, attacker = p, damage = self.dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
	end
	for _, e in ipairs(FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, a:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		e:AddNewModifier(p, a, "modifier_dota688_freezing_field_slow", { duration = a:GetSpecialValueFor("slow_duration") })
	end
end
function modifier_dota688_freezing_field:OnDestroy() if IsServer() then ParticleManager:DestroyParticle(self.fx, false) end end
modifier_dota688_freezing_field_slow = class({})
function modifier_dota688_freezing_field_slow:IsDebuff() return true end
function modifier_dota688_freezing_field_slow:IsPurgable() return true end
function modifier_dota688_freezing_field_slow:GetTexture() return "crystal_maiden_freezing_field" end
function modifier_dota688_freezing_field_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_freezing_field_slow:GetModifierMoveSpeedBonus_Percentage()
	local a = self:GetAbility()
	if not a or a:IsNull() then return 0 end
	return Dota688HasScepter(self:GetCaster()) and a:GetSpecialValueFor("movespeed_slow_scepter") or a:GetSpecialValueFor("movespeed_slow")
end
function modifier_dota688_freezing_field_slow:GetModifierAttackSpeedBonus_Constant()
	local a = self:GetAbility()
	if not a or a:IsNull() then return 0 end
	return Dota688HasScepter(self:GetCaster()) and a:GetSpecialValueFor("attack_slow_scepter") or a:GetSpecialValueFor("attack_slow")
end
