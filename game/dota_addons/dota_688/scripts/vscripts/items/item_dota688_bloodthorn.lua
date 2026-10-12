require("items/dota688_item_base")
-- Bloodthorn (6.88): +25 INT, +30 AS, +60 daune, +150% regen mana, 20% critic 175%; Soul Rend: silence 5 s, toate atacurile pe tinta sunt critice 145% si la final +30% din daunele primite.
LinkLuaModifier("modifier_dota688_soul_rend", "items/item_dota688_bloodthorn", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_bloodthorn", "items/item_dota688_bloodthorn", {
	extraFunctions = { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE },
	modifier = {
		GetModifierPreAttack_CriticalStrike = function(self, params)
			local target = params.target
			if not target or target:IsBuilding() or target:IsOther() then return nil end
			if target:HasModifier("modifier_dota688_soul_rend") then return self:GetAbility():GetSpecialValueFor("target_crit_multiplier") end
			if RollPseudoRandomPercentage(self:GetAbility():GetSpecialValueFor("crit_chance"), DOTA_PSEUDO_RANDOM_ITEM_CRIT, self:GetParent()) then
				return self:GetAbility():GetSpecialValueFor("crit_multiplier")
			end
			return nil
		end,
	},
	item = {
		OnSpellStart = function(self)
			local target = self:GetCursorTarget()
			if target:TriggerSpellAbsorb(self) then return end
			target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_soul_rend", { duration = self:GetSpecialValueFor("silence_duration") })
			target:EmitSound("DOTA_Item.Bloodthorn.Activate")
		end,
	},
})
modifier_dota688_soul_rend = class({})
function modifier_dota688_soul_rend:IsDebuff() return true end
function modifier_dota688_soul_rend:IsPurgable() return true end
function modifier_dota688_soul_rend:GetEffectName() return "particles/items2_fx/orchid.vpcf" end
function modifier_dota688_soul_rend:OnCreated() self.total = 0 end
function modifier_dota688_soul_rend:CheckState() return { [MODIFIER_STATE_SILENCED] = true } end
function modifier_dota688_soul_rend:DeclareFunctions() return { MODIFIER_EVENT_ON_TAKEDAMAGE } end
function modifier_dota688_soul_rend:OnTakeDamage(params)
	if IsServer() and params.unit == self:GetParent() and params.attacker ~= self:GetParent() then self.total = self.total + params.damage end
end
function modifier_dota688_soul_rend:OnDestroy()
	if not IsServer() or not self:GetParent():IsAlive() then return end
	local dmg = (self.total or 0) * self:GetAbility():GetSpecialValueFor("silence_damage_percent") / 100
	if dmg > 0 then
		ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = self:GetAbility() })
	end
end
