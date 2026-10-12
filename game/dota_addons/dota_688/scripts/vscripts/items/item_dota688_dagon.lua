require("items/dota688_item_base")
-- Dagon 1-5 (6.88): +13/16/19/22/25 INT, +3 la toate, +9 daune; Energy Blast: 400-800 daune magice, cd 35-15.
local function Blast(self)
	local target = self:GetCursorTarget()
	local caster = self:GetCaster()
	if target:TriggerSpellAbsorb(self) then return end
	caster:EmitSound("DOTA_Item.Dagon.Activate")
	local fx = ParticleManager:CreateParticle("particles/items_fx/dagon.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(fx)
	ApplyDamage({ victim = target, attacker = caster, damage = self:GetSpecialValueFor("damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
end
Dota688DefineItem("item_dota688_dagon", "items/item_dota688_dagon", { item = { OnSpellStart = Blast } })
Dota688DefineItem("item_dota688_dagon_2", "items/item_dota688_dagon", { item = { OnSpellStart = Blast } })
Dota688DefineItem("item_dota688_dagon_3", "items/item_dota688_dagon", { item = { OnSpellStart = Blast } })
Dota688DefineItem("item_dota688_dagon_4", "items/item_dota688_dagon", { item = { OnSpellStart = Blast } })
Dota688DefineItem("item_dota688_dagon_5", "items/item_dota688_dagon", { item = { OnSpellStart = Blast } })
