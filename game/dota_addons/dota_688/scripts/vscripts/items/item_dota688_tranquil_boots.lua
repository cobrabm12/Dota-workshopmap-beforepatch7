require("dota688/val")
require("items/dota688_item_base")
-- Tranquil Boots (6.88): +85 viteza, +3 armura, +12 regen HP. Break: de fiecare data cand purtatorul ataca sau este
-- atacat (de orice unitate), pierde regenerarea si 30 din viteza (85 -> 55) timp de 13 s; itemul arata timpul pe cooldown.
-- Viteza cizmelor nu se cumuleaza cu alte cizme (bonus unic). Vrajile/daunele care nu sunt atacuri nu strica cizmele.
-- Stare: stack 1 = stricate (calculat pe server, vazut si de client pentru viteza/regen).

local function Break(self, duration)
	local a = self:GetAbility()
	if duration == nil or duration <= 0 then return end
	self.brokenUntil = math.max(self.brokenUntil or 0, GameRules:GetGameTime() + duration)
	self:SetStackCount(1)
	if a and not a:IsNull() and a:GetCooldownTimeRemaining() < duration then
		a:EndCooldown()
		a:StartCooldown(duration)
	end
	self:StartIntervalThink(0.1)
end

Dota688DefineItem("item_dota688_tranquil_boots", "items/item_dota688_tranquil_boots", {
	extraFunctions = { MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE, MODIFIER_EVENT_ON_ATTACK },
	onCreated = function(self)
		if not IsServer() then return end
		-- itemul mutat/aruncat si luat inapoi ramane stricat cat ii mai ramane din cooldown
		local a = self:GetAbility()
		if a and not a:IsNull() and not a:IsCooldownReady() then Break(self, a:GetCooldownTimeRemaining()) end
	end,
	modifier = {
		GetModifierMoveSpeedBonus_Constant = function(self) return 0 end,
		GetModifierMoveSpeedBonus_Special_Boots = function(self)
			local a = self:GetAbility()
			if self:GetStackCount() > 0 then return a:GetSpecialValueFor("broken_movement_speed") end
			return a:GetSpecialValueFor("bonus_movement_speed")
		end,
		GetModifierConstantHealthRegen = function(self)
			if self:GetStackCount() > 0 then return 0 end
			return self:GetAbility():GetSpecialValueFor("bonus_health_regen")
		end,
		OnAttack = function(self, params)
			if not IsServer() then return end
			local parent = self:GetParent()
			if params.attacker == parent or (params.target == parent and params.attacker ~= parent) then
				Break(self, Dota688Val(self, "break_time"))
			end
		end,
		OnIntervalThink = function(self)
			if GameRules:GetGameTime() >= (self.brokenUntil or 0) then
				self:SetStackCount(0)
				self:StartIntervalThink(-1)
			end
		end,
	},
})
