-- Morph Replicate (6.88): apare in locul lui Replicate cat timp replica traieste; pentru 150 mana Morphling ia locul replicii, care dispare.
dota688_morphling_morph_replicate = class({})
function dota688_morphling_morph_replicate:OnSpellStart()
	local caster = self:GetCaster()
	local m = caster:FindModifierByName("modifier_dota688_morphling_replicate_timer")
	local ill = m and m.illusion
	if not ill or ill:IsNull() or not ill:IsAlive() then   -- replica a murit in timpul cast point-ului
		self:RefundManaCost()
		if m then m:Destroy() end
		return
	end
	local from, to, fwd = caster:GetAbsOrigin(), ill:GetAbsOrigin(), ill:GetForwardVector()
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_morphling/morphling_replicate_finish.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fx, 0, from)
	ParticleManager:ReleaseParticleIndex(fx)
	m:Destroy()   -- replica dispare, bara de abilitati revine la Replicate
	ProjectileManager:ProjectileDodge(caster)
	FindClearSpaceForUnit(caster, to, true)
	caster:SetForwardVector(fwd)
	caster:Stop()
	caster:EmitSound("Hero_Morphling.ReplicateEnd")
	fx = ParticleManager:CreateParticle("particles/units/heroes/hero_morphling/morphling_replicate_finish.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
end
