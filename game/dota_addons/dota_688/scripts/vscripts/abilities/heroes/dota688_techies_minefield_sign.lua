-- Minefield Sign (6.88): planteaza un semn (una singura, 180 s). Scepter: minele si capcanele din 125 de semn nu sunt vazute de True Sight.
require("dota688/val")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_techies_minefield_sign"
LinkLuaModifier("modifier_dota688_minefield_sign", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_minefield_sign_hidden", F, LUA_MODIFIER_MOTION_NONE)
dota688_techies_minefield_sign = class({})
function dota688_techies_minefield_sign:GetAOERadius() return self:GetSpecialValueFor("aura_radius") end
function dota688_techies_minefield_sign:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	if caster.dota688_sign and not caster.dota688_sign:IsNull() and caster.dota688_sign:IsAlive() then caster.dota688_sign:ForceKill(false) end
	local sign = CreateUnitByName("npc_dota688_techies_minefield_sign", pos, false, caster, caster:GetPlayerOwner(), caster:GetTeamNumber())
	if not sign then return end
	sign:SetOwner(caster)
	sign:AddNewModifier(caster, self, "modifier_dota688_minefield_sign", { duration = self:GetSpecialValueFor("lifetime") })
	EmitSoundOnLocationWithCaster(pos, "Hero_Techies.Sign", caster)
	caster.dota688_sign = sign
end
modifier_dota688_minefield_sign = class({})
function modifier_dota688_minefield_sign:IsHidden() return true end
function modifier_dota688_minefield_sign:IsPurgable() return false end
function modifier_dota688_minefield_sign:CheckState() return { [MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_DISARMED] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true, [MODIFIER_STATE_NO_HEALTH_BAR] = true, [MODIFIER_STATE_INVULNERABLE] = true, [MODIFIER_STATE_UNSELECTABLE] = true } end
function modifier_dota688_minefield_sign:IsAura() return Dota688HasScepter(self:GetCaster()) end
function modifier_dota688_minefield_sign:GetAuraRadius() return Dota688Val(self, "aura_radius") end
function modifier_dota688_minefield_sign:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_minefield_sign:GetAuraSearchType() return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_OTHER end
function modifier_dota688_minefield_sign:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_dota688_minefield_sign:GetModifierAura() return "modifier_dota688_minefield_sign_hidden" end
function modifier_dota688_minefield_sign:GetAuraEntityReject(unit) return string.find(unit:GetUnitName(), "npc_dota688_techies_", 1, true) ~= 1 end
function modifier_dota688_minefield_sign:OnDestroy() if IsServer() and self:GetParent():IsAlive() then self:GetParent():ForceKill(false) end end
modifier_dota688_minefield_sign_hidden = class({})
function modifier_dota688_minefield_sign_hidden:IsHidden() return true end
function modifier_dota688_minefield_sign_hidden:IsPurgable() return false end
function modifier_dota688_minefield_sign_hidden:CheckState() return { [MODIFIER_STATE_TRUESIGHT_IMMUNE] = true } end
