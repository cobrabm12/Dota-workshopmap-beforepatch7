require("dota688/val")
require("items/dota688_item_base")
-- Crimson Guard (6.88): +250 HP, +8 regen, +2 la toate, +5 armura, block 32/16 (doar atacuri, nu se cumuleaza); Guard: 100% sansa de
-- block 55 si +2 armura pentru EROII aliati din 900, 10 s, cd 46; o unitate afectata de Guard nu mai poate fi afectata 50 s.
local GUARD_LOCKOUT = 50
LinkLuaModifier("modifier_dota688_crimson_active", "items/item_dota688_crimson_guard", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_crimson_lockout", "items/item_dota688_crimson_guard", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_crimson_guard", "items/item_dota688_crimson_guard", {
	extraFunctions = { MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT },
	modifier = {
		GetModifierIncomingDamageConstant = function(self, params)
			local a = self:GetAbility()
			local block = self:GetParent():IsRangedAttacker() and a:GetSpecialValueFor("block_damage_ranged") or a:GetSpecialValueFor("block_damage_melee")
			return Dota688DamageBlock(self:GetParent(), params, "item_dota688_crimson_guard", block)
		end,
	},
	item = {
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			caster:EmitSound("DOTA_Item.CrimsonGuard.Cast")
			local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("bonus_aoe_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _, u in ipairs(allies) do
				if not u:HasModifier("modifier_dota688_crimson_lockout") then
					u:AddNewModifier(caster, self, "modifier_dota688_crimson_active", { duration = self:GetSpecialValueFor("duration") })
					u:AddNewModifier(caster, self, "modifier_dota688_crimson_lockout", { duration = GUARD_LOCKOUT })
				end
			end
		end,
	},
})
modifier_dota688_crimson_active = class({})
function modifier_dota688_crimson_active:IsPurgable() return false end
function modifier_dota688_crimson_active:DeclareFunctions() return { MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function modifier_dota688_crimson_active:GetModifierPhysicalArmorBonus() return Dota688Val(self, "bonus_aoe_armor") end
function modifier_dota688_crimson_active:GetModifierIncomingDamageConstant(params)
	return Dota688DamageBlock(self:GetParent(), params, "modifier_dota688_crimson_active", Dota688Val(self, "block_damage_melee_active"))
end
modifier_dota688_crimson_lockout = class({})
function modifier_dota688_crimson_lockout:IsHidden() return false end
function modifier_dota688_crimson_lockout:IsDebuff() return true end
function modifier_dota688_crimson_lockout:IsPurgable() return false end
function modifier_dota688_crimson_lockout:GetTexture() return "item_crimson_guard" end
