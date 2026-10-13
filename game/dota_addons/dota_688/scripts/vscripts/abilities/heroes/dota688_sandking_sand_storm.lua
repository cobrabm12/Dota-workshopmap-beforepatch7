-- Sand Storm (6.88): canalizare de pana la 50 s; furtuna (raza 525, in locul unde a fost lansata) da 25/50/75/100 daune magice
-- pe secunda inamicilor, iar Sand King este invizibil cat canalizeaza. Invizibilitatea mai ramane 1.5 s dupa ce furtuna se
-- termina (dispare daca ataca sau foloseste o abilitate). Fara furtuna moderna necanalizata / care il urmeaza.
local F = "abilities/heroes/dota688_sandking_sand_storm"
LinkLuaModifier("modifier_dota688_sandking_sand_storm", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_sandking_sand_storm_invis", F, LUA_MODIFIER_MOTION_NONE)
local TICK = 0.5

dota688_sandking_sand_storm = class({})
function dota688_sandking_sand_storm:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Ability.SandKing_SandStorm.start")
	caster:RemoveModifierByName("modifier_dota688_sandking_sand_storm_invis")
	if self.mod and not self.mod:IsNull() then self.mod:Destroy() end
	self.mod = caster:AddNewModifier(caster, self, "modifier_dota688_sandking_sand_storm", { duration = self:GetChannelTime() })
end
function dota688_sandking_sand_storm:OnChannelFinish(interrupted)
	local caster = self:GetCaster()
	if self.mod and not self.mod:IsNull() then self.mod:Destroy() end
	self.mod = nil
	if caster:IsAlive() then
		caster:AddNewModifier(caster, self, "modifier_dota688_sandking_sand_storm_invis", { duration = self:GetSpecialValueFor("sand_storm_invis_delay") })
	end
end

-- furtuna + invizibilitatea din timpul canalizarii (pe Sand King)
modifier_dota688_sandking_sand_storm = class({})
function modifier_dota688_sandking_sand_storm:IsPurgable() return false end
function modifier_dota688_sandking_sand_storm:OnCreated()
	self.dps = 0
	if not IsServer() then return end
	local a, p = self:GetAbility(), self:GetParent()
	self.center = p:GetAbsOrigin()
	self.radius = a:GetSpecialValueFor("sand_storm_radius")
	self.dps = a:GetAbilityDamage()
	self:SetHasCustomTransmitterData(true)
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_sandking/sandking_sandstorm.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.fx, 0, self.center)
	ParticleManager:SetParticleControl(self.fx, 1, Vector(self.radius, self.radius, 0))
	p:EmitSound("Ability.SandKing_SandStorm.loop")
	self:StartIntervalThink(TICK)
end
function modifier_dota688_sandking_sand_storm:AddCustomTransmitterData() return { dps = self.dps } end
function modifier_dota688_sandking_sand_storm:HandleCustomTransmitterData(data) self.dps = data.dps or 0 end
function modifier_dota688_sandking_sand_storm:OnIntervalThink()
	local a, p = self:GetAbility(), self:GetParent()
	if not a or a:IsNull() then self:Destroy(); return end
	for _, e in ipairs(FindUnitsInRadius(p:GetTeamNumber(), self.center, nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if not e:IsMagicImmune() then
			ApplyDamage({ victim = e, attacker = p, damage = self.dps * TICK, damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
		end
	end
end
function modifier_dota688_sandking_sand_storm:OnDestroy()
	if not IsServer() then return end
	self:GetParent():StopSound("Ability.SandKing_SandStorm.loop")
	if self.fx then
		ParticleManager:DestroyParticle(self.fx, false)
		ParticleManager:ReleaseParticleIndex(self.fx)
		self.fx = nil
	end
end
function modifier_dota688_sandking_sand_storm:CheckState() return { [MODIFIER_STATE_INVISIBLE] = true } end
function modifier_dota688_sandking_sand_storm:DeclareFunctions() return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL, MODIFIER_PROPERTY_TOOLTIP } end
function modifier_dota688_sandking_sand_storm:GetModifierInvisibilityLevel() return 1 end
function modifier_dota688_sandking_sand_storm:OnTooltip() return self.dps or 0 end

-- invizibilitatea ramasa dupa furtuna: se rupe la atac sau la folosirea unei abilitati/item
modifier_dota688_sandking_sand_storm_invis = class({})
function modifier_dota688_sandking_sand_storm_invis:IsPurgable() return false end
function modifier_dota688_sandking_sand_storm_invis:CheckState() return { [MODIFIER_STATE_INVISIBLE] = true } end
function modifier_dota688_sandking_sand_storm_invis:DeclareFunctions()
	return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL, MODIFIER_EVENT_ON_ATTACK, MODIFIER_EVENT_ON_ABILITY_EXECUTED }
end
function modifier_dota688_sandking_sand_storm_invis:GetModifierInvisibilityLevel() return 1 end
function modifier_dota688_sandking_sand_storm_invis:OnAttack(params)
	if IsServer() and params.attacker == self:GetParent() then self:Destroy() end
end
function modifier_dota688_sandking_sand_storm_invis:OnAbilityExecuted(params)
	if IsServer() and params.unit == self:GetParent() then self:Destroy() end
end
