require("dota688/val")
require("items/dota688_item_base")
-- Bloodthorn (6.88): +25 INT, +30 AS, +60 daune, +150% regen mana, 20% critic 175%; Soul Rend: silence 5 s, toate atacurile pe tinta
-- (de la oricine) sunt critice 145% (critul propriu de 175% il inlocuieste cand se declanseaza) si la final +30% din daunele primite.
-- True Strike pentru toti atacatorii: evaziunea tintei e anulata (MODIFIER_PROPERTY_NEGATIVE_EVASION_CONSTANT pe debuff).
LinkLuaModifier("modifier_dota688_soul_rend", "items/item_dota688_bloodthorn", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_bloodthorn", "items/item_dota688_bloodthorn", {
	extraFunctions = { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE },
	modifier = {
		GetModifierPreAttack_CriticalStrike = function(self, params)
			local target = params.target
			if not target or target:IsBuilding() or target:IsOther() then return nil end
			if RollPseudoRandomPercentage(Dota688Val(self, "crit_chance"), DOTA_PSEUDO_RANDOM_ITEM_GREATERCRIT, self:GetParent()) then
				return Dota688Val(self, "crit_multiplier")
			end
			if target:HasModifier("modifier_dota688_soul_rend") then return Dota688Val(self, "target_crit_multiplier") end
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
function modifier_dota688_soul_rend:DeclareFunctions() return { MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_PROPERTY_NEGATIVE_EVASION_CONSTANT } end
-- "All attacks on the silenced target will have True Strike": evaziunea tintei e anulata
function modifier_dota688_soul_rend:GetModifierNegativeEvasion_Constant() return 100 end
-- atacurile celorlalti (nu ale purtatorului, care are critul in propria functie) fac 145%
function modifier_dota688_soul_rend:GetModifierIncomingDamage_Percentage(params)
	if params.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK or params.damage_type ~= DAMAGE_TYPE_PHYSICAL then return 0 end
	if params.attacker == self:GetCaster() then return 0 end
	return Dota688Val(self, "target_crit_multiplier") - 100
end
function modifier_dota688_soul_rend:OnTakeDamage(params)
	if IsServer() and params.unit == self:GetParent() and params.attacker ~= self:GetParent() then self.total = self.total + params.damage end
end
function modifier_dota688_soul_rend:OnDestroy()
	if not IsServer() or not self:GetParent():IsAlive() then return end
	local dmg = (self.total or 0) * Dota688Val(self, "silence_damage_percent") / 100
	if dmg > 0 then
		ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = self:GetAbility() })
	end
end
