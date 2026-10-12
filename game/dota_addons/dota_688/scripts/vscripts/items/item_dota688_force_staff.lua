require("items/dota688_item_base")
-- Force Staff (6.88): +10 INT, +4 regen; Force: impinge tinta 600 unitati in directia in care priveste, cd 20, 25 mana.
LinkLuaModifier("modifier_dota688_force_push", "items/item_dota688_force_staff", LUA_MODIFIER_MOTION_HORIZONTAL)
local function Push(self, length)
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()
	if target:GetTeamNumber() ~= caster:GetTeamNumber() and target:TriggerSpellAbsorb(self) then return end
	target:AddNewModifier(caster, self, "modifier_dota688_force_push", { duration = 0.5, distance = length })
	target:EmitSound("DOTA_Item.ForceStaff.Activate")
end
Dota688DefineItem("item_dota688_force_staff", "items/item_dota688_force_staff", {
	item = {
		CastFilterResultTarget = function(self, target)
			if target:IsBuilding() or target:IsOther() or target:IsCourier() then return UF_FAIL_CUSTOM end
			if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() and target:IsMagicImmune() then return UF_FAIL_MAGIC_IMMUNE_ENEMY end
			return UF_SUCCESS
		end,
		OnSpellStart = function(self) Push(self, self:GetSpecialValueFor("push_length")) end,
	},
})
modifier_dota688_force_push = class({})
function modifier_dota688_force_push:IsHidden() return true end
function modifier_dota688_force_push:IsPurgable() return false end
function modifier_dota688_force_push:OnCreated(kv)
	if not IsServer() then return end
	self.distance = kv.distance or 600
	self.dir = self:GetParent():GetForwardVector()
	self.speed = self.distance / 0.5
	if not self:ApplyHorizontalMotionController() then self:Destroy() end
end
function modifier_dota688_force_push:UpdateHorizontalMotion(me, dt)
	me:SetOrigin(me:GetOrigin() + self.dir * self.speed * dt)
end
function modifier_dota688_force_push:OnHorizontalMotionInterrupted() self:Destroy() end
function modifier_dota688_force_push:OnDestroy()
	if IsServer() then
		self:GetParent():RemoveHorizontalMotionController(self)
		FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), false)
	end
end
function modifier_dota688_force_push:CheckState() return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true } end
