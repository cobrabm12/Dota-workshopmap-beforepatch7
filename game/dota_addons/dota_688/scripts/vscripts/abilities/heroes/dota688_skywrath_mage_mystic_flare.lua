-- Mystic Flare (6.88): 600/1000/1400 daune magice impartite egal intre eroii din raza 170, pe 2.4 s (tick 0.1); nu loveste iluzii
-- si creep-eroi.
-- Scepter: cooldown 20/10/5, dureaza 12 s cu aceleasi daune pe secunda (deci de 5x mai multe daune totale).
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_mystic_flare", "abilities/heroes/dota688_skywrath_mage_mystic_flare", LUA_MODIFIER_MOTION_NONE)
dota688_skywrath_mage_mystic_flare = class({})
function dota688_skywrath_mage_mystic_flare:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_skywrath_mage_mystic_flare:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetLevelSpecialValueFor("cooldown_scepter", level) end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_skywrath_mage_mystic_flare:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	local dur = Dota688HasScepter(caster) and self:GetSpecialValueFor("duration_scepter") or self:GetSpecialValueFor("duration")
	caster:EmitSound("Hero_SkywrathMage.MysticFlare.Cast")
	EmitSoundOnLocationWithCaster(pos, "Hero_SkywrathMage.MysticFlare", caster)
	CreateModifierThinker(caster, self, "modifier_dota688_mystic_flare", { duration = dur }, pos, caster:GetTeamNumber(), false)
end
modifier_dota688_mystic_flare = class({})
function modifier_dota688_mystic_flare:IsHidden() return true end
function modifier_dota688_mystic_flare:OnCreated()
	if not IsServer() then return end
	local a = self:GetAbility()
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_skywrath_mage/skywrath_mage_mystic_flare_ambient.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:SetParticleControl(self.fx, 0, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.fx, 1, Vector(a:GetSpecialValueFor("radius"), self:GetDuration(), 0))
	self.interval = a:GetSpecialValueFor("damage_interval")
	self.dps = a:GetSpecialValueFor("damage") / a:GetSpecialValueFor("duration")
	self:StartIntervalThink(self.interval)
end
function modifier_dota688_mystic_flare:OnIntervalThink()
	local a, caster = self:GetAbility(), self:GetCaster()
	if not a or a:IsNull() or not caster or caster:IsNull() then self:Destroy(); return end   -- abilitatea/caster-ul au disparut (Rubick, iluzie moarta)
	local heroes = FindUnitsInRadius(caster:GetTeamNumber(), self:GetParent():GetAbsOrigin(), nil, a:GetSpecialValueFor("radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_ANY_ORDER, false)
	local real = {}
	for _, h in ipairs(heroes) do if h:IsRealHero() then real[#real + 1] = h end end
	heroes = real
	if #heroes == 0 then return end
	local dmg = self.dps * self.interval / #heroes
	for _, h in ipairs(heroes) do
		ApplyDamage({ victim = h, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
	end
end
function modifier_dota688_mystic_flare:OnDestroy() if IsServer() then ParticleManager:DestroyParticle(self.fx, false); UTIL_Remove(self:GetParent()) end end
