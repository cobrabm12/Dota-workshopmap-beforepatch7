-- Call of the Wild: Hawk (6.88): invoca un soim (npc_dota_beastmaster_hawk_1..4 dupa nivel; 40-100 HP, zbor, viziune
-- 500/500 .. 1250/950) pentru 60 s. De la nivelul 3 soimul devine invizibil dupa 4 s in care sta pe loc
-- (beastmaster_hawk_invisibility 6.88: idle_invis_delay 3 + fade_time 1).
LinkLuaModifier("modifier_dota688_beastmaster_hawk_invisibility", "abilities/heroes/dota688_beastmaster_call_of_the_wild", LUA_MODIFIER_MOTION_NONE)
dota688_beastmaster_call_of_the_wild = class({})
local HAWK_IDLE_INVIS = 3 + 1   -- idle_invis_delay + fade_time din beastmaster_hawk_invisibility (6.88)

function dota688_beastmaster_call_of_the_wild:OnSpellStart()
	local caster = self:GetCaster()
	local level = math.max(1, math.min(4, self:GetLevel()))
	caster:EmitSound("Hero_Beastmaster.Call.Hawk")
	local pos = caster:GetAbsOrigin() + caster:GetForwardVector() * 100
	local hawk = CreateUnitByName("npc_dota_beastmaster_hawk_" .. level, pos, true, caster, caster:GetPlayerOwner(), caster:GetTeamNumber())
	if not hawk then return end
	hawk:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
	hawk:SetOwner(caster)
	hawk:SetForwardVector(caster:GetForwardVector())
	hawk:AddNewModifier(caster, self, "modifier_kill", { duration = self:GetSpecialValueFor("hawk_duration") })
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_beastmaster/beastmaster_call_bird.vpcf", PATTACH_ABSORIGIN, hawk)
	ParticleManager:ReleaseParticleIndex(fx)
	-- invizibilitatea 6.88 (4 s pe loc) in locul celei built-in
	if hawk:FindAbilityByName("beastmaster_hawk_invisibility") then hawk:RemoveAbility("beastmaster_hawk_invisibility") end
	if level >= 3 then hawk:AddNewModifier(caster, self, "modifier_dota688_beastmaster_hawk_invisibility", {}) end
end

modifier_dota688_beastmaster_hawk_invisibility = class({})
function modifier_dota688_beastmaster_hawk_invisibility:IsHidden() return self:GetStackCount() == 0 end
function modifier_dota688_beastmaster_hawk_invisibility:IsPurgable() return false end
function modifier_dota688_beastmaster_hawk_invisibility:GetTexture() return "beastmaster_hawk_invisibility" end
function modifier_dota688_beastmaster_hawk_invisibility:OnCreated()
	if not IsServer() then return end
	self.last = self:GetParent():GetAbsOrigin()
	self.still = GameRules:GetGameTime()
	self:StartIntervalThink(0.1)
end
function modifier_dota688_beastmaster_hawk_invisibility:OnIntervalThink()
	local p = self:GetParent()
	local pos = p:GetAbsOrigin()
	if (pos - self.last):Length2D() > 1 then self.still = GameRules:GetGameTime() end
	self.last = pos
	self:SetStackCount((GameRules:GetGameTime() - self.still >= HAWK_IDLE_INVIS) and 1 or 0)
end
function modifier_dota688_beastmaster_hawk_invisibility:DeclareFunctions() return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL } end
function modifier_dota688_beastmaster_hawk_invisibility:GetModifierInvisibilityLevel() return self:GetStackCount() end
function modifier_dota688_beastmaster_hawk_invisibility:CheckState()
	if self:GetStackCount() == 1 then return { [MODIFIER_STATE_INVISIBLE] = true } end
	return {}
end
