-- Ice Blast (6.88): lanseaza un trasor (1500) spre punct; a doua activare (Release) marcheaza locul exploziei. Bulgarele de gheata pleaca apoi de la AA spre
-- locul marcat (raza de atingere 275) si explodeaza cu raza 275 + 50 la fiecare 100 unitati parcurse de trasor (max 1000): 250/350/450 daune magice.
-- Inamicii atinsi sau prinsi in explozie sunt Frostbitten 8/9/10 s: 12.5/20/32 daune/s, fara vindecare/regenerare, mor sub 10/11/12% HP.
-- Scepter: Frostbite 17 s.
require("dota688/aghanim")
local F = "abilities/heroes/dota688_ancient_apparition_ice_blast"
LinkLuaModifier("modifier_dota688_ice_blast_tracer", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_ice_blast_ball", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_frostbite", F, LUA_MODIFIER_MOTION_NONE)
dota688_ancient_apparition_ice_blast = class({})
function dota688_ancient_apparition_ice_blast:GetCastRange(location, target) return 99999 end
function dota688_ancient_apparition_ice_blast:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	local dir = target - caster:GetAbsOrigin(); dir.z = 0
	if dir:Length2D() < 1 then dir = caster:GetForwardVector() end
	caster:EmitSound("Hero_Ancient_Apparition.IceBlast.Cast")
	self.tracer = CreateModifierThinker(caster, self, "modifier_dota688_ice_blast_tracer", { duration = 8, dx = dir.x, dy = dir.y, dist = dir:Length2D() }, caster:GetAbsOrigin(), caster:GetTeamNumber(), false)
	local release = caster:FindAbilityByName("dota688_ancient_apparition_ice_blast_release")
	if release then self:SetHidden(true); release:SetHidden(false); release:SetLevel(1) end
end
function dota688_ancient_apparition_ice_blast:Release()
	local caster = self:GetCaster()
	local release = caster:FindAbilityByName("dota688_ancient_apparition_ice_blast_release")
	if release then release:SetHidden(true); self:SetHidden(false) end
	if not self.tracer or self.tracer:IsNull() then return end
	local m = self.tracer:FindModifierByName("modifier_dota688_ice_blast_tracer")
	if not m then return end
	local mark, travelled = m.pos, m.travelled
	m:Destroy()
	local radius = math.min(self:GetSpecialValueFor("radius_max"), self:GetSpecialValueFor("radius_min") + self:GetSpecialValueFor("radius_grow") * travelled / 100)
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_marker.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fx, 0, mark); ParticleManager:SetParticleControl(fx, 1, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(fx)
	CreateModifierThinker(caster, self, "modifier_dota688_ice_blast_ball", { duration = 30, tx = mark.x, ty = mark.y, radius = radius }, caster:GetAbsOrigin(), caster:GetTeamNumber(), false)
end
function dota688_ancient_apparition_ice_blast:Frostbite(unit)
	if unit:IsMagicImmune() then return end
	local dur = Dota688HasScepter(self:GetCaster()) and self:GetSpecialValueFor("frostbite_duration_scepter") or self:GetSpecialValueFor("frostbite_duration")
	unit:AddNewModifier(self:GetCaster(), self, "modifier_dota688_frostbite", { duration = dur })
end
-- trasorul
modifier_dota688_ice_blast_tracer = class({})
function modifier_dota688_ice_blast_tracer:IsHidden() return true end
function modifier_dota688_ice_blast_tracer:OnCreated(kv)
	if not IsServer() then return end
	self.dir = Vector(kv.dx, kv.dy, 0):Normalized()
	self.pos = self:GetParent():GetAbsOrigin()
	self.travelled = 0
	self.maxDist = kv.dist
	self.speed = self:GetAbility():GetSpecialValueFor("speed")
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_initial.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.fx, 0, self.pos)
	self:StartIntervalThink(0.03)
