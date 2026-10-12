-- Dream Coil (6.88): leaga eroii inamici din 375 timp de 6 s (100/150/200 daune magice + stun 0.5 la inceput);
-- daca se departeaza peste 600, legatura se rupe: stun 1.5/2.25/3 s + 100/150/200 daune.
-- Scepter: 8 s, ruperea face 200/250/300 daune si stun 1.5/3/4.5 s care trece prin imunitatea la magie.
require("dota688/aghanim")
require("dota688/stun")
local F = "abilities/heroes/dota688_puck_dream_coil"
LinkLuaModifier("modifier_dota688_dream_coil_thinker", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_dream_coil", F, LUA_MODIFIER_MOTION_NONE)
dota688_puck_dream_coil = class({})
function dota688_puck_dream_coil:GetAOERadius() return self:GetSpecialValueFor("coil_radius") end
function dota688_puck_dream_coil:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	local scepter = Dota688HasScepter(caster)
	local dur = scepter and self:GetSpecialValueFor("coil_duration_scepter") or self:GetSpecialValueFor("coil_duration")
	caster:EmitSound("Hero_Puck.Dream_Coil")
	CreateModifierThinker(caster, self, "modifier_dota688_dream_coil_thinker", { duration = dur, scepter = scepter and 1 or 0 }, pos, caster:GetTeamNumber(), false)
end
modifier_dota688_dream_coil_thinker = class({})
function modifier_dota688_dream_coil_thinker:IsHidden() return true end
function modifier_dota688_dream_coil_thinker:OnCreated(kv)
	if not IsServer() then return end
	local a, caster, pos = self:GetAbility(), self:GetCaster(), self:GetParent():GetAbsOrigin()
	self.scepter = kv.scepter == 1
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_dreamcoil.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:SetParticleControl(self.fx, 0, pos)
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, a:GetSpecialValueFor("coil_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if not e:IsMagicImmune() then
			ApplyDamage({ victim = e, attacker = caster, damage = a:GetSpecialValueFor("coil_init_damage_tooltip"), damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
			Dota688Stun(e, caster, a, a:GetSpecialValueFor("stun_duration"))
			e:AddNewModifier(caster, a, "modifier_dota688_dream_coil", { duration = self:GetDuration(), x = pos.x, y = pos.y, scepter = kv.scepter })
		end
	end
end
function modifier_dota688_dream_coil_thinker:OnDestroy() if IsServer() then ParticleManager:DestroyParticle(self.fx, false); UTIL_Remove(self:GetParent()) end end
modifier_dota688_dream_coil = class({})
function modifier_dota688_dream_coil:IsDebuff() return true end
function modifier_dota688_dream_coil:IsPurgable() return false end
function modifier_dota688_dream_coil:GetTexture() return "puck_dream_coil" end
function modifier_dota688_dream_coil:OnCreated(kv)
	if not IsServer() then return end
	self.center = Vector(kv.x, kv.y, self:GetParent():GetAbsOrigin().z)
	self.scepter = kv.scepter == 1
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_dreamcoil_tether.vpcf", PATTACH_CUSTOMORIGIN, self:GetParent())
	ParticleManager:SetParticleControl(self.fx, 0, self.center)
	ParticleManager:SetParticleControlEnt(self.fx, 1, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
	self:StartIntervalThink(0.1)
end
function modifier_dota688_dream_coil:OnIntervalThink()
	local p, a, caster = self:GetParent(), self:GetAbility(), self:GetCaster()
	if (p:GetAbsOrigin() - self.center):Length2D() > a:GetSpecialValueFor("coil_break_radius") then
		if self.scepter or not p:IsMagicImmune() then
			local dmg = self.scepter and a:GetSpecialValueFor("coil_break_damage_scepter") or a:GetSpecialValueFor("coil_break_damage")
			local stun = self.scepter and a:GetSpecialValueFor("coil_stun_duration_scepter") or a:GetSpecialValueFor("coil_stun_duration")
			p:EmitSound("Hero_Puck.Dream_Coil_Snap")
			ApplyDamage({ victim = p, attacker = caster, damage = dmg, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
			Dota688Stun(p, caster, a, stun)
		end
		self:Destroy()
	end
end
function modifier_dota688_dream_coil:OnDestroy() if IsServer() then ParticleManager:DestroyParticle(self.fx, false) end end
