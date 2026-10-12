require("items/dota688_item_base")
-- Tango (6.88): 4 incarcaturi. Eat Tree: mananca un copac (raza 165) -> 115 HP in 16 s (regenerare).
-- Eat Ward: mananca un ward inamic (raza 450) -> durata dubla (230 HP in 32 s). Daunele nu opresc vindecarea.
-- Folosit pe un erou aliat ii da un Tango (Shared) si consuma o incarcatura (cere un slot liber in inventar).
-- Tango (Shared): o incarcatura, aceleasi efecte, nu poate fi dat mai departe, nu expira (spre deosebire de 7.x).
-- Un nou Tango cat timp efectul e activ nu se cumuleaza: pastreaza durata ramasa cea mai mare.
LinkLuaModifier("modifier_dota688_tango_heal", "items/item_dota688_tango", LUA_MODIFIER_MOTION_NONE)

local WARDS = { npc_dota_observer_wards = true, npc_dota_sentry_wards = true }

local function IsUnit(target) return target ~= nil and target.GetUnitName ~= nil end   -- copacii nu au GetUnitName

local function HasFreeSlot(unit)
	for s = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_6 do
		if unit:GetItemInSlot(s) == nil then return true end
	end
	return false
end

local function CanShare(self, target)
	local caster = self:GetCaster()
	return self.dota688_shareable and target ~= caster and target:GetTeamNumber() == caster:GetTeamNumber()
		and target:IsRealHero() and not target:IsIllusion()
end

local function Eat(self, duration)
	local caster = self:GetCaster()
	local regen = self:GetSpecialValueFor("total_heal") / self:GetSpecialValueFor("buff_duration")
	local m = caster:FindModifierByName("modifier_dota688_tango_heal")
	if m and m:GetRemainingTime() >= duration then
		m:SetStackCount(math.floor(regen * 100 + 0.5))
	else
		caster:AddNewModifier(caster, self, "modifier_dota688_tango_heal", { duration = duration, regen = regen })
	end
	caster:EmitSound("DOTA_Item.Tango.Activate")
	self:SpendCharge(0)
end

local function Define(name, shareable)
	Dota688DefineItem(name, "items/item_dota688_tango", {
		item = {
			dota688_shareable = shareable,
			CastFilterResultTarget = function(self, target)
				if not IsUnit(target) then return UF_SUCCESS end   -- copac
				local caster = self:GetCaster()
				if WARDS[target:GetUnitName()] then
					if target:GetTeamNumber() == caster:GetTeamNumber() then return UF_FAIL_FRIENDLY end
					return UF_SUCCESS
				end
				if CanShare(self, target) then
					if IsServer() and not HasFreeSlot(target) then
						self.dota688_err = "#dota_hud_error_target_cant_take_items"
						return UF_FAIL_CUSTOM
					end
					return UF_SUCCESS
				end
				if target == caster then
					self.dota688_err = "#dota_hud_error_cant_cast_on_self"
					return UF_FAIL_CUSTOM
				end
				self.dota688_err = "#dota_hud_error_cant_cast_on_other"
				return UF_FAIL_CUSTOM
			end,
			GetCustomCastErrorTarget = function(self, target) return self.dota688_err or "#dota_hud_error_cant_cast_on_other" end,
			GetCastRange = function(self, location, target)
				if IsUnit(target) and WARDS[target:GetUnitName()] then return self:GetSpecialValueFor("cast_range_ward") end
				return self.BaseClass.GetCastRange(self, location, target)
			end,
			OnSpellStart = function(self)
				local caster = self:GetCaster()
				local target = self:GetCursorTarget()
				if not target or target:IsNull() then return end
				local duration = self:GetSpecialValueFor("buff_duration")
				if not IsUnit(target) then
					if target.CutDown then
						target:CutDown(caster:GetTeamNumber())
					else
						-- copac temporar (Sprout etc.): nu e CDOTA_MapTree
						GridNav:DestroyTreesAroundPoint(target:GetAbsOrigin(), 10, false)
					end
					Eat(self, duration)
					return
				end
				if WARDS[target:GetUnitName()] then
					if not target:IsAlive() then return end
					target:Kill(self, caster)
					Eat(self, duration * 2)
					return
				end
				if CanShare(self, target) and HasFreeSlot(target) then
					local tango = CreateItem("item_dota688_tango_single", target, target)
					target:AddItem(tango)
					self:SpendCharge(0)
				end
			end,
		},
	})
end
Define("item_dota688_tango", true)
Define("item_dota688_tango_single", false)

-- regenerarea (motorul curent: regen constant = total_heal / buff_duration); stack = regen x 100 (vazut si de client)
modifier_dota688_tango_heal = class({})
function modifier_dota688_tango_heal:IsPurgable() return false end
function modifier_dota688_tango_heal:GetTexture() return "item_tango" end
function modifier_dota688_tango_heal:GetEffectName() return "particles/items_fx/healing_tango.vpcf" end
function modifier_dota688_tango_heal:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_tango_heal:OnCreated(kv)
	if IsServer() then self:SetStackCount(math.floor((kv.regen or 0) * 100 + 0.5)) end
end
function modifier_dota688_tango_heal:OnRefresh(kv)
	if IsServer() then self:SetStackCount(math.floor((kv.regen or 0) * 100 + 0.5)) end
end
function modifier_dota688_tango_heal:DeclareFunctions() return { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT } end
function modifier_dota688_tango_heal:GetModifierConstantHealthRegen() return self:GetStackCount() / 100 end
