-- Repel (6.88): unitatea tinta primeste imunitate la vraji si 100% rezistenta la daune magice 5/6/7/8 s (raza 500, cd 20/18/16/14).
-- Ca orice imunitate la vraji (purge la aplicare), dar poate fi scoasa cu purge. Tinta (KV 6.88, TEAM_BOTH): aliat sau inamic, erou sau unitate.
LinkLuaModifier("modifier_dota688_omniknight_repel", "abilities/heroes/dota688_omniknight_repel", LUA_MODIFIER_MOTION_NONE)
dota688_omniknight_repel = class({})
function dota688_omniknight_repel:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if not target or target:IsNull() then return end
	local ally = target:GetTeamNumber() == caster:GetTeamNumber()
	if not ally and target:TriggerSpellAbsorb(self) then return end
	-- purge de baza la aplicare, ca la celelalte imunitati 6.88 (Rage, BKB): debuff-urile aliatului / buff-urile inamicului
	target:Purge(not ally, ally, false, false, false)
	target:EmitSound("Hero_Omniknight.Repel")
	target:AddNewModifier(caster, self, "modifier_dota688_omniknight_repel", { duration = self:GetSpecialValueFor("duration") })
end

modifier_dota688_omniknight_repel = class({})
function modifier_dota688_omniknight_repel:IsPurgable() return true end
function modifier_dota688_omniknight_repel:GetTexture() return "omniknight_repel" end
function modifier_dota688_omniknight_repel:GetEffectName() return "particles/units/heroes/hero_omniknight/omniknight_repel_buff.vpcf" end
function modifier_dota688_omniknight_repel:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
-- MAGIC_IMMUNE = imunitatea 6.88; DEBUFF_IMMUNE = acelasi lucru pentru abilitatile C++ moderne (7.33+ verifica "debuff immunity")
function modifier_dota688_omniknight_repel:CheckState() return { [MODIFIER_STATE_MAGIC_IMMUNE] = true, [MODIFIER_STATE_DEBUFF_IMMUNE] = true } end
function modifier_dota688_omniknight_repel:DeclareFunctions() return { MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL } end
function modifier_dota688_omniknight_repel:GetAbsoluteNoDamageMagical() return 1 end
