-- Upgrade-uri de scepter 6.88 care se "lipesc" de abilitati/unitati built-in (C++) fara sa le rescriem:
--   Sven (aura de daune pentru aliati), Gyrocopter (Side Gunner), Batrider (100 dps pe Lasso),
--   Shadow Shaman (daune la wards), Warlock (al doilea golem, -25% statistici, -50% bounty),
--   Visage (al treilea familiar), Brewmaster (brewlingii primesc Thunder Clap / Drunken Haze / Drunken Brawler),
--   Meepo (un Meepo in plus: Divided We Stand nivel 4; clonele primesc 20%/100% din atributele bonus),
--   Invoker (+1 nivel la orbe pentru spell-urile invocate), Rubick (versiunea cu scepter a spell-urilor furate), Ursa (Enrage sub stun/hex).
-- Se incarca din dota688/aghanim.lua.
local AG = Dota688Aghanim
local F = "dota688/aghanim_extras"

-- modifier pe erou cat timp are scepter (AG.EXTRA[hero].modifier) + functii la primire/pierdere
AG.EXTRA = {
	npc_dota_hero_sven = { modifier = "modifier_dota688_scepter_sven" },
	npc_dota_hero_gyrocopter = { modifier = "modifier_dota688_scepter_gyrocopter" },
	npc_dota_hero_batrider = { modifier = "modifier_dota688_scepter_batrider" },
	npc_dota_hero_visage = { modifier = "modifier_dota688_scepter_visage" },
	npc_dota_hero_invoker = { modifier = "modifier_dota688_scepter_invoker" },
	npc_dota_hero_rubick = { modifier = "modifier_dota688_scepter_rubick" },
	npc_dota_hero_meepo = {
		modifier = "modifier_dota688_scepter_meepo",   -- scepter cumparat inainte de Divided We Stand nivel 3
		gained = function(hero)
			local a = hero:FindAbilityByName("meepo_divided_we_stand")
			if a and a:GetLevel() == 3 then a:SetLevel(4) end
		end,
		lost = function(hero)
			local a = hero:FindAbilityByName("meepo_divided_we_stand")
			if a and a:GetLevel() == 4 then
				a:SetLevel(3)
				-- clona in plus dispare (6.88). SetLevel ruleaza OnUpgrade-ul C++, care creeaza INCA o clona (testat:
				-- 3 -> 4 dupa vanzare): pastram cate o clona pe nivel, restul se scot cu UTIL_Remove
				-- (ForceKill pe o clona ar omori toti Meepo)
				Dota688Timers:After(0.1, function()
					if hero:IsNull() then return end
					local clones = {}
					for _, u in ipairs(Entities:FindAllByClassname("npc_dota_hero_meepo")) do
						if u ~= hero and u:IsClone() and u:GetCloneSource() == hero then table.insert(clones, u) end
					end
					table.sort(clones, function(x, y) return x:entindex() < y:entindex() end)
					for i = #clones, a:GetLevel() + 1, -1 do Dota688SafeRemove(clones[i]) end
				end)
			end
		end,
	},
}

-- abilitati C++ ale eroilor din AG.BUILTIN: daca Rubick le fura, primeste si el modifierul "consumed" ca sa aiba versiunea cu scepter
AG.BUILTIN_ABILITIES = {
	earthshaker_enchant_totem = true, witch_doctor_death_ward = true, tidehunter_gush = true, weaver_time_lapse = true,
	batrider_flaming_lasso = true, undying_decay = true, phoenix_supernova = true, winter_wyvern_arctic_burn = true,
	silencer_global_silence = true, shadow_demon_demonic_purge = true,
}

------------------------------------------------------------------------------------------------
-- Invoker: +1 nivel la Quas/Wex/Exort pentru spell-urile invocate (atributele orbelor raman la nivelul de baza – modifier_dota688_invoker_orbs)
modifier_dota688_scepter_invoker = class({})
local ORBS = { "invoker_quas", "invoker_wex", "invoker_exort" }
function modifier_dota688_scepter_invoker:IsHidden() return true end
function modifier_dota688_scepter_invoker:IsPurgable() return false end
function modifier_dota688_scepter_invoker:RemoveOnDeath() return false end
function modifier_dota688_scepter_invoker:OnCreated()
	if not IsServer() then return end
	local p = self:GetParent()
	p.dota688_orb_base = {}
	for _, n in ipairs(ORBS) do
		local a = p:FindAbilityByName(n)
		if a then
			p.dota688_orb_base[n] = a:GetLevel()
			if a:GetLevel() > 0 then a:SetLevel(a:GetLevel() + 1) end
		end
	end
	self:StartIntervalThink(0.2)
