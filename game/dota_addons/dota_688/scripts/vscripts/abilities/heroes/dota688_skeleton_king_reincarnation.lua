-- Reincarnation (6.88): pasiv; cand Wraith King moare cu abilitatea gata si cu destula mana (160), reinvie dupa 3 s in acelasi loc,
-- cu HP si mana pline (cooldown 260/160/60). La moarte, inamicii din 900 sunt incetiniti cu 75% viteza de miscare si 75 viteza
-- de atac pentru 5 s. Scepter (Wraith Delay): eroii aliati din 1200 (si Wraith King, cand nu poate reinvia) care ar muri devin
-- wraith pentru 7 s si abia apoi mor; kill-ul ramane celui care a dat lovitura fatala.
-- Fara activul modern (self-cast), scheletii la reinviere si reducerea de cooldown de la scepter.
require("dota688/val")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_skeleton_king_reincarnation"
LinkLuaModifier("modifier_dota688_skeleton_king_reincarnation", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_skeleton_king_reincarnation_slow", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_skeleton_king_reincarnation_scepter", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_skeleton_king_reincarnation_scepter_active", F, LUA_MODIFIER_MOTION_NONE)

dota688_skeleton_king_reincarnation = class({})
function dota688_skeleton_king_reincarnation:GetIntrinsicModifierName() return "modifier_dota688_skeleton_king_reincarnation" end
-- (server) poate reinvia acum? abilitate invatata, fara cooldown, mana suficienta, erou real
function dota688_skeleton_king_reincarnation:CanReincarnate()
	local c = self:GetCaster()
	return self:GetLevel() > 0 and c:IsRealHero() and not c:IsIllusion() and self:IsCooldownReady() and c:GetMana() >= self:GetManaCost(-1)
end

-- intrinsec pe Wraith King: reincarnarea + aura de scepter (Wraith Delay)
modifier_dota688_skeleton_king_reincarnation = class({})
function modifier_dota688_skeleton_king_reincarnation:IsHidden() return true end
function modifier_dota688_skeleton_king_reincarnation:IsPurgable() return false end
function modifier_dota688_skeleton_king_reincarnation:RemoveOnDeath() return false end
function modifier_dota688_skeleton_king_reincarnation:DeclareFunctions() return { MODIFIER_PROPERTY_REINCARNATION, MODIFIER_EVENT_ON_DEATH } end
function modifier_dota688_skeleton_king_reincarnation:ReincarnateTime()
	if not IsServer() then return nil end
	local a = self:GetAbility()
	if not a or a:IsNull() or not a:CanReincarnate() then return nil end
	-- marcam momentul: OnDeath din acelasi cadru stie ca moartea este o reincarnare a noastra (nu Aegis)
	self.reinc_time = GameRules:GetGameTime()
	return a:GetSpecialValueFor("reincarnate_time")
end
function modifier_dota688_skeleton_king_reincarnation:OnDeath(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	local a = self:GetAbility()
	if not a or a:IsNull() then return end
	if self.reinc_time ~= GameRules:GetGameTime() or params.reincarnate == false then return end
	self.reinc_time = nil
	local p = self:GetParent()
	local pos = p:GetAbsOrigin()
	local delay = a:GetSpecialValueFor("reincarnate_time")
	p:SpendMana(a:GetManaCost(-1), a)
	a:StartCooldown(a:GetEffectiveCooldown(a:GetLevel() - 1))
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_skeletonking/wraith_king_reincarnate.vpcf", PATTACH_CUSTOMORIGIN, p)
	ParticleManager:SetParticleControl(fx, 0, pos)
	ParticleManager:SetParticleControl(fx, 1, Vector(delay, 0, 0))
	ParticleManager:SetParticleControl(fx, 11, Vector(200, 0, 0))
	ParticleManager:ReleaseParticleIndex(fx)
	EmitSoundOnLocationWithCaster(pos, "Hero_SkeletonKing.Reincarnate", p)
	for _, e in ipairs(FindUnitsInRadius(p:GetTeamNumber(), pos, nil, a:GetSpecialValueFor("slow_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if not e:IsMagicImmune() then
			e:AddNewModifier(p, a, "modifier_dota688_skeleton_king_reincarnation_slow", { duration = a:GetSpecialValueFor("slow_duration") })
		end
	end
end
-- aura Wraith Delay (doar cu scepter): eroii aliati reali din aura_radius
function modifier_dota688_skeleton_king_reincarnation:IsAura() return true end
function modifier_dota688_skeleton_king_reincarnation:GetAuraRadius() return Dota688Val(self, "aura_radius") end
function modifier_dota688_skeleton_king_reincarnation:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_skeleton_king_reincarnation:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_dota688_skeleton_king_reincarnation:GetAuraSearchFlags() return DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_INVULNERABLE end
function modifier_dota688_skeleton_king_reincarnation:GetModifierAura() return "modifier_dota688_skeleton_king_reincarnation_scepter" end
function modifier_dota688_skeleton_king_reincarnation:GetAuraEntityReject(unit)
	local p, a = self:GetParent(), self:GetAbility()
	if not a or a:IsNull() or a:GetLevel() < 1 or p:IsIllusion() then return true end
	return not Dota688HasScepter(p) or not unit:IsRealHero()
end

-- incetinirea de la moartea lui Wraith King
modifier_dota688_skeleton_king_reincarnation_slow = class({})
function modifier_dota688_skeleton_king_reincarnation_slow:IsDebuff() return true end
function modifier_dota688_skeleton_king_reincarnation_slow:IsPurgable() return true end
function modifier_dota688_skeleton_king_reincarnation_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT } end
function modifier_dota688_skeleton_king_reincarnation_slow:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "movespeed") end
function modifier_dota688_skeleton_king_reincarnation_slow:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "attackslow_tooltip") end

-- Wraith Delay (aura): o lovitura fatala nu omoara, ci transforma eroul in wraith pentru scepter_duration secunde.
-- Pentru Wraith King insusi conteaza doar mortile "reale" (cand Reincarnation nu este gata).
modifier_dota688_skeleton_king_reincarnation_scepter = class({})
function modifier_dota688_skeleton_king_reincarnation_scepter:IsPurgable() return false end
function modifier_dota688_skeleton_king_reincarnation_scepter:DeclareFunctions() return { MODIFIER_PROPERTY_MIN_HEALTH, MODIFIER_EVENT_ON_TAKEDAMAGE } end
function modifier_dota688_skeleton_king_reincarnation_scepter:Protects()
	local p, a = self:GetParent(), self:GetAbility()
	if p.dota688_wraith_dying or not a or a:IsNull() then return false end
	if p == a:GetCaster() and a:CanReincarnate() then return false end
	return true
end
function modifier_dota688_skeleton_king_reincarnation_scepter:GetMinHealth()
	if not IsServer() then return 0 end
	return self:Protects() and 1 or 0
end
function modifier_dota688_skeleton_king_reincarnation_scepter:BecomeWraith(attacker, inflictor)
	local p = self:GetParent()
	if not p:IsAlive() or p:GetHealth() > 1 or p:HasModifier("modifier_dota688_skeleton_king_reincarnation_scepter_active") then return end
	if not self:Protects() then return end
	local a = self:GetAbility()
	p:AddNewModifier(self:GetCaster(), a, "modifier_dota688_skeleton_king_reincarnation_scepter_active", {
		duration = a:GetSpecialValueFor("scepter_duration"),
		killer = (attacker and not attacker:IsNull()) and attacker:entindex() or -1,
		inflictor = (inflictor and not inflictor:IsNull()) and inflictor:entindex() or -1,
	})
end
function modifier_dota688_skeleton_king_reincarnation_scepter:OnTakeDamage(params)
	if not IsServer() or params.unit ~= self:GetParent() or (params.damage or 0) <= 0 then return end
	self:BecomeWraith(params.attacker, params.inflictor)
end
-- MODIFIER_EVENT_ON_TAKEDAMAGE nu vine pentru daunele cu DOTA_DAMAGE_FLAG_HPLOSS (testat: eroul ramanea la 1 HP pentru
-- totdeauna); verificarea din fiecare cadru prinde si lovitura fatala de acest tip (fara credit de kill)
function modifier_dota688_skeleton_king_reincarnation_scepter:OnCreated()
	if IsServer() then self:StartIntervalThink(FrameTime()) end
end
function modifier_dota688_skeleton_king_reincarnation_scepter:OnIntervalThink()
	self:BecomeWraith(nil, nil)
end

-- wraith-ul: nu poate muri pana la final, apoi moare cu kill-ul dat celui care a dat lovitura fatala
modifier_dota688_skeleton_king_reincarnation_scepter_active = class({})
function modifier_dota688_skeleton_king_reincarnation_scepter_active:IsPurgable() return false end
function modifier_dota688_skeleton_king_reincarnation_scepter_active:GetStatusEffectName() return "particles/status_fx/status_effect_wraithking_ghosts.vpcf" end
function modifier_dota688_skeleton_king_reincarnation_scepter_active:StatusEffectPriority() return 20 end
function modifier_dota688_skeleton_king_reincarnation_scepter_active:GetEffectName() return "particles/units/heroes/hero_skeletonking/wraith_king_ghosts_ambient.vpcf" end
function modifier_dota688_skeleton_king_reincarnation_scepter_active:OnCreated(kv)
	if not IsServer() then return end
	self.killer = (kv.killer and kv.killer >= 0) and EntIndexToHScript(kv.killer) or nil
	self.inflictor = (kv.inflictor and kv.inflictor >= 0) and EntIndexToHScript(kv.inflictor) or nil
	self:GetParent():EmitSound("Hero_SkeletonKing.Reincarnate.Ghost")
end
function modifier_dota688_skeleton_king_reincarnation_scepter_active:DeclareFunctions() return { MODIFIER_PROPERTY_MIN_HEALTH } end
function modifier_dota688_skeleton_king_reincarnation_scepter_active:GetMinHealth()
	if IsServer() and self:GetParent().dota688_wraith_dying then return 0 end
	return 1
end
function modifier_dota688_skeleton_king_reincarnation_scepter_active:OnDestroy()
	if not IsServer() then return end
	local p = self:GetParent()
	if not p:IsAlive() then return end
	local killer = (self.killer and not self.killer:IsNull()) and self.killer or nil
	local inflictor = (self.inflictor and not self.inflictor:IsNull()) and self.inflictor or nil
	p.dota688_wraith_dying = true
	if killer then p:Kill(inflictor, killer) else p:ForceKill(false) end
	p.dota688_wraith_dying = nil
end
