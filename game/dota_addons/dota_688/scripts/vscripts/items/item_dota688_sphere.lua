require("dota688/val")
require("items/dota688_item_base")
-- Linken's Sphere (6.88): +15 la toate, +6 regen, +150% regen mana, +15 daune; Spellblock la fiecare 13 s (motorul: TriggerSpellAbsorb); activ: transfera pe un aliat (nu e implementat inca – TODO).
LinkLuaModifier("modifier_dota688_linkens", "items/item_dota688_sphere", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_sphere", "items/item_dota688_sphere", {
	onCreated = function(self)
		if IsServer() and not self:GetParent():HasModifier("modifier_dota688_linkens") then self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dota688_linkens", {}) end
	end,
	modifier = {
		OnDestroy = function(self)
			if IsServer() and not self:GetParent():HasItemInInventory("item_dota688_sphere") then self:GetParent():RemoveModifierByName("modifier_dota688_linkens") end
		end,
	},
})
modifier_dota688_linkens = class({})
function modifier_dota688_linkens:IsHidden() return false end
function modifier_dota688_linkens:IsPurgable() return false end
function modifier_dota688_linkens:RemoveOnDeath() return false end
function modifier_dota688_linkens:OnCreated() self.ready = 0 end
function modifier_dota688_linkens:DeclareFunctions() return { MODIFIER_PROPERTY_ABSORB_SPELL } end
function modifier_dota688_linkens:GetAbsorbSpell(params)
	if not IsServer() then return 0 end
	if GameRules:GetGameTime() < (self.ready or 0) then return 0 end
	local ab = params.ability
	if not ab or ab:GetCaster():GetTeamNumber() == self:GetParent():GetTeamNumber() then return 0 end
	self.ready = GameRules:GetGameTime() + Dota688Val(self, "block_cooldown")
	local fx = ParticleManager:CreateParticle("particles/items_fx/immunity_sphere.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:ReleaseParticleIndex(fx)
	return 1
end
