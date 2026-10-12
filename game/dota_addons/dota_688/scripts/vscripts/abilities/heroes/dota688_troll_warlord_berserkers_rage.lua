-- Berserker's Rage (6.88): toggle: forma melee (raza 128, BAT 1.5): +10/20/30/40 MS, +6 armura, 10% sansa de bash 0.8-2.0 s cu +20-50 daune.
require("dota688/val")
LinkLuaModifier("modifier_dota688_troll_warlord_berserkers_rage", "abilities/heroes/dota688_troll_warlord_berserkers_rage", LUA_MODIFIER_MOTION_NONE)
dota688_troll_warlord_berserkers_rage = class({})
function dota688_troll_warlord_berserkers_rage:OnToggle()
	local caster = self:GetCaster()
	if self:GetToggleState() then
		caster:AddNewModifier(caster, self, "modifier_dota688_troll_warlord_berserkers_rage", {})
		caster:EmitSound("Hero_TrollWarlord.BerserkersRage.On")
	else
		caster:RemoveModifierByName("modifier_dota688_troll_warlord_berserkers_rage")
		caster:EmitSound("Hero_TrollWarlord.BerserkersRage.Off")
	end
end
function dota688_troll_warlord_berserkers_rage:OnUpgrade()
	if self:GetToggleState() then
		local m = self:GetCaster():FindModifierByName("modifier_dota688_troll_warlord_berserkers_rage")
		if m then m:ForceRefresh() end
	end
end

modifier_dota688_troll_warlord_berserkers_rage = class({})
function modifier_dota688_troll_warlord_berserkers_rage:IsPurgable() return false end
function modifier_dota688_troll_warlord_berserkers_rage:RemoveOnDeath() return false end
function modifier_dota688_troll_warlord_berserkers_rage:OnCreated()
	local a = self:GetAbility()
	self.ms = a:GetSpecialValueFor("bonus_move_speed")
	self.armor = a:GetSpecialValueFor("bonus_armor")
	self.bat = a:GetSpecialValueFor("base_attack_time")
	local p = self:GetParent()
	self.rangedRange = p.GetBaseAttackRange and p:GetBaseAttackRange() or 500   -- GetBaseAttackRange nu exista pe client
	if IsServer() then self:GetParent():SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK) end
end
function modifier_dota688_troll_warlord_berserkers_rage:OnRefresh() self:OnCreated() end
function modifier_dota688_troll_warlord_berserkers_rage:OnDestroy()
	if IsServer() then self:GetParent():SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK) end
end
function modifier_dota688_troll_warlord_berserkers_rage:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL, MODIFIER_EVENT_ON_ATTACK_LANDED }
end
function modifier_dota688_troll_warlord_berserkers_rage:GetModifierMoveSpeedBonus_Constant() return self.ms end
function modifier_dota688_troll_warlord_berserkers_rage:GetModifierPhysicalArmorBonus() return self.armor end
function modifier_dota688_troll_warlord_berserkers_rage:GetModifierBaseAttackTimeConstant() return self.bat end
function modifier_dota688_troll_warlord_berserkers_rage:GetModifierAttackRangeBonus() return 128 - (self.rangedRange or 500) end
function modifier_dota688_troll_warlord_berserkers_rage:GetModifierProcAttack_BonusDamage_Physical(params)
	if not IsServer() then return 0 end
	local parent = self:GetParent()
	local target = params.target
	if parent:PassivesDisabled() or not target or target:IsBuilding() or target:IsOther() then return 0 end
	if RollPseudoRandomPercentage(Dota688Val(self, "bash_chance"), DOTA_PSEUDO_RANDOM_TROLL_BASH, parent) then
		self.bashTarget = target
		return Dota688Val(self, "bash_damage")
	end
	return 0
end
function modifier_dota688_troll_warlord_berserkers_rage:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() or params.target ~= self.bashTarget then return end
	self.bashTarget = nil
	params.target:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_stunned", { duration = Dota688Val(self, "bash_duration") })
end
