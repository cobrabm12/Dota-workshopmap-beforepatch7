-- Leech Seed (6.88): pe un inamic (raza 350), 4.5 s: -28% viteza de miscare si 6 pulsuri (la 0.75 s) de 15/30/45/60 daune magice;
-- la fiecare puls, unitatile aliate din 500 de tinta sunt vindecate cu aceeasi valoare (proiectil de la tinta, viteza 400).
-- (Varianta 7.x - autocast pe atac, root + disarm - nu exista in 6.88.)
require("dota688/val")
LinkLuaModifier("modifier_dota688_treant_leech_seed", "abilities/heroes/dota688_treant_leech_seed", LUA_MODIFIER_MOTION_NONE)
dota688_treant_leech_seed = class({})
function dota688_treant_leech_seed:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if not target or target:IsNull() then return end
	caster:EmitSound("Hero_Treant.LeechSeed.Cast")
	if target:TriggerSpellAbsorb(self) then return end
	target:EmitSound("Hero_Treant.LeechSeed.Target")
	target:AddNewModifier(caster, self, "modifier_dota688_treant_leech_seed", { duration = self:GetSpecialValueFor("duration") })
end
function dota688_treant_leech_seed:OnProjectileHit_ExtraData(target, location, data)
	if not target or target:IsNull() or not target:IsAlive() then return true end
	local heal = data and data.heal or 0
	if heal > 0 then target:Heal(heal, self) end
	return true
end

modifier_dota688_treant_leech_seed = class({})
function modifier_dota688_treant_leech_seed:IsDebuff() return true end
function modifier_dota688_treant_leech_seed:IsPurgable() return true end
function modifier_dota688_treant_leech_seed:GetTexture() return "treant_leech_seed" end
function modifier_dota688_treant_leech_seed:OnCreated()
	if not IsServer() then return end
	self.pulses = 0
	self.maxPulses = math.floor(Dota688Val(self, "duration") / Dota688Val(self, "damage_interval") + 0.001)   -- 4.5 / 0.75 = 6
	self:StartIntervalThink(Dota688Val(self, "damage_interval"))
end
function modifier_dota688_treant_leech_seed:OnRefresh() self:OnCreated() end
function modifier_dota688_treant_leech_seed:OnIntervalThink() self:Pulse() end
function modifier_dota688_treant_leech_seed:Pulse()
	if self.pulses >= self.maxPulses then return end
	self.pulses = self.pulses + 1
	local p, caster, a = self:GetParent(), self:GetCaster(), self:GetAbility()
	if not caster or caster:IsNull() then return end
	local dmg = Dota688Val(self, "leech_damage")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_leech_seed_damage_pulse.vpcf", PATTACH_ABSORIGIN_FOLLOW, p)
	ParticleManager:ReleaseParticleIndex(fx)
	p:EmitSound("Hero_Treant.LeechSeed.Tick")
	ApplyDamage({ victim = p, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
	if not a or a:IsNull() then return end   -- abilitatea a disparut (Rubick): fara vindecare
	for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), p:GetAbsOrigin(), nil, Dota688Val(self, "radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		ProjectileManager:CreateTrackingProjectile({
			Target = u, Source = p, Ability = a, EffectName = "particles/units/heroes/hero_treant/treant_leech_seed_projectile.vpcf",
			iMoveSpeed = Dota688Val(self, "projectile_speed"), vSourceLoc = p:GetAbsOrigin(), bDodgeable = false, bProvidesVision = false,
			ExtraData = { heal = dmg },
		})
	end
end
function modifier_dota688_treant_leech_seed:OnDestroy()
	if not IsServer() then return end
	-- ultimul puls (la 4.5 s) cade odata cu expirarea; nu si cand seed-ul e scos cu purge sau tinta moare
	local p = self:GetParent()
	if self.pulses and self.pulses < self.maxPulses and self:GetRemainingTime() <= 0.05 and not p:IsNull() and p:IsAlive() then self:Pulse() end
end
function modifier_dota688_treant_leech_seed:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_treant_leech_seed:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "movement_slow") end
