-- Battle Hunger (6.88): tinta ia 16/24/32/40 daune magice pe secunda si e incetinita 12% (mereu, oricum ar fi intoarsa)
-- timp de 10 s; efectul se termina cand tinta omoara o unitate. Axe primeste +12% viteza pentru fiecare unitate afectata.
-- Abilitatea curenta da daune pure, incetineste doar tinta intoarsa cu spatele la Axe si nu mai da viteza lui Axe.
require("dota688/val")
local F = "abilities/heroes/dota688_axe_battle_hunger"
LinkLuaModifier("modifier_dota688_axe_battle_hunger", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_axe_battle_hunger_speed", F, LUA_MODIFIER_MOTION_NONE)

dota688_axe_battle_hunger = class({})
function dota688_axe_battle_hunger:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if not target or target:TriggerSpellAbsorb(self) then return end
	caster:EmitSound("Hero_Axe.Battle_Hunger")
	target:AddNewModifier(caster, self, "modifier_dota688_axe_battle_hunger", { duration = self:GetSpecialValueFor("duration") })
end

-- pe tinta
modifier_dota688_axe_battle_hunger = class({})
function modifier_dota688_axe_battle_hunger:IsDebuff() return true end
function modifier_dota688_axe_battle_hunger:IsPurgable() return true end
function modifier_dota688_axe_battle_hunger:GetEffectName() return "particles/units/heroes/hero_axe/axe_battle_hunger.vpcf" end
function modifier_dota688_axe_battle_hunger:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_dota688_axe_battle_hunger:OnCreated()
	if not IsServer() then return end
	self.dps = self:GetAbility():GetAbilityDamage()
	self:StartIntervalThink(1)
	self:UpdateCasterSpeed()
end
function modifier_dota688_axe_battle_hunger:OnRefresh()
	if IsServer() then self.dps = self:GetAbility():GetAbilityDamage() end
end
function modifier_dota688_axe_battle_hunger:OnIntervalThink()
	local a = self:GetAbility()
	if not a or a:IsNull() then return end
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = self.dps, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
end
-- viteza lui Axe = numarul de unitati afectate (stack count pe modifier-ul lui)
function modifier_dota688_axe_battle_hunger:UpdateCasterSpeed()
	local caster = self:GetCaster()
	if not caster or caster:IsNull() then return end
	Dota688Timers:After(0, function()
		if caster:IsNull() then return end
		local n = 0
		for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)) do
			for _, m in ipairs(u:FindAllModifiersByName("modifier_dota688_axe_battle_hunger")) do
				if m:GetCaster() == caster then n = n + 1 end
			end
		end
		local s = caster:FindModifierByName("modifier_dota688_axe_battle_hunger_speed")
		if n == 0 then
			if s then s:Destroy() end
		else
			s = s or caster:AddNewModifier(caster, self:GetAbility(), "modifier_dota688_axe_battle_hunger_speed", {})
			s:SetStackCount(n)
		end
	end)
end
function modifier_dota688_axe_battle_hunger:OnDestroy()
	if IsServer() then self:UpdateCasterSpeed() end
end
function modifier_dota688_axe_battle_hunger:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_EVENT_ON_DEATH } end
function modifier_dota688_axe_battle_hunger:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "slow") end
-- tinta omoara o unitate -> Battle Hunger se termina
function modifier_dota688_axe_battle_hunger:OnDeath(params)
	if IsServer() and params.attacker == self:GetParent() and params.unit ~= self:GetParent() then self:Destroy() end
end

-- pe Axe: +12% viteza pentru fiecare unitate afectata
modifier_dota688_axe_battle_hunger_speed = class({})
function modifier_dota688_axe_battle_hunger_speed:IsPurgable() return false end
function modifier_dota688_axe_battle_hunger_speed:GetTexture() return "axe_battle_hunger" end
function modifier_dota688_axe_battle_hunger_speed:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_axe_battle_hunger_speed:GetModifierMoveSpeedBonus_Percentage() return self:GetStackCount() * Dota688Val(self, "speed_bonus") end
