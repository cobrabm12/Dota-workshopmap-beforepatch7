-- Baza itemelor reimplementate (6.88). Un item isi citeste statisticile din AbilitySpecial-ul original
-- (reference/6.88f/items.txt, generat in npc_items_generated.txt) prin numele standard ale valorilor.
--
-- Utilizare intr-un fisier items/item_dota688_x.lua:
--   require("items/dota688_item_base")
--   Dota688DefineItem("item_dota688_x", "items/item_dota688_x", { ...optional overrides... })
-- Rezulta clasele globale item_dota688_x si modifier_item_dota688_x (intrinsec, stackabil per item: MULTIPLE).

-- cheile 6.88 -> functia de modifier
local STAT_MAP = {
	bonus_strength   = { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, "GetModifierBonusStats_Strength" },
	bonus_str        = { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, "GetModifierBonusStats_Strength" },
	bonus_agility    = { MODIFIER_PROPERTY_STATS_AGILITY_BONUS, "GetModifierBonusStats_Agility" },
	bonus_agi        = { MODIFIER_PROPERTY_STATS_AGILITY_BONUS, "GetModifierBonusStats_Agility" },
	bonus_intellect  = { MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, "GetModifierBonusStats_Intellect" },
	bonus_intelligence = { MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, "GetModifierBonusStats_Intellect" },
	bonus_int        = { MODIFIER_PROPERTY_STATS_INTELLECT_BONUS, "GetModifierBonusStats_Intellect" },
	bonus_damage     = { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, "GetModifierPreAttack_BonusDamage" },
	bonus_armor      = { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, "GetModifierPhysicalArmorBonus" },
	bonus_attack_speed = { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, "GetModifierAttackSpeedBonus_Constant" },
	bonus_health     = { MODIFIER_PROPERTY_HEALTH_BONUS, "GetModifierHealthBonus" },
	bonus_mana       = { MODIFIER_PROPERTY_MANA_BONUS, "GetModifierManaBonus" },
	bonus_health_regen = { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, "GetModifierConstantHealthRegen" },
	hp_regen         = { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, "GetModifierConstantHealthRegen" },
	health_regen     = { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, "GetModifierConstantHealthRegen" },
	bonus_movement_speed = { MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, "GetModifierMoveSpeedBonus_Constant" },
	bonus_movement   = { MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, "GetModifierMoveSpeedBonus_Constant" },
	movement_speed   = { MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, "GetModifierMoveSpeedBonus_Constant" },
	movement_speed_percent_bonus = { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE_UNIQUE, "GetModifierMoveSpeedBonus_Percentage_Unique" },
	bonus_evasion    = { MODIFIER_PROPERTY_EVASION_CONSTANT, "GetModifierEvasion_Constant" },
	bonus_magical_armor = { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, "GetModifierMagicalResistanceBonus" },
	magic_resistance = { MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, "GetModifierMagicalResistanceBonus" },
	cast_range_bonus = { MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING, "GetModifierCastRangeBonusStacking" },
	spell_amp        = { MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE, "GetModifierSpellAmplify_Percentage" },
	bonus_attack_range = { MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, "GetModifierAttackRangeBonus" },
}
-- "bonus_all_stats" se adauga la toate cele 3 atribute
-- "bonus_mana_regen" / "mana_regen" (6.88) = procent din regenerarea de baza (0.01 + 0.04 x INT); "mana_regen_flat" = valoare fixa
-- "lifesteal_percent" = lifesteal pe atacuri

-- Cand itemul dispare (vandut, aruncat, combinat), efectele aurei/buff-urile lui mai raman putin pe unitati si
-- GetAbility() intoarce nil (testat: zeci de "attempt to index a nil value" la Vladmir, Pipe, Drums, Shiva...).
-- Callback-urile din configurarile itemelor sunt invelite: fara item, getter-ele dau 0, CheckState nimic.
function Dota688GuardItemFn(key, fn)
	if type(fn) ~= "function" then return fn end
	return function(self, ...)
		local a = self:GetAbility()
		if a == nil or a:IsNull() then
			if key == "CheckState" then return {} end
			if string.sub(key, 1, 3) == "Get" then return 0 end
			return nil
		end
		return fn(self, ...)
	end
end

function Dota688ManaRegenFromPct(unit, pct)
	-- regenerarea "de baza" din 6.88 la care se aplica procentele itemelor
	local int = unit.GetIntellect and unit:GetIntellect(true) or 0
	return (0.01 + 0.04 * int) * pct / 100
end

