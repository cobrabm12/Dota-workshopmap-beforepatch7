-- Land Mines (6.88): mina invizibila (dupa 2 s), armata dupa 0.5 s; explodeaza la 0.3 s dupa ce un inamic intra in 200: 150/190/225/260 daune fizice (jumatate in 500).
require("abilities/heroes/dota688_techies_shared")
LinkLuaModifier("modifier_dota688_techies_land_mine", "abilities/heroes/dota688_techies_land_mines", LUA_MODIFIER_MOTION_NONE)
dota688_techies_land_mines = class({})
function dota688_techies_land_mines:GetAOERadius() return self:GetSpecialValueFor("small_radius") end
function dota688_techies_land_mines:OnSpellStart()
	local pos = self:GetCursorPosition()
	Dota688Techies.Spawn("npc_dota688_techies_land_mine", self:GetCaster(), self, pos, "modifier_dota688_techies_land_mine", 600)
	EmitSoundOnLocationWithCaster(pos, "Dota688.Techies.LandMine.Plant", self:GetCaster())
end
modifier_dota688_techies_land_mine = Dota688Techies.MineModifier("fade_time")
function modifier_dota688_techies_land_mine:OnIntervalThink()
	local a, mine, caster = self:GetAbility(), self:GetParent(), self:GetCaster()
	if self.exploding or GameRules:GetGameTime() - self.start < a:GetSpecialValueFor("activation_time") then return end
	local near = FindUnitsInRadius(caster:GetTeamNumber(), mine:GetAbsOrigin(), nil, a:GetSpecialValueFor("small_radius"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	if #near == 0 then return end
	self.exploding = true
	mine:EmitSound("Dota688.Techies.LandMine.Priming")
	Dota688Timers:After(a:GetSpecialValueFor("explode_delay"), function()
		if mine:IsNull() or not mine:IsAlive() then return end
		local small, big = a:GetSpecialValueFor("small_radius"), a:GetSpecialValueFor("big_radius")
		Dota688Techies.Explode(mine, caster, a, a:GetSpecialValueFor("damage"), DAMAGE_TYPE_PHYSICAL, big,
			"particles/units/heroes/hero_techies/techies_land_mine_explode.vpcf", "Dota688.Techies.LandMine.Detonate",
			function(e, dmg) if (e:GetAbsOrigin() - mine:GetAbsOrigin()):Length2D() > small then return dmg / 2 end return dmg end,
			-- 6.88: "Damages buildings", trece prin imunitatea la vraji (SPELL_IMMUNITY_ENEMIES_YES)
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
		mine:ForceKill(false)
	end)
end
