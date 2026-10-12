-- Crippling Fear (6.88): silence + sansa de ratare (10% ziua / 50% noaptea); durata 3 s ziua, 5/6/7/8 s noaptea.
LinkLuaModifier("modifier_dota688_night_stalker_crippling_fear", "abilities/heroes/dota688_night_stalker_crippling_fear", LUA_MODIFIER_MOTION_NONE)
dota688_night_stalker_crippling_fear = class({})
function dota688_night_stalker_crippling_fear:OnSpellStart()
	local target = self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	local night = not GameRules:IsDaytime()
	local duration = night and self:GetSpecialValueFor("duration_night") or self:GetSpecialValueFor("duration_day")
	target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_night_stalker_crippling_fear", { duration = duration })
	target:EmitSound("Hero_Nightstalker.Trickling_Fear")
end
modifier_dota688_night_stalker_crippling_fear = class({})
function modifier_dota688_night_stalker_crippling_fear:IsDebuff() return true end
function modifier_dota688_night_stalker_crippling_fear:IsPurgable() return true end
function modifier_dota688_night_stalker_crippling_fear:GetEffectName() return "particles/units/heroes/hero_night_stalker/nightstalker_crippling_fear.vpcf" end
function modifier_dota688_night_stalker_crippling_fear:CheckState() return { [MODIFIER_STATE_SILENCED] = true } end
function modifier_dota688_night_stalker_crippling_fear:DeclareFunctions() return { MODIFIER_PROPERTY_MISS_PERCENTAGE } end
function modifier_dota688_night_stalker_crippling_fear:GetModifierMiss_Percentage()
	if GameRules:IsDaytime() then return self:GetAbility():GetSpecialValueFor("miss_rate_day") end
	return self:GetAbility():GetSpecialValueFor("miss_rate_night")
end
