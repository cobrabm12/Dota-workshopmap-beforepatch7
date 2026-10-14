require("dota688/val")
require("items/dota688_item_base")
-- Mekansm (6.88): +5 la toate, +5 armura; aura +4 regen (900); Restore: vindeca 250 si +2 armura 25 s aliatilor din 900, cd 65, 225 mana.
require("items/dota688_item_base")
Dota688DefineAura("modifier_dota688_mekansm_aura", "items/item_dota688_mekansm", {
	radius = function(self) return Dota688Val(self, "aura_radius") end,
	functions = { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT },
	effect = { GetModifierConstantHealthRegen = function(self) return Dota688Val(self, "aura_health_regen") end },
})
LinkLuaModifier("modifier_dota688_mekansm_armor", "items/item_dota688_mekansm", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_mekansm", "items/item_dota688_mekansm", {
	onCreated = function(self)
		if IsServer() and not self:GetParent():HasModifier("modifier_dota688_mekansm_aura") then
			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dota688_mekansm_aura", {})
		end
	end,
	modifier = {
		OnDestroy = function(self)
			if IsServer() then Dota688ReapplyAura(self:GetParent(), "modifier_dota688_mekansm_aura", { "item_dota688_mekansm" }) end
		end,
	},
	item = {
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			caster:EmitSound("DOTA_Item.Mekansm.Activate")
			local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("heal_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _, u in ipairs(allies) do
				if not u:HasModifier("modifier_dota688_restore_lockout") then   -- 6.88: nu afecteaza unitatile vindecate de Restore/Mend in ultimele 25 s
					u:Heal(self:GetSpecialValueFor("heal_amount"), self)
					u:AddNewModifier(caster, self, "modifier_dota688_mekansm_armor", { duration = self:GetSpecialValueFor("heal_armor_duration") })
					u:AddNewModifier(caster, self, "modifier_dota688_restore_lockout", { duration = Dota688RESTORE_LOCKOUT })
					local fx = ParticleManager:CreateParticle("particles/items2_fx/mekanism.vpcf", PATTACH_ABSORIGIN_FOLLOW, u)
					ParticleManager:ReleaseParticleIndex(fx)
				end
			end
		end,
	},
})
modifier_dota688_mekansm_armor = class({})
function modifier_dota688_mekansm_armor:IsPurgable() return true end
function modifier_dota688_mekansm_armor:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS } end
function modifier_dota688_mekansm_armor:GetModifierPhysicalArmorBonus() return Dota688Val(self, "heal_bonus_armor") end
