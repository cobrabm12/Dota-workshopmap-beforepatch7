-- Natural Order (6.88): aura pasiva cu raza 275 in jurul lui Elder Titan si, cat timp exista, si in jurul lui Astral
-- Spirit (aceeasi aura, nu se cumuleaza daca inamicul e langa amandoi). Inamicii (inclusiv cei imuni la vraji) pierd
-- 40/60/80/100% din armura de baza si 12/19/26/33 puncte procentuale din rezistenta magica de baza (eroi: 25% ->
-- 13/6/-1/-8%). Ambele reduceri urmeaza unitatea care poarta aura. Motorul curent centreaza reducerea de armura pe
-- erou si pe cea de rezistenta magica pe spirit (raza 375, 40-100% din rezistenta de baza).
require("dota688/val")
require("dota688/constants")
local C = DOTA688
local F = "abilities/heroes/dota688_elder_titan_natural_order"
LinkLuaModifier("modifier_dota688_natural_order", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_natural_order_effect", F, LUA_MODIFIER_MOTION_NONE)

local SPIRIT_CLASS = "npc_dota_elder_titan_ancestral_spirit"   -- unitatea creata de elder_titan_ancestral_spirit
local SPIRIT_BUILTIN = "elder_titan_natural_order_spirit"      -- aura moderna a spiritului (dezactivata)

dota688_elder_titan_natural_order = class({})
function dota688_elder_titan_natural_order:GetIntrinsicModifierName() return "modifier_dota688_natural_order" end

--------------------------------------------------------------------------------------------------------------------------
-- purtatorul aurii: pe erou (intrinsec) si pe Astral Spirit (pus de modifier-ul eroului)
modifier_dota688_natural_order = class({})
function modifier_dota688_natural_order:IsHidden() return true end
function modifier_dota688_natural_order:IsPurgable() return false end
function modifier_dota688_natural_order:RemoveOnDeath() return false end
function modifier_dota688_natural_order:IsAura() return true end
function modifier_dota688_natural_order:IsAuraActiveOnDeath() return false end
function modifier_dota688_natural_order:GetAuraRadius() return Dota688Val(self, "radius") end
function modifier_dota688_natural_order:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_dota688_natural_order:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_natural_order:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES end
function modifier_dota688_natural_order:GetModifierAura() return "modifier_dota688_natural_order_effect" end
function modifier_dota688_natural_order:OnCreated()
	if not IsServer() then return end
	-- doar instanta de pe erou cauta spiritul
	if self:GetParent() == self:GetCaster() then self:StartIntervalThink(0.1) end
end
function modifier_dota688_natural_order:OnIntervalThink()
	local hero, a = self:GetParent(), self:GetAbility()
	if not a or a:IsNull() or a:GetLevel() < 1 then return end
	for _, s in ipairs(Entities:FindAllByClassname(SPIRIT_CLASS)) do
		if not s:IsNull() and s:IsAlive() and s:GetTeamNumber() == hero:GetTeamNumber()
			and (s:GetOwner() == hero or s:GetPlayerOwnerID() == hero:GetPlayerOwnerID()) then
			-- aura moderna a spiritului (doar rezistenta magica, raza 375) nu exista in 6.88
			local b = s:FindAbilityByName(SPIRIT_BUILTIN)
			if b and b:GetLevel() > 0 then b:SetLevel(0) end
			for _, m in ipairs(s:FindAllModifiers()) do
				local n = m:GetName()
				if n:find("^modifier_elder_titan_natural_order") then m:Destroy() end
			end
			if not s:HasModifier("modifier_dota688_natural_order") then
				s:AddNewModifier(hero, a, "modifier_dota688_natural_order", {})
			end
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------
-- efectul pe inamici; daca sunt doua instante (erou + spirit), doar prima conteaza
modifier_dota688_natural_order_effect = class({})
function modifier_dota688_natural_order_effect:IsDebuff() return true end
function modifier_dota688_natural_order_effect:IsPurgable() return false end
function modifier_dota688_natural_order_effect:GetTexture() return "elder_titan_natural_order" end
function modifier_dota688_natural_order_effect:IsPrimary()
	local all = self:GetParent():FindAllModifiersByName(self:GetName())
	return all[1] == self
end
function modifier_dota688_natural_order_effect:IsHidden() return not self:IsPrimary() end
-- break pe purtatorul aurii o opreste
function modifier_dota688_natural_order_effect:Active()
	if not self:IsPrimary() then return false end
	local a = self:GetAbility()
	if a and not a:IsNull() and a:GetLevel() < 1 then return false end
	local o = self:GetAuraOwner()
	return not (o and not o:IsNull() and o:PassivesDisabled())
end
function modifier_dota688_natural_order_effect:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, MODIFIER_PROPERTY_TOOLTIP }
end
-- armura de baza (din KV, fara agilitate/iteme) redusa cu armor_reduction_pct
function modifier_dota688_natural_order_effect:GetModifierPhysicalArmorBonus()
	if not self:Active() then return 0 end
	local base = math.max(0, self:GetParent():GetPhysicalArmorBaseValue())
	return -base * Dota688Val(self, "armor_reduction_pct") / 100
end
-- rezistenta de baza scade cu magic_resistance_pct puncte; rezistentele se combina multiplicativ, deci bonusul negativ
-- echivalent este -p / (1 - baza) (eroi: baza 6.88 de 25%, deja readusa de modifier_dota688_attributes)
function modifier_dota688_natural_order_effect:GetModifierMagicalResistanceBonus()
	if not self:Active() then return 0 end
	local p = self:GetParent()
	local base = p:IsHero() and C.ATTR.BASE_MAGIC_RES or p:GetBaseMagicalResistanceValue()
	if base >= 100 then return 0 end
	return -100 * Dota688Val(self, "magic_resistance_pct") / (100 - base)
end
function modifier_dota688_natural_order_effect:OnTooltip() return Dota688Val(self, "armor_reduction_pct") end
