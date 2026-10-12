-- Reality Rift (6.88): CK si tinta sunt teleportati intr-un punct aleator intre ei; urmatorul atac al lui CK in 1.2 s are +60/100/140/180 daune.
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
end
modifier_dota688_ck_rift_damage = class({})
function modifier_dota688_ck_rift_damage:IsHidden() return true end
function modifier_dota688_ck_rift_damage:IsPurgable() return false end
function modifier_dota688_ck_rift_damage:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_ck_rift_damage:GetModifierPreAttack_BonusDamage() return Dota688Val(self, "bonus_damage") end
function modifier_dota688_ck_rift_damage:OnAttackLanded(params) if IsServer() and params.attacker == self:GetParent() then self:Destroy() end end
