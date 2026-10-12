-- Utilitare comune pentru minele Techies 6.88 (unitati invizibile create din KV-ul 6.88, logica in Lua).
require("dota688/val")
Dota688Techies = Dota688Techies or {}

-- creeaza o mina/capcana: unitate invizibila, fara abilitati, controlata de Techies
function Dota688Techies.Spawn(unitName, caster, ability, pos, modifierName, duration)
	local u = CreateUnitByName(unitName, pos, false, caster, caster:GetPlayerOwner(), caster:GetTeamNumber())
	if not u then return nil end
	u:SetOwner(caster)
	u:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
	u:AddNewModifier(caster, ability, modifierName, { duration = duration })
	return u
end

-- types / flags: tipurile si flag-urile cautarii (implicit eroi + unitati de baza, fara imunitate la vraji)
function Dota688Techies.Explode(mine, caster, ability, damage, damageType, radius, particle, sound, extra, types, flags)
	local pos = mine:GetAbsOrigin()
	if particle then
		local fx = ParticleManager:CreateParticle(particle, PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(fx, 0, pos); ParticleManager:SetParticleControl(fx, 1, Vector(radius, radius, radius))
		ParticleManager:ReleaseParticleIndex(fx)
	end
	if sound then EmitSoundOnLocationWithCaster(pos, sound, caster) end
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
		types or (DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC), flags or DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		local dmg = damage
		if extra then dmg = extra(e, dmg) end
		if dmg and dmg > 0 then ApplyDamage({ victim = e, attacker = caster, damage = dmg, damage_type = damageType, ability = ability }) end
	end
end

-- modifier de baza pentru mine: invizibil dupa fade_time, nu poate fi tintit, nu se misca
function Dota688Techies.MineModifier(fadeTimeKey)
	local m = class({})
	function m:IsHidden() return true end
	function m:IsPurgable() return false end
	function m:OnCreated()
		self.start = GameRules:GetGameTime()
		if IsServer() then
			local p = self:GetParent()
			for i = 0, 15 do local ab = p:GetAbilityByIndex(i); if ab then ab:SetActivated(false) end end
			self:StartIntervalThink(0.1)
		end
	end
	function m:Faded() return GameRules:GetGameTime() - (self.start or 0) >= Dota688Val(self, fadeTimeKey or "fade_time") end
	function m:CheckState()
		return { [MODIFIER_STATE_INVISIBLE] = self:Faded(), [MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true, [MODIFIER_STATE_NO_HEALTH_BAR] = true, [MODIFIER_STATE_MAGIC_IMMUNE] = true }
	end
	function m:DeclareFunctions() return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL } end
	function m:GetModifierInvisibilityLevel() return self:Faded() and 1 or 0 end
	function m:OnDestroy()
		if IsServer() and self:GetParent():IsAlive() and self:GetRemainingTime() <= 0.05 then self:GetParent():ForceKill(false) end
	end
	return m
end
