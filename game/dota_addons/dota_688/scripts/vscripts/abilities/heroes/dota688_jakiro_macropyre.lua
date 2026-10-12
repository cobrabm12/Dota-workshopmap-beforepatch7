-- Macropyre (6.88): linie de foc de 1400 (latime 240) timp de 10 s, 100/140/180 daune magice/s. Scepter: 1800 lungime, 30 s, 125/175/225 daune/s.
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_macropyre", "abilities/heroes/dota688_jakiro_macropyre", LUA_MODIFIER_MOTION_NONE)
dota688_jakiro_macropyre = class({})
function dota688_jakiro_macropyre:OnSpellStart()
	local caster = self:GetCaster()
	local scepter = Dota688HasScepter(caster)
	local len = scepter and self:GetSpecialValueFor("cast_range_scepter") or self:GetSpecialValueFor("cast_range")
	local dur = scepter and self:GetSpecialValueFor("duration_scepter") or self:GetSpecialValueFor("duration")
	local dir = self:GetCursorPosition() - caster:GetAbsOrigin(); dir.z = 0
	if dir:Length2D() < 1 then dir = caster:GetForwardVector() end
	dir = dir:Normalized()
	local start = caster:GetAbsOrigin()
	caster:EmitSound("Hero_Jakiro.Macropyre")
	CreateModifierThinker(caster, self, "modifier_dota688_macropyre", { duration = dur, dx = dir.x, dy = dir.y, len = len }, start, caster:GetTeamNumber(), false)
end
modifier_dota688_macropyre = class({})
function modifier_dota688_macropyre:IsHidden() return true end
function modifier_dota688_macropyre:OnCreated(kv)
	if not IsServer() then return end
	local a = self:GetAbility()
	self.start = self:GetParent():GetAbsOrigin()
	self.dir = Vector(kv.dx, kv.dy, 0)
	self.len = kv.len
	self.finish = self.start + self.dir * self.len
	self.dmg = Dota688HasScepter(self:GetCaster()) and a:GetSpecialValueFor("damage_scepter") or a:GetSpecialValueFor("damage")
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_jakiro/jakiro_macropyre.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.fx, 0, self.start)
	ParticleManager:SetParticleControl(self.fx, 1, self.finish)
	ParticleManager:SetParticleControl(self.fx, 2, Vector(self:GetDuration(), 0, 0))
	ParticleManager:SetParticleControl(self.fx, 3, self.start)
	self.interval = a:GetSpecialValueFor("burn_interval")
	self:StartIntervalThink(self.interval)
end
function modifier_dota688_macropyre:OnIntervalThink()
	local a, caster = self:GetAbility(), self:GetCaster()
	if not a or a:IsNull() or not caster or caster:IsNull() then self:Destroy(); return end   -- abilitatea/caster-ul au disparut (Rubick, iluzie moarta)
	for _, e in ipairs(FindUnitsInLine(caster:GetTeamNumber(), self.start, self.finish, nil, a:GetSpecialValueFor("path_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE)) do
		ApplyDamage({ victim = e, attacker = caster, damage = self.dmg * self.interval, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
	end
end
function modifier_dota688_macropyre:OnDestroy() if IsServer() then ParticleManager:DestroyParticle(self.fx, false); UTIL_Remove(self:GetParent()) end end
