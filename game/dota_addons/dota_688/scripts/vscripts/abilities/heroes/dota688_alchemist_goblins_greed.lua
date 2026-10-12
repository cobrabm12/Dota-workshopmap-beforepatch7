-- Greevil's Greed (6.88): +6/8/10/12 aur bonus la fiecare unitate ucisa, +3 pentru fiecare kill recent (30 s), max 12/20/28/36; runele Bounty x3/4/5/6 (gestionat in runes.lua).
LinkLuaModifier("modifier_dota688_alchemist_goblins_greed", "abilities/heroes/dota688_alchemist_goblins_greed", LUA_MODIFIER_MOTION_NONE)
dota688_alchemist_goblins_greed = class({})
function dota688_alchemist_goblins_greed:GetIntrinsicModifierName() return "modifier_dota688_alchemist_goblins_greed" end
modifier_dota688_alchemist_goblins_greed = class({})
function modifier_dota688_alchemist_goblins_greed:IsHidden() return false end
function modifier_dota688_alchemist_goblins_greed:IsPurgable() return false end
function modifier_dota688_alchemist_goblins_greed:RemoveOnDeath() return false end
function modifier_dota688_alchemist_goblins_greed:OnCreated() self.kills = {} end
function modifier_dota688_alchemist_goblins_greed:DeclareFunctions() return { MODIFIER_EVENT_ON_DEATH } end
function modifier_dota688_alchemist_goblins_greed:OnDeath(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	if params.attacker ~= parent or parent:PassivesDisabled() then return end
	local u = params.unit
	if not u or u:IsBuilding() or u:IsOther() or u:IsIllusion() or u:GetTeamNumber() == parent:GetTeamNumber() then return end
	local a, now = self:GetAbility(), GameRules:GetGameTime()
	local kept = {}
	for _, t in ipairs(self.kills or {}) do if now - t < a:GetSpecialValueFor("duration") then table.insert(kept, t) end end
	local gold = math.min(a:GetSpecialValueFor("bonus_gold_cap"), a:GetSpecialValueFor("bonus_gold") + a:GetSpecialValueFor("bonus_bonus_gold") * #kept)
	table.insert(kept, now); self.kills = kept; self:SetStackCount(#kept)
	local pid = parent:GetPlayerOwnerID()
	if pid >= 0 then
		PlayerResource:ModifyGold(pid, gold, false, DOTA_ModifyGold_AbilityGold)
		SendOverheadEventMessage(parent:GetPlayerOwner(), OVERHEAD_ALERT_GOLD, parent, gold, nil)
	end
end
