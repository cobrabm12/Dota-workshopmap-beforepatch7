require("dota688/val")
require("items/dota688_item_base")
-- Power Treads (6.88): +45 MS, +25 AS, +9 la atributul ales (STR/AGI/INT, comutat prin click).
-- Atributul ales sta in stack count-ul modifierului intrinsec (0 STR, 1 AGI, 2 INT), care ajunge si la client (statisticile
-- din HUD). Iconita itemului (power_treads_str/agi/int) se alege pe client dupa un modifier-marcaj ascuns pe erou:
-- clientul are doar HasModifier, nu si cautarea modifierilor dupa nume.
local MARKERS = { [0] = "modifier_dota688_treads_str", [1] = "modifier_dota688_treads_agi", [2] = "modifier_dota688_treads_int" }
local ICONS = { [0] = "item_power_treads_str", [1] = "item_power_treads_agi", [2] = "item_power_treads_int" }
for _, name in pairs(MARKERS) do
	LinkLuaModifier(name, "items/item_dota688_power_treads", LUA_MODIFIER_MOTION_NONE)
	local m = class({})
	function m:IsHidden() return true end
	function m:IsPurgable() return false end
	function m:RemoveOnDeath() return false end
	_G[name] = m
end
local function SetMarker(unit, attr)
	for a, name in pairs(MARKERS) do
		if a ~= attr then unit:RemoveModifierByName(name) end
	end
	if attr and not unit:HasModifier(MARKERS[attr]) then unit:AddNewModifier(unit, nil, MARKERS[attr], {}) end
end
local function Bonus(self, attr) return self:GetStackCount() == attr and Dota688Val(self, "bonus_stat") or 0 end
Dota688DefineItem("item_dota688_power_treads", "items/item_dota688_power_treads", {
	boots = true,   -- viteza cizmelor nu se aduna cu alte cizme (6.88)
	onCreated = function(self)
		if not IsServer() then return end
		local attr = self:GetAbility().attr or 0
		self:SetStackCount(attr)
		SetMarker(self:GetParent(), attr)
	end,
	modifier = {
		GetModifierBonusStats_Strength = function(self) return Bonus(self, 0) end,
		GetModifierBonusStats_Agility = function(self) return Bonus(self, 1) end,
		GetModifierBonusStats_Intellect = function(self) return Bonus(self, 2) end,
		OnDestroy = function(self)
			if not IsServer() then return end
			local p = self:GetParent()
			-- alte Power Treads ramase in inventar: marcajul urmeaza primele dintre ele
			local other = p:FindModifierByName("modifier_item_dota688_power_treads")
			SetMarker(p, other and other ~= self and other:GetStackCount() or nil)
		end,
	},
	item = {
		GetAbilityTextureName = function(self)
			local caster = self:GetCaster()
			if caster and not caster:IsNull() then
				for attr, name in pairs(MARKERS) do
					if caster:HasModifier(name) then return ICONS[attr] end
				end
			end
			return ICONS[0]
		end,
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			self.attr = ((self.attr or 0) + 1) % 3
			for _, m in ipairs(caster:FindAllModifiersByName("modifier_item_dota688_power_treads")) do
				if m:GetAbility() == self then m:SetStackCount(self.attr) end
			end
			SetMarker(caster, self.attr)
			caster:CalculateStatBonus(true)
			caster:EmitSound("DOTA_Item.PowerTreads.Activate")
		end,
	},
})
