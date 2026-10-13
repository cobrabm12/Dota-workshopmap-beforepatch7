-- Track (6.88, ultimate): marcheaza un erou inamic 30 s (si prin imunitate): echipa lui Bounty Hunter il vede si are
-- True Sight pe el, iar buff-ul arata aurul pe care il are. Eroii aliati aflati la cel mult 900 de tinta primesc
-- +16/18/20% viteza de miscare. Daca tinta moare (oricum) cat e marcata: Bounty Hunter primeste 150/250/350 aur,
-- iar eroii aliati din raza 925 a tintei cate 40/80/120 aur (aur sigur). Marcajul e vizibil doar aliatilor lui BH.
require("dota688/val")
local F = "abilities/heroes/dota688_bounty_hunter_track"
LinkLuaModifier("modifier_dota688_bounty_hunter_track", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_bounty_hunter_track_effect", F, LUA_MODIFIER_MOTION_NONE)
dota688_bounty_hunter_track = class({})

function dota688_bounty_hunter_track:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if target:TriggerSpellAbsorb(self) then return end
	caster:EmitSound("Hero_BountyHunter.Target")
	local fx = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_cast.vpcf", PATTACH_CUSTOMORIGIN, caster, caster:GetTeamNumber())
	ParticleManager:SetParticleControlEnt(fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack2", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
	target:AddNewModifier(caster, self, "modifier_dota688_bounty_hunter_track", { duration = self:GetSpecialValueFor("duration") })
end

local function give_gold(hero, amount)
	local pid = hero:GetPlayerOwnerID()
	if amount <= 0 or not pid or pid < 0 then return end
	Dota688GiveGold(pid, amount, true, DOTA_ModifyGold_AbilityGold)
	SendOverheadEventMessage(nil, OVERHEAD_ALERT_GOLD, hero, amount, nil)
end

modifier_dota688_bounty_hunter_track = class({})
function modifier_dota688_bounty_hunter_track:IsDebuff() return true end
-- vizibil doar echipei lui Bounty Hunter
function modifier_dota688_bounty_hunter_track:IsHidden()
	if IsServer() then return false end
	local caster = self:GetCaster()
	return caster == nil or GetLocalPlayerTeam() ~= caster:GetTeamNumber()
end
function modifier_dota688_bounty_hunter_track:IsPurgable() return false end
function modifier_dota688_bounty_hunter_track:GetPriority() return MODIFIER_PRIORITY_SUPER_ULTRA end
function modifier_dota688_bounty_hunter_track:OnCreated()
	if not IsServer() then return end
	local p, caster = self:GetParent(), self:GetCaster()
	self.fx = ParticleManager:CreateParticleForTeam("particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_shield.vpcf", PATTACH_OVERHEAD_FOLLOW, p, caster:GetTeamNumber())
	self:AddParticle(self.fx, false, false, -1, false, true)
	self:OnIntervalThink()
	self:StartIntervalThink(0.25)
end
function modifier_dota688_bounty_hunter_track:OnIntervalThink()
	local p, caster = self:GetParent(), self:GetCaster()
	local pid = p:GetPlayerOwnerID()
	if pid and pid >= 0 then self:SetStackCount(PlayerResource:GetGold(pid)) end
	if not caster or caster:IsNull() or not p:IsAlive() then return end
	-- viziune pe tinta (pe langa MODIFIER_STATE_PROVIDES_VISION)
	AddFOWViewer(caster:GetTeamNumber(), p:GetAbsOrigin(), 64, 0.3, false)
	-- haste pentru eroii aliati ai lui BH din jurul tintei
	for _, ally in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), p:GetAbsOrigin(), nil, Dota688Val(self, "aura_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)) do
		ally:AddNewModifier(caster, self:GetAbility(), "modifier_dota688_bounty_hunter_track_effect", { duration = 0.5 })
	end
end
function modifier_dota688_bounty_hunter_track:CheckState()
	return { [MODIFIER_STATE_INVISIBLE] = false, [MODIFIER_STATE_PROVIDES_VISION] = true }
end
function modifier_dota688_bounty_hunter_track:DeclareFunctions() return { MODIFIER_PROPERTY_TOOLTIP, MODIFIER_EVENT_ON_DEATH } end
function modifier_dota688_bounty_hunter_track:OnTooltip() return self:GetStackCount() end
function modifier_dota688_bounty_hunter_track:OnDeath(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	local p, caster = self:GetParent(), self:GetCaster()
	if not p:IsRealHero() or p:IsReincarnating() or not caster or caster:IsNull() then return end
	give_gold(caster, Dota688Val(self, "bonus_gold_self"))
	local paid = { [caster:GetPlayerOwnerID()] = true }
	local bonus = Dota688Val(self, "bonus_gold")
	for _, ally in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), p:GetAbsOrigin(), nil, Dota688Val(self, "bonus_gold_radius"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)) do
		local pid = ally:GetPlayerOwnerID()
		if ally:IsRealHero() and pid and pid >= 0 and not paid[pid] then
			paid[pid] = true
			give_gold(ally, bonus)
		end
	end
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_reward.vpcf", PATTACH_ABSORIGIN, p)
	ParticleManager:ReleaseParticleIndex(fx)
end

modifier_dota688_bounty_hunter_track_effect = class({})
function modifier_dota688_bounty_hunter_track_effect:IsPurgable() return false end
function modifier_dota688_bounty_hunter_track_effect:GetTexture() return "bounty_hunter_track" end
function modifier_dota688_bounty_hunter_track_effect:GetEffectName() return "particles/units/heroes/hero_bounty_hunter/bounty_hunter_track_haste.vpcf" end
function modifier_dota688_bounty_hunter_track_effect:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_bounty_hunter_track_effect:OnCreated() self.ms = Dota688Val(self, "bonus_move_speed_pct") end
function modifier_dota688_bounty_hunter_track_effect:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_bounty_hunter_track_effect:GetModifierMoveSpeedBonus_Percentage() return self.ms end