end
function modifier_dota688_scepter_invoker:OnIntervalThink()
	local p = self:GetParent()
	local base = p.dota688_orb_base
	if not base then return end
	for _, n in ipairs(ORBS) do
		local a = p:FindAbilityByName(n)
		if a then
			local cur, b = a:GetLevel(), base[n] or 0
			local expected = (b > 0) and (b + 1) or 0
			if cur == expected then
				-- ok
			elseif cur == expected + 1 then
				base[n] = b + 1              -- jucatorul a mai pus un nivel
			elseif b == 0 and cur == 1 then
				base[n] = 1; a:SetLevel(2)   -- primul nivel pus cu scepter in inventar
			elseif cur < expected then
				base[n] = math.max(0, cur - 1)
			end
			if base[n] > 7 then base[n] = 7; a:SetLevel(8) end
		end
	end
end
function modifier_dota688_scepter_invoker:OnDestroy()
	if not IsServer() then return end
	local p = self:GetParent()
	if p:IsNull() or not p.dota688_orb_base then return end
	for _, n in ipairs(ORBS) do
		local a = p:FindAbilityByName(n)
		if a and a:GetLevel() > 0 then a:SetLevel(p.dota688_orb_base[n] or (a:GetLevel() - 1)) end
	end
	p.dota688_orb_base = nil
end

------------------------------------------------------------------------------------------------
-- Rubick: spell-urile furate de la eroii cu upgrade built-in primesc versiunea cu scepter
modifier_dota688_scepter_rubick = class({})
function modifier_dota688_scepter_rubick:IsHidden() return true end
function modifier_dota688_scepter_rubick:IsPurgable() return false end
function modifier_dota688_scepter_rubick:RemoveOnDeath() return false end
function modifier_dota688_scepter_rubick:OnCreated() if IsServer() then self:StartIntervalThink(0.2) end end
function modifier_dota688_scepter_rubick:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_START } end
function modifier_dota688_scepter_rubick:OnAbilityStart(params)
	-- cat timp fura un spell, fara "consumed" (altfel Spell Steal modern ar fura 2 spell-uri)
	if IsServer() and params.unit == self:GetParent() and params.ability:GetName() == "rubick_spell_steal" then
		self:GetParent():RemoveModifierByName(AG.CONSUMED)
		self.block = GameRules:GetGameTime() + 0.5
	end
end
function modifier_dota688_scepter_rubick:OnIntervalThink()
	local p = self:GetParent()
	local want = false
	if not (self.block and GameRules:GetGameTime() < self.block) then
		for i = 0, 23 do
			local a = p:GetAbilityByIndex(i)
			if a and a:GetLevel() > 0 and AG.BUILTIN_ABILITIES[a:GetName()] then want = true end
		end
	end
	local has = p:HasModifier(AG.CONSUMED)
	if want and not has then p:AddNewModifier(p, nil, AG.CONSUMED, {}) elseif has and not want then p:RemoveModifierByName(AG.CONSUMED) end
end
function modifier_dota688_scepter_rubick:OnDestroy()
	if IsServer() and not self:GetParent():IsNull() then self:GetParent():RemoveModifierByName(AG.CONSUMED) end
end

------------------------------------------------------------------------------------------------
-- Meepo: clonele primesc 20% din atributele bonus ale lui Meepo (100% cu scepter)
modifier_dota688_meepo_share = class({})
function modifier_dota688_meepo_share:IsHidden() return true end
function modifier_dota688_meepo_share:IsPurgable() return false end
function modifier_dota688_meepo_share:RemoveOnDeath() return false end
function modifier_dota688_meepo_share:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_dota688_meepo_share:OnCreated()
	self.s, self.a, self.i = 0, 0, 0
	if IsServer() then self:StartIntervalThink(0.5) end
