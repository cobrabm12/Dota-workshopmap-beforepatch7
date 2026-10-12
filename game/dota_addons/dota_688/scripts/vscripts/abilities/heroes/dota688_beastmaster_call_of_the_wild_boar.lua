-- Call of the Wild: Boar (6.88). Invoca un mistret (nivel 1-4) pentru 60 s; un nou mistret il inlocuieste pe cel vechi.
dota688_beastmaster_call_of_the_wild_boar = class({})

function dota688_beastmaster_call_of_the_wild_boar:OnSpellStart()
	local caster = self:GetCaster()
	local level = self:GetLevel()
	if caster.dota688_boar and not caster.dota688_boar:IsNull() and caster.dota688_boar:IsAlive() then
		caster.dota688_boar:ForceKill(false)
	end
	caster:EmitSound("Hero_Beastmaster.Call.Boar")
	local pos = caster:GetAbsOrigin() + RandomVector(100)
	local boar = CreateUnitByName("npc_dota_beastmaster_boar_" .. level, pos, true, caster, caster:GetPlayerOwner(), caster:GetTeamNumber())
	if not boar then return end
	boar:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
	boar:SetOwner(caster)
	FindClearSpaceForUnit(boar, pos, true)
	boar:AddNewModifier(caster, self, "modifier_kill", { duration = self:GetSpecialValueFor("boar_duration") })
	local poison = boar:FindAbilityByName("beastmaster_boar_poison")
	if poison then poison:SetLevel(level) end
	caster.dota688_boar = boar
end
