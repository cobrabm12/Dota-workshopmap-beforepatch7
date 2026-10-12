-- Spirit Form (6.88): 40 s; Ezalor devine luminescent si primeste Recall si Blinding Light (la nivelul Spirit Form).
-- Scepter: Spirit Form permanent; ziua, Illuminate vindeca aliatii cu aceeasi valoare cu care face daune.
require("dota688/aghanim")
local F = "abilities/heroes/dota688_keeper_of_the_light_spirit_form"
LinkLuaModifier("modifier_dota688_spirit_form", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_spirit_form_passive", F, LUA_MODIFIER_MOTION_NONE)
dota688_keeper_of_the_light_spirit_form = class({})
function dota688_keeper_of_the_light_spirit_form:GetIntrinsicModifierName() return "modifier_dota688_spirit_form_passive" end
function dota688_keeper_of_the_light_spirit_form:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_KeeperOfTheLight.SpiritForm.Cast")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_spirit_form_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:ReleaseParticleIndex(fx)
	if not Dota688HasScepter(caster) then
		caster:AddNewModifier(caster, self, "modifier_dota688_spirit_form", { duration = self:GetSpecialValueFor("duration") })
	end
end
-- pasiv: Spirit Form permanent cu scepter + vindecarea Illuminate ziua
modifier_dota688_spirit_form_passive = class({})
function modifier_dota688_spirit_form_passive:IsHidden() return true end
function modifier_dota688_spirit_form_passive:IsPurgable() return false end
function modifier_dota688_spirit_form_passive:RemoveOnDeath() return false end
function modifier_dota688_spirit_form_passive:OnCreated() if IsServer() then self:StartIntervalThink(0.1) end end
function modifier_dota688_spirit_form_passive:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_FULLY_CAST } end
function modifier_dota688_spirit_form_passive:OnAbilityFullyCast(params)
	if IsServer() and params.unit == self:GetParent() and params.ability:GetName() == "keeper_of_the_light_illuminate" then
		self.illumDir = self:GetParent():GetForwardVector()
		self.chanStart = GameRules:GetGameTime()
	end
end
function modifier_dota688_spirit_form_passive:OnIntervalThink()
	local p, a = self:GetParent(), self:GetAbility()
	local scepter = Dota688HasScepter(p) and a:GetLevel() > 0
	local form = p:FindModifierByName("modifier_dota688_spirit_form")
	if scepter and (not form or form:GetDuration() > 0) then
		if form then form:Destroy() end
		p:AddNewModifier(p, a, "modifier_dota688_spirit_form", {})
	elseif not scepter and form and form:GetDuration() <= 0 then
		form:Destroy()
	end
	-- Illuminate: urmarim canalizarea (modifierul built-in) ca sa vindecam aliatii la sfarsit
	local chan = p:HasModifier("modifier_keeper_of_the_light_illuminate")
	if chan and not self.chanStart then self.chanStart = GameRules:GetGameTime(); self.illumDir = p:GetForwardVector() end
	if not chan and self.chanStart then
		local t = GameRules:GetGameTime() - self.chanStart
		self.chanStart = nil
		if scepter and GameRules:IsDaytime() then self:HealWave(t) end
	end
end
function modifier_dota688_spirit_form_passive:HealWave(t)
	local p = self:GetParent()
	local illum = p:FindAbilityByName("keeper_of_the_light_illuminate")
	if not illum or illum:GetLevel() < 1 then return end
	local maxT = math.max(0.1, illum:GetSpecialValueFor("max_channel_time"))
	local amount = illum:GetSpecialValueFor("damage_per_second") * math.min(t, maxT)
	if amount <= 0 then amount = illum:GetSpecialValueFor("total_damage") * math.min(t, maxT) / maxT end   -- KV-ul curent: total_damage
	if amount <= 0 then return end
	local radius, range = illum:GetSpecialValueFor("radius"), illum:GetSpecialValueFor("range")
	local dir = self.illumDir or p:GetForwardVector()
	local finish = p:GetAbsOrigin() + dir * range
	for _, u in ipairs(FindUnitsInLine(p:GetTeamNumber(), p:GetAbsOrigin(), finish, nil, radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE)) do
		u:Heal(amount, illum)
	end
end
modifier_dota688_spirit_form = class({})
function modifier_dota688_spirit_form:IsPurgable() return false end
function modifier_dota688_spirit_form:RemoveOnDeath() return false end
function modifier_dota688_spirit_form:GetTexture() return "keeper_of_the_light_spirit_form" end
function modifier_dota688_spirit_form:GetEffectName() return "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_spirit_form_ambient.vpcf" end
function modifier_dota688_spirit_form:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_spirit_form:SetGranted(on)
	local p, lvl = self:GetParent(), self:GetAbility():GetLevel()
	for _, n in ipairs({ "keeper_of_the_light_recall", "dota688_keeper_of_the_light_blinding_light" }) do
		local ab = p:FindAbilityByName(n)
		if ab then ab:SetLevel(on and lvl or 0); ab:SetActivated(on) end
	end
end
function modifier_dota688_spirit_form:OnCreated() if IsServer() then self:SetGranted(true) end end
function modifier_dota688_spirit_form:OnRefresh() if IsServer() then self:SetGranted(true) end end
function modifier_dota688_spirit_form:OnDestroy() if IsServer() and not self:GetParent():IsNull() then self:SetGranted(false) end end
