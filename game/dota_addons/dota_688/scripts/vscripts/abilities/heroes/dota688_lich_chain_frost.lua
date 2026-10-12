-- Chain Frost (6.88): proiectil (850) care sare de 10 ori intre inamicii din 575; 280/370/460 daune magice, -30% viteza de miscare/atac 4 s.
-- Scepter: 370/460/550 daune, raza de cast 850, -50% incetinire, sarituri nelimitate.
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_chain_frost_slow", "abilities/heroes/dota688_lich_chain_frost", LUA_MODIFIER_MOTION_NONE)
dota688_lich_chain_frost = class({})
function dota688_lich_chain_frost:GetCastRange(location, target)
	if Dota688HasScepter(self:GetCaster()) then return self:GetSpecialValueFor("cast_range_scepter") end
	return self.BaseClass.GetCastRange(self, location, target)
end
function dota688_lich_chain_frost:Launch(from, target, jumps)
	ProjectileManager:CreateTrackingProjectile({
		Target = target, Source = from, Ability = self, EffectName = "particles/units/heroes/hero_lich/lich_chain_frost.vpcf",
		iMoveSpeed = self:GetSpecialValueFor("projectile_speed"), vSourceLoc = from:GetAbsOrigin(), bDodgeable = false, bProvidesVision = true,
		iVisionRadius = self:GetSpecialValueFor("vision_radius"), iVisionTeamNumber = self:GetCaster():GetTeamNumber(), ExtraData = { jumps = jumps },
	})
end
function dota688_lich_chain_frost:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	caster:EmitSound("Hero_Lich.ChainFrost")
	local jumps = Dota688HasScepter(caster) and 100000 or self:GetSpecialValueFor("jumps")
	self:Launch(caster, target, jumps)
end
function dota688_lich_chain_frost:OnProjectileHit_ExtraData(target, location, data)
	if not target then return end
	local caster = self:GetCaster()
	local scepter = Dota688HasScepter(caster)
	target:EmitSound("Hero_Lich.ChainFrostImpact")
	if not target:IsMagicImmune() then
		ApplyDamage({ victim = target, attacker = caster, damage = scepter and self:GetSpecialValueFor("damage_scepter") or self:GetSpecialValueFor("damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
		target:AddNewModifier(caster, self, "modifier_dota688_chain_frost_slow", { duration = self:GetSpecialValueFor("slow_duration") })
	end
	local jumps = (data.jumps or 1) - 1
	if jumps <= 0 then return end
	local next = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, self:GetSpecialValueFor("jump_range"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	local cands = {}
	for _, u in ipairs(next) do if u ~= target then table.insert(cands, u) end end
	if #cands == 0 then return end
	self:Launch(target, cands[RandomInt(1, #cands)], jumps)
end
modifier_dota688_chain_frost_slow = class({})
function modifier_dota688_chain_frost_slow:IsDebuff() return true end
function modifier_dota688_chain_frost_slow:IsPurgable() return true end
function modifier_dota688_chain_frost_slow:GetTexture() return "lich_chain_frost" end
function modifier_dota688_chain_frost_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_chain_frost_slow:GetModifierMoveSpeedBonus_Percentage()
	local a = self:GetAbility()
	if not a or a:IsNull() then return 0 end
	return Dota688HasScepter(self:GetCaster()) and a:GetSpecialValueFor("slow_movement_speed_scepter") or a:GetSpecialValueFor("slow_movement_speed")
end
function modifier_dota688_chain_frost_slow:GetModifierAttackSpeedBonus_Constant()
	local a = self:GetAbility()
	if not a or a:IsNull() then return 0 end
	return Dota688HasScepter(self:GetCaster()) and a:GetSpecialValueFor("slow_attack_speed_scepter") or a:GetSpecialValueFor("slow_attack_speed")
end
