require("items/dota688_item_base")
-- Glimmer Cape (6.88): +20 AS, +15% rezistenta magica; Glimmer: invizibilitate dupa 0.6 s + 45% rezistenta magica, 5 s, cd 16, 90 mana.
LinkLuaModifier("modifier_dota688_glimmer", "items/item_dota688_glimmer_cape", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_glimmer_cape", "items/item_dota688_glimmer_cape", {
	item = {
		OnSpellStart = function(self)
			local target = self:GetCursorTarget() or self:GetCaster()
			target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_glimmer", { duration = self:GetSpecialValueFor("duration") })
			target:EmitSound("DOTA_Item.GlimmerCape.Target")
		end,
	},
})
modifier_dota688_glimmer = class({})
function modifier_dota688_glimmer:IsPurgable() return true end
function modifier_dota688_glimmer:GetEffectName() return "particles/items3_fx/glimmer_cape_initial_flash.vpcf" end
function modifier_dota688_glimmer:OnCreated() self.start = GameRules:GetGameTime() end
function modifier_dota688_glimmer:Faded() return GameRules:GetGameTime() - (self.start or 0) >= self:GetAbility():GetSpecialValueFor("fade_delay") end
function modifier_dota688_glimmer:CheckState() return { [MODIFIER_STATE_INVISIBLE] = self:Faded() } end
function modifier_dota688_glimmer:DeclareFunctions() return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL, MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS } end
function modifier_dota688_glimmer:GetModifierInvisibilityLevel() return self:Faded() and 1 or 0 end
function modifier_dota688_glimmer:GetModifierMagicalResistanceBonus() return self:GetAbility():GetSpecialValueFor("active_magical_armor") end
