require("dota688/val")
require("items/dota688_item_base")
-- Drum of Endurance (6.88): +9 INT, +6 STR, +3 AGI, +3 daune, +3 regen; aura 900: +5% AS si MS; Endurance (6 incarcaturi): +25% AS, +13% MS 6 s aliatilor din 900.
Dota688DefineAura("modifier_dota688_janggo_aura", "items/item_dota688_ancient_janggo", {
	radius = function(self) return Dota688Val(self, "radius") end,
	functions = { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE },
	effect = {
		GetModifierAttackSpeedBonus_Constant = function(self) return Dota688Val(self, "bonus_aura_attack_speed_pct") end,
		GetModifierMoveSpeedBonus_Percentage = function(self) return Dota688Val(self, "bonus_aura_movement_speed_pct") end,
	},
})
LinkLuaModifier("modifier_dota688_janggo_active", "items/item_dota688_ancient_janggo", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_ancient_janggo", "items/item_dota688_ancient_janggo", {
	onCreated = function(self)
		if IsServer() and not self:GetParent():HasModifier("modifier_dota688_janggo_aura") then
			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dota688_janggo_aura", {})
		end
	end,
	modifier = {
		OnDestroy = function(self)
			if IsServer() and not self:GetParent():HasItemInInventory("item_dota688_ancient_janggo") then self:GetParent():RemoveModifierByName("modifier_dota688_janggo_aura") end
		end,
	},
	item = {
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			if self:GetCurrentCharges() <= 0 then return end
			self:SetCurrentCharges(self:GetCurrentCharges() - 1)
			caster:EmitSound("DOTA_Item.DoE.Activate")
			local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _, u in ipairs(allies) do u:AddNewModifier(caster, self, "modifier_dota688_janggo_active", { duration = self:GetSpecialValueFor("duration") }) end
		end,
	},
})
modifier_dota688_janggo_active = class({})
function modifier_dota688_janggo_active:IsPurgable() return true end
function modifier_dota688_janggo_active:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_janggo_active:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "bonus_attack_speed_pct") end
function modifier_dota688_janggo_active:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "bonus_movement_speed_pct") end
