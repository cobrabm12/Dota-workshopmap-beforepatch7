require("items/dota688_item_base")
-- Manta Style (6.88): +10 STR, +26 AGI, +10 INT, +15 AS, +10% MS; Mirror Image: 2 iluzii 20 s (33%/28% daune, 350%/400% daune primite), cd 30 melee / 45 ranged.
Dota688DefineItem("item_dota688_manta", "items/item_dota688_manta", {
	extraFunctions = { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE_UNIQUE },
	modifier = {
		-- bonus_movement_speed "10" e procent in 6.88 ("+10% Movement Speed", nu se cumuleaza cu Yasha / S&Y)
		GetModifierMoveSpeedBonus_Constant = function() return 0 end,
		GetModifierMoveSpeedBonus_Percentage_Unique = function(self) local a = self:GetAbility(); return a and a:GetSpecialValueFor("bonus_movement_speed") or 0 end,
	},
	item = {
		GetCooldown = function(self, level)
			local c = self:GetCaster()
			if c and c:IsRangedAttacker() then return self:GetSpecialValueFor("cooldown_ranged_tooltip") end
			return self:GetSpecialValueFor("cooldown_melee")
		end,
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			local ranged = caster:IsRangedAttacker()
			caster:EmitSound("DOTA_Item.Manta.Activate")
			caster:Purge(false, true, false, false, false)
			ProjectileManager:ProjectileDodge(caster)
			caster:AddNewModifier(caster, self, "modifier_invulnerable", { duration = self:GetSpecialValueFor("invuln_duration") })
			local out = ranged and self:GetSpecialValueFor("images_do_damage_percent_ranged") or self:GetSpecialValueFor("images_do_damage_percent_melee")
			local inc = ranged and self:GetSpecialValueFor("images_take_damage_percent_ranged") or self:GetSpecialValueFor("images_take_damage_percent_melee")
			CreateIllusions(caster, caster, { outgoing_damage = out, incoming_damage = inc, duration = self:GetSpecialValueFor("tooltip_illusion_duration") },
				self:GetSpecialValueFor("images_count"), 108, true, true)
		end,
	},
})