end
function modifier_dota688_meepo_share:OnIntervalThink()
	local clone = self:GetParent()
	local main = clone.GetCloneSource and clone:GetCloneSource() or nil
	if not main or main:IsNull() then return end
	local pct = Dota688HasScepter(main) and 1.0 or 0.2
	-- nu se impart: Attribute Bonus (clona il are la acelasi nivel) si atributele cizmelor (clona le poarta intregi, 6.88)
	local function own(u, k)
		local v = 0
		local ab = u:FindModifierByName("modifier_dota688_attribute_bonus")
		if ab then
			local f = ({ ab.GetModifierBonusStats_Strength, ab.GetModifierBonusStats_Agility, ab.GetModifierBonusStats_Intellect })[k]
			if f then v = v + (f(ab) or 0) end
		end
		if Dota688Meepo688 and Dota688Meepo688.BootAttributes then v = v + (select(k, Dota688Meepo688.BootAttributes(u)) or 0) end
		return v
	end
	local function want(getTotal, getBase, k)
		local bonusMain = getTotal(main) - getBase(main) - own(main, k)      -- atributele lui Meepo din iteme (fara cizme)
		local bonusClone = getTotal(clone) - getBase(clone) - own(clone, k)  -- ce are clona acum (inclusiv contributia noastra)
		return bonusMain * pct - bonusClone
	end
	local ds = want(function(u) return u:GetStrength() end, function(u) return u:GetBaseStrength() end, 1)
	local da = want(function(u) return u:GetAgility() end, function(u) return u:GetBaseAgility() end, 2)
	local di = want(function(u) return u:GetIntellect(true) end, function(u) return u:GetBaseIntellect() end, 3)
	local s, a, i = math.floor(self.s + ds + 0.5), math.floor(self.a + da + 0.5), math.floor(self.i + di + 0.5)
	if s ~= self.s or a ~= self.a or i ~= self.i then
		self.s, self.a, self.i = s, a, i
		self:SetStackCount((s + 500) * 1000000 + (a + 500) * 1000 + (i + 500))
		clone:CalculateStatBonus(true)
	end
end
function modifier_dota688_meepo_share:Decode()
	local v = self:GetStackCount()
	if v == 0 then return 0, 0, 0 end
	return math.floor(v / 1000000) - 500, math.floor((v % 1000000) / 1000) - 500, (v % 1000) - 500
end
function modifier_dota688_meepo_share:DeclareFunctions() return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, MODIFIER_PROPERTY_STATS_AGILITY_BONUS, MODIFIER_PROPERTY_STATS_INTELLECT_BONUS } end
function modifier_dota688_meepo_share:GetModifierBonusStats_Strength() local s = self:Decode(); return s end
function modifier_dota688_meepo_share:GetModifierBonusStats_Agility() local _, a = self:Decode(); return a end
function modifier_dota688_meepo_share:GetModifierBonusStats_Intellect() local _, _, i = self:Decode(); return i end

------------------------------------------------------------------------------------------------
-- la spawn-ul unui erou (gamemode): clonele Meepo primesc share-ul 6.88; Vengeance Illusion dispare la revenirea lui Venge
function AG.OnHeroSpawned(hero)
	if hero.dota688_copy then return end
	-- abilitatile oferite de scepter in 6.88 (AG.GRANT) sunt ascunse cat timp eroul nu are scepter;
	-- modifierul scepter-ului le deblocheaza (aghanim.lua). Fara asta se vedeau si se puteau invata de la inceput.
	if not Dota688HasScepter(hero) then
		for _, name in ipairs(AG.GRANT[hero:GetUnitName()] or {}) do
			local a = hero:FindAbilityByName(name)
			if a then
				a:SetHidden(true)
				a:SetActivated(false)
				if a:GetMaxLevel() == 1 then a:SetLevel(0) end
			end
		end
	end
	if hero:GetUnitName() == "npc_dota_hero_meepo" and hero.IsClone and hero:IsClone() and not hero:HasModifier("modifier_dota688_meepo_share") then
		hero:AddNewModifier(hero, nil, "modifier_dota688_meepo_share", {})
	end
	local v = hero.dota688_vengeance
	if v and not v:IsNull() and v:IsAlive() then v:ForceKill(false) end
	hero.dota688_vengeance = nil
