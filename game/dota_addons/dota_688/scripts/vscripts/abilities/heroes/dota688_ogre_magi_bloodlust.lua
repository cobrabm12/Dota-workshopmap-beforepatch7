-- Bloodlust (6.88): pe un aliat (si turnuri, si imuni la vraji; raza 600, cd 20, 50 mana): +10/12/14/16% viteza de miscare,
-- +30/40/50/60 viteza de atac, +25% marime, 30 s. Autocast: se lanseaza singur pe eroii aliati din raza fara Bloodlust.
-- Multicast nivel 1/2/3: -5/10/15 s cooldown; la 2x/3x/4x se lanseaza si pe aliati aleatori din 575 de Ogre.
require("dota688/val")
require("abilities/heroes/dota688_ogre_magi_multicast")
local F = "abilities/heroes/dota688_ogre_magi_bloodlust"
LinkLuaModifier("modifier_dota688_ogre_magi_bloodlust", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_ogre_magi_bloodlust_autocast", F, LUA_MODIFIER_MOTION_NONE)
dota688_ogre_magi_bloodlust = class({})
function dota688_ogre_magi_bloodlust:GetIntrinsicModifierName() return "modifier_dota688_ogre_magi_bloodlust_autocast" end
function dota688_ogre_magi_bloodlust:GetCooldown(level)
	return math.max(0, self.BaseClass.GetCooldown(self, level) - Dota688OgreMulticast.Value(self:GetCaster(), "bloodlust_cooldown"))
end
function dota688_ogre_magi_bloodlust:Apply(target)
	target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_ogre_magi_bloodlust", { duration = self:GetSpecialValueFor("duration") })
	target:EmitSound("Hero_OgreMagi.Bloodlust.Target")
end
function dota688_ogre_magi_bloodlust:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if not target or target:IsNull() then return end
	caster:EmitSound("Hero_OgreMagi.Bloodlust.Cast")
	self:Apply(target)
	-- autocast: Ogre ataca din nou tinta pe care o ataca inainte (doar daca lansarea vine chiar din autocast)
	local r = self.dota688_resume
	self.dota688_resume = nil
	local resume = r and GameRules:GetGameTime() - r.time < 2 and r.target
	if resume then
		Dota688Timers:After(0, function()
			if not caster:IsNull() and caster:IsAlive() and not resume:IsNull() and resume:IsAlive() then caster:MoveToTargetToAttack(resume) end
		end)
	end
	local count = Dota688OgreMulticast.Roll(caster)
	if count < 2 then return end
	local cands = {}
	for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), caster:GetAbsOrigin(), nil, Dota688OgreMulticast.Value(caster, "bloodlust_aoe"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)) do
		if u ~= target and not u:IsOther() then table.insert(cands, u) end
	end
	Dota688OgreMulticast.Repeat(self, count, 0, function(i)
		if #cands == 0 then return end
		local u = table.remove(cands, RandomInt(1, #cands))
		Dota688OgreMulticast.Effect(caster, i)
		self:Apply(u)
	end)
end

modifier_dota688_ogre_magi_bloodlust = class({})
function modifier_dota688_ogre_magi_bloodlust:IsPurgable() return true end
function modifier_dota688_ogre_magi_bloodlust:GetTexture() return "ogre_magi_bloodlust" end
function modifier_dota688_ogre_magi_bloodlust:GetEffectName() return "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf" end
function modifier_dota688_ogre_magi_bloodlust:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_ogre_magi_bloodlust:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MODEL_SCALE }
end
function modifier_dota688_ogre_magi_bloodlust:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "bonus_movement_speed") end
function modifier_dota688_ogre_magi_bloodlust:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "bonus_attack_speed") end
function modifier_dota688_ogre_magi_bloodlust:GetModifierModelScale() return Dota688Val(self, "modelscale") end

-- autocast (KV 6.88: AUTOCAST): pe eroii aliati din raza (si Ogre) fara Bloodlust, doar cand Ogre sta sau ataca
-- (nu intrerupe miscarea ordonata de jucator); dupa lansare Ogre reia atacul.
modifier_dota688_ogre_magi_bloodlust_autocast = class({})
function modifier_dota688_ogre_magi_bloodlust_autocast:IsHidden() return true end
function modifier_dota688_ogre_magi_bloodlust_autocast:IsPurgable() return false end
function modifier_dota688_ogre_magi_bloodlust_autocast:RemoveOnDeath() return false end
function modifier_dota688_ogre_magi_bloodlust_autocast:OnCreated()
	if IsServer() then self:StartIntervalThink(0.25) end
end
function modifier_dota688_ogre_magi_bloodlust_autocast:OnIntervalThink()
	local a, c = self:GetAbility(), self:GetParent()
	if not a or a:IsNull() then self:Destroy(); return end
	if a:GetLevel() < 1 or not a:GetAutoCastState() or not a:IsCooldownReady() or not a:IsFullyCastable() or a:IsHidden() then return end
	if not c:IsAlive() or c:IsIllusion() or c:IsChanneling() or c:GetCurrentActiveAbility() or c:IsSilenced() or c:IsStunned()
		or c:IsHexed() or c:IsInvisible() or c:IsCommandRestricted() then return end
	local attacking = c:GetAttackTarget()
	if not attacking and not c:IsIdle() then return end
	local range = a:GetCastRange(c:GetAbsOrigin(), nil)
	for _, h in ipairs(FindUnitsInRadius(c:GetTeamNumber(), c:GetAbsOrigin(), nil, range, DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS, FIND_CLOSEST, false)) do
		if h:IsAlive() and not h:HasModifier("modifier_dota688_ogre_magi_bloodlust") then
			a.dota688_resume = attacking and { target = attacking, time = GameRules:GetGameTime() } or nil
			c:CastAbilityOnTarget(h, a, c:GetPlayerOwnerID())
			return
		end
	end
end
