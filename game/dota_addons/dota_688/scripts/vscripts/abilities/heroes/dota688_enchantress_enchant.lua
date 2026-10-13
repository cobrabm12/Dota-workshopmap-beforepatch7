-- Enchant (6.88): pe un erou inamic -> incetinire 20/30/40/50% pentru 5.5 s (fara dispel; abilitatea curenta scoate si
-- buff-urile eroului). Pe un creep (nu ancient) sau pe o iluzie -> Enchantress preia controlul 80 s, apoi unitatea dispare.
-- Folosita pe un creep deja controlat de ea, ii reimprospateaza durata.
require("dota688/val")
local F = "abilities/heroes/dota688_enchantress_enchant"
LinkLuaModifier("modifier_dota688_enchantress_enchant_slow", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_enchantress_enchant_controlled", F, LUA_MODIFIER_MOTION_NONE)

dota688_enchantress_enchant = class({})
local function Mine(self, target)
	local m = target:FindModifierByName("modifier_dota688_enchantress_enchant_controlled")
	return m and m:GetCaster() == self:GetCaster()
end
function dota688_enchantress_enchant:CastFilterResultTarget(target)
	if Mine(self, target) then return UF_SUCCESS end   -- si pe client (modifierul ajunge acolo)
	return UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS, self:GetCaster():GetTeamNumber())
end
function dota688_enchantress_enchant:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if not target then return end
	caster:EmitSound("Hero_Enchantress.EnchantCast")
	if Mine(self, target) then
		target:FindModifierByName("modifier_dota688_enchantress_enchant_controlled"):SetDuration(self:GetSpecialValueFor("dominate_duration"), true)
		return
	end
	if target:TriggerSpellAbsorb(self) then return end
	if target:IsRealHero() or target:IsConsideredHero() and not target:IsIllusion() then
		target:EmitSound("Hero_Enchantress.EnchantHero")
		target:AddNewModifier(caster, self, "modifier_dota688_enchantress_enchant_slow", { duration = self:GetSpecialValueFor("tooltip_duration") })
		return
	end
	-- creep / iluzie: trece de partea Enchantress
	target:SetTeam(caster:GetTeamNumber())
	target:SetOwner(caster:GetPlayerOwner())
	target:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
	if target.SetInitialGoalEntity then target:SetInitialGoalEntity(nil) end   -- creepii de linie nu mai urmeaza ruta
	target:Stop()
	target:EmitSound("Hero_Enchantress.EnchantCreep")
	target:AddNewModifier(caster, self, "modifier_dota688_enchantress_enchant_controlled", { duration = self:GetSpecialValueFor("dominate_duration") })
end

modifier_dota688_enchantress_enchant_slow = class({})
function modifier_dota688_enchantress_enchant_slow:IsDebuff() return true end
function modifier_dota688_enchantress_enchant_slow:IsPurgable() return true end
function modifier_dota688_enchantress_enchant_slow:GetEffectName() return "particles/units/heroes/hero_enchantress/enchantress_enchant_slow.vpcf" end
function modifier_dota688_enchantress_enchant_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_enchantress_enchant_slow:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "slow_movement_speed") end

modifier_dota688_enchantress_enchant_controlled = class({})
function modifier_dota688_enchantress_enchant_controlled:IsPurgable() return false end
function modifier_dota688_enchantress_enchant_controlled:GetEffectName() return "particles/units/heroes/hero_enchantress/enchantress_enchant.vpcf" end
function modifier_dota688_enchantress_enchant_controlled:OnDestroy()
	if not IsServer() then return end
	local p = self:GetParent()
	if p:IsAlive() and self:GetRemainingTime() <= 0.05 then p:ForceKill(false) end   -- durata s-a terminat
end