end

-- filtrul de ordine (gamemode): Ursa cu scepter poate folosi Enrage si cand e dezactivat (stun/hex)
function AG.OrderFilter(ev)
	if ev.order_type ~= DOTA_UNIT_ORDER_CAST_NO_TARGET or not ev.entindex_ability then return true end
	local ab = EntIndexToHScript(ev.entindex_ability)
	if not ab or ab:IsNull() or ab:GetName() ~= "dota688_ursa_enrage" then return true end
	local unit = ev.units and ev.units["0"] and EntIndexToHScript(ev.units["0"])
	if not unit or not unit:IsAlive() or not Dota688HasScepter(unit) then return true end
	if not (unit:IsStunned() or unit:IsHexed()) then return true end
	if ab:GetLevel() < 1 or not ab:IsCooldownReady() then return true end
	local cost = ab:GetManaCost(ab:GetLevel() - 1)
	if unit:GetMana() < cost then return true end
	unit:SpendMana(cost, ab)
	ab:StartCooldown(ab:GetCooldown(ab:GetLevel() - 1))
	ab:OnSpellStart()
	return false
end

------------------------------------------------------------------------------------------------
-- Sven: God's Strength da +75/100/125% daune de baza eroilor aliati din 900
modifier_dota688_scepter_sven = class({})
local SVEN_DMG = { 75, 100, 125 }
function modifier_dota688_scepter_sven:IsHidden() return true end
function modifier_dota688_scepter_sven:IsPurgable() return false end
function modifier_dota688_scepter_sven:RemoveOnDeath() return false end
function modifier_dota688_scepter_sven:IsAura() return self:GetParent():HasModifier("modifier_sven_gods_strength") end
function modifier_dota688_scepter_sven:GetAuraRadius() return 900 end
function modifier_dota688_scepter_sven:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_scepter_sven:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_dota688_scepter_sven:GetModifierAura() return "modifier_dota688_scepter_sven_buff" end
function modifier_dota688_scepter_sven:GetAuraEntityReject(unit) return unit == self:GetParent() end
modifier_dota688_scepter_sven_buff = class({})
function modifier_dota688_scepter_sven_buff:IsPurgable() return false end
function modifier_dota688_scepter_sven_buff:GetTexture() return "sven_gods_strength" end
function modifier_dota688_scepter_sven_buff:DeclareFunctions() return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE } end
function modifier_dota688_scepter_sven_buff:GetModifierBaseDamageOutgoing_Percentage()
	local caster = self:GetCaster()
	local a = caster and caster:FindAbilityByName("sven_gods_strength")
	local lvl = a and a:GetLevel() or 1
	return SVEN_DMG[math.max(1, math.min(3, lvl))]
end

