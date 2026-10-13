-- Spin Web (6.88): panza de raza 900 care nu expira (max 2/4/6/8; la depasire dispare cea mai veche); 1/2/3/4 incarcaturi,
-- fiecare se reface in 40 s. Se poate arunca de oriunde daca noua panza atinge una existenta (altfel raza 1000).
-- In panza, Broodmother si paianjenii ei (Spiderlings/Spiderites) au miscare libera (peste copaci/stanci), +40/50/60/70%
-- viteza de miscare si +2/4/6/8 HP/s regen. Daca iau daune: 6 s fara miscare libera si bonusul de viteza injumatatit
-- (20/25/30/35%); copacii din jur sunt distrusi. Broodmother devine invizibila dupa 2 s in panza fara sa atace.
-- Panza e o unitate (npc_dota688_broodmother_web) cu abilitatea Destroy Spin Web (dota688_broodmother_spin_web_destroy).
require("dota688/val")
local F = "abilities/heroes/dota688_broodmother_spin_web"
LinkLuaModifier("modifier_dota688_spin_web_charges", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_spin_web_thinker", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_spin_web_aura", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_spin_web", F, LUA_MODIFIER_MOTION_NONE)
dota688_broodmother_spin_web = class({})

local WEB_PARTICLE = "particles/units/heroes/hero_broodmother/broodmother_web.vpcf"

local function webs_of(caster)
	caster.dota688_webs = caster.dota688_webs or {}
	local list = {}
	for _, w in ipairs(caster.dota688_webs) do
		if w and not w:IsNull() and w:HasModifier("modifier_dota688_spin_web_thinker") then table.insert(list, w) end
	end
	caster.dota688_webs = list
	return list
end

function dota688_broodmother_spin_web:GetIntrinsicModifierName() return "modifier_dota688_spin_web_charges" end
function dota688_broodmother_spin_web:GetAOERadius() return self:GetSpecialValueFor("radius") end
-- de oriunde, daca noua panza atinge o panza existenta (distanta intre centre <= 2 x raza)
function dota688_broodmother_spin_web:GetCastRange(location, target)
	local base = self.BaseClass.GetCastRange(self, location, target)
	if IsServer() and location then
		local r = self:GetSpecialValueFor("radius")
		for _, w in ipairs(webs_of(self:GetCaster())) do
			if (w:GetAbsOrigin() - location):Length2D() <= 2 * r then return 99999 end
		end
	end
	return base
end
function dota688_broodmother_spin_web:OnAbilityPhaseStart()
	if not IsServer() then return true end
	local m = self:GetCaster():FindModifierByName("modifier_dota688_spin_web_charges")
	return not m or m:GetStackCount() > 0
end
function dota688_broodmother_spin_web:OnUpgrade()
	local m = self:GetCaster():FindModifierByName("modifier_dota688_spin_web_charges")
	if m then m:OnLevelUp() end
end
function dota688_broodmother_spin_web:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	caster:EmitSound("Hero_Broodmother.SpinWebCast")
	local web = CreateUnitByName("npc_dota688_broodmother_web", pos, false, caster, caster, caster:GetTeamNumber())
	if web then
		web:SetOwner(caster)
		web:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
		web:SetAbsOrigin(pos)
		local d = web:FindAbilityByName("dota688_broodmother_spin_web_destroy") or web:AddAbility("dota688_broodmother_spin_web_destroy")
		if d then d:SetLevel(1) end
		web:AddNewModifier(caster, self, "modifier_dota688_spin_web_thinker", { unit = 1 })
	else
		-- unitatea panzei lipseste din KV: panza functioneaza, dar nu poate fi distrusa manual
		web = CreateModifierThinker(caster, self, "modifier_dota688_spin_web_thinker", {}, pos, caster:GetTeamNumber(), false)
	end
	local list = webs_of(caster)
	table.insert(list, web)
	while #list > self:GetSpecialValueFor("count") do
		local old = table.remove(list, 1)
		local m = old:FindModifierByName("modifier_dota688_spin_web_thinker")
		if m then m:Destroy() end
	end
	local charges = caster:FindModifierByName("modifier_dota688_spin_web_charges")
	if charges then charges:Use() end
end

-- incarcaturile (buff vizibil cu numarul lor, ca in 6.88); cronometrul arata refacerea urmatoarei
modifier_dota688_spin_web_charges = class({})
function modifier_dota688_spin_web_charges:IsHidden() return self:GetAbility() == nil or self:GetAbility():GetLevel() < 1 end
function modifier_dota688_spin_web_charges:IsPurgable() return false end
function modifier_dota688_spin_web_charges:RemoveOnDeath() return false end
function modifier_dota688_spin_web_charges:DestroyOnExpire() return false end
function modifier_dota688_spin_web_charges:GetTexture() return "broodmother_spin_web" end
function modifier_dota688_spin_web_charges:OnCreated()
	if not IsServer() then return end
	self.restoreAt = nil
	self.max = 0
	self:SetStackCount(0)
	self:OnLevelUp()
	self:StartIntervalThink(0.1)
end
function modifier_dota688_spin_web_charges:OnLevelUp()
	if not IsServer() then return end
	local a = self:GetAbility()
	if not a or a:GetLevel() < 1 then return end
	local max = a:GetSpecialValueFor("max_charges")
	-- fiecare nivel nou adauga incarcatura in plus
	if max > (self.max or 0) then
		self:SetStackCount(math.min(max, self:GetStackCount() + (max - (self.max or 0))))
		self.max = max
	end
	self:Update()
end
function modifier_dota688_spin_web_charges:Use()
	self:SetStackCount(math.max(0, self:GetStackCount() - 1))
	self:Update()
end
function modifier_dota688_spin_web_charges:Update()
	local a = self:GetAbility()
	if not a or a:IsNull() then return end
	local now = GameRules:GetGameTime()
	local restore = a:GetSpecialValueFor("charge_restore_time")
	if self:GetStackCount() < self.max then
		if not self.restoreAt then
			self.restoreAt = now + restore
			self:SetDuration(restore, true)
		end
	else
		self.restoreAt = nil
		self:SetDuration(-1, true)
	end
	if self:GetStackCount() == 0 and self.restoreAt then
		a:EndCooldown()
		a:StartCooldown(self.restoreAt - now)
	elseif self:GetStackCount() > 0 and not a:IsCooldownReady() then
		a:EndCooldown()
	end
end
function modifier_dota688_spin_web_charges:OnIntervalThink()
	local now = GameRules:GetGameTime()
	if self.restoreAt and now >= self.restoreAt then
		self.restoreAt = nil
		self:SetStackCount(math.min(self.max, self:GetStackCount() + 1))
		self:Update()
	end
	-- fara incarcaturi: abilitatea sta in cooldown pana la urmatoarea (corectie daca motorul a resetat cooldown-ul)
	local a = self:GetAbility()
	if a and not a:IsNull() and self:GetStackCount() == 0 and self.restoreAt and a:IsCooldownReady() then
		a:StartCooldown(self.restoreAt - now)
	end
end

-- pe unitatea panzei: aura + particula
modifier_dota688_spin_web_thinker = class({})
function modifier_dota688_spin_web_thinker:IsHidden() return true end
function modifier_dota688_spin_web_thinker:IsPurgable() return false end
function modifier_dota688_spin_web_thinker:OnCreated(kv)
	if not IsServer() then return end
	self.isUnit = (kv.unit or 0) == 1
	local r = Dota688Val(self, "radius")
	self.fx = ParticleManager:CreateParticle(WEB_PARTICLE, PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.fx, 0, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(self.fx, 1, Vector(r, r, r))
end
function modifier_dota688_spin_web_thinker:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.fx, false)
	ParticleManager:ReleaseParticleIndex(self.fx)
	local p = self:GetParent()
	local caster = self:GetCaster()
	if caster and not caster:IsNull() and caster.dota688_webs then
		for i, w in ipairs(caster.dota688_webs) do
			if w == p then table.remove(caster.dota688_webs, i) break end
		end
	end
	if not self.isUnit then
		UTIL_Remove(p)
	elseif p:IsAlive() then
		-- unitatea panzei (poate fi chiar cea care foloseste Destroy Spin Web): omorata, apoi scoasa din joc
		p:ForceKill(false)
		if Dota688Timers then Dota688Timers:After(1, function() if not p:IsNull() then UTIL_Remove(p) end end) end
	end
end
function modifier_dota688_spin_web_thinker:CheckState()
	return { [MODIFIER_STATE_INVULNERABLE] = true, [MODIFIER_STATE_NO_HEALTH_BAR] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_NOT_ON_MINIMAP] = true, [MODIFIER_STATE_MAGIC_IMMUNE] = true, [MODIFIER_STATE_ATTACK_IMMUNE] = true,
		[MODIFIER_STATE_DISARMED] = true, [MODIFIER_STATE_ROOTED] = true }
