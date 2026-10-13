-- Mecanici 6.88 ale unor abilitati built-in pe care motorul curent nu le mai are (gasite de verificarea din 13.10.2026).
-- Valorile se citesc din KV-ul abilitatii: generatorul pastreaza cheile 6.88 disparute in AbilityValues (motorul le ignora).
--   Morph (Morphling): pasiv +3/4/5/6 Agility si Strength.
--   Mass Serpent Ward: daune splash 100% pe 175 in jurul tintei.
--   Phantom Strike: bonusul de viteza de atac tine maxim 4 atacuri.
--   Corrosive Skin: atacatorul e incetinit si la miscare (-10/15/20/25%), nu doar la atac.
--   Thunder Clap: creepii raman incetiniti 8 s (eroii 4 s).
--   Reverse Polarity: creepii sunt stunati 3/4/5 s (eroii 2.25/3/3.75 s).
--   Earth Brewling (Primal Split): Spell Immunity = imun la vraji (motorul curent da doar 60% rezistenta la magie).
Dota688Extras = Dota688Extras or {}
local F = "dota688/extras_688"
LinkLuaModifier("modifier_dota688_extra_morph", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_ward_splash", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_phantom_strike", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_corrosive", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_corrosive_slow", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_creep_duration", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_extra_spell_immunity", F, LUA_MODIFIER_MOTION_NONE)

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
	local radius = ability:GetSpecialValueFor(cfg.radius) + 200
	if dur <= 0 then return end
	Dota688Timers:After(0.1, function()
		if caster:IsNull() then return end
		for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)) do
			if not u:IsConsideredHero() then
				for _, m in ipairs(u:FindAllModifiersByName(cfg.modifier)) do
					if m:GetCaster() == caster then m:SetDuration(dur, true) end
				end
			end
		end
	end)
end

------------------------------------------------------------------------------------------------
-- Earth Brewling: imunitate la vraji permanenta (6.88: "Immune to spells.")
modifier_dota688_extra_spell_immunity = hidden(class({}))
function modifier_dota688_extra_spell_immunity:CheckState() return { [MODIFIER_STATE_MAGIC_IMMUNE] = true } end

------------------------------------------------------------------------------------------------
local HERO_EXTRAS = {
	npc_dota_hero_morphling = { "modifier_dota688_extra_morph" },
	npc_dota_hero_phantom_assassin = { "modifier_dota688_extra_phantom_strike" },
	npc_dota_hero_viper = { "modifier_dota688_extra_corrosive" },
	npc_dota_hero_brewmaster = { "modifier_dota688_extra_creep_duration" },
	npc_dota_hero_magnataur = { "modifier_dota688_extra_creep_duration" },
}
-- apelat din gamemode la npc_spawned, pentru orice unitate (eroi, iluzii, invocari)
function Dota688Extras.OnSpawned(unit)
	local name = unit:GetUnitName()
	local list = HERO_EXTRAS[name]
	if string.find(name, "npc_dota_shadow_shaman_ward", 1, true) == 1 then list = { "modifier_dota688_extra_ward_splash" } end
	if string.find(name, "npc_dota_brewmaster_earth_", 1, true) == 1 then list = { "modifier_dota688_extra_spell_immunity" } end
	if not list then return end
	for _, m in ipairs(list) do
		if not unit:HasModifier(m) then unit:AddNewModifier(unit, nil, m, {}) end
	end
end
