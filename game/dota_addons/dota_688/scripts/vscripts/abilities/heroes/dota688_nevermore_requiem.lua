-- Requiem of Souls (6.88): o linie de energie (80/120/160 daune magice, 125->425 latime, 1000 raza, viteza 700) pentru fiecare 2 suflete;
-- inamicii din 700 la lansare au -25% viteza si -50% daune 5 s. Se lanseaza automat la moartea lui Shadow Fiend (cu sufletele din acel moment).
-- Scepter: liniile se intorc la Shadow Fiend cu 40% daune si il vindeca cu 100% din daunele facute la intoarcere; +4/6/8/10 suflete maxime (Necromastery).
require("dota688/aghanim")
local F = "abilities/heroes/dota688_nevermore_requiem"
LinkLuaModifier("modifier_dota688_requiem_slow", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_requiem_passive", F, LUA_MODIFIER_MOTION_NONE)
dota688_nevermore_requiem = class({})
function dota688_nevermore_requiem:GetIntrinsicModifierName() return "modifier_dota688_requiem_passive" end
function dota688_nevermore_requiem:Souls()
	local m = self:GetCaster():FindModifierByName("modifier_dota688_necromastery")
	return m and m:GetStackCount() or 0
end
function dota688_nevermore_requiem:Line(from, dir, returning)
	local caster = self:GetCaster()
	ProjectileManager:CreateLinearProjectile({
		Ability = self, EffectName = "particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf", vSpawnOrigin = from,
		fDistance = self:GetSpecialValueFor("requiem_radius"), fStartRadius = self:GetSpecialValueFor("requiem_line_width_start"), fEndRadius = self:GetSpecialValueFor("requiem_line_width_end"),
		Source = caster, bHasFrontalCone = true, bReplaceExisting = false, iUnitTargetTeam = DOTA_UNIT_TARGET_TEAM_ENEMY,
		iUnitTargetFlags = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, iUnitTargetType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
		fExpireTime = GameRules:GetGameTime() + 5, bDeleteOnHit = false, vVelocity = dir * self:GetSpecialValueFor("requiem_line_speed"), bProvidesVision = false,
		ExtraData = { returning = returning and 1 or 0 },
	})
end
function dota688_nevermore_requiem:Release(onDeath)
	local caster = self:GetCaster()
	local lines = math.floor(self:Souls() / self:GetSpecialValueFor("requiem_soul_conversion"))
	caster:EmitSound("Hero_Nevermore.RequiemOfSouls")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	-- incetinire + reducere de daune pentru inamicii din 700
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("requiem_reduction_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)) do
		e:AddNewModifier(caster, self, "modifier_dota688_requiem_slow", { duration = self:GetSpecialValueFor("requiem_slow_duration") })
	end
	if lines <= 0 then return end
	local origin = caster:GetAbsOrigin()
	local scepter = Dota688HasScepter(caster)
	for i = 0, lines - 1 do
		local ang = 2 * math.pi * i / lines
		local dir = Vector(math.cos(ang), math.sin(ang), 0)
		self:Line(origin, dir, false)
		if scepter then
			local travel = self:GetSpecialValueFor("requiem_radius") / self:GetSpecialValueFor("requiem_line_speed")
			Dota688Timers:After(travel, function()
				if self:IsNull() or caster:IsNull() then return end
				local start = origin + dir * self:GetSpecialValueFor("requiem_radius")
				local back = caster:GetAbsOrigin() - start; back.z = 0
				if back:Length2D() < 1 then back = -dir end
				self:Line(start, back:Normalized(), true)
			end)
		end
	end
	if onDeath then
		local m = caster:FindModifierByName("modifier_dota688_necromastery")
		if m then m:SetStackCount(math.floor(m:GetStackCount() * 0.5)) end
	end
end
function dota688_nevermore_requiem:OnSpellStart() self:Release(false) end
function dota688_nevermore_requiem:OnProjectileHit_ExtraData(target, location, data)
	if not target or target:IsMagicImmune() then return end
	local caster = self:GetCaster()
	local dmg = self:GetAbilityDamage()
	if data.returning == 1 then
		dmg = dmg * self:GetSpecialValueFor("requiem_damage_pct_scepter") / 100
		local before = target:GetHealth()
		ApplyDamage({ victim = target, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
		caster:Heal((before - target:GetHealth()) * self:GetSpecialValueFor("requiem_heal_pct_scepter") / 100, self)
	else
		ApplyDamage({ victim = target, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
	end
end
modifier_dota688_requiem_slow = class({})
function modifier_dota688_requiem_slow:IsDebuff() return true end
function modifier_dota688_requiem_slow:IsPurgable() return true end
function modifier_dota688_requiem_slow:GetTexture() return "nevermore_requiem" end
function modifier_dota688_requiem_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE } end
function modifier_dota688_requiem_slow:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("requiem_reduction_ms") end
function modifier_dota688_requiem_slow:GetModifierBaseDamageOutgoing_Percentage() return self:GetAbility():GetSpecialValueFor("requiem_reduction_damage") end
-- la moarte: Requiem automat
modifier_dota688_requiem_passive = class({})
function modifier_dota688_requiem_passive:IsHidden() return true end
function modifier_dota688_requiem_passive:IsPurgable() return false end
function modifier_dota688_requiem_passive:RemoveOnDeath() return false end
function modifier_dota688_requiem_passive:DeclareFunctions() return { MODIFIER_EVENT_ON_DEATH } end
function modifier_dota688_requiem_passive:OnDeath(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	local a = self:GetAbility()
	if not a or a:IsNull() then return end
	if a:GetLevel() < 1 or self:GetParent():IsReincarnating() or self:GetParent():IsIllusion() then return end
	a:Release(true)
end
