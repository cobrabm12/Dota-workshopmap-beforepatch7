-- Song of the Siren (6.88): toti inamicii din 1250 dorm (invulnerabili, nu pot actiona) 7 s; inamicii care intra in raza sunt si ei adormiti.
-- A doua activare (Cancel) opreste cantecul. Scepter: aliatii din raza se vindeca cu 10% din HP maxim pe secunda.
require("dota688/aghanim")
local F = "abilities/heroes/dota688_naga_siren_song_of_the_siren"
LinkLuaModifier("modifier_dota688_siren_song", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_siren_song_sleep", F, LUA_MODIFIER_MOTION_NONE)
dota688_naga_siren_song_of_the_siren = class({})
function dota688_naga_siren_song_of_the_siren:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_NagaSiren.SongOfTheSiren.Cast")
	caster:AddNewModifier(caster, self, "modifier_dota688_siren_song", { duration = self:GetSpecialValueFor("duration") })
	local cancel = caster:FindAbilityByName("dota688_naga_siren_song_of_the_siren_cancel")
	if cancel then self:SetHidden(true); cancel:SetHidden(false); cancel:SetLevel(1) end
end
function dota688_naga_siren_song_of_the_siren:Stop()
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_dota688_siren_song")
end
modifier_dota688_siren_song = class({})
function modifier_dota688_siren_song:IsPurgable() return false end
function modifier_dota688_siren_song:GetTexture() return "naga_siren_song_of_the_siren" end
function modifier_dota688_siren_song:OnCreated()
	if not IsServer() then return end
	local p, a = self:GetParent(), self:GetAbility()
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_siren/naga_siren_song_aura.vpcf", PATTACH_ABSORIGIN_FOLLOW, p)
	ParticleManager:SetParticleControl(self.fx, 1, Vector(a:GetSpecialValueFor("radius"), 0, 0))
	self:StartIntervalThink(0.25)
end
function modifier_dota688_siren_song:OnIntervalThink()
	if not Dota688HasScepter(self:GetParent()) then return end
	local p, a = self:GetParent(), self:GetAbility()
	for _, u in ipairs(FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, a:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		u:Heal(u:GetMaxHealth() * a:GetSpecialValueFor("regen_rate") / 100 * 0.25, a)
	end
end
function modifier_dota688_siren_song:IsAura() return true end
function modifier_dota688_siren_song:GetAuraRadius() return self:GetAbility():GetSpecialValueFor("radius") end
function modifier_dota688_siren_song:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_dota688_siren_song:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_siren_song:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NONE end
function modifier_dota688_siren_song:GetModifierAura() return "modifier_dota688_siren_song_sleep" end
function modifier_dota688_siren_song:GetAuraDuration() return 0.1 end
function modifier_dota688_siren_song:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.fx, false)
	local p = self:GetParent()
	p:StopSound("Hero_NagaSiren.SongOfTheSiren.Cast")
	local a = self:GetAbility()
	local cancel = p:FindAbilityByName("dota688_naga_siren_song_of_the_siren_cancel")
	if cancel then cancel:SetHidden(true) end
	if a then a:SetHidden(false) end
end
modifier_dota688_siren_song_sleep = class({})
function modifier_dota688_siren_song_sleep:IsDebuff() return true end
function modifier_dota688_siren_song_sleep:IsPurgable() return false end
function modifier_dota688_siren_song_sleep:GetTexture() return "naga_siren_song_of_the_siren" end
function modifier_dota688_siren_song_sleep:GetEffectName() return "particles/units/heroes/hero_siren/naga_siren_song_debuff.vpcf" end
function modifier_dota688_siren_song_sleep:GetOverrideAnimation() return ACT_DOTA_IDLE end
function modifier_dota688_siren_song_sleep:CheckState() return { [MODIFIER_STATE_STUNNED] = true, [MODIFIER_STATE_INVULNERABLE] = true } end
