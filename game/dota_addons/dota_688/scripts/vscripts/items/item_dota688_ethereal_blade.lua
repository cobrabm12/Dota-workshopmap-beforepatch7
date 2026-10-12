require("items/dota688_item_base")
-- Ethereal Blade (6.88): +40 AGI, +10 STR, +10 INT; Ether Blast: tinta devine eterica 3 s (4 s aliat), -80% MS, +40% daune magice primite; 75 + 2 x AGI daune magice.
LinkLuaModifier("modifier_dota688_ethereal", "items/item_dota688_ethereal_blade", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_ethereal_blade", "items/item_dota688_ethereal_blade", {
	item = {
		OnSpellStart = function(self)
			local caster, target = self:GetCaster(), self:GetCursorTarget()
			local ally = target:GetTeamNumber() == caster:GetTeamNumber()
			if not ally and target:TriggerSpellAbsorb(self) then return end
			caster:EmitSound("DOTA_Item.EtherealBlade.Activate")
			ProjectileManager:CreateTrackingProjectile({ Target = target, Source = caster, Ability = self,
				EffectName = "particles/items_fx/ethereal_blade.vpcf", iMoveSpeed = self:GetSpecialValueFor("projectile_speed"), bDodgeable = true })
		end,
		OnProjectileHit = function(self, target, loc)
			if not target then return end
			local caster = self:GetCaster()
			local ally = target:GetTeamNumber() == caster:GetTeamNumber()
			target:EmitSound("DOTA_Item.EtherealBlade.Target")
			target:AddNewModifier(caster, self, "modifier_dota688_ethereal", { duration = ally and self:GetSpecialValueFor("duration_ally") or self:GetSpecialValueFor("duration") })
			if not ally then
				local dmg = self:GetSpecialValueFor("blast_damage_base") + caster:GetAgility() * self:GetSpecialValueFor("blast_agility_multiplier")
				ApplyDamage({ victim = target, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
			end
			return true
		end,
	},
})
modifier_dota688_ethereal = class({})
function modifier_dota688_ethereal:IsPurgable() return true end
function modifier_dota688_ethereal:IsDebuff() return self:GetParent():GetTeamNumber() ~= self:GetCaster():GetTeamNumber() end
function modifier_dota688_ethereal:GetStatusEffectName() return "particles/status_fx/status_effect_ghost.vpcf" end
function modifier_dota688_ethereal:CheckState() return { [MODIFIER_STATE_DISARMED] = true, [MODIFIER_STATE_ATTACK_IMMUNE] = true } end
function modifier_dota688_ethereal:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS } end
function modifier_dota688_ethereal:GetModifierMoveSpeedBonus_Percentage()
	if self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber() then return 0 end
	return self:GetAbility():GetSpecialValueFor("blast_movement_slow")
end
function modifier_dota688_ethereal:GetModifierMagicalResistanceBonus() return self:GetAbility():GetSpecialValueFor("ethereal_damage_bonus") end
