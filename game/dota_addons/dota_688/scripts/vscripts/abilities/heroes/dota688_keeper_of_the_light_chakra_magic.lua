-- Chakra Magic (6.88, dupa tooltip): reda 75/150/225/300 mana aliatului tinta, ii mareste capacitatea de mana si reduce cu 3/4/5/6 s
-- cooldown-ul urmatorului spell (nu item) lansat de el in 15 s. KV-ul 6.88 nu are o cheie separata pentru capacitate: mana maxima creste
-- cu valoarea redata (mana_restore), tot 15 s, ca mana redata sa nu se piarda cand tinta e aproape plina.
-- (Varianta moderna: reduce cooldown-urile tuturor abilitatilor, bonus pe sine, mana leak - nu exista in 6.88.)
require("dota688/val")
local F = "abilities/heroes/dota688_keeper_of_the_light_chakra_magic"
LinkLuaModifier("modifier_dota688_keeper_of_the_light_chakra_magic", F, LUA_MODIFIER_MOTION_NONE)

dota688_keeper_of_the_light_chakra_magic = class({})
function dota688_keeper_of_the_light_chakra_magic:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	local restore = self:GetSpecialValueFor("mana_restore")
	local before = target:GetMana()
	target:AddNewModifier(caster, self, "modifier_dota688_keeper_of_the_light_chakra_magic", { duration = self:GetSpecialValueFor("duration") })
	target:GiveMana(restore)
	-- mana maxima se recalculeaza dupa adaugarea modifierului: fixam mana la exact "inainte + restore"
	Dota688Timers:After(0, function()
		if target:IsNull() or not target:IsAlive() then return end
		target:SetMana(math.min(before + restore, target:GetMaxMana()))
	end)
	target:EmitSound("Hero_KeeperOfTheLight.ChakraMagic.Target")
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_keeper_of_the_light/keeper_chakra_magic.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(fx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
end

-- pe tinta: +mana maxima; urmatorul spell cu cooldown are cooldown-ul redus, apoi modifierul dispare
modifier_dota688_keeper_of_the_light_chakra_magic = class({})
function modifier_dota688_keeper_of_the_light_chakra_magic:IsPurgable() return false end
function modifier_dota688_keeper_of_the_light_chakra_magic:OnCreated()
	self.mana = Dota688Val(self, "mana_restore")
	self.reduction = Dota688Val(self, "cooldown_reduction")
end
function modifier_dota688_keeper_of_the_light_chakra_magic:OnRefresh() self:OnCreated() end
function modifier_dota688_keeper_of_the_light_chakra_magic:DeclareFunctions() return { MODIFIER_PROPERTY_EXTRA_MANA_BONUS, MODIFIER_EVENT_ON_ABILITY_FULLY_CAST } end
function modifier_dota688_keeper_of_the_light_chakra_magic:GetModifierExtraManaBonus() return self.mana end
function modifier_dota688_keeper_of_the_light_chakra_magic:OnAbilityFullyCast(params)
	if not IsServer() or params.unit ~= self:GetParent() or self.used then return end
	local ability = params.ability
	if not ability or ability:IsNull() or ability:IsItem() then return end
	-- Chakra Magic lansat de Ezalor pe el insusi nu se consuma singur
	if ability == self:GetAbility() and GameRules:GetGameTime() - self:GetCreationTime() < 0.1 then return end
	Dota688Timers:After(0, function()
		if ability:IsNull() or self:IsNull() or self.used then return end
		local remaining = ability:GetCooldownTimeRemaining()
		if remaining <= 0 then return end   -- spell fara cooldown (orbe, toggle-uri): reducerea ramane pentru urmatorul
		self.used = true
		ability:EndCooldown()
		local left = remaining - (self.reduction or 0)
		if left > 0 then ability:StartCooldown(left) end
		self:Destroy()
	end)
end
