require("items/dota688_item_base")
-- Lotus Orb (6.88): +10 daune, +10 armura, +6 regen, +125% regen mana, +250 mana; Echo Shell: 6 s reflecta vrajile tintite (TODO: reflectare – deocamdata doar dispel la cast).
LinkLuaModifier("modifier_dota688_echo_shell", "items/item_dota688_lotus_orb", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_lotus_orb", "items/item_dota688_lotus_orb", {
	item = {
		OnSpellStart = function(self)
			local target = self:GetCursorTarget() or self:GetCaster()
			target:Purge(false, true, false, false, false)
			target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_echo_shell", { duration = self:GetSpecialValueFor("active_duration") })
			target:EmitSound("DOTA_Item.LotusOrb.Activate")
		end,
	},
})
modifier_dota688_echo_shell = class({})
function modifier_dota688_echo_shell:IsPurgable() return false end
function modifier_dota688_echo_shell:GetEffectName() return "particles/items2_fx/lotus_orb_shield.vpcf" end
function modifier_dota688_echo_shell:DeclareFunctions() return { MODIFIER_PROPERTY_REFLECT_SPELL } end
function modifier_dota688_echo_shell:GetReflectSpell(params)
	-- Reflectarea completa a vrajilor necesita copierea abilitatii pe tinta (ca in C++); TODO.
	return 0
end
