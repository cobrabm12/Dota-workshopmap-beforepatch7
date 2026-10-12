-- Replicate (6.88): iluzie a unui erou (aliat sau inamic, nu Morphling insusi; raza 700/1100/1500), creata langa Morphling,
-- 30/45/60 s, face 80% din daunele eroului copiat si ia 100% daune. Cat timp iluzia traieste, Replicate e inlocuit de
-- Morph Replicate (150 mana): Morphling ii ia locul, iar iluzia dispare. Daca Morphling moare, iluzia dispare.
require("dota688/aghanim")
local F = "abilities/heroes/dota688_morphling_replicate"
LinkLuaModifier("modifier_dota688_morphling_replicate_timer", F, LUA_MODIFIER_MOTION_NONE)
dota688_morphling_replicate = class({})
function dota688_morphling_replicate:CastFilterResultTarget(target)
	local c = self:GetCaster()
	if target == c then return UF_FAIL_CUSTOM end
	return UnitFilter(target, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, c:GetTeamNumber())
end
function dota688_morphling_replicate:GetCustomCastErrorTarget(target) return "#dota_hud_error_cant_cast_on_self" end
function dota688_morphling_replicate:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if not target or target:IsNull() then return end
	if target:GetTeamNumber() ~= caster:GetTeamNumber() and target:TriggerSpellAbsorb(self) then return end
	local dur = self:GetSpecialValueFor("duration")
	local out = Dota688HasScepter(caster) and self:GetSpecialValueFor("illusion_damage_out_pct_scepter") or self:GetSpecialValueFor("illusion_damage_out_pct")
	local ills = CreateIllusions(caster, target, { outgoing_damage = out, incoming_damage = self:GetSpecialValueFor("illusion_damage_in_pct"), duration = dur }, 1, 0, false, false)
	local ill = ills and ills[1]
	if not ill then return end
	-- replica apare langa Morphling (in 6.88 o lasai in spate si te intorceai la ea cu Morph Replicate)
	FindClearSpaceForUnit(ill, caster:GetAbsOrigin() + caster:GetForwardVector() * 64, true)
	ill:SetForwardVector(caster:GetForwardVector())
	caster:EmitSound("Hero_Morphling.Replicate")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_morphling/morphling_replicate.vpcf", PATTACH_ABSORIGIN_FOLLOW, ill)
	ParticleManager:ReleaseParticleIndex(fx)
	caster:RemoveModifierByName("modifier_dota688_morphling_replicate_timer")
	local m = caster:AddNewModifier(caster, self, "modifier_dota688_morphling_replicate_timer", { duration = dur })
	if m then m.illusion = ill end
	-- Replicate -> Morph Replicate (acelasi loc in bara de abilitati, ca Song of the Siren / Cancel)
	local morph = caster:FindAbilityByName("dota688_morphling_morph_replicate")
	if morph and not self:IsStolen() then
		if morph:GetLevel() < morph:GetMaxLevel() then morph:SetLevel(morph:GetMaxLevel()) end   -- toate nivelurile sunt egale (150 mana); nu se poate "invata"
		morph:SetActivated(true)
		self:SetHidden(true)
		morph:SetHidden(false)
	end
end

-- pe Morphling, cat traieste replica: o tine minte, o omoara la moartea lui Morphling si reface bara de abilitati
modifier_dota688_morphling_replicate_timer = class({})
function modifier_dota688_morphling_replicate_timer:IsPurgable() return false end
function modifier_dota688_morphling_replicate_timer:GetTexture() return "morphling_replicate" end
function modifier_dota688_morphling_replicate_timer:OnCreated()
	if IsServer() then self:StartIntervalThink(0.1) end
end
function modifier_dota688_morphling_replicate_timer:OnIntervalThink()
	local ill = self.illusion
	if not ill or ill:IsNull() or not ill:IsAlive() then self:Destroy() end
end
function modifier_dota688_morphling_replicate_timer:OnDestroy()
	if not IsServer() then return end
	local ill = self.illusion
	self.illusion = nil
	if ill and not ill:IsNull() and ill:IsAlive() then
		ill:AddNoDraw()
		ill:ForceKill(false)
	end
	local p = self:GetParent()
	if p:IsNull() then return end
	local morph = p:FindAbilityByName("dota688_morphling_morph_replicate")
	if morph then morph:SetHidden(true) end
	local a = self:GetAbility()
	if a and not a:IsNull() then a:SetHidden(false) end
end
