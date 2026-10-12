require("dota688/val")
require("items/dota688_item_base")
require("items/item_dota688_force_staff")
-- Hurricane Pike (6.88): +10 INT, +4 regen, +20 AGI, +15 STR, +140 raza de atac (ranged); Hurricane Thrust: aliat/self impins 600; inamic: ambii impinsi 450 unul de altul,
-- urmatoarele 4 atacuri in 5 s fara limita de raza si +100 AS. cd 14, 25 mana.
LinkLuaModifier("modifier_dota688_pike_attacks", "items/item_dota688_hurricane_pike", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_hurricane_pike", "items/item_dota688_hurricane_pike", {
	modifier = {
		GetModifierAttackRangeBonus = function(self)
			if self:GetParent():IsRangedAttacker() then return Dota688Val(self, "base_attack_range") end
			return 0
		end,
		-- bonus_attack_speed e doar al activei ("Grants 100 Attack Speed during the attacks"), nu pasiv
		GetModifierAttackSpeedBonus_Constant = function() return 0 end,
	},
	item = {
		CastFilterResultTarget = function(self, target)
			if target:IsBuilding() or target:IsOther() or target:IsCourier() then return UF_FAIL_CUSTOM end
			if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() and target:IsMagicImmune() then return UF_FAIL_MAGIC_IMMUNE_ENEMY end
			return UF_SUCCESS
		end,
		GetCastRange = function(self, loc, target)
			if target and target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then return self:GetSpecialValueFor("cast_range_enemy") end
			return 800
		end,
		OnSpellStart = function(self)
			local caster, target = self:GetCaster(), self:GetCursorTarget()
			if target:GetTeamNumber() == caster:GetTeamNumber() then
				target:AddNewModifier(caster, self, "modifier_dota688_force_push", { duration = 0.5, distance = self:GetSpecialValueFor("push_length") })
			else
				if target:TriggerSpellAbsorb(self) then return end
				local dir = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
				caster:SetForwardVector(-dir); target:SetForwardVector(dir)
				local len = self:GetSpecialValueFor("enemy_length")
				caster:AddNewModifier(caster, self, "modifier_dota688_force_push", { duration = 0.5, distance = len })
				target:AddNewModifier(caster, self, "modifier_dota688_force_push", { duration = 0.5, distance = len })
				caster:AddNewModifier(caster, self, "modifier_dota688_pike_attacks", { duration = self:GetSpecialValueFor("range_duration") })
			end
			target:EmitSound("DOTA_Item.HurricanePike.Activate")
		end,
	},
})
modifier_dota688_pike_attacks = class({})
function modifier_dota688_pike_attacks:IsPurgable() return false end
function modifier_dota688_pike_attacks:OnCreated() self:SetStackCount(Dota688Val(self, "max_attacks")) end
function modifier_dota688_pike_attacks:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_EVENT_ON_ATTACK } end
function modifier_dota688_pike_attacks:GetModifierAttackRangeBonus() return 5000 end
function modifier_dota688_pike_attacks:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "bonus_attack_speed") end
function modifier_dota688_pike_attacks:OnAttack(params)
	if not IsServer() or params.attacker ~= self:GetParent() then return end
	self:DecrementStackCount()
	if self:GetStackCount() <= 0 then self:Destroy() end
end
