-- Precision Aura (6.88): aura globala: eroii aliati cu atac la distanta primesc +20/26/32/38% din daunele de baza ale lui Drow? Nu:
-- +20/26/32/38% din AGILITATEA lui Drow ca daune pentru eroii aliati ranged. Activ (cd 100): aplica si creepilor timp de 30 s.
require("dota688/val")
local F = "abilities/heroes/dota688_drow_ranger_trueshot"
LinkLuaModifier("modifier_dota688_drow_ranger_trueshot", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_drow_ranger_trueshot_effect", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_drow_ranger_trueshot_creeps", F, LUA_MODIFIER_MOTION_NONE)

dota688_drow_ranger_trueshot = class({})
function dota688_drow_ranger_trueshot:GetIntrinsicModifierName() return "modifier_dota688_drow_ranger_trueshot" end
function dota688_drow_ranger_trueshot:OnSpellStart()
	self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_dota688_drow_ranger_trueshot_creeps", { duration = self:GetDuration() })
	self:GetCaster():EmitSound("Hero_DrowRanger.Trueshot.Cast")
end

modifier_dota688_drow_ranger_trueshot_creeps = class({})
function modifier_dota688_drow_ranger_trueshot_creeps:IsHidden() return false end
function modifier_dota688_drow_ranger_trueshot_creeps:IsPurgable() return false end

modifier_dota688_drow_ranger_trueshot = class({})
function modifier_dota688_drow_ranger_trueshot:IsHidden() return true end
function modifier_dota688_drow_ranger_trueshot:IsPurgable() return false end
function modifier_dota688_drow_ranger_trueshot:IsAura() return true end
function modifier_dota688_drow_ranger_trueshot:GetAuraRadius() return 60000 end
function modifier_dota688_drow_ranger_trueshot:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_drow_ranger_trueshot:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_drow_ranger_trueshot:GetModifierAura() return "modifier_dota688_drow_ranger_trueshot_effect" end
function modifier_dota688_drow_ranger_trueshot:GetAuraEntityReject(unit)
	if not unit:IsRangedAttacker() then return true end
	if unit:IsHero() then return false end
	return not self:GetParent():HasModifier("modifier_dota688_drow_ranger_trueshot_creeps")
end

modifier_dota688_drow_ranger_trueshot_effect = class({})
function modifier_dota688_drow_ranger_trueshot_effect:IsPurgable() return false end
function modifier_dota688_drow_ranger_trueshot_effect:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE } end
function modifier_dota688_drow_ranger_trueshot_effect:GetModifierPreAttack_BonusDamage()
	local caster = self:GetCaster()
	if not caster or caster:IsNull() or caster:PassivesDisabled() then return 0 end
	return math.floor(caster:GetAgility() * Dota688Val(self, "trueshot_ranged_damage") / 100)
end