end
function modifier_dota688_spin_web_thinker:IsAura() return true end
function modifier_dota688_spin_web_thinker:GetAuraRadius() return Dota688Val(self, "radius") end
function modifier_dota688_spin_web_thinker:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_spin_web_thinker:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC end
function modifier_dota688_spin_web_thinker:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_dota688_spin_web_thinker:GetModifierAura() return "modifier_dota688_spin_web_aura" end
function modifier_dota688_spin_web_thinker:GetAuraEntityReject(unit)
	-- doar Broodmother (si iluziile ei) si paianjenii jucatorului ei
	local caster = self:GetCaster()
	if not caster or caster:IsNull() or unit:GetPlayerOwnerID() ~= caster:GetPlayerOwnerID() then return true end
	local name = unit:GetUnitName()
	if name == caster:GetUnitName() then return false end
	return string.find(name, "npc_dota_broodmother_spider", 1, true) ~= 1
end

-- marcaj de aura (poate fi de mai multe ori pe unitate, cate unul de la fiecare panza); efectul e un singur buff
modifier_dota688_spin_web_aura = class({})
function modifier_dota688_spin_web_aura:IsHidden() return true end
function modifier_dota688_spin_web_aura:IsPurgable() return false end
function modifier_dota688_spin_web_aura:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_dota688_spin_web_aura:OnCreated()
	if not IsServer() then return end
	local p = self:GetParent()
	if not p:HasModifier("modifier_dota688_spin_web") then
		p:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_dota688_spin_web", {})
	end
