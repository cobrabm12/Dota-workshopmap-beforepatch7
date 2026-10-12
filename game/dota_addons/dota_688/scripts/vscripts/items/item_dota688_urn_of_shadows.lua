require("dota688/val")
require("items/dota688_item_base")
-- Urn of Shadows (6.88): +6 STR, +50% regen mana; incarcaturi la moartea eroilor inamici in 1400 (2 initial, +1); Soul Release: vindeca 400 / 8 s sau 150 daune pure / 8 s.
LinkLuaModifier("modifier_dota688_urn_heal", "items/item_dota688_urn_of_shadows", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_urn_damage", "items/item_dota688_urn_of_shadows", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_urn_of_shadows", "items/item_dota688_urn_of_shadows", {
	extraFunctions = { MODIFIER_EVENT_ON_DEATH },
	onCreated = function(self)
		local a = self:GetAbility()
		if IsServer() and not a.dota688_init then
			a.dota688_init = true
			a:SetCurrentCharges(a:GetSpecialValueFor("soul_initial_charge"))
		end
	end,
	modifier = {
		OnDeath = function(self, params)
			if not IsServer() then return end
			local parent = self:GetParent()
			local unit = params.unit
			if not unit or not unit:IsRealHero() or unit:IsIllusion() or unit:GetTeamNumber() == parent:GetTeamNumber() then return end
			if (unit:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D() > Dota688Val(self, "soul_radius") then return end
			local a = self:GetAbility()
			a:SetCurrentCharges(a:GetCurrentCharges() + a:GetSpecialValueFor("soul_additional_charges"))
		end,
	},
	item = {
		CastFilterResultTarget = function(self, target)
			if self:GetCurrentCharges() <= 0 then return UF_FAIL_CUSTOM end
			return UF_SUCCESS
		end,
		GetCustomCastErrorTarget = function(self, target) return "#dota_hud_error_item_no_charges" end,
		OnSpellStart = function(self)
			local caster, target = self:GetCaster(), self:GetCursorTarget()
			if self:GetCurrentCharges() <= 0 then return end
			if target:GetTeamNumber() == caster:GetTeamNumber() then
				target:AddNewModifier(caster, self, "modifier_dota688_urn_heal", { duration = self:GetSpecialValueFor("soul_heal_duration") })
			else
				if target:TriggerSpellAbsorb(self) then return end
				target:AddNewModifier(caster, self, "modifier_dota688_urn_damage", { duration = self:GetSpecialValueFor("soul_damage_duration") })
			end
			self:SetCurrentCharges(self:GetCurrentCharges() - 1)
			target:EmitSound("DOTA_Item.UrnOfShadows.Activate")
		end,
	},
})
modifier_dota688_urn_heal = class({})
function modifier_dota688_urn_heal:IsPurgable() return true end
function modifier_dota688_urn_heal:GetEffectName() return "particles/items2_fx/urn_of_shadows_heal.vpcf" end
function modifier_dota688_urn_heal:OnCreated()
	local a = self:GetAbility()
	self.tick = a:GetSpecialValueFor("soul_heal_interval")
	self.per = a:GetSpecialValueFor("soul_heal_amount") / a:GetSpecialValueFor("soul_heal_duration") * self.tick
	if IsServer() then self:StartIntervalThink(self.tick) end
end
function modifier_dota688_urn_heal:OnIntervalThink() self:GetParent():Heal(self.per, self:GetAbility()) end
function modifier_dota688_urn_heal:DeclareFunctions() return { MODIFIER_EVENT_ON_TAKEDAMAGE } end
function modifier_dota688_urn_heal:OnTakeDamage(params)
	-- vindecarea se opreste la daune de la jucatori
	if IsServer() and params.unit == self:GetParent() and params.attacker and params.attacker:IsControllableByAnyPlayer() and params.attacker:GetTeamNumber() ~= self:GetParent():GetTeamNumber() then
		self:Destroy()
	end
end
modifier_dota688_urn_damage = class({})
function modifier_dota688_urn_damage:IsDebuff() return true end
function modifier_dota688_urn_damage:IsPurgable() return true end
function modifier_dota688_urn_damage:GetEffectName() return "particles/items2_fx/urn_of_shadows_damage.vpcf" end
function modifier_dota688_urn_damage:OnCreated()
	local a = self:GetAbility()
	self.tick = 1.0
	self.per = a:GetSpecialValueFor("soul_damage_amount") / a:GetSpecialValueFor("soul_damage_duration") * self.tick
	if IsServer() then self:StartIntervalThink(self.tick) end
end
function modifier_dota688_urn_damage:OnIntervalThink()
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = self.per, damage_type = DAMAGE_TYPE_PURE, ability = self:GetAbility() })
end
