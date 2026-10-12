-- Living Armor (6.88): global, pe un aliat sau o cladire: +4/8/12/16 regenerare 15 s si blocheaza 20/40/60/80 daune din 4/5/6/7 instante.
LinkLuaModifier("modifier_dota688_treant_living_armor", "abilities/heroes/dota688_treant_living_armor", LUA_MODIFIER_MOTION_NONE)
dota688_treant_living_armor = class({})
function dota688_treant_living_armor:GetCastRange() return 60000 end
function dota688_treant_living_armor:OnSpellStart()
	local target = self:GetCursorTarget() or self:GetCaster()
	target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_treant_living_armor", { duration = self:GetSpecialValueFor("duration") })
	target:EmitSound("Hero_Treant.LivingArmor.Target")
end
modifier_dota688_treant_living_armor = class({})
function modifier_dota688_treant_living_armor:IsPurgable() return true end
function modifier_dota688_treant_living_armor:GetEffectName() return "particles/units/heroes/hero_treant/treant_livingarmor.vpcf" end
function modifier_dota688_treant_living_armor:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_dota688_treant_living_armor:OnCreated()
	self:SetStackCount(self:GetAbility():GetSpecialValueFor("damage_count"))
	self.block = self:GetAbility():GetSpecialValueFor("damage_block")
end
function modifier_dota688_treant_living_armor:OnRefresh() self:OnCreated() end
function modifier_dota688_treant_living_armor:DeclareFunctions() return { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT } end
function modifier_dota688_treant_living_armor:GetModifierConstantHealthRegen() return self:GetAbility():GetSpecialValueFor("health_regen") end
function modifier_dota688_treant_living_armor:GetModifierIncomingDamageConstant(params)
	if not IsServer() then return 0 end
	if params.damage <= 0 or (params.damage_flags and bit.band(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) ~= 0) then return 0 end
	self:DecrementStackCount()
	if self:GetStackCount() <= 0 then self:Destroy() end
	return -math.min(self.block, params.damage)
end
