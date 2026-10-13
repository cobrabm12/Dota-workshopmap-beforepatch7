-- Mana Shield (6.88, toggle, 4 niveluri): cat e activ, 60% din daunele primite sunt absorbite cu mana Medusei,
-- 1.6/1.9/2.2/2.5 daune per punct de mana. Mana se calculeaza pe daunele dinainte de armura/rezistenta (nota 6.88).
-- Fara mana suficienta absoarbe doar cat permite mana ramasa. (In 7.x e innate, 98%, ascunsa.)
require("dota688/val")
LinkLuaModifier("modifier_dota688_medusa_mana_shield", "abilities/heroes/dota688_medusa_mana_shield", LUA_MODIFIER_MOTION_NONE)
dota688_medusa_mana_shield = class({})
function dota688_medusa_mana_shield:OnToggle()
	local caster = self:GetCaster()
	if self:GetToggleState() then
		caster:AddNewModifier(caster, self, "modifier_dota688_medusa_mana_shield", {})
		caster:EmitSound("Hero_Medusa.ManaShield.On")
	else
		caster:RemoveModifierByName("modifier_dota688_medusa_mana_shield")
		caster:EmitSound("Hero_Medusa.ManaShield.Off")
	end
end

modifier_dota688_medusa_mana_shield = class({})
function modifier_dota688_medusa_mana_shield:IsPurgable() return false end
function modifier_dota688_medusa_mana_shield:RemoveOnDeath() return false end
function modifier_dota688_medusa_mana_shield:AllowIllusionDuplicate() return true end
function modifier_dota688_medusa_mana_shield:GetTexture() return "medusa_mana_shield" end
function modifier_dota688_medusa_mana_shield:GetEffectName() return "particles/units/heroes/hero_medusa/medusa_mana_shield.vpcf" end
function modifier_dota688_medusa_mana_shield:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_medusa_mana_shield:DeclareFunctions() return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_dota688_medusa_mana_shield:GetModifierIncomingDamage_Percentage(params)
	if not IsServer() then return 0 end
	if not params then return 0 end
	local p = self:GetParent()
	local raw = params.original_damage or params.damage or 0
	if raw <= 0 or (params.damage_flags and bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= 0) then return 0 end
	local absorb = Dota688Val(self, "absorption_tooltip")   -- 60 (singura cheie 6.88 cu procentul)
	if absorb <= 0 then absorb = 60 end
	local dpm = Dota688Val(self, "damage_per_mana")
	if dpm <= 0 then return 0 end
	local need = raw * absorb / 100 / dpm
	local mana = p:GetMana()
	if mana <= 0 then return 0 end
	local spent = math.min(mana, need)
	p:SpendMana(spent, self:GetAbility())
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_medusa/medusa_mana_shield_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, p)
	ParticleManager:SetParticleControl(fx, 1, Vector(spent, 0, 0))
	ParticleManager:ReleaseParticleIndex(fx)
	p:EmitSound("Hero_Medusa.ManaShield.Proc")
	return -absorb * spent / need
end
