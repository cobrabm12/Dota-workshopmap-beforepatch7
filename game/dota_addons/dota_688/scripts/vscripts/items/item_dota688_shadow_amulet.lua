require("items/dota688_item_base")
-- Shadow Amulet (6.88): +20 AS; activ: tinta (self/aliat) devine invizibila dupa 1.5 s cat timp sta pe loc; cd 10.
LinkLuaModifier("modifier_dota688_shadow_amulet", "items/item_dota688_shadow_amulet", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_shadow_amulet", "items/item_dota688_shadow_amulet", {
	item = {
		OnSpellStart = function(self)
			local target = self:GetCursorTarget() or self:GetCaster()
			target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_shadow_amulet", {})
			target:EmitSound("DOTA_Item.ShadowAmulet.Activate")
		end,
	},
})
modifier_dota688_shadow_amulet = class({})
function modifier_dota688_shadow_amulet:IsPurgable() return false end
function modifier_dota688_shadow_amulet:OnCreated()
	self.start = GameRules:GetGameTime()
	if IsServer() then self.pos = self:GetParent():GetAbsOrigin(); self:StartIntervalThink(0.1) end
end
function modifier_dota688_shadow_amulet:OnIntervalThink()
	local p = self:GetParent()
	if (p:GetAbsOrigin() - self.pos):Length2D() > 1 or p:IsAttacking() then self:Destroy() end
end
function modifier_dota688_shadow_amulet:Faded() return GameRules:GetGameTime() - self.start >= self:GetAbility():GetSpecialValueFor("fade_time") end
function modifier_dota688_shadow_amulet:CheckState() return { [MODIFIER_STATE_INVISIBLE] = self:Faded() } end
function modifier_dota688_shadow_amulet:DeclareFunctions() return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL, MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
function modifier_dota688_shadow_amulet:GetModifierInvisibilityLevel() return self:Faded() and 1 or 0 end
function modifier_dota688_shadow_amulet:OnAbilityExecuted(params) if IsServer() and params.unit == self:GetParent() then self:Destroy() end end
