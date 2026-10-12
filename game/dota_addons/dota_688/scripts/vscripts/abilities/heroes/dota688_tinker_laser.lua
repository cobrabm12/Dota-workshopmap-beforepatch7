-- Laser (6.88): 80/160/240/320 daune pure + 100% miss 3/3.5/4/4.5 s (6 s pe creepi). Scepter: se refracta la toti inamicii vizibili din 650 (in lant).
require("dota688/val")
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_laser_blind", "abilities/heroes/dota688_tinker_laser", LUA_MODIFIER_MOTION_NONE)
dota688_tinker_laser = class({})
function dota688_tinker_laser:Hit(source, target)
	local caster = self:GetCaster()
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_tinker/tinker_laser.vpcf", PATTACH_ABSORIGIN_FOLLOW, source)
	ParticleManager:SetParticleControlEnt(fx, 9, source, PATTACH_POINT_FOLLOW, source == caster and "attach_attack2" or "attach_hitloc", source:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
	target:EmitSound("Hero_Tinker.LaserImpact")
	if target:IsMagicImmune() then return end
	ApplyDamage({ victim = target, attacker = caster, damage = self:GetAbilityDamage(), damage_type = DAMAGE_TYPE_PURE, ability = self })
	local dur = target:IsHero() and self:GetSpecialValueFor("duration_hero") or self:GetSpecialValueFor("duration_creep")
	target:AddNewModifier(caster, self, "modifier_dota688_laser_blind", { duration = dur })
end
function dota688_tinker_laser:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	caster:EmitSound("Hero_Tinker.Laser")
	self:Hit(caster, target)
	if not Dota688HasScepter(caster) then return end
	-- refractie: din fiecare tinta lovita, spre toti inamicii vizibili din 650 care nu au fost loviti
	local hit, queue = { [target:entindex()] = true }, { target }
	local range = self:GetSpecialValueFor("cast_range_scepter")
	while #queue > 0 do
		local from = table.remove(queue, 1)
		for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), from:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_FOW_VISIBLE + DOTA_UNIT_TARGET_FLAG_NO_INVIS, FIND_ANY_ORDER, false)) do
			if not hit[e:entindex()] then
				hit[e:entindex()] = true
				self:Hit(from, e)
				table.insert(queue, e)
			end
		end
	end
end
modifier_dota688_laser_blind = class({})
function modifier_dota688_laser_blind:IsDebuff() return true end
function modifier_dota688_laser_blind:IsPurgable() return true end
function modifier_dota688_laser_blind:GetTexture() return "tinker_laser" end
function modifier_dota688_laser_blind:DeclareFunctions() return { MODIFIER_PROPERTY_MISS_PERCENTAGE } end
function modifier_dota688_laser_blind:GetModifierMiss_Percentage() return Dota688Val(self, "miss_rate") end
