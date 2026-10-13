-- Summon Spirit Bear (6.88): invoca ursul de nivelul abilitatii (npc_dota_lone_druid_bear1..4: 1400/1800/2300/2700 HP, armura 3-6,
-- BAT 1.75-1.45, regen 2-5; nivel 2: Return, nivel 3: + Entangling Claws, nivel 4: + Demolish; Savage Roar la nivelul celui al lui LD).
-- Reinvocarea il aduce langa Lone Druid cu viata plina (cu itemele; un nivel nou al abilitatii se aplica abia la reinvocare);
-- nu se poate reinvoca daca ursul a primit daune de la o unitate a unui jucator in ultimele 3 s. Ursul nu ataca la peste 1100 de LD
-- si moare odata cu el; cand ursul moare, LD pierde 10% din viata maxima (daune pure). Ursul mort isi pastreaza itemele.
-- Scepter: ursul ataca la orice distanta si nu moare odata cu Lone Druid.
-- (Varianta moderna: abilitate innata, ursul creste cu nivelul eroului, Return canalizat etc. - nu exista in 6.88.)
require("dota688/val")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_lone_druid_spirit_bear"
LinkLuaModifier("modifier_dota688_lone_druid_spirit_bear", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_lone_druid_spirit_bear_attack_check", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_lone_druid_spirit_bear_recent_damage", F, LUA_MODIFIER_MOTION_NONE)

local LEASH = 1100          -- tooltip 6.88
local DAMAGE_BLOCK = 3      -- s: reinvocare / Return blocate dupa daune de la unitatile jucatorilor
-- abilitatile ursului (in ordinea sloturilor) si nivelul abilitatii de la care le are
local BEAR_ABILITIES = {
	{ "dota688_lone_druid_spirit_bear_return", 2 },
	{ "dota688_lone_druid_spirit_bear_entangle", 3 },
	{ "lone_druid_savage_roar_bear", 1 },
	{ "dota688_lone_druid_spirit_bear_demolish", 4 },
}

dota688_lone_druid_spirit_bear = class({})
function dota688_lone_druid_spirit_bear:GetIntrinsicModifierName() return "modifier_dota688_lone_druid_spirit_bear" end
function dota688_lone_druid_spirit_bear:CastFilterResult()
	if self:GetCaster():HasModifier("modifier_dota688_lone_druid_spirit_bear_recent_damage") then return UF_FAIL_CUSTOM end
	return UF_SUCCESS
end
function dota688_lone_druid_spirit_bear:GetCustomCastError() return "#dota688_bear_recently_damaged" end

function dota688_lone_druid_spirit_bear:OnSpellStart()
	local caster = self:GetCaster()
	local level = self:GetLevel()
	local old = caster.dota688_bear
	if old and old:IsNull() then old = nil end
	local pos = caster:GetAbsOrigin() + caster:GetForwardVector() * 150
	caster:EmitSound("Hero_LoneDruid.SpiritBear.Cast")
	local bear
	if old and old:IsAlive() and old.dota688_bear_level == level then
		bear = old   -- reinvocare: acelasi urs, langa Lone Druid, cu viata plina
		FindClearSpaceForUnit(bear, pos, true)
		bear:Stop()
		bear:SetHealth(bear:GetMaxHealth())
	else
		bear = CreateUnitByName("npc_dota_lone_druid_bear" .. level, pos, true, caster, caster:GetPlayerOwner(), caster:GetTeamNumber())
		if not bear then return end
		bear.dota688_bear_level = level
		bear.dota688_bear_owner = caster
		bear:SetOwner(caster)
		bear:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
		bear:SetUnitCanRespawn(true)   -- nu e sters la moarte: itemele raman pe el pana la reinvocare
		FindClearSpaceForUnit(bear, pos, true)
		self:SetupBear(bear, level)
		if old then
			-- ursul vechi (mort sau de nivel mai mic) e inlocuit: itemele trec pe cel nou, fara moarte/backlash
			local m = old:FindModifierByName("modifier_dota688_lone_druid_spirit_bear_attack_check")
			if m then m.replaced = true end
			self:TransferItems(old, bear)
			Dota688SafeRemove(old)
		end
		caster.dota688_bear = bear
	end
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/lone_druid_bear_spawn.vpcf", PATTACH_ABSORIGIN_FOLLOW, bear)
	ParticleManager:ReleaseParticleIndex(fx)
end

