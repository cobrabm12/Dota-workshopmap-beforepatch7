require("items/dota688_item_base")
-- Armlet of Mordiggian (6.88): +9 daune, +25 AS, +5 armura, +7 regen; Unholy Strength (toggle): +31 daune, +25 STR, +4 armura, -45 HP/s.
LinkLuaModifier("modifier_dota688_unholy_strength", "items/item_dota688_armlet", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_armlet", "items/item_dota688_armlet", {
	item = {
		OnToggle = function(self)
			local caster = self:GetCaster()
			if self:GetToggleState() then
				caster:AddNewModifier(caster, self, "modifier_dota688_unholy_strength", {})
				caster:EmitSound("DOTA_Item.Armlet.Activate")
			else
				caster:RemoveModifierByName("modifier_dota688_unholy_strength")
				caster:EmitSound("DOTA_Item.Armlet.DeActivate")
			end
		end,
	},
})
modifier_dota688_unholy_strength = class({})
function modifier_dota688_unholy_strength:IsPurgable() return false end
function modifier_dota688_unholy_strength:RemoveOnDeath() return true end
function modifier_dota688_unholy_strength:GetEffectName() return "particles/items_fx/armlet.vpcf" end
function modifier_dota688_unholy_strength:OnCreated()
	if IsServer() then self:StartIntervalThink(0.1) end
end
function modifier_dota688_unholy_strength:OnIntervalThink()
	local p = self:GetParent()
	local drain = self:GetAbility():GetSpecialValueFor("unholy_health_drain_per_tick") * 0.1 / 0.1  -- 5 per 0.1 s? KV: 5 per tick, 45/s => tick ~0.111; folosim 4.5 la 0.1 s
	drain = self:GetAbility():GetSpecialValueFor("unholy_health_drain_per_second_tooltip") * 0.1
	if p:GetHealth() > drain then p:SetHealth(p:GetHealth() - drain) else p:SetHealth(1) end
end
function modifier_dota688_unholy_strength:OnDestroy()
	if IsServer() then
		local a = self:GetAbility()
		if a and a:GetToggleState() then a:ToggleAbility() end
	end
end
function modifier_dota688_unholy_strength:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_unholy_strength:GetModifierPreAttack_BonusDamage() return self:GetAbility():GetSpecialValueFor("unholy_bonus_damage") end
function modifier_dota688_unholy_strength:GetModifierBonusStats_Strength() return self:GetAbility():GetSpecialValueFor("unholy_bonus_strength") end
function modifier_dota688_unholy_strength:GetModifierPhysicalArmorBonus() return self:GetAbility():GetSpecialValueFor("unholy_bonus_armor") end
function modifier_dota688_unholy_strength:GetModifierAttackSpeedBonus_Constant() return self:GetAbility():GetSpecialValueFor("unholy_bonus_attack_speed") end
