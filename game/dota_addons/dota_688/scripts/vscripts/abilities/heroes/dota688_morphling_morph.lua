-- Morph (6.88, pasiv ascuns): Morphling primeste +3/4/5/6 STR si AGI permanent, in functie de nivelul lui Morph (Agi/Str).
require("dota688/val")
LinkLuaModifier("modifier_dota688_morphling_morph", "abilities/heroes/dota688_morphling_morph", LUA_MODIFIER_MOTION_NONE)
dota688_morphling_morph = class({})
function dota688_morphling_morph:GetIntrinsicModifierName() return "modifier_dota688_morphling_morph" end
function dota688_morphling_morph:IsHidden() return true end
modifier_dota688_morphling_morph = class({})
function modifier_dota688_morphling_morph:IsHidden() return true end
function modifier_dota688_morphling_morph:IsPurgable() return false end
function modifier_dota688_morphling_morph:RemoveOnDeath() return false end
function modifier_dota688_morphling_morph:OnCreated() if IsServer() then self:StartIntervalThink(1.0) end end
function modifier_dota688_morphling_morph:OnIntervalThink()
	local morph = self:GetParent():FindAbilityByName("morphling_morph_agi")
	local lvl = morph and morph:GetLevel() or 0
	if lvl ~= self:GetStackCount() then self:SetStackCount(lvl) end
	local a = self:GetAbility()
	if not a or a:IsNull() then self:Destroy(); return end   -- abilitatea/caster-ul au disparut (Rubick, iluzie moarta)
	if a and a:GetLevel() ~= math.max(1, lvl) then a:SetLevel(math.max(1, lvl)) end
end
function modifier_dota688_morphling_morph:Bonus()
	if self:GetStackCount() == 0 then return 0 end
	return Dota688Val(self, "bonus_attributes")
end
function modifier_dota688_morphling_morph:DeclareFunctions() return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, MODIFIER_PROPERTY_STATS_AGILITY_BONUS } end
function modifier_dota688_morphling_morph:GetModifierBonusStats_Strength() return self:Bonus() end
function modifier_dota688_morphling_morph:GetModifierBonusStats_Agility() return self:Bonus() end