function dota688_lone_druid_spirit_bear:SetupBear(bear, level)
	-- statisticile 6.88 sunt si in KV-ul unitatii; le punem si din abilitate, in caz ca clasa C++ a ursului le recalculeaza
	local hp = self:GetSpecialValueFor("bear_hp")
	if hp > 0 then
		bear:SetBaseMaxHealth(hp)
		bear:SetMaxHealth(hp)
		bear:SetHealth(hp)
	end
	bear:SetPhysicalArmorBaseValue(self:GetSpecialValueFor("bear_armor"))
	local bat = self:GetSpecialValueFor("bear_bat")
	if bat > 0 then bear:SetBaseAttackTime(bat) end
	bear:SetBaseHealthRegen(self:GetSpecialValueFor("bear_regen_tooltip"))
	-- abilitatile 6.88 ale nivelului; orice alta abilitate (ex. cele moderne ale clasei) se scoate
	local want = {}
	for _, e in ipairs(BEAR_ABILITIES) do if level >= e[2] then want[e[1]] = true end end
	for i = bear:GetAbilityCount() - 1, 0, -1 do
		local a = bear:GetAbilityByIndex(i)
		if a and not want[a:GetAbilityName()] then bear:RemoveAbilityByHandle(a) end
	end
	for _, e in ipairs(BEAR_ABILITIES) do
		if want[e[1]] then
			local a = bear:FindAbilityByName(e[1]) or bear:AddAbility(e[1])
			if a and e[1] ~= "lone_druid_savage_roar_bear" and a:GetLevel() < 1 then a:SetLevel(1) end
		end
	end
	bear:AddNewModifier(self:GetCaster(), self, "modifier_dota688_lone_druid_spirit_bear_attack_check", {})
end

function dota688_lone_druid_spirit_bear:TransferItems(from, to)
	for slot = 0, 8 do
		local item = from:GetItemInSlot(slot)
		if item and not item:IsNull() then
			from:TakeItem(item)
			local added = to:AddItem(item)
			if added and not added:IsNull() then
				local cur = added:GetItemSlot()
				if cur >= 0 and cur ~= slot then to:SwapItems(cur, slot) end
			end
		end
	end
end

------------------------------------------------------------------------------------------------
-- pe Lone Druid: ursul moare odata cu el (fara scepter)
modifier_dota688_lone_druid_spirit_bear = class({})
function modifier_dota688_lone_druid_spirit_bear:IsHidden() return true end
function modifier_dota688_lone_druid_spirit_bear:IsPurgable() return false end
function modifier_dota688_lone_druid_spirit_bear:RemoveOnDeath() return false end
function modifier_dota688_lone_druid_spirit_bear:DeclareFunctions() return { MODIFIER_EVENT_ON_DEATH } end
function modifier_dota688_lone_druid_spirit_bear:OnDeath(params)
	if not IsServer() then return end
	local p = self:GetParent()
	if params.unit ~= p or not p:IsRealHero() or p:IsReincarnating() or Dota688HasScepter(p) then return end
	local bear = p.dota688_bear
	if bear and not bear:IsNull() and bear:IsAlive() then bear:ForceKill(false) end
end

------------------------------------------------------------------------------------------------
-- pe urs (caster = Lone Druid): lesa de 1100 (vizibil cand ursul e prea departe), daunele recente, moartea, Savage Roar / Rabid
modifier_dota688_lone_druid_spirit_bear_attack_check = class({})
function modifier_dota688_lone_druid_spirit_bear_attack_check:IsHidden() return self:GetStackCount() == 0 end
function modifier_dota688_lone_druid_spirit_bear_attack_check:IsDebuff() return true end
function modifier_dota688_lone_druid_spirit_bear_attack_check:IsPurgable() return false end
function modifier_dota688_lone_druid_spirit_bear_attack_check:GetTexture() return "lone_druid_spirit_bear" end
function modifier_dota688_lone_druid_spirit_bear_attack_check:CheckState()
	if self:GetStackCount() == 1 then return { [MODIFIER_STATE_DISARMED] = true } end
	return {}
end
function modifier_dota688_lone_druid_spirit_bear_attack_check:OnCreated()
	if not IsServer() then return end
	self.backlash = Dota688Val(self, "backlash_damage")
	self:StartIntervalThink(0.1)
	self:OnIntervalThink()
