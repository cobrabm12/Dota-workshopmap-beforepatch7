require("dota688/val")
require("items/dota688_item_base")
-- Linken's Sphere (6.88): +15 la toate, +6 regen, +150% regen mana, +15 daune; Spellblock la fiecare 13 s (motorul: TriggerSpellAbsorb);
-- Transfer Spellblock (cd 13, raza 700): blocul trece pe un erou aliat pentru TRANSFER_DURATION s, timp in care purtatorul nu il are.
local TRANSFER_DURATION = 20   -- Liquipedia (6.84-7.06): "Transfers Spellblock to an ally for 20 seconds"
LinkLuaModifier("modifier_dota688_linkens", "items/item_dota688_sphere", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_sphere", "items/item_dota688_sphere", {
	onCreated = function(self)
		if not IsServer() then return end
		local m = self:GetParent():FindModifierByName("modifier_dota688_linkens")
		if m and m:GetDuration() > 0 then m:Destroy(); m = nil end   -- blocul primit prin Transfer e inlocuit de cel propriu
		if not m then self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dota688_linkens", {}) end
	end,
	modifier = {
		OnDestroy = function(self)
			if IsServer() and not self:GetParent():HasItemInInventory("item_dota688_sphere") then self:GetParent():RemoveModifierByName("modifier_dota688_linkens") end
		end,
	},
	item = {
		OnSpellStart = function(self)
			local caster, target = self:GetCaster(), self:GetCursorTarget()
			if not target or target == caster then return end
			local own = caster:FindModifierByName("modifier_dota688_linkens")
			if own then own.transferred_until = GameRules:GetGameTime() + TRANSFER_DURATION end
			local tm = target:FindModifierByName("modifier_dota688_linkens")
			if tm and tm:GetDuration() <= 0 then
				tm.ready = 0   -- aliatul are propriul Linken's: nu-l inlocuim cu unul temporar, doar ii reincarcam blocul
			else
				target:AddNewModifier(caster, self, "modifier_dota688_linkens", { duration = TRANSFER_DURATION })
			end
			target:EmitSound("DOTA_Item.LinkensSphere.Activate")
		end,
	},
})
modifier_dota688_linkens = class({})
function modifier_dota688_linkens:IsHidden() return false end
function modifier_dota688_linkens:IsPurgable() return false end
function modifier_dota688_linkens:RemoveOnDeath() return false end
function modifier_dota688_linkens:OnCreated() self.ready = 0 end
function modifier_dota688_linkens:DeclareFunctions() return { MODIFIER_PROPERTY_ABSORB_SPELL } end
function modifier_dota688_linkens:GetAbsorbSpell(params)
	if not IsServer() then return 0 end
	if GameRules:GetGameTime() < (self.ready or 0) then return 0 end
	if GameRules:GetGameTime() < (self.transferred_until or 0) then return 0 end   -- blocul e la aliat
	local ab = params.ability
	if not ab or ab:GetCaster():GetTeamNumber() == self:GetParent():GetTeamNumber() then return 0 end
	self.ready = GameRules:GetGameTime() + Dota688Val(self, "block_cooldown")
	local fx = ParticleManager:CreateParticle("particles/items_fx/immunity_sphere.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent())
	ParticleManager:ReleaseParticleIndex(fx)
	return 1
end
