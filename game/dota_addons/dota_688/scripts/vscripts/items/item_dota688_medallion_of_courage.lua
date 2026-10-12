require("items/dota688_item_base")
-- Medallion of Courage (6.88): +7 armura, +50% regen mana; Valor: -7 armura tie si tintei (aliat: +7) pentru 7 s.
LinkLuaModifier("modifier_dota688_valor", "items/item_dota688_medallion_of_courage", LUA_MODIFIER_MOTION_NONE)
local function Valor(self)
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	local ally = target:GetTeamNumber() == caster:GetTeamNumber()
	if not ally and target:TriggerSpellAbsorb(self) then return end
	local d = self:GetSpecialValueFor("duration")
	caster:AddNewModifier(caster, self, "modifier_dota688_valor", { duration = d, self_cast = 1 })
	target:AddNewModifier(caster, self, "modifier_dota688_valor", { duration = d, ally = ally and 1 or 0 })
	target:EmitSound("DOTA_Item.MedallionOfCourage.Activate")
end
Dota688DefineItem("item_dota688_medallion_of_courage", "items/item_dota688_medallion_of_courage", { item = { OnSpellStart = Valor } })
Dota688DefineItem("item_dota688_solar_crest", "items/item_dota688_medallion_of_courage", { item = { OnSpellStart = Valor } })

modifier_dota688_valor = class({})
function modifier_dota688_valor:IsPurgable() return true end
function modifier_dota688_valor:OnCreated(kv)
	local a = self:GetAbility()
	self.selfCast = kv.self_cast == 1
	self.ally = kv.ally == 1
	if self.selfCast then
		self.armor = a:GetSpecialValueFor("armor_reduction")
		self.evasion = -a:GetSpecialValueFor("bonus_evasion")
	elseif self.ally then
		self.armor = a:GetSpecialValueFor("allied_armor") ~= 0 and a:GetSpecialValueFor("allied_armor") or a:GetSpecialValueFor("bonus_armor")
		self.evasion = a:GetSpecialValueFor("allied_evasion")
	else
		self.armor = a:GetSpecialValueFor("armor_reduction")
		self.miss = a:GetSpecialValueFor("miss_chance")
	end
end
function modifier_dota688_valor:IsDebuff() return not self.ally and not self.selfCast end
function modifier_dota688_valor:DeclareFunctions() return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_EVASION_CONSTANT, MODIFIER_PROPERTY_MISS_PERCENTAGE } end
function modifier_dota688_valor:GetModifierPhysicalArmorBonus() return self.armor or 0 end
function modifier_dota688_valor:GetModifierEvasion_Constant() return self.evasion or 0 end
function modifier_dota688_valor:GetModifierMiss_Percentage() return self.miss or 0 end
