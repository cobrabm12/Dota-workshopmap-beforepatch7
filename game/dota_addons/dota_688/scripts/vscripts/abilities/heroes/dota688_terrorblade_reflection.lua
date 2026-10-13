-- Reflection (6.88): fara tinta; fiecare erou inamic din 900 in jurul lui Terrorblade este incetinit cu 25% viteza de miscare si
-- 25 viteza de atac si este atacat de o reflexie a lui insusi (iluzie invulnerabila, care nu poate fi tintita si ataca doar
-- sursa) cu 40/60/80/100% din daunele lui, timp de 2.5/3.5/4.5/5.5 s. Nu afecteaza unitatile imune la magie.
-- Fara varianta moderna tintita pe zona (raza 400 la 700 de unitati).
require("dota688/val")
local F = "abilities/heroes/dota688_terrorblade_reflection"
LinkLuaModifier("modifier_dota688_terrorblade_reflection_slow", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_terrorblade_reflection_illusion", F, LUA_MODIFIER_MOTION_NONE)

dota688_terrorblade_reflection = class({})
function dota688_terrorblade_reflection:GetCastAnimation() return ACT_DOTA_CAST_ABILITY_1 end
function dota688_terrorblade_reflection:OnSpellStart()
	local caster = self:GetCaster()
	local dur = self:GetSpecialValueFor("illusion_duration")
	local out = self:GetSpecialValueFor("illusion_outgoing_damage")
	caster:EmitSound("Hero_Terrorblade.Reflection")
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("range"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if e:IsHero() and not e:IsMagicImmune() then
			e:AddNewModifier(caster, self, "modifier_dota688_terrorblade_reflection_slow", { duration = dur })
			local ills = CreateIllusions(caster, e, { outgoing_damage = out, incoming_damage = 0, bounty_base = 0, bounty_growth = 0, duration = dur }, 1, 72, false, true)
			local ill = ills and ills[1]
			if ill then
				ill:AddNewModifier(caster, self, "modifier_dota688_terrorblade_reflection_illusion", { duration = dur, target = e:entindex() })
				ill:SetForceAttackTarget(e)
			end
		end
	end
end

-- incetinirea de pe eroul reflectat
modifier_dota688_terrorblade_reflection_slow = class({})
function modifier_dota688_terrorblade_reflection_slow:IsDebuff() return true end
function modifier_dota688_terrorblade_reflection_slow:IsPurgable() return true end
function modifier_dota688_terrorblade_reflection_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_terrorblade_reflection_slow:GetModifierMoveSpeedBonus_Percentage() return -Dota688Val(self, "move_slow") end
function modifier_dota688_terrorblade_reflection_slow:GetModifierAttackSpeedBonus_Constant() return -Dota688Val(self, "attack_slow_tooltip") end

-- reflexia: invulnerabila, nu poate fi tintita/selectata, ataca doar sursa; dispare daca sursa moare
modifier_dota688_terrorblade_reflection_illusion = class({})
function modifier_dota688_terrorblade_reflection_illusion:IsHidden() return true end
function modifier_dota688_terrorblade_reflection_illusion:IsPurgable() return false end
function modifier_dota688_terrorblade_reflection_illusion:OnCreated(kv)
	if not IsServer() then return end
	self.target = kv.target and EntIndexToHScript(kv.target) or nil
	self:StartIntervalThink(0.1)
end
function modifier_dota688_terrorblade_reflection_illusion:OnIntervalThink()
	local p, t = self:GetParent(), self.target
	if not t or t:IsNull() or not t:IsAlive() then
		p:ForceKill(false)
		return
	end
	p:SetForceAttackTarget(t)
end
function modifier_dota688_terrorblade_reflection_illusion:GetStatusEffectName() return "particles/status_fx/status_effect_terrorblade_reflection.vpcf" end
function modifier_dota688_terrorblade_reflection_illusion:StatusEffectPriority() return 10 end
function modifier_dota688_terrorblade_reflection_illusion:CheckState()
	return {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_UNTARGETABLE] = true,
		[MODIFIER_STATE_UNSELECTABLE] = true,
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
	}
end
