-- Hybrid (6.88, oferita de scepter): creeaza o copie a unui erou aliat (raza 600), cu abilitatile lui, pentru 20 s; face 80% daune (fara scepter 50%).
require("dota688/aghanim")
require("dota688/herocopy")
dota688_morphling_hybrid = class({})
function dota688_morphling_hybrid:CastFilterResultTarget(target)
	local c = self:GetCaster()
	if target == c then return UF_FAIL_CUSTOM end
	if not target:IsRealHero() or target:GetTeamNumber() ~= c:GetTeamNumber() then return UF_FAIL_FRIENDLY end
	return UF_SUCCESS
end
function dota688_morphling_hybrid:GetCustomCastErrorTarget(target) return "#dota_hud_error_cant_cast_on_self" end
function dota688_morphling_hybrid:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	local out = Dota688HasScepter(caster) and self:GetSpecialValueFor("illusion_damage_out_pct_scepter") or self:GetSpecialValueFor("illusion_damage_out_pct")
	caster:EmitSound("Hero_Morphling.Replicate")
	if caster.dota688_hybrid and not caster.dota688_hybrid:IsNull() and caster.dota688_hybrid:IsAlive() then caster.dota688_hybrid:ForceKill(false) end
	caster.dota688_hybrid = Dota688CreateHeroCopy(target, caster, caster:GetAbsOrigin() + RandomVector(100), self:GetSpecialValueFor("duration"), out, self:GetSpecialValueFor("illusion_damage_in_pct"))
end
