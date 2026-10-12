-- Tower Protection (6.88): aura turnului, raza 900, +1 armura (Tier 1) / +3 armura (Tier 2-4) pentru eroii, iluziile
-- si creep-eroii echipei turnului. Nu se cumuleaza (doar cea mai mare valoare dintre turnurile din raza), fara
-- regenerare. Aura moderna a motorului (modifier_tower_aura pe turn / modifier_tower_aura_bonus pe eroi:
-- +3/5/5/5 armura si regenerare) e blocata de Dota688Buildings:ModifierGainedFilter si scoasa de pe turnuri.
local RADIUS = 900
local ARMOR_TIER1 = 1
local ARMOR_TIER2_4 = 3
local EFFECT = "modifier_dota688_tower_aura_effect"
local ENGINE_BONUS = "modifier_tower_aura_bonus"

-- Pe turn ----------------------------------------------------------------------------------------------------------
modifier_dota688_tower_aura = class({})

function modifier_dota688_tower_aura:IsHidden() return true end
function modifier_dota688_tower_aura:IsPurgable() return false end
function modifier_dota688_tower_aura:RemoveOnDeath() return true end
function modifier_dota688_tower_aura:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_dota688_tower_aura:IsAura() return true end
function modifier_dota688_tower_aura:IsAuraActiveOnDeath() return false end
function modifier_dota688_tower_aura:GetAuraRadius() return RADIUS end
function modifier_dota688_tower_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_tower_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_tower_aura:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_dota688_tower_aura:GetModifierAura() return EFFECT end

-- doar eroi (inclusiv iluzii) si creep-eroi (Spirit Bear etc.); creepii obisnuiti nu primesc armura
function modifier_dota688_tower_aura:GetAuraEntityReject(unit)
	return not (unit:IsHero() or unit:IsCreepHero() or unit:IsConsideredHero())
end

-- Pe erou ----------------------------------------------------------------------------------------------------------
-- O instanta pentru fiecare turn din raza (MULTIPLE); serverul pune armura doar pe instanta cu valoarea cea mai mare
-- (stack count = armura, celelalte 0), deci bonusul nu se cumuleaza. Stack count-ul ajunge si pe client.
modifier_dota688_tower_aura_effect = class({})

function modifier_dota688_tower_aura_effect:IsHidden() return self:GetStackCount() == 0 end
function modifier_dota688_tower_aura_effect:IsPurgable() return false end
function modifier_dota688_tower_aura_effect:IsDebuff() return false end
function modifier_dota688_tower_aura_effect:GetTexture() return "tower_armor_aura" end
function modifier_dota688_tower_aura_effect:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end

function modifier_dota688_tower_aura_effect:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_dota688_tower_aura_effect:GetModifierPhysicalArmorBonus()
	return self:GetStackCount()
end

local function TowerArmor(tower)
	if not tower or tower:IsNull() then return 0 end
	local tier = tonumber(string.match(tower:GetUnitName(), "tower(%d)"))
	if tier == 1 then return ARMOR_TIER1 end
	return ARMOR_TIER2_4
end

-- doar pe server: alege instanta activa (armura maxima); `add` = instanta noua (poate lipsi inca din lista),
-- `exclude` = instanta care se distruge
local function Recalc(parent, add, exclude)
	if not parent or parent:IsNull() then return end
	local list, hasAdd = {}, false
	for _, m in ipairs(parent:FindAllModifiersByName(EFFECT)) do
		if m ~= exclude and not m:IsNull() then
			list[#list + 1] = m
			if m == add then hasAdd = true end
		end
	end
	if add and not hasAdd then list[#list + 1] = add end
	local best
	for _, m in ipairs(list) do
		if not best or (m.dota688_armor or 0) > (best.dota688_armor or 0) then best = m end
	end
	for _, m in ipairs(list) do
		local v = (m == best) and (m.dota688_armor or 0) or 0
		if m:GetStackCount() ~= v then m:SetStackCount(v) end
	end
end

function modifier_dota688_tower_aura_effect:OnCreated()
	if not IsServer() then return end
	self.dota688_armor = TowerArmor(self:GetAuraOwner() or self:GetCaster())
	local parent = self:GetParent()
	-- rezerva, daca filtrul de modifieri nu prinde aura motorului
	if parent:HasModifier(ENGINE_BONUS) then parent:RemoveModifierByName(ENGINE_BONUS) end
	Recalc(parent, self, nil)
end

function modifier_dota688_tower_aura_effect:OnDestroy()
	if not IsServer() then return end
	Recalc(self:GetParent(), nil, self)
end