end
function modifier_dota688_ice_blast_tracer:OnIntervalThink()
	local step = self.speed * 0.03
	self.pos = self.pos + self.dir * step
	self.travelled = self.travelled + step
	ParticleManager:SetParticleControl(self.fx, 0, self.pos)
	if self.travelled >= self.maxDist then self:GetAbility():Release() end
end
function modifier_dota688_ice_blast_tracer:OnDestroy()
	if IsServer() then ParticleManager:DestroyParticle(self.fx, false); UTIL_Remove(self:GetParent()) end
end
-- bulgarele
modifier_dota688_ice_blast_ball = class({})
function modifier_dota688_ice_blast_ball:IsHidden() return true end
function modifier_dota688_ice_blast_ball:OnCreated(kv)
	if not IsServer() then return end
	self.pos = self:GetParent():GetAbsOrigin()
	self.target = Vector(kv.tx, kv.ty, self.pos.z)
	self.radius = kv.radius
	self.speed = self:GetAbility():GetSpecialValueFor("speed")
	self.hit = {}
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_main.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.fx, 0, self.pos)
	self:StartIntervalThink(0.03)
end
function modifier_dota688_ice_blast_ball:OnIntervalThink()
	local a, caster = self:GetAbility(), self:GetCaster()
	local to = self.target - self.pos; to.z = 0
	local step = self.speed * 0.03
	if to:Length2D() <= step then
		self.pos = self.target
		EmitSoundOnLocationWithCaster(self.pos, "Hero_Ancient_Apparition.IceBlastRelease.Target", caster)
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_final.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(fx, 0, self.pos); ParticleManager:SetParticleControl(fx, 1, Vector(self.radius, 0, 0))
		ParticleManager:ReleaseParticleIndex(fx)
		for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), self.pos, nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
			ApplyDamage({ victim = e, attacker = caster, damage = a:GetAbilityDamage(), damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
			a:Frostbite(e)
		end
		self:Destroy()
		return
	end
	self.pos = self.pos + to:Normalized() * step
	ParticleManager:SetParticleControl(self.fx, 0, self.pos)
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), self.pos, nil, a:GetSpecialValueFor("path_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if not self.hit[e:entindex()] then self.hit[e:entindex()] = true; a:Frostbite(e) end
	end
end
function modifier_dota688_ice_blast_ball:OnDestroy()
	if IsServer() then ParticleManager:DestroyParticle(self.fx, false); UTIL_Remove(self:GetParent()) end
end
-- Frostbite
modifier_dota688_frostbite = class({})
function modifier_dota688_frostbite:IsDebuff() return true end
function modifier_dota688_frostbite:IsPurgable() return false end
function modifier_dota688_frostbite:GetTexture() return "ancient_apparition_ice_blast" end
function modifier_dota688_frostbite:GetEffectName() return "particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_debuff.vpcf" end
function modifier_dota688_frostbite:OnCreated()
	if not IsServer() then return end
	self.acc = 0
	self:StartIntervalThink(0.1)
end
function modifier_dota688_frostbite:OnIntervalThink()
	local p, a, caster = self:GetParent(), self:GetAbility(), self:GetCaster()
	if p:GetHealth() / p:GetMaxHealth() * 100 < a:GetSpecialValueFor("kill_pct") and not p:IsInvulnerable() then
		local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_ancient_apparition/ancient_apparition_ice_blast_death.vpcf", PATTACH_ABSORIGIN, p)
		ParticleManager:ReleaseParticleIndex(fx)
		p:Kill(a, caster)
		return
	end
	self.acc = self.acc + 0.1
	if self.acc >= 1 then
		self.acc = self.acc - 1
		ApplyDamage({ victim = p, attacker = caster, damage = a:GetSpecialValueFor("dot_damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
	end
end
function modifier_dota688_frostbite:DeclareFunctions() return { MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_TARGET, MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE, MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE } end
function modifier_dota688_frostbite:GetModifierHealAmplify_PercentageTarget() return -100 end
function modifier_dota688_frostbite:GetModifierHPRegenAmplify_Percentage() return -100 end
function modifier_dota688_frostbite:GetModifierLifestealRegenAmplify_Percentage() return -100 end
