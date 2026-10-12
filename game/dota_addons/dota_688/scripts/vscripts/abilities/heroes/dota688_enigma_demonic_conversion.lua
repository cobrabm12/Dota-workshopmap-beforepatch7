-- Demonic Conversion (6.88): tinteste un creep (aliat, inamic sau neutru; nu Ancient, nu creep-erou); creepul moare
-- (bounty pentru Enigma daca e inamic) si din el apar 3 eidoloni (lesser/normal/greater/dire dupa nivel) pentru 35 s.
-- Fiecare eidolon initial se multiplica o singura data, dupa 6 atacuri reusite: apare un eidolon nou (care nu se mai
-- multiplica), amandoi au viata refacuta si durata ramasa prelungita cu 2 s (life_extension).
-- Unitatile: npc_dota_lesser_eidolon / npc_dota_eidolon / npc_dota_greater_eidolon / npc_dota_dire_eidolon
-- (statisticile lor - daune, armura, rezistenta magica, viteza, bounty - trebuie aduse la 6.88 in KV de generator).
require("dota688/val")
LinkLuaModifier("modifier_dota688_eidolon", "abilities/heroes/dota688_enigma_demonic_conversion", LUA_MODIFIER_MOTION_NONE)
dota688_enigma_demonic_conversion = class({})

local EIDOLONS = { "npc_dota_lesser_eidolon", "npc_dota_eidolon", "npc_dota_greater_eidolon", "npc_dota_dire_eidolon" }

function dota688_enigma_demonic_conversion:CastFilterResultTarget(target)
	if target:IsHero() or target:IsConsideredHero() or target:IsBuilding() or target:IsCourier() or target:IsOther() then
		return UF_FAIL_CUSTOM
	end
	return UnitFilter(target, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_CREEP,
		DOTA_UNIT_TARGET_FLAG_NOT_ANCIENTS + DOTA_UNIT_TARGET_FLAG_NOT_CREEP_HERO, self:GetCaster():GetTeamNumber())
end
function dota688_enigma_demonic_conversion:GetCustomCastErrorTarget(target)
	if target:IsHero() or target:IsConsideredHero() then return "#dota_hud_error_cant_cast_on_hero" end
	return "#dota_hud_error_cant_cast_on_other"
end

function dota688_enigma_demonic_conversion:Duration()
	local d = self:GetDuration()
	if not d or d <= 0 then d = self:GetSpecialValueFor("duration_tooltip") end
	return d
end

-- creeaza un eidolon; canSplit = 1 pentru cei 3 initiali
function dota688_enigma_demonic_conversion:SpawnEidolon(pos, duration, canSplit)
	local caster = self:GetCaster()
	local lvl = math.max(1, math.min(#EIDOLONS, self:GetLevel()))
	local u = CreateUnitByName(EIDOLONS[lvl], pos, true, caster, caster, caster:GetTeamNumber())
	if not u then return nil end
	u:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
	u:SetOwner(caster)
	FindClearSpaceForUnit(u, pos, true)
	u:AddNewModifier(caster, self, "modifier_kill", { duration = duration })
	u:AddNewModifier(caster, self, "modifier_dota688_eidolon", { can_split = canSplit })
	return u
end

function dota688_enigma_demonic_conversion:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	local pos = target:GetAbsOrigin()
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_enigma/enigma_demonic_conversion.vpcf", PATTACH_ABSORIGIN, target)
	ParticleManager:SetParticleControl(fx, 0, pos)
	ParticleManager:ReleaseParticleIndex(fx)
	target:EmitSound("Hero_Enigma.Demonic_Conversion")
	-- creepul convertit moare ucis de Enigma (inamicii dau aur si experienta)
	target:Kill(self, caster)
	local duration = self:Duration()
	for i = 1, self:GetSpecialValueFor("spawn_count") do
		self:SpawnEidolon(pos + RandomVector(80), duration, 1)
	end
end

modifier_dota688_eidolon = class({})
function modifier_dota688_eidolon:IsHidden() return false end
function modifier_dota688_eidolon:IsPurgable() return false end
function modifier_dota688_eidolon:GetTexture() return "enigma_demonic_conversion" end
function modifier_dota688_eidolon:OnCreated(kv)
	if not IsServer() then return end
	self.canSplit = (kv.can_split or 0) == 1
	self.needed = Dota688Val(self, "split_attack_count")
	self.extension = Dota688Val(self, "life_extension")
	self:SetStackCount(0)
end
function modifier_dota688_eidolon:DeclareFunctions() return { MODIFIER_EVENT_ON_ATTACK_LANDED } end
function modifier_dota688_eidolon:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() or not self.canSplit then return end
	self:IncrementStackCount()
	if self:GetStackCount() < self.needed then return end
	self.canSplit = false
	local p, a = self:GetParent(), self:GetAbility()
	local kill = p:FindModifierByName("modifier_kill")
	local remaining = (kill and kill:GetRemainingTime() or 0) + self.extension
	if kill then kill:SetDuration(remaining, true) end
	p:SetHealth(p:GetMaxHealth())
	if a and not a:IsNull() then
		local u = a:SpawnEidolon(p:GetAbsOrigin() + RandomVector(60), remaining, 0)
		if u and params.target and not params.target:IsNull() and params.target:IsAlive() then
			u:MoveToTargetToAttack(params.target)
		end
	end
end
