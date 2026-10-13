require("items/dota688_item_base")
-- Desolator (6.88): +50 daune; Corruption: -7 armura 15 s (Unique Attack Modifier, vezi dota688/uam.lua; merge si pe cladiri).
LinkLuaModifier("modifier_dota688_corruption", "items/item_dota688_desolator", LUA_MODIFIER_MOTION_NONE)
function Dota688Corruption(self, params)
	local target, parent, a = params.target, self:GetParent(), self:GetAbility()
	if not target or target:GetTeamNumber() == parent:GetTeamNumber() then return end
	Dota688UAM:Queue(parent, target, a, function()
		if target:IsNull() or not target:IsAlive() or a:IsNull() then return end
		target:AddNewModifier(parent, a, "modifier_dota688_corruption", { duration = a:GetSpecialValueFor("corruption_duration"), armor = a:GetSpecialValueFor("corruption_armor") })
	end)
end
Dota688DefineItem("item_dota688_desolator", "items/item_dota688_desolator", {
	onAttackLanded = Dota688Corruption,
	extraFunctions = { MODIFIER_PROPERTY_PROJECTILE_NAME },
	modifier = { GetModifierProjectileName = function() return "particles/items_fx/desolator_projectile.vpcf" end },
})
-- un singur debuff Corruption pe tinta: unul nou il inlocuieste pe cel vechi (Desolator sau Blight Stone)
modifier_dota688_corruption = class({})
function modifier_dota688_corruption:IsDebuff() return true end
function modifier_dota688_corruption:IsPurgable() return true end
function modifier_dota688_corruption:GetTexture() return "item_desolator" end
function modifier_dota688_corruption:OnCreated(kv) if IsServer() then self:SetStackCount(-(kv.armor or 0)) end end
function modifier_dota688_corruption:OnRefresh(kv) if IsServer() then self:SetStackCount(math.max(self:GetStackCount(), -(kv.armor or 0))) end end
function modifier_dota688_corruption:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function modifier_dota688_corruption:GetModifierPhysicalArmorBonus() return -self:GetStackCount() end