function Dota688DefineItem(itemName, scriptPath, opts)
	opts = opts or {}
	local modName = "modifier_" .. itemName
	local item = class({})
	_G[itemName] = item
	function item:GetIntrinsicModifierName() return modName end
	if opts.item then for k, v in pairs(opts.item) do item[k] = v end end

	local mod = class({})
	_G[modName] = mod
	function mod:IsHidden() return true end
	function mod:IsPurgable() return false end
	function mod:RemoveOnDeath() return false end
	function mod:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
	function mod:OnCreated()
		self:ReadStats()
		if opts.onCreated then opts.onCreated(self) end
	end
	function mod:OnRefresh() self:ReadStats() end
	function mod:ReadStats()
		local a = self:GetAbility()
		self.stats = {}
		if not a or a:IsNull() then return end
		for key, def in pairs(STAT_MAP) do
			local v = a:GetSpecialValueFor(key)
			if v ~= 0 then self.stats[def[2]] = (self.stats[def[2]] or 0) + v end
		end
		local all = a:GetSpecialValueFor("bonus_all_stats")
		if all ~= 0 then
			for _, f in ipairs({ "GetModifierBonusStats_Strength", "GetModifierBonusStats_Agility", "GetModifierBonusStats_Intellect" }) do
				self.stats[f] = (self.stats[f] or 0) + all
			end
		end
		self.manaRegenPct = a:GetSpecialValueFor("bonus_mana_regen") + a:GetSpecialValueFor("mana_regen")
		self.manaRegenFlat = a:GetSpecialValueFor("mana_regen_flat")
		self.lifesteal = a:GetSpecialValueFor("lifesteal_percent")
	end
	function mod:DeclareFunctions()
		local funcs = { MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, MODIFIER_EVENT_ON_ATTACK_LANDED }
		for _, def in pairs(STAT_MAP) do table.insert(funcs, def[1]) end
		if opts.extraFunctions then for _, f in ipairs(opts.extraFunctions) do table.insert(funcs, f) end end
		if opts.boots then table.insert(funcs, MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE) end
		return funcs
	end
	for _, def in pairs(STAT_MAP) do
		local fname = def[2]
		if not mod[fname] then
			mod[fname] = function(self) return (self.stats and self.stats[fname]) or 0 end
		end
	end
	-- cizme (opts.boots): viteza de miscare a cizmelor nu se aduna intre ele (6.88), deci bonusul fix trece pe
	-- proprietatea "unica" a cizmelor in locul celei constante
	if opts.boots then
		mod.GetModifierMoveSpeedBonus_Constant = function() return 0 end
		mod.GetModifierMoveSpeedBonus_Special_Boots = function(self) return (self.stats and self.stats.GetModifierMoveSpeedBonus_Constant) or 0 end
	end
	function mod:GetModifierConstantManaRegen()
		local v = self.manaRegenFlat or 0
		if self.manaRegenPct and self.manaRegenPct ~= 0 then v = v + Dota688ManaRegenFromPct(self:GetParent(), self.manaRegenPct) end
		if opts.manaRegen then v = v + opts.manaRegen(self) end
		return v
	end
	function mod:OnAttackLanded(params)
		if not IsServer() then return end
		local parent = self:GetParent()
		if params.attacker ~= parent then return end
		local target = params.target
		if self.lifesteal and self.lifesteal > 0 and target and not target:IsBuilding() and not target:IsOther() then
			parent:Heal(params.damage * self.lifesteal / 100, self:GetAbility())
			local fx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
			ParticleManager:ReleaseParticleIndex(fx)
		end
		if opts.onAttackLanded and self:GetAbility() and not self:GetAbility():IsNull() then opts.onAttackLanded(self, params) end
	end
	if opts.modifier then for k, v in pairs(opts.modifier) do mod[k] = Dota688GuardItemFn(k, v) end end
	LinkLuaModifier(modName, scriptPath, LUA_MODIFIER_MOTION_NONE)
	return item, mod
end

-- Aura generica (ex. Vladmir, Basilius, Headdress): defineste modifier-ul de aura + efectul.
function Dota688DefineAura(name, scriptPath, cfg)
	local auraMod = class({})
	_G[name] = auraMod
	function auraMod:IsHidden() return true end
	function auraMod:IsPurgable() return false end
	function auraMod:RemoveOnDeath() return false end
	function auraMod:IsAura() return true end
	function auraMod:GetAuraRadius() local a = self:GetAbility(); if not a or a:IsNull() then return 0 end; return cfg.radius(self) end
	function auraMod:GetAuraSearchTeam() return cfg.team or DOTA_UNIT_TARGET_TEAM_FRIENDLY end
	function auraMod:GetAuraSearchType() return cfg.types or (DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC) end
	function auraMod:GetModifierAura() return name .. "_effect" end
	function auraMod:GetAuraDuplicateModifier() return name .. "_effect" end
	if cfg.reject then auraMod.GetAuraEntityReject = cfg.reject end
	local eff = class({})
	_G[name .. "_effect"] = eff
	function eff:IsHidden() return cfg.hiddenEffect or false end
	function eff:IsPurgable() return false end
	function eff:IsDebuff() return cfg.debuff or false end
	function eff:DeclareFunctions() return cfg.functions end
	for k, v in pairs(cfg.effect) do eff[k] = Dota688GuardItemFn(k, v) end
	LinkLuaModifier(name, scriptPath, LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier(name .. "_effect", scriptPath, LUA_MODIFIER_MOTION_NONE)
	return auraMod, eff
end
