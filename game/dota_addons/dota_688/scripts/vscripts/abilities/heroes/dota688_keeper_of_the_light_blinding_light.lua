-- Blinding Light (6.88, Aghanim): inamicii din 675 sunt impinsi 525 unitati si rateaza 80% din atacuri 4/5/6 s.
LinkLuaModifier("modifier_dota688_kotl_blinding_light", "abilities/heroes/dota688_keeper_of_the_light_blinding_light", LUA_MODIFIER_MOTION_NONE)
dota688_keeper_of_the_light_blinding_light = class({})
function dota688_keeper_of_the_light_blinding_light:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_keeper_of_the_light_blinding_light:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	EmitSoundOnLocationWithCaster(pos, "Hero_KeeperOfTheLight.BlindingLight", caster)
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_blinding_light_aoe.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fx, 0, pos); ParticleManager:ReleaseParticleIndex(fx)
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		e:AddNewModifier(caster, self, "modifier_dota688_kotl_blinding_light", { duration = self:GetSpecialValueFor("miss_duration") })
		e:AddNewModifier(caster, self, "modifier_knockback", { duration = self:GetSpecialValueFor("knockback_duration"), knockback_duration = self:GetSpecialValueFor("knockback_duration"),
			knockback_distance = self:GetSpecialValueFor("knockback_distance"), knockback_height = self:GetSpecialValueFor("knockback_height"), center_x = pos.x, center_y = pos.y, center_z = pos.z })
	end
end
modifier_dota688_kotl_blinding_light = class({})
function modifier_dota688_kotl_blinding_light:IsDebuff() return true end
function modifier_dota688_kotl_blinding_light:IsPurgable() return true end
function modifier_dota688_kotl_blinding_light:DeclareFunctions() return { MODIFIER_PROPERTY_MISS_PERCENTAGE } end
function modifier_dota688_kotl_blinding_light:GetModifierMiss_Percentage() return self:GetAbility():GetSpecialValueFor("miss_rate") end
