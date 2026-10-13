-- Refraction (6.88): doua efecte separate, fiecare cu 3/4/5/6 instante, 17 s:
--   * evitare: orice instanta de daune de cel putin 5 (nu HP Removal) e anulata complet si consuma o instanta;
--   * daune: +20/40/60/80 daune pe atac, fiecare atac consuma o instanta.
-- Abilitatea curenta foloseste o bariera de 30 HP per instanta (consumata doar cand se sparge).
require("dota688/val")
local F = "abilities/heroes/dota688_templar_assassin_refraction"
LinkLuaModifier("modifier_dota688_refraction_absorb", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_refraction_damage", F, LUA_MODIFIER_MOTION_NONE)

dota688_templar_assassin_refraction = class({})
function dota688_templar_assassin_refraction:OnSpellStart()
	local caster = self:GetCaster()
	local dur, n = self:GetSpecialValueFor("duration"), self:GetSpecialValueFor("instances")
	caster:EmitSound("Hero_TemplarAssassin.Refraction")
	local a = caster:AddNewModifier(caster, self, "modifier_dota688_refraction_absorb", { duration = dur })
	if a then a:SetStackCount(n) end
	local d = caster:AddNewModifier(caster, self, "modifier_dota688_refraction_damage", { duration = dur })
	if d then d:SetStackCount(n) end
end

modifier_dota688_refraction_absorb = class({})
function modifier_dota688_refraction_absorb:IsPurgable() return false end
function modifier_dota688_refraction_absorb:GetTexture() return "templar_assassin_refraction" end
function modifier_dota688_refraction_absorb:OnCreated()
	if not IsServer() then return end
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_templar_assassin/templar_assassin_refraction.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:SetParticleControlEnt(self.fx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
end
function modifier_dota688_refraction_absorb:OnDestroy()
	if IsServer() and self.fx then ParticleManager:DestroyParticle(self.fx, false); ParticleManager:ReleaseParticleIndex(self.fx) end
end
function modifier_dota688_refraction_absorb:DeclareFunctions() return { MODIFIER_PROPERTY_AVOID_DAMAGE } end
function modifier_dota688_refraction_absorb:GetModifierAvoidDamage(params)
	if not IsServer() then return 0 end
	if bit.band(params.damage_flags or 0, DOTA_DAMAGE_FLAG_HPLOSS) ~= 0 then return 0 end   -- HP Removal trece
	if (params.original_damage or params.damage or 0) < Dota688Val(self, "damage_threshold") then return 0 end
	local p = self:GetParent()
	p:EmitSound("Hero_TemplarAssassin.Refraction.Absorb")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_templar_assassin/templar_assassin_refract_hit.vpcf", PATTACH_CUSTOMORIGIN, p)
	ParticleManager:SetParticleControlEnt(fx, 0, p, PATTACH_POINT_FOLLOW, "attach_hitloc", p:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
	if self:GetStackCount() <= 1 then self:Destroy() else self:DecrementStackCount() end
	return 1
end

modifier_dota688_refraction_damage = class({})
function modifier_dota688_refraction_damage:IsPurgable() return false end
function modifier_dota688_refraction_damage:GetTexture() return "templar_assassin_refraction" end
function modifier_dota688_refraction_damage:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_refraction_damage:GetModifierPreAttack_BonusDamage() return Dota688Val(self, "bonus_damage") end
function modifier_dota688_refraction_damage:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() then return end
	params.target:EmitSound("Hero_TemplarAssassin.Refraction.Damage")
	if self:GetStackCount() <= 1 then self:Destroy() else self:DecrementStackCount() end
end
