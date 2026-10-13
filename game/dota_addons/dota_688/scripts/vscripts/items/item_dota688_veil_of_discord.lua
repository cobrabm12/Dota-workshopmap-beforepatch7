require("dota688/val")
require("items/dota688_item_base")
-- Veil of Discord (6.88): +6 regen, +6 armura, +6 STR/AGI, +12 INT, +6 daune; Magic Weakness: -25% rezistenta magica in 600 raza, 16 s.
LinkLuaModifier("modifier_dota688_veil_debuff", "items/item_dota688_veil_of_discord", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_veil_of_discord", "items/item_dota688_veil_of_discord", {
	item = {
		GetAOERadius = function(self) return self:GetSpecialValueFor("debuff_radius") end,
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			local pos = self:GetCursorPosition()
			caster:EmitSound("DOTA_Item.VeilofDiscord.Activate")
			local fx = ParticleManager:CreateParticle("particles/items2_fx/veil_of_discord.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(fx, 0, pos)
			ParticleManager:SetParticleControl(fx, 1, Vector(self:GetSpecialValueFor("debuff_radius"), 0, 0))
			ParticleManager:ReleaseParticleIndex(fx)
			local enemies = FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, self:GetSpecialValueFor("debuff_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _, e in ipairs(enemies) do
				e:AddNewModifier(caster, self, "modifier_dota688_veil_debuff", { duration = self:GetSpecialValueFor("resist_debuff_duration") })
			end
		end,
	},
})
modifier_dota688_veil_debuff = class({})
function modifier_dota688_veil_debuff:IsDebuff() return true end
function modifier_dota688_veil_debuff:IsPurgable() return true end
function modifier_dota688_veil_debuff:GetEffectName() return "particles/items2_fx/veil_of_discord_debuff.vpcf" end
function modifier_dota688_veil_debuff:DeclareFunctions() return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS } end
function modifier_dota688_veil_debuff:GetModifierMagicalResistanceBonus() return Dota688Val(self, "resist_debuff") end
