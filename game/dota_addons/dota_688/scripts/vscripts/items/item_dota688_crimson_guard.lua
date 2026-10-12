require("dota688/val")
require("items/dota688_item_base")
-- Crimson Guard (6.88): +250 HP, +8 regen, +2 la toate, +5 armura, block 32/16; Guard: 100% sansa de block 55 pentru aliatii din 900, 10 s, cd 46.
LinkLuaModifier("modifier_dota688_crimson_active", "items/item_dota688_crimson_guard", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_crimson_guard", "items/item_dota688_crimson_guard", {
	extraFunctions = { MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT },
	modifier = {
		GetModifierIncomingDamageConstant = function(self, params)
			if not IsServer() or params.damage_type ~= DAMAGE_TYPE_PHYSICAL or not params.attacker then return 0 end
			if bit.band(params.damage_flags or 0, DOTA_DAMAGE_FLAG_HPLOSS) ~= 0 then return 0 end
			local a = self:GetAbility()
			local block = self:GetParent():IsRangedAttacker() and a:GetSpecialValueFor("block_damage_ranged") or a:GetSpecialValueFor("block_damage_melee")
			return -math.min(block, params.damage)
		end,
	},
	item = {
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			caster:EmitSound("DOTA_Item.CrimsonGuard.Cast")
			local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("bonus_aoe_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _, u in ipairs(allies) do
				u:AddNewModifier(caster, self, "modifier_dota688_crimson_active", { duration = self:GetSpecialValueFor("duration") })
			end
		end,
	},
})
modifier_dota688_crimson_active = class({})
function modifier_dota688_crimson_active:IsPurgable() return false end
function modifier_dota688_crimson_active:DeclareFunctions() return { MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function modifier_dota688_crimson_active:GetModifierPhysicalArmorBonus() return Dota688Val(self, "bonus_aoe_armor") end
function modifier_dota688_crimson_active:GetModifierIncomingDamageConstant(params)
	if not IsServer() or params.damage_type ~= DAMAGE_TYPE_PHYSICAL or not params.attacker then return 0 end
	if bit.band(params.damage_flags or 0, DOTA_DAMAGE_FLAG_HPLOSS) ~= 0 then return 0 end
	return -math.min(Dota688Val(self, "block_damage_melee_active"), params.damage)
end
