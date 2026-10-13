-- Unrefined Fireblast (6.88, oferita de Aghanim's Scepter): 275 daune magice si stun 1.5 s (raza 475, cd 6);
-- costa 60% din mana curenta a lui Ogre. Poate face Multicast ca Fireblast (aceeasi tinta, la 0.5 s).
-- Ascunsa/deblocata de dota688/aghanim.lua (AG.GRANT).
require("abilities/heroes/dota688_ogre_magi_multicast")
dota688_ogre_magi_unrefined_fireblast = class({})
function dota688_ogre_magi_unrefined_fireblast:GetManaCost(level)
	local c = self:GetCaster()
	if not c or c:IsNull() then return 0 end
	local f = self:GetSpecialValueFor("scepter_mana")   -- 0.6 in KV 6.88 (60 daca e convertit in procent)
	if f > 1 then f = f / 100 end
	return c:GetMana() * f
end
function dota688_ogre_magi_unrefined_fireblast:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if not target or target:IsNull() then return end
	caster:EmitSound("Hero_OgreMagi.Fireblast.Cast")
	Dota688OgreMulticast.Fireblast(self, target, self:GetAbilityDamage(), self:GetSpecialValueFor("stun_duration"),
		"particles/units/heroes/hero_ogre_magi/ogre_magi_unr_fireblast.vpcf")
end
