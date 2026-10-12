require("items/dota688_item_base")
-- Lotus Orb (6.88): +10 daune, +10 armura, +6 regen, +125% regen mana, +250 mana; Echo Shell (cd 15, 75 mana, raza 900): 6 s
-- vrajile tintite pe unitate sunt re-lansate pe cel care le-a aruncat (unitatea le primeste si ea); dispel la aplicare.
-- MODIFIER_PROPERTY_REFLECT_SPELL e apelata de motor dar nu reflecta nimic pentru modifierii Lua (testat), deci copiem
-- abilitatea pe purtator (ascunsa, la nivelul originalului) si o lansam cu OnSpellStart pe caster. Itemele nu se reflecta.
LinkLuaModifier("modifier_dota688_echo_shell", "items/item_dota688_lotus_orb", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_lotus_orb", "items/item_dota688_lotus_orb", {
	item = {
		OnSpellStart = function(self)
			local target = self:GetCursorTarget() or self:GetCaster()
			target:Purge(false, true, false, false, false)
			target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_echo_shell", { duration = self:GetSpecialValueFor("active_duration") })
			target:EmitSound("DOTA_Item.LotusOrb.Activate")
		end,
	},
})
modifier_dota688_echo_shell = class({})
function modifier_dota688_echo_shell:IsPurgable() return false end
function modifier_dota688_echo_shell:GetEffectName() return "particles/items3_fx/lotus_orb_plasma.vpcf" end
function modifier_dota688_echo_shell:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_echo_shell:DeclareFunctions() return { MODIFIER_PROPERTY_REFLECT_SPELL } end
function modifier_dota688_echo_shell:OnCreated() self.copies = {} end

function modifier_dota688_echo_shell:GetReflectSpell(params)
	if not IsServer() then return 0 end
	local parent, ability = self:GetParent(), params.ability
	if not ability or ability:IsNull() or ability:IsItem() or ability.dota688_reflected then return 0 end
	local caster = ability:GetCaster()
	if not caster or caster:IsNull() or caster == parent or caster:GetTeamNumber() == parent:GetTeamNumber() then return 0 end
	local name = ability:GetAbilityName()
	local copy = self.copies[name]
	if not copy or copy:IsNull() then
		copy = parent:FindAbilityByName(name)
		if copy then
			self.copies[name] = { own = true, ability = copy }
		else
			copy = parent:AddAbility(name)
			if not copy then return 0 end
			copy:SetHidden(true)
			self.copies[name] = { own = false, ability = copy }
		end
	else
		copy = copy.ability
	end
	local lvl = copy:GetLevel()
	copy:SetLevel(math.max(1, ability:GetLevel()))
	copy.dota688_reflected = true
	parent:SetCursorCastTarget(caster)
	copy:OnSpellStart()
	copy.dota688_reflected = nil
	if self.copies[name].own then copy:SetLevel(lvl) end
	parent:EmitSound("Item.LotusOrb.Activate")
	return 0
end

function modifier_dota688_echo_shell:OnDestroy()
	if not IsServer() then return end
	local parent = self:GetParent()
	for _, c in pairs(self.copies or {}) do
		if not c.own and c.ability and not c.ability:IsNull() then parent:RemoveAbilityByHandle(c.ability) end
	end
end
