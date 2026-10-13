-- Phantom Rush (6.88, pasiv): cand primeste ordin de atac pe un inamic aflat la 300-600/700/800/900, Phantom Lancer (si
-- iluziile lui) alearga spre el cu +800 viteza (peste limita de viteza) pana ajunge in raza de atac; cooldown 16/12/8/4.
-- Un ordin nou anuleaza viteza. Abilitatea curenta (toggle, cu evaziune) nu se declanseaza in addon (testat).
require("dota688/val")
local F = "abilities/heroes/dota688_phantom_lancer_phantom_edge"
LinkLuaModifier("modifier_dota688_phantom_edge", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_phantom_edge_rush", F, LUA_MODIFIER_MOTION_NONE)

dota688_phantom_lancer_phantom_edge = class({})
function dota688_phantom_lancer_phantom_edge:GetIntrinsicModifierName() return "modifier_dota688_phantom_edge" end

modifier_dota688_phantom_edge = class({})
function modifier_dota688_phantom_edge:IsHidden() return true end
function modifier_dota688_phantom_edge:IsPurgable() return false end
function modifier_dota688_phantom_edge:RemoveOnDeath() return false end
function modifier_dota688_phantom_edge:DeclareFunctions() return { MODIFIER_EVENT_ON_ORDER } end
function modifier_dota688_phantom_edge:OnOrder(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	local p, a = self:GetParent(), self:GetAbility()
	local rush = p:FindModifierByName("modifier_dota688_phantom_edge_rush")
	local t = params.target
	if params.order_type ~= DOTA_UNIT_ORDER_ATTACK_TARGET or not t then
		if rush then rush:Destroy() end   -- ordinul de atac a fost anulat
		return
	end
	if rush and rush.target == t then return end
	if rush then rush:Destroy() end
	if not a or a:GetLevel() < 1 or not a:IsCooldownReady() or p:PassivesDisabled() or t:GetTeamNumber() == p:GetTeamNumber() then return end
	local d = (t:GetAbsOrigin() - p:GetAbsOrigin()):Length2D()
	if d < a:GetSpecialValueFor("min_distance") or d > a:GetSpecialValueFor("max_distance") then return end
	a:StartCooldown(a:GetEffectiveCooldown(a:GetLevel() - 1))
	local m = p:AddNewModifier(p, a, "modifier_dota688_phantom_edge_rush", { duration = 3 })
	if m then m.target = t end
	p:EmitSound("Hero_PhantomLancer.PhantomEdge")
end

-- viteza de rush, pana la primul atac (sau un ordin nou)
modifier_dota688_phantom_edge_rush = class({})
function modifier_dota688_phantom_edge_rush:IsPurgable() return true end
function modifier_dota688_phantom_edge_rush:GetTexture() return "phantom_lancer_phantom_edge" end
function modifier_dota688_phantom_edge_rush:GetEffectName() return "particles/units/heroes/hero_phantom_lancer/phantomlancer_edge_boost.vpcf" end
function modifier_dota688_phantom_edge_rush:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT, MODIFIER_EVENT_ON_ATTACK_START }
end
function modifier_dota688_phantom_edge_rush:GetModifierMoveSpeedBonus_Constant() return Dota688Val(self, "bonus_speed") end
function modifier_dota688_phantom_edge_rush:GetModifierIgnoreMovespeedLimit() return 1 end
function modifier_dota688_phantom_edge_rush:OnAttackStart(params)
	if IsServer() and params.attacker == self:GetParent() then self:Destroy() end
end