end

-- efectul panzei: bit 1 = a luat daune recent, bit 2 = invizibil
modifier_dota688_spin_web = class({})
function modifier_dota688_spin_web:IsPurgable() return false end
function modifier_dota688_spin_web:GetTexture() return "broodmother_spin_web" end
function modifier_dota688_spin_web:OnCreated()
	self.ms = Dota688Val(self, "invis_movespeed_tooltip")
	self.msHurt = Dota688Val(self, "bonus_movespeed")
	self.regen = Dota688Val(self, "heath_regen")
	if not IsServer() then return end
	self.fade = Dota688Val(self, "fade_delay")
	self.hurtTime = Dota688Val(self, "damage_time")
	self.hurtUntil = 0
	self.lastAttack = GameRules:GetGameTime()
	self:SetStackCount(0)
	self:StartIntervalThink(0.1)
end
function modifier_dota688_spin_web:Hurt() return bit.band(self:GetStackCount(), 1) ~= 0 end
function modifier_dota688_spin_web:Invisible() return bit.band(self:GetStackCount(), 2) ~= 0 end
function modifier_dota688_spin_web:UpdateState()
	local p = self:GetParent()
	local now = GameRules:GetGameTime()
	local hurt = now < self.hurtUntil
	local invis = p:IsHero() and now - self.lastAttack >= self.fade
	if hurt and not self:Hurt() then
		-- fara miscare libera: copacii de sub unitate sunt distrusi
		GridNav:DestroyTreesAroundPoint(p:GetAbsOrigin(), 150, false)
	end
	self:SetStackCount((hurt and 1 or 0) + (invis and 2 or 0))
end
function modifier_dota688_spin_web:OnIntervalThink()
	if not self:GetParent():HasModifier("modifier_dota688_spin_web_aura") then
		self:Destroy()
		return
	end
	self:UpdateState()
end
function modifier_dota688_spin_web:OnDestroy()
	if not IsServer() then return end
	if not self:Hurt() then GridNav:DestroyTreesAroundPoint(self:GetParent():GetAbsOrigin(), 150, false) end
end
function modifier_dota688_spin_web:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
		MODIFIER_EVENT_ON_ATTACK, MODIFIER_EVENT_ON_TAKEDAMAGE }
end
function modifier_dota688_spin_web:GetModifierMoveSpeedBonus_Percentage() if self:Hurt() then return self.msHurt end return self.ms end
function modifier_dota688_spin_web:GetModifierConstantHealthRegen() return self.regen end
function modifier_dota688_spin_web:GetModifierInvisibilityLevel() return self:Invisible() and 1 or 0 end
function modifier_dota688_spin_web:CheckState()
	-- doar starile active (un "false" ar anula invizibilitatea din alte surse)
	local s = {}
	if not self:Hurt() then s[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true end
	if self:Invisible() then s[MODIFIER_STATE_INVISIBLE] = true end
	return s
end
function modifier_dota688_spin_web:OnAttack(params)
	if not IsServer() or params.attacker ~= self:GetParent() then return end
	self.lastAttack = GameRules:GetGameTime()
	self:UpdateState()
end
function modifier_dota688_spin_web:OnTakeDamage(params)
	if not IsServer() or params.unit ~= self:GetParent() or params.damage <= 0 then return end
	if params.attacker and params.attacker:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
	self.hurtUntil = GameRules:GetGameTime() + self.hurtTime
	self:UpdateState()
end