------------------------------------------------------------------------------------------------
-- Gyrocopter: Side Gunner – la fiecare 1.2 s ataca un inamic aleator din 600
modifier_dota688_scepter_gyrocopter = class({})
function modifier_dota688_scepter_gyrocopter:IsHidden() return true end
function modifier_dota688_scepter_gyrocopter:IsPurgable() return false end
function modifier_dota688_scepter_gyrocopter:RemoveOnDeath() return false end
function modifier_dota688_scepter_gyrocopter:OnCreated() if IsServer() then self:StartIntervalThink(1.2) end end
function modifier_dota688_scepter_gyrocopter:OnIntervalThink()
	local p = self:GetParent()
	if not p:IsAlive() or p:IsStunned() or p:IsDisarmed() then return end
	local enemies = FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, 600, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	if #enemies == 0 then return end
	p:PerformAttack(enemies[RandomInt(1, #enemies)], true, true, true, false, true, false, false)
end

------------------------------------------------------------------------------------------------
-- Batrider: Flaming Lasso face 100 daune/s
modifier_dota688_scepter_batrider = class({})
function modifier_dota688_scepter_batrider:IsHidden() return true end
function modifier_dota688_scepter_batrider:IsPurgable() return false end
function modifier_dota688_scepter_batrider:RemoveOnDeath() return false end
function modifier_dota688_scepter_batrider:OnCreated() if IsServer() then self:StartIntervalThink(0.25) end end
function modifier_dota688_scepter_batrider:OnIntervalThink()
	local p = self:GetParent()
	for _, u in ipairs(FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, 1200, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)) do
		local lasso = u:FindModifierByNameAndCaster("modifier_batrider_flaming_lasso", p)
		if lasso and not u:HasModifier("modifier_dota688_scepter_batrider_burn") then
			u:AddNewModifier(p, lasso:GetAbility(), "modifier_dota688_scepter_batrider_burn", {})
		end
	end
end
modifier_dota688_scepter_batrider_burn = class({})
function modifier_dota688_scepter_batrider_burn:IsHidden() return true end
function modifier_dota688_scepter_batrider_burn:IsPurgable() return false end
function modifier_dota688_scepter_batrider_burn:OnCreated() if IsServer() then self:StartIntervalThink(0.5) end end
function modifier_dota688_scepter_batrider_burn:OnIntervalThink()
	local p = self:GetParent()
	if not p:HasModifier("modifier_batrider_flaming_lasso") then self:Destroy() return end
	ApplyDamage({ victim = p, attacker = self:GetCaster(), damage = 50, damage_type = DAMAGE_TYPE_MAGICAL, ability = self:GetAbility() })
end

------------------------------------------------------------------------------------------------
-- Visage: 3 familiari (al treilea e creat din Lua dupa cast)
modifier_dota688_scepter_visage = class({})
function modifier_dota688_scepter_visage:IsHidden() return true end
function modifier_dota688_scepter_visage:IsPurgable() return false end
function modifier_dota688_scepter_visage:RemoveOnDeath() return false end
function modifier_dota688_scepter_visage:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_FULLY_CAST } end
function modifier_dota688_scepter_visage:OnAbilityFullyCast(params)
	if not IsServer() or params.unit ~= self:GetParent() or params.ability:GetName() ~= "visage_summon_familiars" then return end
	local p, a = self:GetParent(), params.ability
	if p.dota688_extra_familiar and not p.dota688_extra_familiar:IsNull() and p.dota688_extra_familiar:IsAlive() then
		p.dota688_extra_familiar:ForceKill(false)
	end
	local u = CreateUnitByName("npc_dota_visage_familiar" .. a:GetLevel(), p:GetAbsOrigin() + RandomVector(100), true, p, p:GetPlayerOwner(), p:GetTeamNumber())
	if u then
		u:SetOwner(p)
		u:SetControllableByPlayer(p:GetPlayerOwnerID(), true)
		p.dota688_extra_familiar = u
	end
end

------------------------------------------------------------------------------------------------
-- Shadow Shaman: wards cu +45 daune
modifier_dota688_scepter_ward_damage = class({})
function modifier_dota688_scepter_ward_damage:IsHidden() return true end
function modifier_dota688_scepter_ward_damage:IsPurgable() return false end
function modifier_dota688_scepter_ward_damage:DeclareFunctions() return { MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE } end
function modifier_dota688_scepter_ward_damage:GetModifierBaseAttack_BonusDamage() return 45 end

-- Warlock: golemi cu -25% HP si daune, -50% bounty
modifier_dota688_scepter_golem = class({})
function modifier_dota688_scepter_golem:IsHidden() return true end
function modifier_dota688_scepter_golem:IsPurgable() return false end
function modifier_dota688_scepter_golem:DeclareFunctions() return { MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE, MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE } end
function modifier_dota688_scepter_golem:GetModifierExtraHealthPercentage() return -25 end
function modifier_dota688_scepter_golem:GetModifierBaseDamageOutgoing_Percentage() return -25 end

local function copy_golem(orig, owner)
	local u = CreateUnitByName(orig:GetUnitName(), orig:GetAbsOrigin() + RandomVector(120), true, owner, owner:GetPlayerOwner(), owner:GetTeamNumber())
	if not u then return end
	u:SetOwner(owner)
	u:SetControllableByPlayer(owner:GetPlayerOwnerID(), true)
	u:SetBaseMaxHealth(orig:GetBaseMaxHealth())
	u:SetMaxHealth(orig:GetMaxHealth())
	u:SetHealth(u:GetMaxHealth())
	u:SetBaseDamageMin(orig:GetBaseDamageMin()); u:SetBaseDamageMax(orig:GetBaseDamageMax())
	u:SetPhysicalArmorBaseValue(orig:GetPhysicalArmorBaseValue())
	u:SetBaseHealthRegen(orig:GetBaseHealthRegen())
	u:SetBaseMoveSpeed(orig:GetBaseMoveSpeed())
	for i = 0, 15 do
		local oa = orig:GetAbilityByIndex(i)
		if oa then
			local na = u:FindAbilityByName(oa:GetName()) or u:AddAbility(oa:GetName())
			if na then na:SetLevel(oa:GetLevel()) end
		end
	end
	u:AddNewModifier(owner, nil, "modifier_kill", { duration = 60 })
	return u
end

-- apelat din gamemode (npc_spawned) pentru unitatile care nu sunt eroi
function AG.OnUnitSpawned(unit)
	local owner = unit:GetOwner()
	if not owner or owner:IsNull() or not owner.IsRealHero or not owner:IsRealHero() then return end
	if not Dota688HasScepter(owner) then return end
	local name = unit:GetUnitName()
	if string.find(name, "npc_dota_shadow_shaman_ward", 1, true) == 1 then
		unit:AddNewModifier(owner, nil, "modifier_dota688_scepter_ward_damage", {})
	elseif name == "npc_dota_warlock_golem" and not unit.dota688_golem_copy then
		unit:AddNewModifier(owner, nil, "modifier_dota688_scepter_golem", {})
		local now = GameRules:GetGameTime()
		if (owner.dota688_last_golem or -10) + 0.5 < now then
			owner.dota688_last_golem = now
			Dota688Timers:After(0.1, function()
				if unit:IsNull() or not unit:IsAlive() then return end
				local c = copy_golem(unit, owner)
				if c then
					c.dota688_golem_copy = true
					c:AddNewModifier(owner, nil, "modifier_dota688_scepter_golem", {})
					for _, g in ipairs({ unit, c }) do
						g:SetMinimumGoldBounty(g:GetMinimumGoldBounty() * 0.5); g:SetMaximumGoldBounty(g:GetMaximumGoldBounty() * 0.5)
					end
				end
			end)
		end
	elseif string.find(name, "npc_dota_brewmaster_", 1, true) == 1 then
		local kind = name:match("npc_dota_brewmaster_(%a+)_")
		local gift = ({ earth = "brewmaster_thunder_clap", storm = "dota688_brewmaster_drunken_haze", fire = "dota688_brewmaster_drunken_brawler" })[kind]
		if gift then
			local src = owner:FindAbilityByName(gift)
			local lvl = src and src:GetLevel() or 1
			if lvl > 0 then
				local a = unit:FindAbilityByName(gift) or unit:AddAbility(gift)
				if a then a:SetLevel(lvl) end
			end
		end
	end
end

-- Meepo: scepter-ul da o clona in plus si cand Divided We Stand ajunge la nivelul 3 dupa cumparare
modifier_dota688_scepter_meepo = class({})
function modifier_dota688_scepter_meepo:IsHidden() return true end
function modifier_dota688_scepter_meepo:IsPurgable() return false end
function modifier_dota688_scepter_meepo:RemoveOnDeath() return false end
function modifier_dota688_scepter_meepo:OnCreated() if IsServer() then self:StartIntervalThink(0.5) end end
function modifier_dota688_scepter_meepo:OnIntervalThink()
	local p = self:GetParent()
	if p:IsClone() then return end
	local a = p:FindAbilityByName("meepo_divided_we_stand")
	if a and a:GetLevel() == 3 then a:SetLevel(4) end
end

for _, m in ipairs({ "modifier_dota688_scepter_meepo", "modifier_dota688_scepter_sven", "modifier_dota688_scepter_sven_buff", "modifier_dota688_scepter_gyrocopter",
	"modifier_dota688_scepter_batrider", "modifier_dota688_scepter_batrider_burn", "modifier_dota688_scepter_visage",
	"modifier_dota688_scepter_ward_damage", "modifier_dota688_scepter_golem", "modifier_dota688_scepter_invoker",
	"modifier_dota688_scepter_rubick", "modifier_dota688_meepo_share" }) do
	LinkLuaModifier(m, F, LUA_MODIFIER_MOTION_NONE)
end
