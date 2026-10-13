require("dota688/val")
require("items/dota688_item_base")
-- Shiva's Guard (6.88): +30 INT, +15 armura; aura: -45 AS inamicilor in 900; Arctic Blast: 200 daune magice, -40% MS 4 s.
LinkLuaModifier("modifier_dota688_shivas_aura", "items/item_dota688_shivas_guard", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_shivas_aura_effect", "items/item_dota688_shivas_guard", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_shivas_blast", "items/item_dota688_shivas_guard", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_shivas_guard", "items/item_dota688_shivas_guard", {
	onCreated = function(self)
		if IsServer() and not self:GetParent():HasModifier("modifier_dota688_shivas_aura") then
			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dota688_shivas_aura", {})
		end
	end,
	modifier = {
		OnDestroy = function(self)
			if IsServer() and not self:GetParent():HasItemInInventory("item_dota688_shivas_guard") then
				self:GetParent():RemoveModifierByName("modifier_dota688_shivas_aura")
			end
		end,
	},
	item = {
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			caster:EmitSound("DOTA_Item.ShivasGuard.Activate")
			local r = self:GetSpecialValueFor("blast_radius")
			local fx = ParticleManager:CreateParticle("particles/items2_fx/shivas_guard_active.vpcf", PATTACH_ABSORIGIN, caster)
			ParticleManager:SetParticleControl(fx, 1, Vector(r, 0, self:GetSpecialValueFor("blast_speed")))
			ParticleManager:ReleaseParticleIndex(fx)
			local enemies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, r, DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _, e in ipairs(enemies) do
				local delay = (e:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D() / self:GetSpecialValueFor("blast_speed")
				Dota688Timers:After(delay, function()
					if e:IsNull() or not e:IsAlive() then return end
					ApplyDamage({ victim = e, attacker = caster, damage = self:GetSpecialValueFor("blast_damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
					e:AddNewModifier(caster, self, "modifier_dota688_shivas_blast", { duration = self:GetSpecialValueFor("blast_debuff_duration") })
				end)
			end
		end,
	},
})
modifier_dota688_shivas_aura = class({})
function modifier_dota688_shivas_aura:IsHidden() return true end
function modifier_dota688_shivas_aura:IsPurgable() return false end
function modifier_dota688_shivas_aura:RemoveOnDeath() return false end
function modifier_dota688_shivas_aura:IsAura() return true end
function modifier_dota688_shivas_aura:GetAuraRadius() return Dota688Val(self, "aura_radius") end
function modifier_dota688_shivas_aura:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_ENEMY end
function modifier_dota688_shivas_aura:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_shivas_aura:GetModifierAura() return "modifier_dota688_shivas_aura_effect" end
modifier_dota688_shivas_aura_effect = class({})
function modifier_dota688_shivas_aura_effect:IsDebuff() return true end
function modifier_dota688_shivas_aura_effect:IsPurgable() return false end
function modifier_dota688_shivas_aura_effect:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_shivas_aura_effect:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "aura_attack_speed") end
modifier_dota688_shivas_blast = class({})
function modifier_dota688_shivas_blast:IsDebuff() return true end
function modifier_dota688_shivas_blast:IsPurgable() return true end
function modifier_dota688_shivas_blast:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_shivas_blast:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "blast_movement_speed") end