end
function modifier_dota688_lone_druid_spirit_bear_attack_check:OnIntervalThink()
	local bear, owner = self:GetParent(), self:GetCaster()
	if not owner or owner:IsNull() then return end
	local scepter = Dota688HasScepter(owner)
	local far = false
	if not scepter then
		far = not owner:IsAlive() or (bear:GetAbsOrigin() - owner:GetAbsOrigin()):Length2D() > LEASH
	else
		bear:RemoveModifierByName("modifier_lone_druid_spirit_bear_attack_check")   -- lesa C++ a clasei ursului, daca exista
	end
	local s = far and 1 or 0
	if self:GetStackCount() ~= s then self:SetStackCount(s) end
	-- Savage Roar al ursului: nivelul celui al lui Lone Druid
	local roar, ldRoar = bear:FindAbilityByName("lone_druid_savage_roar_bear"), owner:FindAbilityByName("lone_druid_savage_roar")
	if roar then
		local lvl = ldRoar and ldRoar:GetLevel() or 0
		if roar:GetLevel() ~= lvl then roar:SetLevel(lvl) end
		if roar:IsHidden() ~= (lvl == 0) then roar:SetHidden(lvl == 0) end
		-- cooldown comun (si pentru un urs nou invocat cat timp Savage Roar al lui LD e pe cooldown)
		if ldRoar then
			local a, b = ldRoar:GetCooldownTimeRemaining(), roar:GetCooldownTimeRemaining()
			if a > b + 0.2 then roar:EndCooldown(); roar:StartCooldown(a)
			elseif b > a + 0.2 then ldRoar:EndCooldown(); ldRoar:StartCooldown(b) end
		end
	end
	-- Rabid (6.88) creste si viteza ursului
	local om = owner:FindModifierByName("modifier_lone_druid_rabid")
	if om and om:GetAbility() and bear:IsAlive() then
		local bm = bear:FindModifierByName("modifier_lone_druid_rabid")
		if not bm or bm:GetLastAppliedTime() + 0.05 < om:GetLastAppliedTime() then
			bear:AddNewModifier(owner, om:GetAbility(), "modifier_lone_druid_rabid", { duration = om:GetRemainingTime() })
		end
	end
end
function modifier_dota688_lone_druid_spirit_bear_attack_check:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_EVENT_ON_DEATH, MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end
function modifier_dota688_lone_druid_spirit_bear_attack_check:OnTakeDamage(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	local attacker, owner = params.attacker, self:GetCaster()
	if not attacker or attacker:IsNull() or not attacker.GetPlayerOwnerID or attacker:GetPlayerOwnerID() < 0 then return end
	if attacker:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
	local a = self:GetAbility()
	self:GetParent():AddNewModifier(owner, a, "modifier_dota688_lone_druid_spirit_bear_recent_damage", { duration = DAMAGE_BLOCK })
	if owner and not owner:IsNull() then owner:AddNewModifier(owner, a, "modifier_dota688_lone_druid_spirit_bear_recent_damage", { duration = DAMAGE_BLOCK }) end
end
function modifier_dota688_lone_druid_spirit_bear_attack_check:OnDeath(params)
	if not IsServer() or params.unit ~= self:GetParent() or self.replaced then return end
	local bear, owner = self:GetParent(), self:GetCaster()
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/lone_druid_spirit_bear_death.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(fx, 0, bear:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(fx)
	if not owner or owner:IsNull() then return end
	owner:RemoveModifierByName("modifier_dota688_lone_druid_spirit_bear_recent_damage")   -- ursul mort se poate reinvoca imediat
	if not owner:IsAlive() then return end
	local killer = params.attacker
	if not killer or killer:IsNull() or killer:GetTeamNumber() == owner:GetTeamNumber() then killer = owner end
	local a = self:GetAbility()
	ApplyDamage({ victim = owner, attacker = killer, damage = owner:GetMaxHealth() * (self.backlash or 10) / 100, damage_type = DAMAGE_TYPE_PURE,
		ability = (a and not a:IsNull()) and a or nil, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION })
end
-- Savage Roar: cooldown comun intre Lone Druid si urs
function modifier_dota688_lone_druid_spirit_bear_attack_check:OnAbilityFullyCast(params)
	if not IsServer() or not params.ability then return end
	local bear, owner = self:GetParent(), self:GetCaster()
	local name = params.ability:GetAbilityName()
	local other
	if params.unit == bear and name == "lone_druid_savage_roar_bear" then
		other = owner and not owner:IsNull() and owner:FindAbilityByName("lone_druid_savage_roar")
	elseif params.unit == owner and name == "lone_druid_savage_roar" then
		other = bear:FindAbilityByName("lone_druid_savage_roar_bear")
	end
	if not other then return end
	local used = params.ability
	Dota688Timers:After(0, function()
		if used:IsNull() or other:IsNull() then return end
		local cd = used:GetCooldownTimeRemaining()
		if cd > other:GetCooldownTimeRemaining() then other:EndCooldown(); other:StartCooldown(cd) end
	end)
end

------------------------------------------------------------------------------------------------
-- marcaj: ursul a primit daune de la o unitate a unui jucator (pe urs si pe Lone Druid; HasModifier merge si pe client)
modifier_dota688_lone_druid_spirit_bear_recent_damage = class({})
function modifier_dota688_lone_druid_spirit_bear_recent_damage:IsHidden() return true end
function modifier_dota688_lone_druid_spirit_bear_recent_damage:IsPurgable() return false end
