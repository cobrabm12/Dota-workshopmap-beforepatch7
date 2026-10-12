-- Reality Rift (6.88): CK, iluziile lui si tinta sunt teleportati intr-un punct aleator intre ei si ataca tinta; urmatorul atac al lui CK
-- in 1.2 s are +60/100/140/180 daune.
require("dota688/val")
LinkLuaModifier("modifier_dota688_ck_rift_damage", "abilities/heroes/dota688_chaos_knight_reality_rift", LUA_MODIFIER_MOTION_NONE)
dota688_chaos_knight_reality_rift = class({})
function dota688_chaos_knight_reality_rift:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	local a, b = caster:GetAbsOrigin(), target:GetAbsOrigin()
	local mid = a + (b - a) * RandomFloat(0.3, 0.7)
	local dir = (b - a):Normalized()
	caster:EmitSound("Hero_ChaosKnight.RealityRift")
	FindClearSpaceForUnit(caster, mid - dir * 60, true)
	FindClearSpaceForUnit(target, mid + dir * 60, true)
	caster:SetForwardVector(dir); target:SetForwardVector(-dir)
	caster:AddNewModifier(caster, self, "modifier_dota688_ck_rift_damage", { duration = self:GetSpecialValueFor("bonus_duration") })
	caster:MoveToTargetToAttack(target)
	-- "teleports you, any images you have, and the target unit"
	local pid = caster:GetPlayerOwnerID()
	for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, 1500, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if u ~= caster and u:IsIllusion() and u:GetPlayerOwnerID() == pid and u:GetUnitName() == caster:GetUnitName() then
			FindClearSpaceForUnit(u, mid - dir * 60 + RandomVector(80), true)
			u:SetForwardVector(dir)
			u:MoveToTargetToAttack(target)
		end
	end
end
modifier_dota688_ck_rift_damage = class({})
function modifier_dota688_ck_rift_damage:IsHidden() return true end
function modifier_dota688_ck_rift_damage:IsPurgable() return false end
function modifier_dota688_ck_rift_damage:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_ck_rift_damage:GetModifierPreAttack_BonusDamage() return Dota688Val(self, "bonus_damage") end
function modifier_dota688_ck_rift_damage:OnAttackLanded(params) if IsServer() and params.attacker == self:GetParent() then self:Destroy() end end
