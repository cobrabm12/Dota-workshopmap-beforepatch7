-- Test of Faith (6.88): doar pe inamici (eroi/unitati, nu Ancient); daune pure aleatoare intre 50/100/150/200 si
-- 100/200/300/400. (Varianta curenta tinteste si aliati, pe care ii vindeca.)
dota688_chen_test_of_faith = class({})
function dota688_chen_test_of_faith:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	target:EmitSound("Hero_Chen.TestOfFaith.Target")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_chen/chen_test_of_faith.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:ReleaseParticleIndex(fx)
	local lo, hi = self:GetSpecialValueFor("damage_min"), self:GetSpecialValueFor("damage_max")
	ApplyDamage({ victim = target, attacker = caster, damage = RandomInt(math.min(lo, hi), math.max(lo, hi)), damage_type = DAMAGE_TYPE_PURE, ability = self })
end
