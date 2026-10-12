-- Upgrade-uri de scepter 6.88 care se "lipesc" de abilitati/unitati built-in (C++) fara sa le rescriem:
--   Sven (aura de daune pentru aliati), Gyrocopter (Side Gunner), Batrider (100 dps pe Lasso),
--   Shadow Shaman (daune la wards), Warlock (al doilea golem, -25% statistici, -50% bounty),
--   Visage (al treilea familiar), Brewmaster (brewlingii primesc Thunder Clap / Drunken Haze / Drunken Brawler),
--   Meepo (un Meepo in plus: Divided We Stand nivel 4).
-- Se incarca din dota688/aghanim.lua.
local AG = Dota688Aghanim
local F = "dota688/aghanim_extras"

-- modifier pe erou cat timp are scepter (AG.EXTRA[hero].modifier) + functii la primire/pierdere
AG.EXTRA = {
	npc_dota_hero_sven = { modifier = "modifier_dota688_scepter_sven" },
	npc_dota_hero_gyrocopter = { modifier = "modifier_dota688_scepter_gyrocopter" },
	npc_dota_hero_batrider = { modifier = "modifier_dota688_scepter_batrider" },
	npc_dota_hero_visage = { modifier = "modifier_dota688_scepter_visage" },
	npc_dota_hero_meepo = {
		gained = function(hero)
			local a = hero:FindAbilityByName("meepo_divided_we_stand")
			if a and a:GetLevel() == 3 then a:SetLevel(4) end
		end,
		lost = function(hero)
			local a = hero:FindAbilityByName("meepo_divided_we_stand")
			if a and a:GetLevel() == 4 then a:SetLevel(3) end
		end,
	},
}

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
		local gift = ({ earth = "brewmaster_thunder_clap", storm = "brewmaster_drunken_haze", fire = "dota688_brewmaster_drunken_brawler" })[kind]
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

for _, m in ipairs({ "modifier_dota688_scepter_sven", "modifier_dota688_scepter_sven_buff", "modifier_dota688_scepter_gyrocopter",
	"modifier_dota688_scepter_batrider", "modifier_dota688_scepter_batrider_burn", "modifier_dota688_scepter_visage",
	"modifier_dota688_scepter_ward_damage", "modifier_dota688_scepter_golem" }) do
	LinkLuaModifier(m, F, LUA_MODIFIER_MOTION_NONE)
end
