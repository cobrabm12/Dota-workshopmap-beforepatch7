-- Poison Nova (6.88): val de otrava (255 -> 830 raza, viteza 500); 30/55/80 daune magice/s 16 s, nu poate omori (lasa 1 HP).
-- Scepter: 60/85/110 daune/s, cooldown 140/120/60.
require("dota688/aghanim")
local F = "abilities/heroes/dota688_venomancer_poison_nova"
LinkLuaModifier("modifier_dota688_poison_nova_wave", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_poison_nova", F, LUA_MODIFIER_MOTION_NONE)
dota688_venomancer_poison_nova = class({})
function dota688_venomancer_poison_nova:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetLevelSpecialValueFor("cooldown_scepter", level) end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_venomancer_poison_nova:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_Venomancer.PoisonNova")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_venomancer/venomancer_poison_nova.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(fx, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(fx, 1, Vector(self:GetSpecialValueFor("radius"), 0, 0))
	ParticleManager:ReleaseParticleIndex(fx)
	CreateModifierThinker(caster, self, "modifier_dota688_poison_nova_wave", { duration = 3 }, caster:GetAbsOrigin(), caster:GetTeamNumber(), false)
end
modifier_dota688_poison_nova_wave = class({})
function modifier_dota688_poison_nova_wave:IsHidden() return true end
function modifier_dota688_poison_nova_wave:OnCreated()
	if not IsServer() then return end
	self.r = self:GetAbility():GetSpecialValueFor("start_radius")
	self.hit = {}
	self:StartIntervalThink(0.1)
end
function modifier_dota688_poison_nova_wave:OnIntervalThink()
	local a, caster = self:GetAbility(), self:GetCaster()
	if not a or a:IsNull() or not caster or caster:IsNull() then self:Destroy(); return end   -- abilitatea/caster-ul au disparut (Rubick, iluzie moarta)
	self.r = self.r + a:GetSpecialValueFor("speed") * 0.1
	local maxr = a:GetSpecialValueFor("radius")
	local dur = Dota688HasScepter(caster) and a:GetSpecialValueFor("duration_scepter") or a:GetSpecialValueFor("duration")
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, math.min(self.r, maxr), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if not self.hit[e:entindex()] then
			self.hit[e:entindex()] = true
			e:AddNewModifier(caster, a, "modifier_dota688_poison_nova", { duration = dur })
		end
	end
	if self.r >= maxr then self:Destroy() end
end
function modifier_dota688_poison_nova_wave:OnDestroy() if IsServer() then UTIL_Remove(self:GetParent()) end end
modifier_dota688_poison_nova = class({})
function modifier_dota688_poison_nova:IsDebuff() return true end
function modifier_dota688_poison_nova:IsPurgable() return false end
function modifier_dota688_poison_nova:GetEffectName() return "particles/units/heroes/hero_venomancer/venomancer_poison_debuff_nova.vpcf" end
function modifier_dota688_poison_nova:OnCreated()
	if not IsServer() then return end
	self.dmg = Dota688HasScepter(self:GetCaster()) and self:GetAbility():GetSpecialValueFor("damage_scepter") or self:GetAbility():GetSpecialValueFor("damage")
	self:StartIntervalThink(1.0)
end
function modifier_dota688_poison_nova:OnIntervalThink()
	local p = self:GetParent()
	local dmg = math.min(self.dmg, math.max(0, p:GetHealth() - 1))   -- nu omoara
	if dmg > 0 then ApplyDamage({ victim = p, attacker = self:GetCaster(), damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = self:GetAbility(), damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL }) end
end
