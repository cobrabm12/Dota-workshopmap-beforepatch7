require("dota688/val")
require("items/dota688_item_base")
-- Scythe of Vyse (6.88): +10 STR, +10 AGI, +35 INT, +150% regen mana; Hex 3.5 s (140 MS), cd 25; distruge iluziile instant.
LinkLuaModifier("modifier_dota688_hex", "items/item_dota688_sheepstick", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_sheepstick", "items/item_dota688_sheepstick", {
	item = {
		OnSpellStart = function(self)
			local target = self:GetCursorTarget()
			if target:TriggerSpellAbsorb(self) then return end
			if target:IsIllusion() then target:ForceKill(false); return end   -- "Instantly destroys illusions"
			target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_hex", { duration = self:GetSpecialValueFor("sheep_duration") })
			target:EmitSound("DOTA_Item.Sheepstick.Activate")
		end,
	},
})
modifier_dota688_hex = class({})
function modifier_dota688_hex:IsDebuff() return true end
function modifier_dota688_hex:IsPurgable() return true end
function modifier_dota688_hex:OnCreated()
	if IsServer() then self:GetParent():InterruptMotionControllers(true) end   -- 6.88: hex-ul nu face dispel
end
function modifier_dota688_hex:CheckState()
	return { [MODIFIER_STATE_HEXED] = true, [MODIFIER_STATE_SILENCED] = true, [MODIFIER_STATE_MUTED] = true, [MODIFIER_STATE_DISARMED] = true }
end
function modifier_dota688_hex:DeclareFunctions() return { MODIFIER_PROPERTY_MODEL_CHANGE, MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE } end
function modifier_dota688_hex:GetModifierModelChange() return "models/props_gameplay/pig.vmdl" end
function modifier_dota688_hex:GetModifierMoveSpeed_Absolute() return Dota688Val(self, "sheep_movement_speed") end
