require("items/dota688_item_base")
-- Boots of Travel 1/2 (6.88): +100 viteza (bonusurile cizmelor nu se cumuleaza intre ele).
-- Teleport: channel 3 s, 75 mana, cd 45, cooldown comun cu TP-ul (in ambele sensuri).
--   Nivel 1: la o unitate non-erou aliata (creep, unitate controlata) sau la o cladire aliata.
--   Nivel 2: si la eroii aliati.
--   Click pe teren = tinta valida cea mai apropiata de punct; dublu-click (pe erou) = fantana echipei.
--   Destinatia urmareste unitatea tinta; daca tinta moare in timpul channel-ului, teleportul esueaza
--   (mana si cooldown-ul raman consumate). La o cladire: punctul ales, la 70-575 de cladire (ca TP-ul 6.88).
-- Nu foloseste slotul dedicat de TP al motorului curent (TP-urile stau in sloturi normale, dota688/backpack.lua).

LinkLuaModifier("modifier_dota688_travel_thinker", "items/item_dota688_travel_boots", LUA_MODIFIER_MOTION_NONE)

local TP_SCROLLS = { item_tpscroll = true, item_dota688_tpscroll = true }
local TELEPORT_ITEMS = { item_tpscroll = true, item_dota688_tpscroll = true, item_dota688_travel_boots = true, item_dota688_travel_boots_2 = true }
local BUILDING_MIN = 70    -- minimun_distance al TP-ului 6.88
local BUILDING_MAX = 575   -- maximum_distance al TP-ului 6.88
local SELF_CAST_RADIUS = 50                  -- dublu-click pe un ability de tip punct = punctul eroului

local function ValidTarget(self, unit)
	local caster = self:GetCaster()
	if unit == nil or unit:IsNull() or unit == caster then return false end
	if unit.IsAlive and not unit:IsAlive() then return false end
	if UnitFilter(unit, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_BUILDING,
		DOTA_UNIT_TARGET_FLAG_INVULNERABLE, caster:GetTeamNumber()) ~= UF_SUCCESS then return false end
	if unit:IsCourier() or unit:IsOther() then return false end
	-- minele / semnul Techies sunt unitati Lua de tip creep in addon; in 6.88 nu erau tinte de teleport
	if string.find(unit:GetUnitName(), "npc_dota688_techies_", 1, true) == 1 then return false end
	if unit:IsHero() and not self.dota688_tp_heroes then return false end
	return true
end

local function Nearest(self, point)
	local caster = self:GetCaster()
	local units = FindUnitsInRadius(caster:GetTeamNumber(), point, nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_CREEP + DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_CLOSEST, false)
	for _, u in ipairs(units) do
		if ValidTarget(self, u) then return u end
	end
	return nil
end

local function Fountain(team)
	for _, f in ipairs(Entities:FindAllByClassname("ent_dota_fountain")) do
		if f:GetTeamNumber() == team then return f end
	end
	return nil
end

local function BuildingSpot(building, point)
	local bpos = building:GetAbsOrigin()
	local d = point - bpos
	d.z = 0
	local len = d:Length2D()
	if len < 1 then return bpos end
	return bpos + d:Normalized() * math.min(math.max(len, BUILDING_MIN), BUILDING_MAX)
end

local function ShareCooldown(unit, src, cd)
	if cd == nil or cd <= 0 then return end
	for s = DOTA_ITEM_SLOT_1, DOTA_ITEM_TP_SCROLL do
		local it = unit:GetItemInSlot(s)
		if it and it ~= src and TELEPORT_ITEMS[it:GetAbilityName()] and it:GetCooldownTimeRemaining() < cd then
			it:EndCooldown()
			it:StartCooldown(cd)
		end
	end
end

local function Minimap(caster, pos, ally, enemy, duration)
	local team = caster:GetTeamNumber()
	for _, t in ipairs({ DOTA_TEAM_GOODGUYS, DOTA_TEAM_BADGUYS }) do
		MinimapEvent(t, caster, math.floor(pos.x), math.floor(pos.y), t == team and ally or enemy, duration)
	end
end

local function Cleanup(self, tp)
	local caster = self:GetCaster()
	caster:StopSound("Portal.Loop_Disappear")
	if tp.fx then
		ParticleManager:DestroyParticle(tp.fx, false)
		ParticleManager:ReleaseParticleIndex(tp.fx)
	end
	if tp.thinker and not tp.thinker:IsNull() then
		local m = tp.thinker:FindModifierByName("modifier_dota688_travel_thinker")
		if m then m:Destroy() else UTIL_Remove(tp.thinker) end
	end
end

