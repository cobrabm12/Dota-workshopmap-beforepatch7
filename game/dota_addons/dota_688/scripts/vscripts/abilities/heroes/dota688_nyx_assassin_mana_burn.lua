-- Mana Burn (6.88): arde eroului tinta mana egala cu 3.5/4/4.5/5 x Inteligenta lui si ii da daune magice egale cu mana arsa.
-- (In 7.x abilitatea a fost inlocuita cu Jolt.)
dota688_nyx_assassin_mana_burn = class({})
function dota688_nyx_assassin_mana_burn:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if not target or target:IsNull() then return end
	caster:EmitSound("Hero_NyxAssassin.ManaBurn.Cast")
	if target:TriggerSpellAbsorb(self) then return end
	local int = target.GetIntellect and target:GetIntellect(true) or 0
	local burn = math.min(target:GetMana(), int * self:GetSpecialValueFor("float_multiplier"))
	target:EmitSound("Hero_NyxAssassin.ManaBurn.Target")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_mana_burn.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:ReleaseParticleIndex(fx)
	if burn <= 0 then return end
	target:Script_ReduceMana(burn, self)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_MANA_LOSS, target, burn, nil)
	ApplyDamage({ victim = target, attacker = caster, damage = burn, damage_type = self:GetAbilityDamageType(), ability = self })
end
