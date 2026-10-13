-- Whirling Death (6.88): 100/150/200/250 daune magice inamicilor din 300 si distruge copacii din raza; daca a taiat cel putin
-- un copac, daunele sunt pure. Eroii loviti pierd 15% din atributul principal pentru 14 s (fiecare lansare separat).
-- Abilitatea curenta da daune in plus per copac (dezactivate din valori), deci conversia in daune pure lipsea.
local F = "abilities/heroes/dota688_shredder_whirling_death"
LinkLuaModifier("modifier_dota688_whirling_death_debuff", F, LUA_MODIFIER_MOTION_NONE)

dota688_shredder_whirling_death = class({})
function dota688_shredder_whirling_death:OnSpellStart()
	local caster = self:GetCaster()
	local pos = caster:GetAbsOrigin()
	local radius = self:GetSpecialValueFor("whirling_radius")
	local trees = GridNav:GetAllTreesAroundPoint(pos, radius, false) or {}
	local cut = false
	for _, t in ipairs(trees) do
		if t.IsStanding == nil or t:IsStanding() then cut = true; break end
	end
	GridNav:DestroyTreesAroundPoint(pos, radius, false)
	caster:EmitSound("Hero_Shredder.WhirlingDeath.Cast")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_shredder/shredder_whirling_death.vpcf", PATTACH_CENTER_FOLLOW, caster)
	ParticleManager:SetParticleControl(fx, 1, Vector(radius, radius, radius))
	ParticleManager:ReleaseParticleIndex(fx)
	local dmgType = cut and DAMAGE_TYPE_PURE or DAMAGE_TYPE_MAGICAL
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		ApplyDamage({ victim = e, attacker = caster, damage = self:GetSpecialValueFor("whirling_damage"), damage_type = dmgType, ability = self })
		e:EmitSound("Hero_Shredder.WhirlingDeath.Damage")
		if e:IsRealHero() and e:IsAlive() then
			e:AddNewModifier(caster, self, "modifier_dota688_whirling_death_debuff", { duration = self:GetSpecialValueFor("duration") })
		end
	end
end

-- -15% din atributul principal (calculat la aplicare), instante separate
modifier_dota688_whirling_death_debuff = class({})
function modifier_dota688_whirling_death_debuff:IsDebuff() return true end
function modifier_dota688_whirling_death_debuff:IsPurgable() return true end
function modifier_dota688_whirling_death_debuff:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_dota688_whirling_death_debuff:GetEffectName() return "particles/units/heroes/hero_shredder/shredder_whirling_death_debuff.vpcf" end
function modifier_dota688_whirling_death_debuff:OnCreated()
	if not IsServer() then return end
	local p, a = self:GetParent(), self:GetAbility()
	local attr = p:GetPrimaryAttribute()
	local cur = (attr == DOTA_ATTRIBUTE_STRENGTH and p:GetStrength()) or (attr == DOTA_ATTRIBUTE_AGILITY and p:GetAgility()) or p:GetIntellect(false)
	-- stack count = atributul (0/1/2) * 10000 + valoarea pierduta (ajunge si la client)
	self:SetStackCount(attr * 10000 + math.floor(cur * a:GetSpecialValueFor("stat_loss_pct") / 100))
	p:CalculateStatBonus(true)
end
function modifier_dota688_whirling_death_debuff:OnDestroy()
	if IsServer() then self:GetParent():CalculateStatBonus(true) end
end
function modifier_dota688_whirling_death_debuff:Loss(attr)
	local v = self:GetStackCount()
	if math.floor(v / 10000) ~= attr then return 0 end
	return -(v % 10000)
end
function modifier_dota688_whirling_death_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, MODIFIER_PROPERTY_STATS_AGILITY_BONUS, MODIFIER_PROPERTY_STATS_INTELLECT_BONUS }
end
function modifier_dota688_whirling_death_debuff:GetModifierBonusStats_Strength() return self:Loss(DOTA_ATTRIBUTE_STRENGTH) end
function modifier_dota688_whirling_death_debuff:GetModifierBonusStats_Agility() return self:Loss(DOTA_ATTRIBUTE_AGILITY) end
function modifier_dota688_whirling_death_debuff:GetModifierBonusStats_Intellect() return self:Loss(DOTA_ATTRIBUTE_INTELLECT) end