local ITEM = {
	GetBehavior = function(self)
		-- KV 6.88 are si NO_TARGET (dublu-click in motorul vechi); in motorul curent ar transforma itemul in cast instant
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_CHANNELLED + DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK
	end,
	CastFilterResultTarget = function(self, target)
		if target == self:GetCaster() then return UF_SUCCESS end   -- dublu-click: fantana
		if ValidTarget(self, target) then return UF_SUCCESS end
		if target:GetTeamNumber() ~= self:GetCaster():GetTeamNumber() then return UF_FAIL_ENEMY end
		if target:IsHero() and not self.dota688_tp_heroes then return UF_FAIL_HERO end
		return UF_FAIL_CUSTOM
	end,
	GetCustomCastErrorTarget = function(self, target) return "#dota_hud_error_cant_cast_on_other" end,
	OnSpellStart = function(self)
		local caster = self:GetCaster()
		local team = caster:GetTeamNumber()
		local target = self:GetCursorTarget()
		local point = self:GetCursorPosition()
		local tp = {}
		self.dota688_tp = tp

		local unit
		if target == caster or (target == nil and (point - caster:GetAbsOrigin()):Length2D() < SELF_CAST_RADIUS) then
			unit = Fountain(team)
			if unit then tp.pos = unit:GetAbsOrigin() end
		else
			local direct = target ~= nil and ValidTarget(self, target)
			unit = direct and target or Nearest(self, point)
			if unit then
				if unit:IsBuilding() then
					tp.pos = BuildingSpot(unit, direct and unit:GetAbsOrigin() or point)
				else
					tp.follow = true
					tp.pos = unit:GetAbsOrigin()
				end
			end
		end
		if not unit then
			-- nicio destinatie (nu ar trebui sa se intample: fantana e mereu o cladire valida)
			tp.fail = true
			self:EndCooldown()
			self:RefundManaCost()
			return
		end
		tp.unit = unit
		ShareCooldown(caster, self, self:GetCooldownTimeRemaining())

		local channel = self:GetChannelTime()
		caster:EmitSound("Portal.Loop_Disappear")
		tp.fx = ParticleManager:CreateParticle("particles/items2_fx/teleport_start.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(tp.fx, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(tp.fx, 2, Vector(255, 255, 255))
		tp.thinker = CreateModifierThinker(caster, self, "modifier_dota688_travel_thinker", { duration = channel + 1 }, tp.pos, team, false)
		Minimap(caster, tp.pos, DOTA_MINIMAP_EVENT_TEAMMATE_TELEPORTING, DOTA_MINIMAP_EVENT_ENEMY_TELEPORTING, math.ceil(channel))
	end,
	OnChannelThink = function(self, interval)
		local tp = self.dota688_tp
		if not tp then return end
		local caster = self:GetCaster()
		if tp.fail or (tp.unit and (tp.unit:IsNull() or not tp.unit:IsAlive())) then
			caster:InterruptChannel()
			return
		end
		if tp.follow then
			tp.pos = tp.unit:GetAbsOrigin()
			if tp.thinker and not tp.thinker:IsNull() then
				local m = tp.thinker:FindModifierByName("modifier_dota688_travel_thinker")
				if m then m:MoveTo(tp.pos) end
			end
		end
	end,
	OnChannelFinish = function(self, interrupted)
		local tp = self.dota688_tp
		self.dota688_tp = nil
		if not tp then return end
		local caster = self:GetCaster()
		Cleanup(self, tp)
		if tp.fail then return end
		local dead = tp.unit == nil or tp.unit:IsNull() or not tp.unit:IsAlive()
		if interrupted or dead then
			Minimap(caster, tp.pos, DOTA_MINIMAP_EVENT_CANCEL_TELEPORTING, DOTA_MINIMAP_EVENT_CANCEL_TELEPORTING, 1)
			return
		end
		local dest = tp.follow and tp.unit:GetAbsOrigin() or tp.pos
		EmitSoundOnLocationWithCaster(caster:GetAbsOrigin(), "Portal.Hero_Disappear", caster)
		ProjectileManager:ProjectileDodge(caster)
		FindClearSpaceForUnit(caster, dest, true)
		caster:Stop()
		caster:EmitSound("Portal.Hero_Appear")
	end,
}

local function Define(name, heroes)
	local item = {}
	for k, v in pairs(ITEM) do item[k] = v end
	item.dota688_tp_heroes = heroes
	Dota688DefineItem(name, "items/item_dota688_travel_boots", {
		extraFunctions = { MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE, MODIFIER_EVENT_ON_ABILITY_EXECUTED },
		modifier = {
			-- viteza cizmelor: unica (cea mai mare dintre cizme), nu constanta cumulabila
			GetModifierMoveSpeedBonus_Constant = function(self) return 0 end,
			GetModifierMoveSpeedBonus_Special_Boots = function(self) return self:GetAbility():GetSpecialValueFor("bonus_movement_speed") end,
			-- cooldown comun: TP-ul folosit de purtator pune si BoT pe cooldown
			OnAbilityExecuted = function(self, params)
				if not IsServer() or params.unit ~= self:GetParent() then return end
				local used = params.ability
				if used == nil or used:IsNull() or used == self:GetAbility() or not TP_SCROLLS[used:GetAbilityName()] then return end
				local cd = math.max(used:GetCooldownTimeRemaining(), used:GetEffectiveCooldown(used:GetLevel() - 1))
				local a = self:GetAbility()
				if a:GetCooldownTimeRemaining() < cd then
					a:EndCooldown()
					a:StartCooldown(cd)
				end
			end,
		},
		item = item,
	})
end
Define("item_dota688_travel_boots", false)
Define("item_dota688_travel_boots_2", true)

-- punctul de sosire: particula + sunetul de la destinatie (urmareste unitatea tinta)
modifier_dota688_travel_thinker = class({})
function modifier_dota688_travel_thinker:IsHidden() return true end
function modifier_dota688_travel_thinker:IsPurgable() return false end
function modifier_dota688_travel_thinker:OnCreated()
	if not IsServer() then return end
	self.fx = ParticleManager:CreateParticle("particles/items2_fx/teleport_end.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.fx, 2, Vector(255, 255, 255))
	self:MoveTo(self:GetParent():GetAbsOrigin())
	self:GetParent():EmitSound("Portal.Loop_Appear")
end
function modifier_dota688_travel_thinker:MoveTo(pos)
	self:GetParent():SetAbsOrigin(pos)
	ParticleManager:SetParticleControl(self.fx, 0, pos)
	ParticleManager:SetParticleControl(self.fx, 1, pos)
end
function modifier_dota688_travel_thinker:OnDestroy()
	if not IsServer() then return end
	local p = self:GetParent()
	p:StopSound("Portal.Loop_Appear")
	ParticleManager:DestroyParticle(self.fx, false)
	ParticleManager:ReleaseParticleIndex(self.fx)
	UTIL_Remove(p)
end
