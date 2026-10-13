-- Overcharge (6.88): toggle: +40/50/60/70 AS si 5/10/15/20% reducere a daunelor primite, pentru Io si unitatea legata prin Tether;
-- Io pierde 4.5% din viata si mana curenta pe secunda.
require("dota688/val")
local F = "abilities/heroes/dota688_wisp_overcharge"
LinkLuaModifier("modifier_dota688_wisp_overcharge", F, LUA_MODIFIER_MOTION_NONE)
dota688_wisp_overcharge = class({})
function dota688_wisp_overcharge:OnToggle()
	local caster = self:GetCaster()
	if self:GetToggleState() then
		caster:AddNewModifier(caster, self, "modifier_dota688_wisp_overcharge", {})
		caster:EmitSound("Hero_Wisp.Overcharge")
	else
		caster:RemoveModifierByName("modifier_dota688_wisp_overcharge")
		local t = caster.dota688_overcharge_target
		if t and not t:IsNull() then t:RemoveModifierByName("modifier_dota688_wisp_overcharge") end
	end
end
modifier_dota688_wisp_overcharge = class({})
function modifier_dota688_wisp_overcharge:IsPurgable() return false end
function modifier_dota688_wisp_overcharge:GetEffectName() return "particles/units/heroes/hero_wisp/wisp_overcharge.vpcf" end
function modifier_dota688_wisp_overcharge:OnCreated()
	if IsServer() and self:GetParent() == self:GetCaster() then self:StartIntervalThink(Dota688Val(self, "drain_interval")) end
end
function modifier_dota688_wisp_overcharge:OnIntervalThink()
	local caster = self:GetParent()
	local pct = Dota688Val(self, "drain_pct") * Dota688Val(self, "drain_interval")
	caster:SetHealth(math.max(1, caster:GetHealth() - caster:GetHealth() * pct))
	caster:SetMana(math.max(0, caster:GetMana() - caster:GetMana() * pct))
	-- aplicam si pe unitatea legata prin Tether (modifier-ul built-in al Tether-ului)
	-- modifierul Tether-ului nu expune tinta in Lua: o cautam dupa modifierul pus de Io pe aliatul legat
	local tethered = nil
	if caster:HasModifier("modifier_wisp_tether") then
		for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE,
			DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)) do
			if u ~= caster and u:FindModifierByNameAndCaster("modifier_wisp_tether_haste", caster) then tethered = u; break end
		end
	end
	local prev = caster.dota688_overcharge_target
	if prev and not prev:IsNull() and prev ~= tethered then prev:RemoveModifierByName("modifier_dota688_wisp_overcharge") end
	if tethered and not tethered:IsNull() and not tethered:HasModifier("modifier_dota688_wisp_overcharge") then
		tethered:AddNewModifier(caster, self:GetAbility(), "modifier_dota688_wisp_overcharge", {})
	end
	caster.dota688_overcharge_target = tethered
end
function modifier_dota688_wisp_overcharge:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_dota688_wisp_overcharge:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "bonus_attack_speed") end
function modifier_dota688_wisp_overcharge:GetModifierIncomingDamage_Percentage() return Dota688Val(self, "bonus_damage_pct") end
