-- Eyes in the Forest (6.88, oferita de scepter): vrajeste un copac, care da viziune neobstructionata 800 in jur.
-- Cand Treant foloseste Overgrowth, inamicii din 800 de fiecare copac vrajit sunt prinsi (Overgrowth) si iau 175 daune magice/s.
require("dota688/val")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_treant_eyes_in_the_forest"
LinkLuaModifier("modifier_dota688_treant_eye", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_treant_eyes_passive", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_treant_eyes_burn", F, LUA_MODIFIER_MOTION_NONE)
dota688_treant_eyes_in_the_forest = class({})
function dota688_treant_eyes_in_the_forest:GetIntrinsicModifierName() return "modifier_dota688_treant_eyes_passive" end
function dota688_treant_eyes_in_the_forest:Eyes()
	self.eyes = self.eyes or {}
	local alive = {}
	for _, e in ipairs(self.eyes) do if not e:IsNull() and e:IsAlive() then table.insert(alive, e) end end
	self.eyes = alive
	return alive
end
function dota688_treant_eyes_in_the_forest:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	local eye = CreateUnitByName("npc_dota688_treant_eyes", pos, false, caster, caster:GetPlayerOwner(), caster:GetTeamNumber())
	if not eye then return end
	eye:SetOwner(caster)
	eye:AddNewModifier(caster, self, "modifier_dota688_treant_eye", {})
	caster:EmitSound("Hero_Treant.Eyes.Cast")
	table.insert(self:Eyes(), eye)
end
modifier_dota688_treant_eye = class({})
function modifier_dota688_treant_eye:IsHidden() return true end
function modifier_dota688_treant_eye:IsPurgable() return false end
function modifier_dota688_treant_eye:OnCreated()
	if not IsServer() then return end
	local p = self:GetParent()
	p:SetDayTimeVisionRange(Dota688Val(self, "vision_aoe"))
	p:SetNightTimeVisionRange(Dota688Val(self, "vision_aoe"))
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_eyesintheforest.vpcf", PATTACH_ABSORIGIN_FOLLOW, p)
end
function modifier_dota688_treant_eye:OnDestroy() if IsServer() then ParticleManager:DestroyParticle(self.fx, false) end end
function modifier_dota688_treant_eye:CheckState()
	return { [MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_DISARMED] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true, [MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_INVULNERABLE] = true, [MODIFIER_STATE_UNSELECTABLE] = true, [MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true, [MODIFIER_STATE_FORCED_FLYING_VISION] = true }
end
-- pe Treant: Overgrowth in jurul ochilor
modifier_dota688_treant_eyes_passive = class({})
function modifier_dota688_treant_eyes_passive:IsHidden() return true end
function modifier_dota688_treant_eyes_passive:IsPurgable() return false end
function modifier_dota688_treant_eyes_passive:RemoveOnDeath() return false end
function modifier_dota688_treant_eyes_passive:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_FULLY_CAST } end
function modifier_dota688_treant_eyes_passive:OnAbilityFullyCast(params)
	if not IsServer() or params.unit ~= self:GetParent() or params.ability:GetName() ~= "treant_overgrowth" then return end
	local p, a, over = self:GetParent(), self:GetAbility(), params.ability
	if not Dota688HasScepter(p) or a:GetLevel() < 1 then return end
	local dur = over:GetSpecialValueFor("duration")
	for _, eye in ipairs(a:Eyes()) do
		for _, e in ipairs(FindUnitsInRadius(p:GetTeamNumber(), eye:GetAbsOrigin(), nil, a:GetSpecialValueFor("overgrowth_aoe"), DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)) do
			e:AddNewModifier(p, over, "modifier_treant_overgrowth", { duration = dur })
			e:AddNewModifier(p, a, "modifier_dota688_treant_eyes_burn", { duration = dur })
		end
	end
end
modifier_dota688_treant_eyes_burn = class({})
function modifier_dota688_treant_eyes_burn:IsHidden() return true end
function modifier_dota688_treant_eyes_burn:IsPurgable() return false end
function modifier_dota688_treant_eyes_burn:OnCreated() if IsServer() then self:StartIntervalThink(0.5) end end
function modifier_dota688_treant_eyes_burn:OnIntervalThink()
	ApplyDamage({ victim = self:GetParent(), attacker = self:GetCaster(), damage = Dota688Val(self, "damage") * 0.5, damage_type = DAMAGE_TYPE_MAGICAL, ability = self:GetAbility() })
end
