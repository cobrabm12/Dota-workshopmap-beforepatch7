-- Rip Tide (6.88, activa, fara tinta; cd 10, 80/90/100/110 mana): Naga si toate imaginile ei lovesc inamicii din 320 cu un val:
-- 100/140/180/220 daune magice si -2/3/4/5 armura 8 s. Un inamic prins in mai multe valuri e lovit o singura data.
-- (Varianta pasiva "la fiecare N atacuri" e din 7.x.)
require("dota688/val")
LinkLuaModifier("modifier_dota688_naga_siren_rip_tide", "abilities/heroes/dota688_naga_siren_rip_tide", LUA_MODIFIER_MOTION_NONE)
dota688_naga_siren_rip_tide = class({})
-- Naga + iluziile ei (Mirror Image, Manta) controlate de acelasi jucator
function dota688_naga_siren_rip_tide:Sources()
	local caster = self:GetCaster()
	local out = { caster }
	if caster:IsIllusion() then return out end
	local pid = caster:GetPlayerOwnerID()
	for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)) do
		if u ~= caster and u:IsIllusion() and u:IsAlive() and u:GetUnitName() == caster:GetUnitName() and u:GetPlayerOwnerID() == pid then
			table.insert(out, u)
		end
	end
	return out
end
function dota688_naga_siren_rip_tide:OnSpellStart()
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")
	local damage = self:GetAbilityDamage()
	local hit = {}
	for _, src in ipairs(self:Sources()) do
		local pos = src:GetAbsOrigin()
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_siren/naga_siren_riptide.vpcf", PATTACH_ABSORIGIN_FOLLOW, src)
		ParticleManager:SetParticleControl(fx, 1, Vector(radius, radius, radius))
		ParticleManager:SetParticleControl(fx, 3, Vector(radius, 0, 0))
		ParticleManager:ReleaseParticleIndex(fx)
		src:EmitSound("Hero_NagaSiren.Riptide.Cast")
		for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
			local id = e:entindex()
			if not hit[id] then
				hit[id] = true
				e:AddNewModifier(caster, self, "modifier_dota688_naga_siren_rip_tide", { duration = duration })
				ApplyDamage({ victim = e, attacker = caster, damage = damage, damage_type = self:GetAbilityDamageType(), ability = self })
			end
		end
	end
end

modifier_dota688_naga_siren_rip_tide = class({})
function modifier_dota688_naga_siren_rip_tide:IsDebuff() return true end
function modifier_dota688_naga_siren_rip_tide:IsPurgable() return true end
function modifier_dota688_naga_siren_rip_tide:GetTexture() return "naga_siren_rip_tide" end
function modifier_dota688_naga_siren_rip_tide:GetEffectName() return "particles/units/heroes/hero_siren/naga_siren_riptide_debuff.vpcf" end
function modifier_dota688_naga_siren_rip_tide:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_naga_siren_rip_tide:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function modifier_dota688_naga_siren_rip_tide:GetModifierPhysicalArmorBonus() return Dota688Val(self, "armor_reduction") end
