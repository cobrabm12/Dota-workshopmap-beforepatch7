-- Fireblast (6.88): 55/110/165/220 daune magice si stun 1.5 s (raza 475, cd 12, 75/85/95/105 mana).
-- Multicast nivel 1/2/3: +20/40/60 mana, -2/4/6 s cooldown, sansa de 2x/3x/4x pe aceeasi tinta (la 0.5 s).
require("abilities/heroes/dota688_ogre_magi_multicast")
dota688_ogre_magi_fireblast = class({})
function dota688_ogre_magi_fireblast:GetManaCost(level)
	return self.BaseClass.GetManaCost(self, level) + Dota688OgreMulticast.Value(self:GetCaster(), "fireblast_mana_cost")
end
function dota688_ogre_magi_fireblast:GetCooldown(level)
	return math.max(0, self.BaseClass.GetCooldown(self, level) - Dota688OgreMulticast.Value(self:GetCaster(), "fireblast_cooldown"))
end
function dota688_ogre_magi_fireblast:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if not target or target:IsNull() then return end
	caster:EmitSound("Hero_OgreMagi.Fireblast.Cast")
	Dota688OgreMulticast.Fireblast(self, target, self:GetAbilityDamage(), self:GetSpecialValueFor("stun_duration"),
		"particles/units/heroes/hero_ogre_magi/ogre_magi_fireblast.vpcf")
end
