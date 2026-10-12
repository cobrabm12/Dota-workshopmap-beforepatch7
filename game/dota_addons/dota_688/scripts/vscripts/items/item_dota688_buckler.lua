require("items/dota688_item_base")
-- Buckler (6.88): +5 armura, +2 la toate; activ: +2 armura aliatilor din 900 pentru 30 s (25 s eroi), cd 25, 10 mana.
LinkLuaModifier("modifier_dota688_buckler_armor", "items/item_dota688_buckler", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_buckler", "items/item_dota688_buckler", {
	item = {
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			caster:EmitSound("DOTA_Item.Buckler.Activate")
			local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("bonus_aoe_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _, u in ipairs(allies) do
				local d = u:IsHero() and self:GetSpecialValueFor("bonus_aoe_duration_hero") or self:GetSpecialValueFor("bonus_aoe_duration")
				u:AddNewModifier(caster, self, "modifier_dota688_buckler_armor", { duration = d })
			end
		end,
	},
})
modifier_dota688_buckler_armor = class({})
function modifier_dota688_buckler_armor:IsPurgable() return true end
function modifier_dota688_buckler_armor:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function modifier_dota688_buckler_armor:GetModifierPhysicalArmorBonus() return self:GetAbility():GetSpecialValueFor("bonus_aoe_armor") end
