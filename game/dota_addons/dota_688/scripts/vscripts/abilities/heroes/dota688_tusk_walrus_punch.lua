-- Walrus PUNCH! (6.88, orb/ultimate): urmatorul atac e critic 350%, arunca tinta in aer 1 s si o incetineste 40% pentru 2/3/4 s.
require("dota688/val")
local F = "abilities/heroes/dota688_tusk_walrus_punch"
LinkLuaModifier("modifier_dota688_walrus_punch_buff", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_walrus_punch_slow", F, LUA_MODIFIER_MOTION_NONE)
dota688_tusk_walrus_punch = class({})
function dota688_tusk_walrus_punch:OnOrbFire(params) end
function dota688_tusk_walrus_punch:OnOrbImpact(params)
	-- motorul nu transmite fiabil criticul prin OnOrbImpact; folosim buff-ul de "urmatorul atac"
end
function dota688_tusk_walrus_punch:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_dota688_walrus_punch_buff", { duration = 10 })
	local t = self:GetCursorTarget()
	if t then caster:PerformAttack(t, true, true, true, false, true, false, false) end
end
modifier_dota688_walrus_punch_buff = class({})
function modifier_dota688_walrus_punch_buff:IsHidden() return false end
function modifier_dota688_walrus_punch_buff:IsPurgable() return false end
function modifier_dota688_walrus_punch_buff:DeclareFunctions() return { MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE, MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_walrus_punch_buff:GetModifierPreAttack_CriticalStrike(params)
	local t = params.target
	if not t or t:IsBuilding() or t:IsOther() then return nil end
	self.punchTarget = t
	return Dota688Val(self, "crit_multiplier")
end
function modifier_dota688_walrus_punch_buff:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() or params.target ~= self.punchTarget then return end
	local a, t = self:GetAbility(), params.target
	t:EmitSound("Hero_Tusk.WalrusPunch.Target")
	if not t:IsMagicImmune() or true then
		t:AddNewModifier(self:GetParent(), a, "modifier_knockback", { duration = a:GetSpecialValueFor("air_time"), knockback_duration = a:GetSpecialValueFor("air_time"),
			knockback_distance = 50, knockback_height = 350, should_stun = 1, center_x = self:GetParent():GetAbsOrigin().x, center_y = self:GetParent():GetAbsOrigin().y, center_z = self:GetParent():GetAbsOrigin().z })
		t:AddNewModifier(self:GetParent(), a, "modifier_dota688_walrus_punch_slow", { duration = a:GetSpecialValueFor("slow_duration") + a:GetSpecialValueFor("air_time") })
	end
	self:Destroy()
end
modifier_dota688_walrus_punch_slow = class({})
function modifier_dota688_walrus_punch_slow:IsDebuff() return true end
function modifier_dota688_walrus_punch_slow:IsPurgable() return true end
function modifier_dota688_walrus_punch_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_walrus_punch_slow:GetModifierMoveSpeedBonus_Percentage() return -Dota688Val(self, "move_slow") end
