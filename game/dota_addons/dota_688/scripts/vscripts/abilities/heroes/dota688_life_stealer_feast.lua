-- Feast (6.88): fiecare atac face in plus 4.5/5.5/6.5/7.5% din viata CURENTA a tintei ca daune fizice si il vindeca pe Lifestealer
-- cu aceeasi valoare (independent de daunele reale). Nu functioneaza pe Roshan, cladiri si wards; afecteaza unitatile imune la magie.
-- (Varianta moderna: % din viata maxima, HP permanent la kill-uri - nu exista in 6.88.)
require("dota688/val")
LinkLuaModifier("modifier_dota688_life_stealer_feast", "abilities/heroes/dota688_life_stealer_feast", LUA_MODIFIER_MOTION_NONE)
dota688_life_stealer_feast = class({})
function dota688_life_stealer_feast:GetIntrinsicModifierName() return "modifier_dota688_life_stealer_feast" end

modifier_dota688_life_stealer_feast = class({})
function modifier_dota688_life_stealer_feast:IsHidden() return true end
function modifier_dota688_life_stealer_feast:IsPurgable() return false end
function modifier_dota688_life_stealer_feast:DeclareFunctions() return { MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL } end
function modifier_dota688_life_stealer_feast:GetModifierProcAttack_BonusDamage_Physical(params)
	if not IsServer() then return 0 end
	local parent, t = self:GetParent(), params.target
	if parent:PassivesDisabled() or not t or t:IsNull() or t:IsBuilding() or t:IsOther() then return 0 end
	if t:GetTeamNumber() == parent:GetTeamNumber() or t:GetUnitName() == "npc_dota_roshan" then return 0 end
	local amount = t:GetHealth() * Dota688Val(self, "hp_leech_percent") / 100
	if amount <= 0 then return 0 end
	parent:Heal(amount, self:GetAbility())
	local fx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
	ParticleManager:ReleaseParticleIndex(fx)
	return amount
end
