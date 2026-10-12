-- Caustic Finale (6.88): atacurile aplica un debuff 6 s; daca unitatea moare cu debuff explodeaza (90/130/170/220 daune magice, raza 400, -30% MS 3 s); la expirare 50% daune.
local F = "abilities/heroes/dota688_sandking_caustic_finale"
LinkLuaModifier("modifier_dota688_sandking_caustic_finale", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_sandking_caustic_finale_debuff", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_sandking_caustic_finale_slow", F, LUA_MODIFIER_MOTION_NONE)
dota688_sandking_caustic_finale = class({})
function dota688_sandking_caustic_finale:GetIntrinsicModifierName() return "modifier_dota688_sandking_caustic_finale" end
function dota688_sandking_caustic_finale:Explode(unit, pct)
	local caster = self:GetCaster()
	local r = self:GetSpecialValueFor("caustic_finale_radius")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_sandking/sandking_caustic_finale_explode.vpcf", PATTACH_ABSORIGIN, unit)
	ParticleManager:SetParticleControl(fx, 1, Vector(r, r, r)); ParticleManager:ReleaseParticleIndex(fx)
	unit:EmitSound("Hero_SandKing.CausticFinale")
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), unit:GetAbsOrigin(), nil, r, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		ApplyDamage({ victim = e, attacker = caster, damage = self:GetSpecialValueFor("caustic_finale_damage") * pct / 100, damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
		e:AddNewModifier(caster, self, "modifier_dota688_sandking_caustic_finale_slow", { duration = self:GetSpecialValueFor("caustic_finale_slow_duration") })
	end
end
modifier_dota688_sandking_caustic_finale = class({})
function modifier_dota688_sandking_caustic_finale:IsHidden() return true end
function modifier_dota688_sandking_caustic_finale:IsPurgable() return false end
function modifier_dota688_sandking_caustic_finale:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_sandking_caustic_finale:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() or self:GetParent():PassivesDisabled() then return end
	local t = params.target
	if not t or t:IsBuilding() or t:IsOther() or t:IsMagicImmune() or t:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
	t:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dota688_sandking_caustic_finale_debuff", { duration = self:GetAbility():GetSpecialValueFor("caustic_finale_duration") })
end
modifier_dota688_sandking_caustic_finale_debuff = class({})
function modifier_dota688_sandking_caustic_finale_debuff:IsDebuff() return true end
function modifier_dota688_sandking_caustic_finale_debuff:IsPurgable() return true end
function modifier_dota688_sandking_caustic_finale_debuff:GetEffectName() return "particles/units/heroes/hero_sandking/sandking_caustic_finale_debuff.vpcf" end
function modifier_dota688_sandking_caustic_finale_debuff:DeclareFunctions() return { MODIFIER_EVENT_ON_DEATH } end
function modifier_dota688_sandking_caustic_finale_debuff:OnDeath(params)
	if IsServer() and params.unit == self:GetParent() then self.exploded = true; self:GetAbility():Explode(self:GetParent(), 100) end
end
function modifier_dota688_sandking_caustic_finale_debuff:OnDestroy()
	if IsServer() and not self.exploded and self:GetParent():IsAlive() and self:GetRemainingTime() <= 0.05 then
		self:GetAbility():Explode(self:GetParent(), self:GetAbility():GetSpecialValueFor("caustic_finale_damage_reduced"))
	end
end
modifier_dota688_sandking_caustic_finale_slow = class({})
function modifier_dota688_sandking_caustic_finale_slow:IsDebuff() return true end
function modifier_dota688_sandking_caustic_finale_slow:IsPurgable() return true end
function modifier_dota688_sandking_caustic_finale_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_sandking_caustic_finale_slow:GetModifierMoveSpeedBonus_Percentage() return self:GetAbility():GetSpecialValueFor("caustic_finale_slow") end
