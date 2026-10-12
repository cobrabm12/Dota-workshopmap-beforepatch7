require("dota688/val")
require("items/dota688_item_base")
-- Pipe of Insight (6.88): +8 regen, +30% rezistenta magica; aura 900: +4 regen, +10% rezistenta; Barrier: 400 absorbtie magica 12 s aliatilor din 900, cd 60.
Dota688DefineAura("modifier_dota688_pipe_aura", "items/item_dota688_pipe", {
	radius = function(self) return Dota688Val(self, "aura_radius") end,
	functions = { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS },
	effect = {
		GetModifierConstantHealthRegen = function(self) return Dota688Val(self, "aura_health_regen") end,
		GetModifierMagicalResistanceBonus = function(self) return Dota688Val(self, "magic_resistance_aura") end,
	},
})
LinkLuaModifier("modifier_dota688_pipe_barrier", "items/item_dota688_pipe", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_pipe_barrier_cd", "items/item_dota688_pipe", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_pipe", "items/item_dota688_pipe", {
	onCreated = function(self)
		if IsServer() and not self:GetParent():HasModifier("modifier_dota688_pipe_aura") then
			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dota688_pipe_aura", {})
		end
	end,
	modifier = {
		OnDestroy = function(self)
			if IsServer() and not self:GetParent():HasItemInInventory("item_dota688_pipe") then self:GetParent():RemoveModifierByName("modifier_dota688_pipe_aura") end
		end,
	},
	item = {
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			caster:EmitSound("DOTA_Item.Pipe.Activate")
			local allies = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, self:GetSpecialValueFor("barrier_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _, u in ipairs(allies) do
				if not u:HasModifier("modifier_dota688_pipe_barrier_cd") then
					u:AddNewModifier(caster, self, "modifier_dota688_pipe_barrier", { duration = self:GetSpecialValueFor("barrier_duration") })
					u:AddNewModifier(caster, self, "modifier_dota688_pipe_barrier_cd", { duration = self:GetSpecialValueFor("barrier_debuff_duration") })
				end
			end
		end,
	},
})
modifier_dota688_pipe_barrier = class({})
function modifier_dota688_pipe_barrier:IsPurgable() return false end
function modifier_dota688_pipe_barrier:OnCreated()
	local a = self:GetAbility()
	self.left = self:GetParent():IsHero() and a:GetSpecialValueFor("barrier_block") or a:GetSpecialValueFor("barrier_block_creep")
end
function modifier_dota688_pipe_barrier:DeclareFunctions() return { MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT } end
function modifier_dota688_pipe_barrier:GetModifierIncomingDamageConstant(params)
	if not IsServer() or params.damage_type ~= DAMAGE_TYPE_MAGICAL or params.damage <= 0 then return 0 end
	local block = math.min(self.left, params.damage)
	self.left = self.left - block
	if self.left <= 0 then self:Destroy() end
	return -block
end
modifier_dota688_pipe_barrier_cd = class({})
function modifier_dota688_pipe_barrier_cd:IsHidden() return true end
function modifier_dota688_pipe_barrier_cd:IsDebuff() return true end
function modifier_dota688_pipe_barrier_cd:IsPurgable() return false end
