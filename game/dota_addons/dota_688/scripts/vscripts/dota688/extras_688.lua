-- Mecanici 6.88 ale unor abilitati built-in pe care motorul curent nu le mai are (gasite de verificarea din 13.10.2026).
-- Valorile se citesc din KV-ul abilitatii: generatorul pastreaza cheile 6.88 disparute in AbilityValues (motorul le ignora).
--   Morph (Morphling): pasiv +3/4/5/6 Agility si Strength.
--   Mass Serpent Ward: daune splash 100% pe 175 in jurul tintei.
--   Phantom Strike: bonusul de viteza de atac tine maxim 4 atacuri.
--   Corrosive Skin: atacatorul e incetinit si la miscare (-10/15/20/25%), nu doar la atac.
--   Thunder Clap: creepii raman incetiniti 8 s (eroii 4 s).
--   Reverse Polarity: creepii sunt stunati 3/4/5 s (eroii 2.25/3/3.75 s).
--   Earth Brewling (Primal Split): Spell Immunity = imun la vraji (motorul curent da doar 60% rezistenta la magie).
--   Frostbite: pe creepi tine 10 s (eroii 1.5-3 s); Frost Arrows: pe creepi 7 s (eroii 1.5 s).
--   Spark Wraith: purge pe tinta (Dota688Extras.OnDamage, din DamageFilter).
--   Mana Drain: nu se poate folosi pe aliati (Dota688Extras.OrderFilter).
--   Homing Missile: daunele cresc cu distanta parcursa de racheta (50 -> maxim la 1500), ca in 6.88.
--   Stone Gaze: unitatile pietrificate au 100% rezistenta la magie, iar iluziile pietrificate mor.
--   Wind Walk: folosirea unei abilitati il scoate pe Clinkz din invizibilitate.
--   Blade Fury: Juggernaut e imun la magie (si scapa de debuff-uri la lansare); motorul curent da doar rezistenta.
--   Boulder Smash: un Stone Remnant lovit stuneaza inamicii atinsi (motorul curent ii incetineste).
--   Devour: digestia dureaza HP / 20 s (motorul curent: cat cooldown-ul); fara alt-cast, nu pe catapulte.
--   Black King Bar: imunitate la vraji (MAGIC_IMMUNE) cat tine Avatar; motorul curent da doar "debuff immunity", iar
--   IsMagicImmune() / filtrele de tinte ale abilitatilor Lua nu o vedeau (testat: IsMagicImmune false cu BKB activ).
Dota688Extras = Dota688Extras or {}
local F = "dota688/extras_688"
LinkLuaModifier("modifier_dota688_extra_morph", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_ward_splash", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_phantom_strike", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_corrosive", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_corrosive_slow", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_creep_duration", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_spell_immunity", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_frost_arrows", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_stone_gaze", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_wind_walk", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_bkb", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_blade_fury", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_boulder_smash", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_petrified", F, LUA_MODIFIER_MOTION_NONE)

local function val(unit, ability, key)
	local a = unit and not unit:IsNull() and unit:FindAbilityByName(ability)
	if not a or a:GetLevel() == 0 then return 0 end
	return a:GetSpecialValueFor(key)
end

-- clasa de baza: modifier ascuns, permanent
local function hidden(m)
	m.IsHidden = function() return true end
	m.IsPurgable = function() return false end
	m.RemoveOnDeath = function() return false end
	m.GetAttributes = function() return MODIFIER_ATTRIBUTE_PERMANENT end
	return m
end

------------------------------------------------------------------------------------------------
-- Morph: pasiv +bonus_attributes la Agility si Strength (Morph Agility si Morph Strength au acelasi nivel)
modifier_dota688_extra_morph = hidden(class({}))
function modifier_dota688_extra_morph:DeclareFunctions() return { MODIFIER_PROPERTY_STATS_AGILITY_BONUS, MODIFIER_PROPERTY_STATS_STRENGTH_BONUS } end
function modifier_dota688_extra_morph:GetModifierBonusStats_Agility() return val(self:GetParent(), "morphling_morph_agi", "bonus_attributes") end
function modifier_dota688_extra_morph:GetModifierBonusStats_Strength() return val(self:GetParent(), "morphling_morph_str", "bonus_attributes") end

------------------------------------------------------------------------------------------------
-- Serpent Ward: splash fizic in jurul tintei (nu pe cladiri)
modifier_dota688_extra_ward_splash = hidden(class({}))
function modifier_dota688_extra_ward_splash:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_extra_ward_splash:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() then return end
	local ward, target = self:GetParent(), params.target
	if not target or target:IsNull() or target:IsBuilding() then return end
	local owner = ward:GetOwner()
	local radius = val(owner, "shadow_shaman_mass_serpent_ward", "splash_radius")
	local pct = val(owner, "shadow_shaman_mass_serpent_ward", "splash_damage")
	if radius <= 0 or pct <= 0 then return end
	local dmg = params.original_damage * pct / 100
	for _, u in ipairs(FindUnitsInRadius(ward:GetTeamNumber(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if u ~= target then
			ApplyDamage({ victim = u, attacker = ward, damage = dmg, damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION })
		end
	end
end

------------------------------------------------------------------------------------------------
-- Phantom Strike: bonusul de viteza de atac se termina dupa bonus_max_attack_count atacuri
modifier_dota688_extra_phantom_strike = hidden(class({}))
function modifier_dota688_extra_phantom_strike:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK } end
function modifier_dota688_extra_phantom_strike:OnAttack(params)
	if not IsServer() or params.attacker ~= self:GetParent() then return end
	local buff = self:GetParent():FindModifierByName("modifier_phantom_assassin_phantom_strike")
	if not buff then return end
	if self.buffTime ~= buff:GetCreationTime() then self.buffTime = buff:GetCreationTime(); self.count = 0 end
	self.count = self.count + 1
	local max = val(self:GetParent(), "phantom_assassin_phantom_strike", "bonus_max_attack_count")
	if max > 0 and self.count >= max then buff:Destroy() end
end

------------------------------------------------------------------------------------------------
-- Corrosive Skin: pe langa slow-ul de atac al motorului, slow de miscare cat dureaza debuff-ul built-in
modifier_dota688_extra_corrosive = hidden(class({}))
function modifier_dota688_extra_corrosive:DeclareFunctions() return { MODIFIER_EVENT_ON_TAKEDAMAGE } end
function modifier_dota688_extra_corrosive:OnTakeDamage(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	local attacker = params.attacker
	if not attacker or attacker:IsNull() or attacker:GetTeamNumber() == self:GetParent():GetTeamNumber() then return end
	local viper = self:GetParent()
	Dota688Timers:After(0, function()
		if attacker:IsNull() or not attacker:IsAlive() then return end
		local m = attacker:FindModifierByName("modifier_viper_corrosive_skin_slow")
		if m and m:GetCaster() == viper then
			local s = attacker:AddNewModifier(viper, viper:FindAbilityByName("viper_corrosive_skin"), "modifier_dota688_extra_corrosive_slow", { duration = m:GetRemainingTime() })
			if s then s.slow = val(viper, "viper_corrosive_skin", "bonus_movement_speed") end
		end
	end)
end
modifier_dota688_extra_corrosive_slow = class({})
function modifier_dota688_extra_corrosive_slow:IsHidden() return true end
function modifier_dota688_extra_corrosive_slow:IsDebuff() return true end
function modifier_dota688_extra_corrosive_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_extra_corrosive_slow:GetModifierMoveSpeedBonus_Percentage() return self.slow or 0 end

------------------------------------------------------------------------------------------------
-- Thunder Clap / Reverse Polarity: durata pe creepi (unitati care nu sunt eroi)
local CREEP_DURATION = {
	brewmaster_thunder_clap = { modifier = "modifier_brewmaster_thunder_clap", key = "duration_creeps", radius = "radius" },
	magnataur_reverse_polarity = { modifier = "modifier_magnataur_reverse_polarity_stun", key = "creep_stun_duration", radius = "pull_radius" },
	crystal_maiden_frostbite = { modifier = "modifier_crystal_maiden_frostbite", key = "creep_duration", target = true },
}
modifier_dota688_extra_creep_duration = hidden(class({}))
function modifier_dota688_extra_creep_duration:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
function modifier_dota688_extra_creep_duration:OnAbilityExecuted(params)
	if not IsServer() or params.unit ~= self:GetParent() or not params.ability then return end
	local name = params.ability:GetAbilityName()
	local cfg = CREEP_DURATION[name]
	if not cfg then return end
	local caster, ability = self:GetParent(), params.ability
	local dur = ability:GetSpecialValueFor(cfg.key)
	if dur <= 0 then return end
	local target = params.target
	Dota688Timers:After(0.1, function()
		if caster:IsNull() then return end
		local units
		if cfg.target then
			units = (target and not target:IsNull()) and { target } or {}
		else
			units = FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, ability:GetSpecialValueFor(cfg.radius) + 200, DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		end
		for _, u in ipairs(units) do
			if not u:IsConsideredHero() then
				for _, m in ipairs(u:FindAllModifiersByName(cfg.modifier)) do
					if m:GetCaster() == caster then m:SetDuration(dur, true) end
				end
			end
		end
	end)
end

------------------------------------------------------------------------------------------------
-- Frost Arrows: incetinirea pe creepi tine frost_arrows_creep_duration (7 s)
modifier_dota688_extra_frost_arrows = hidden(class({}))
function modifier_dota688_extra_frost_arrows:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_extra_frost_arrows:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() then return end
	local t, caster = params.target, self:GetParent()
	if not t or t:IsNull() or t:IsConsideredHero() or t:IsBuilding() then return end
	local dur = val(caster, "drow_ranger_frost_arrows", "frost_arrows_creep_duration")
	if dur <= 0 then return end
	Dota688Timers:After(0, function()
		if t:IsNull() then return end
		for _, m in ipairs(t:FindAllModifiersByName("modifier_drow_ranger_frost_arrows_slow")) do
			if m:GetCaster() == caster and m:GetElapsedTime() < 0.2 then m:SetDuration(dur, true) end
		end
	end)
end

-- Mana Drain (6.88): doar pe inamici; abilitatea curenta poate tinti si aliati (cheia AbilityUnitTargetTeam e ignorata)
-- Curierul (6.88): "Go to Secret Shop" mergea la secret shop-ul echipei tale. Motorul curent trimite curierii ambelor echipe
-- la acelasi secret shop (testat: curierul Radiant ajunge la cel Dire, si cu echipa pusa pe entitatile de shop). Comenzile de
-- shop ale curierului devin un drum pana la shop-ul potrivit: secret = al echipei (Radiant stanga, Dire dreapta, ca pe harta
-- 6.88), enemy secret = celalalt, side shop = cel mai apropiat de curier, side shop 2 = celalalt.
local COURIER_SHOP = { courier_go_to_secretshop = "secret", courier_go_to_enemy_secretshop = "enemy", courier_go_to_sideshop = "side", courier_go_to_sideshop2 = "side2" }
local function shopPositions(shopType)
	local out = {}
	for _, e in ipairs(Entities:FindAllByClassname("ent_dota_shop")) do
		if e:GetShopType() == shopType then out[#out + 1] = e:GetAbsOrigin() end
	end
	return out
end
function Dota688Extras.CourierShopTarget(courier, kind)
	if kind == "secret" or kind == "enemy" then
		local own = (courier:GetTeamNumber() == DOTA_TEAM_GOODGUYS) == (kind == "secret")   -- shop-ul Radiant e cel din stanga
		for _, p in ipairs(shopPositions(DOTA_SHOP_SECRET)) do
			if (p.x < 0) == own then return p end
		end
	else
		local list = shopPositions(DOTA_SHOP_SIDE)
		table.sort(list, function(x, y) return (x - courier:GetAbsOrigin()):Length2D() < (y - courier:GetAbsOrigin()):Length2D() end)
		return list[kind == "side" and 1 or 2]
	end
end
function Dota688Extras.CourierShopOrderFilter(ev)
	if ev.order_type ~= DOTA_UNIT_ORDER_CAST_NO_TARGET or not ev.entindex_ability or ev.entindex_ability <= 0 then return true end
	local a = EntIndexToHScript(ev.entindex_ability)
	local kind = a and a.GetAbilityName and COURIER_SHOP[a:GetAbilityName()]
	if not kind then return true end
	local courier = a:GetCaster()
	local target = courier and Dota688Extras.CourierShopTarget(courier, kind)
	if not target then return true end
	ev.order_type = DOTA_UNIT_ORDER_MOVE_TO_POSITION
	ev.entindex_ability = 0
	ev.position_x, ev.position_y, ev.position_z = target.x, target.y, target.z
	return true
end

function Dota688Extras.OrderFilter(ev)
	if not Dota688Extras.DevourOrderFilter(ev) then return false end
	if not Dota688Extras.CourierShopOrderFilter(ev) then return false end
	if ev.order_type ~= DOTA_UNIT_ORDER_CAST_TARGET then return true end
	local a = ev.entindex_ability and EntIndexToHScript(ev.entindex_ability)
	local t = ev.entindex_target and EntIndexToHScript(ev.entindex_target)
	if a and t and a.GetAbilityName and a:GetAbilityName() == "lion_mana_drain" and t:GetTeamNumber() == a:GetCaster():GetTeamNumber() then
		return false
	end
	return true
end

-- Homing Missile (6.88): "deals greater damage the further it has traveled", minim 50, maxim (125/250/375/500) la 1500.
-- Motorul curent da mereu hit_damage (pus la maxim in override); distanta parcursa de fiecare racheta e masurata aici.
local MISSILE = "npc_dota_gyrocopter_homing_missile"
Dota688Extras.missiles = Dota688Extras.missiles or {}
function Dota688Extras.TrackMissile(unit)
	unit.dota688_travel = 0
	Dota688Extras.missiles[unit] = true
	local last = unit:GetAbsOrigin()
	Dota688Timers:Every(0.05, function()
		if unit:IsNull() then Dota688Extras.missiles[unit] = nil; return false end
		if not unit:IsAlive() then Dota688Timers:After(1, function() Dota688Extras.missiles[unit] = nil end); return false end
		local pos = unit:GetAbsOrigin()
		unit.dota688_travel = unit.dota688_travel + (pos - last):Length2D()
		last = pos
	end)
end
local function MissileScale(attacker, victim, ability)
	local best, bestD
	for m in pairs(Dota688Extras.missiles) do
		if not m:IsNull() and m.dota688_travel and (m:GetOwner() == attacker or m:GetOwnerEntity() == attacker) then
			local d = (m:GetAbsOrigin() - victim:GetAbsOrigin()):Length2D()
			if not bestD or d < bestD then best, bestD = m, d end
		end
	end
	if not best then return 1 end
	local maxDmg = ability:GetAbilityDamage()
	local minDmg = ability:GetSpecialValueFor("min_damage")
	local maxDist = ability:GetSpecialValueFor("max_distance")
	if maxDmg <= 0 then return 1 end
	if maxDist <= 0 then maxDist = 1500 end
	local dmg = minDmg + (maxDmg - minDmg) * math.min(1, best.dota688_travel / maxDist)
	return dmg / maxDmg
end

-- Spark Wraith: purge pe tinta lovita (6.88: "dealing magical damage and purging the unit"); apelat din Dota688:DamageFilter
function Dota688Extras.OnDamage(ev)
	local inflictor = ev.entindex_inflictor_const and EntIndexToHScript(ev.entindex_inflictor_const)
	if not inflictor or not inflictor.GetAbilityName then return end
	local victim = ev.entindex_victim_const and EntIndexToHScript(ev.entindex_victim_const)
	if inflictor:GetAbilityName() == "gyrocopter_homing_missile" and victim then
		local attacker = ev.entindex_attacker_const and EntIndexToHScript(ev.entindex_attacker_const)
		ev.damage = ev.damage * MissileScale(attacker, victim, inflictor)
		return
	end
	if inflictor:GetAbilityName() == "earth_spirit_boulder_smash" and victim then
		Dota688Extras.BoulderSmashStun(ev.entindex_attacker_const and EntIndexToHScript(ev.entindex_attacker_const), victim, inflictor)
		return
	end
	if inflictor:GetAbilityName() ~= "arc_warden_spark_wraith" then return end
	if victim and not victim:IsNull() and victim:IsAlive() then
		Dota688Timers:After(0, function() if not victim:IsNull() then victim:Purge(true, false, false, false, false) end end)
	end
end

------------------------------------------------------------------------------------------------
-- Stone Gaze (6.88): "Petrified units are stunned, have 100% magic damage resistance ... If the petrified unit is an
-- illusion, it is immediately killed." Cat timp Stone Gaze e activ, unitatile pietrificate primesc rezistenta / iluziile mor.
local STONE = "modifier_medusa_stone_gaze_stone"
modifier_dota688_extra_stone_gaze = hidden(class({}))
function modifier_dota688_extra_stone_gaze:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
function modifier_dota688_extra_stone_gaze:OnAbilityExecuted(params)
	if not IsServer() or params.unit ~= self:GetParent() or not params.ability or params.ability:GetAbilityName() ~= "medusa_stone_gaze" then return end
	local caster, a = self:GetParent(), params.ability
	local untilT = GameRules:GetGameTime() + a:GetSpecialValueFor("duration") + a:GetSpecialValueFor("stone_duration") + 0.5
	Dota688Timers:Every(0.1, function()
		if caster:IsNull() or GameRules:GetGameTime() > untilT then return false end
		for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)) do
			local m = u:FindModifierByName(STONE)
			if m and m:GetCaster() == caster then
				if u:IsIllusion() then
					u:ForceKill(false)
				elseif not u:HasModifier("modifier_dota688_extra_petrified") then
					u:AddNewModifier(caster, a, "modifier_dota688_extra_petrified", { duration = m:GetRemainingTime() })
				end
			end
		end
	end)
end
modifier_dota688_extra_petrified = class({})
function modifier_dota688_extra_petrified:IsHidden() return true end
function modifier_dota688_extra_petrified:IsPurgable() return false end
function modifier_dota688_extra_petrified:DeclareFunctions() return { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS } end
function modifier_dota688_extra_petrified:GetModifierMagicalResistanceBonus() return 100 end

------------------------------------------------------------------------------------------------
-- Wind Walk (6.88): "moves invisibly ... until the moment he attacks or uses an ability"
modifier_dota688_extra_wind_walk = hidden(class({}))
function modifier_dota688_extra_wind_walk:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
function modifier_dota688_extra_wind_walk:OnAbilityExecuted(params)
	if not IsServer() or params.unit ~= self:GetParent() or not params.ability or params.ability:IsItem() then return end
	if params.ability:GetAbilityName() == "clinkz_wind_walk" then return end
	self:GetParent():RemoveModifierByName("modifier_clinkz_wind_walk")
end

-- Blade Fury (6.88): "rendering him immune to magic" -> imunitate la vraji cat dureaza, plus purge de debuff-uri la lansare
modifier_dota688_extra_blade_fury = hidden(class({}))
function modifier_dota688_extra_blade_fury:CheckState()
	if self:GetParent():HasModifier("modifier_juggernaut_blade_fury") then return { [MODIFIER_STATE_MAGIC_IMMUNE] = true } end
	return {}
end
function modifier_dota688_extra_blade_fury:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
function modifier_dota688_extra_blade_fury:OnAbilityExecuted(params)
	if not IsServer() or params.unit ~= self:GetParent() or not params.ability or params.ability:GetAbilityName() ~= "juggernaut_blade_fury" then return end
	self:GetParent():Purge(false, true, false, false, false)
end

-- Boulder Smash (6.88): daca tinta lovita e un Stone Remnant, inamicii atinsi de el sunt stunati 0.75/1.25/1.75/2.25 s
local REMNANT = "npc_dota_earth_spirit_stone"
modifier_dota688_extra_boulder_smash = hidden(class({}))
function modifier_dota688_extra_boulder_smash:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
function modifier_dota688_extra_boulder_smash:OnAbilityExecuted(params)
	if not IsServer() or params.unit ~= self:GetParent() or not params.ability or params.ability:GetAbilityName() ~= "earth_spirit_boulder_smash" then return end
	local p, a = self:GetParent(), params.ability
	local rock = params.target and not params.target:IsNull() and params.target:GetUnitName() == REMNANT
	if not params.target then
		-- lansat pe teren: motorul loveste cel mai apropiat Stone Remnant din jurul punctului
		local pos = a:GetCursorPosition()
		for _, u in ipairs(FindUnitsInRadius(p:GetTeamNumber(), pos, nil, a:GetSpecialValueFor("rock_search_aoe") > 0 and a:GetSpecialValueFor("rock_search_aoe") or 200,
			DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)) do
			if u:GetUnitName() == REMNANT then rock = true; break end
		end
	end
	if rock then p.dota688_rock_smash = { untilT = GameRules:GetGameTime() + 3, hit = {} } end
end
function Dota688Extras.BoulderSmashStun(attacker, victim, ability)
	local r = attacker and attacker.dota688_rock_smash
	if not r or GameRules:GetGameTime() > r.untilT or r.hit[victim:entindex()] then return end
	r.hit[victim:entindex()] = true
	Dota688Timers:After(0, function()
		if victim:IsNull() or not victim:IsAlive() then return end
		victim:AddNewModifier(attacker, ability, "modifier_stunned", { duration = ability:GetSpecialValueFor("stun_duration") })
	end)
end

------------------------------------------------------------------------------------------------
-- Earth Brewling: imunitate la vraji permanenta (6.88: "Immune to spells.")
modifier_dota688_extra_spell_immunity = hidden(class({}))
function modifier_dota688_extra_spell_immunity:CheckState() return { [MODIFIER_STATE_MAGIC_IMMUNE] = true } end

------------------------------------------------------------------------------------------------
-- Devour (6.88): "The amount of time it takes to Devour depends on the current HP of the unit" -> digestia dureaza
-- HP / health_per_second (20/s); pana se termina, Devour nu se poate folosi (cooldown = max(cooldown, digestie)).
-- Restul (aur, abilitatile creep-ului in empty1/empty2) ramane al abilitatii built-in.
LinkLuaModifier("modifier_dota688_extra_devour", F, LUA_MODIFIER_MOTION_NONE)
local DEVOUR = "doom_bringer_devour"
local DEVOUR_BUFF = "modifier_doom_bringer_devour"
modifier_dota688_extra_devour = hidden(class({}))
function modifier_dota688_extra_devour:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_START, MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
-- HP-ul tintei la inceputul cast-ului (dupa executie creep-ul poate fi deja mort, cu 0 HP)
function modifier_dota688_extra_devour:OnAbilityStart(params)
	if not IsServer() or params.unit ~= self:GetParent() or not params.ability or params.ability:GetAbilityName() ~= DEVOUR then return end
	local t = params.target or params.ability:GetCursorTarget()
	self.hp = (t and not t:IsNull() and t:IsAlive()) and t:GetHealth() or nil
end
function modifier_dota688_extra_devour:OnAbilityExecuted(params)
	if not IsServer() or params.unit ~= self:GetParent() or not params.ability or params.ability:GetAbilityName() ~= DEVOUR then return end
	local doom, a = self:GetParent(), params.ability
	local t = params.target or a:GetCursorTarget()
	local hp = self.hp
	if t and not t:IsNull() and t:IsAlive() and t:GetHealth() > 0 then hp = t:GetHealth() end   -- HP-ul de la executie, daca mai exista
	self.hp = nil
	if not hp or hp <= 0 then return end
	local hps = a:GetSpecialValueFor("health_per_second")   -- cheie 6.88 pastrata de generator in AbilityValues
	if hps <= 0 then hps = 20 end
	local digest = hp / hps
	doom.dota688_devour_end = GameRules:GetGameTime() + digest
	local function apply()
		if doom:IsNull() then return true end
		local buff = doom:FindModifierByName(DEVOUR_BUFF)
		if buff then buff:SetDuration(math.max(0.1, digest - buff:GetElapsedTime()), true) end
		if not a:IsNull() and digest > a:GetCooldownTimeRemaining() then
			a:EndCooldown()
			a:StartCooldown(digest)
		end
		return buff ~= nil
	end
	-- modifierul built-in apare in OnSpellStart; cadrul urmator e sigur, cu o reincercare daca nu e inca acolo
	Dota688Timers:After(0, function()
		if not apply() then Dota688Timers:After(0.1, function() apply() end) end
	end)
end

-- filtrul de ordine (din Dota688Extras.OrderFilter):
--   * alt-cast-ul (nu fura abilitatile) nu exista in 6.88;
--   * nu se poate manca din nou cat timp digera (ex. dupa Refresher Orb);
--   * nu pe unitati mecanice (catapultele).
local ORDER_TOGGLE_ALT = _G["DOTA_UNIT_ORDER_CAST_TOGGLE_ALT"]
function Dota688Extras.DevourOrderFilter(ev)
	if ev.order_type ~= DOTA_UNIT_ORDER_CAST_TARGET and (not ORDER_TOGGLE_ALT or ev.order_type ~= ORDER_TOGGLE_ALT) then return true end
	local a = ev.entindex_ability and EntIndexToHScript(ev.entindex_ability)
	if not a or not a.GetAbilityName or a:GetAbilityName() ~= DEVOUR then return true end
	if ev.order_type == ORDER_TOGGLE_ALT then return false end
	local caster = a:GetCaster()
	if caster and caster.dota688_devour_end and GameRules:GetGameTime() < caster.dota688_devour_end then return false end
	local t = ev.entindex_target and EntIndexToHScript(ev.entindex_target)
	if t and t.GetUnitName then
		if string.find(t:GetUnitName(), "_siege", 1, true) then return false end   -- catapultele (unitati mecanice)
	end
	return true
end
------------------------------------------------------------------------------------------------
-- Black King Bar: cat exista modifierul motorului, unitatea e si imuna la vraji (6.88)
local BKB = "modifier_black_king_bar_immune"
modifier_dota688_extra_bkb = class({})
function modifier_dota688_extra_bkb:IsHidden() return true end
function modifier_dota688_extra_bkb:IsPurgable() return false end
function modifier_dota688_extra_bkb:OnCreated() if IsServer() then self:StartIntervalThink(0.1) end end
function modifier_dota688_extra_bkb:OnIntervalThink()
	if not self:GetParent():HasModifier(BKB) then self:Destroy() end
end
function modifier_dota688_extra_bkb:CheckState() return { [MODIFIER_STATE_MAGIC_IMMUNE] = true } end
-- din Dota688:ModifierGainedFilter
function Dota688Extras.ModifierGained(ev)
	if ev.name_const ~= BKB then return end
	local u = ev.entindex_parent_const and EntIndexToHScript(ev.entindex_parent_const)
	if not u then return end
	Dota688Timers:After(0, function()
		if not u:IsNull() and u:HasModifier(BKB) and not u:HasModifier("modifier_dota688_extra_bkb") then
			u:AddNewModifier(u, nil, "modifier_dota688_extra_bkb", {})
		end
	end)
end

------------------------------------------------------------------------------------------------
local HERO_EXTRAS = {
	npc_dota_hero_morphling = { "modifier_dota688_extra_morph" },
	npc_dota_hero_phantom_assassin = { "modifier_dota688_extra_phantom_strike" },
	npc_dota_hero_viper = { "modifier_dota688_extra_corrosive" },
	npc_dota_hero_brewmaster = { "modifier_dota688_extra_creep_duration" },
	npc_dota_hero_magnataur = { "modifier_dota688_extra_creep_duration" },
	npc_dota_hero_crystal_maiden = { "modifier_dota688_extra_creep_duration" },
	npc_dota_hero_drow_ranger = { "modifier_dota688_extra_frost_arrows" },
	npc_dota_hero_medusa = { "modifier_dota688_extra_stone_gaze" },
	npc_dota_hero_clinkz = { "modifier_dota688_extra_wind_walk" },
	npc_dota_hero_juggernaut = { "modifier_dota688_extra_blade_fury" },
	npc_dota_hero_earth_spirit = { "modifier_dota688_extra_boulder_smash" },
	npc_dota_hero_doom_bringer = { "modifier_dota688_extra_devour" },
}
-- apelat din gamemode la npc_spawned, pentru orice unitate (eroi, iluzii, invocari)
function Dota688Extras.OnSpawned(unit)
	local name = unit:GetUnitName()
	if name == MISSILE then Dota688Extras.TrackMissile(unit) return end
	local list = HERO_EXTRAS[name]
	if string.find(name, "npc_dota_shadow_shaman_ward", 1, true) == 1 then list = { "modifier_dota688_extra_ward_splash" } end
	if string.find(name, "npc_dota_brewmaster_earth_", 1, true) == 1 then list = { "modifier_dota688_extra_spell_immunity" } end
	if not list then return end
	for _, m in ipairs(list) do
		if not unit:HasModifier(m) then unit:AddNewModifier(unit, nil, m, {}) end
	end
end
