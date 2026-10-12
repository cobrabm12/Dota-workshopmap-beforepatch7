-- Return (6.88, ursul de nivel 2+): ursul se teleporteaza instant langa Lone Druid; cooldown 5 s. Nu merge daca ursul a primit daune
-- de la o unitate a unui jucator in ultimele 3 s (marcajul pus de dota688_lone_druid_spirit_bear.lua).
-- (Varianta moderna: canalizare de 3 s, cooldown 30 - nu exista in 6.88.)
dota688_lone_druid_spirit_bear_return = class({})
function dota688_lone_druid_spirit_bear_return:CastFilterResult()
	if self:GetCaster():HasModifier("modifier_dota688_lone_druid_spirit_bear_recent_damage") then return UF_FAIL_CUSTOM end
	return UF_SUCCESS
end
function dota688_lone_druid_spirit_bear_return:GetCustomCastError() return "#dota688_bear_recently_damaged" end
function dota688_lone_druid_spirit_bear_return:OnSpellStart()
	local bear = self:GetCaster()
	local owner = bear.dota688_bear_owner or bear:GetOwner()
	if not owner or owner:IsNull() or not owner:IsAlive() then
		self:EndCooldown()
		return
	end
	local start = ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/lone_druid_bear_blink_start.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(start, 0, bear:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(start)
	EmitSoundOnLocationWithCaster(bear:GetAbsOrigin(), "LoneDruid_SpiritBear.Return", bear)
	FindClearSpaceForUnit(bear, owner:GetAbsOrigin() + RandomVector(100), true)
	bear:Stop()
	local finish = ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/lone_druid_bear_blink_end.vpcf", PATTACH_ABSORIGIN, bear)
	ParticleManager:ReleaseParticleIndex(finish)
end
