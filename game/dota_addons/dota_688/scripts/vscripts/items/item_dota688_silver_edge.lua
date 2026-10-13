require("dota688/val")
require("items/dota688_item_base")
-- Silver Edge (6.88): +30 daune, +30 AS, +15 la toate; Shadow Walk: invizibil 14 s, +20% MS; atacul din invizibilitate: +225 daune, Break 5 s si -50% daune 5 s.
LinkLuaModifier("modifier_dota688_silver_edge_invis", "items/item_dota688_silver_edge", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_silver_edge_debuff", "items/item_dota688_silver_edge", LUA_MODIFIER_MOTION_NONE)
Dota688DefineItem("item_dota688_silver_edge", "items/item_dota688_silver_edge", {
	item = {
		OnSpellStart = function(self)
			self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_dota688_silver_edge_invis", { duration = self:GetSpecialValueFor("windwalk_duration") })
			self:GetCaster():EmitSound("DOTA_Item.InvisibilitySword.Activate")
		end,
	},
})
modifier_dota688_silver_edge_invis = class({})
function modifier_dota688_silver_edge_invis:IsPurgable() return false end
function modifier_dota688_silver_edge_invis:OnCreated() self.start = GameRules:GetGameTime() end
function modifier_dota688_silver_edge_invis:Faded() return GameRules:GetGameTime() - self.start >= Dota688Val(self, "windwalk_fade_time") end
function modifier_dota688_silver_edge_invis:CheckState() return { [MODIFIER_STATE_INVISIBLE] = self:Faded(), [MODIFIER_STATE_NO_UNIT_COLLISION] = true } end   -- "can move through units"
function modifier_dota688_silver_edge_invis:DeclareFunctions() return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL, MODIFIER_EVENT_ON_ATTACK, MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
-- un atac ratat sau in zbor tot termina invizibilitatea (dupa ce proiectilul ar fi ajuns)
function modifier_dota688_silver_edge_invis:OnAttack(params)
	if not IsServer() or params.attacker ~= self:GetParent() or self.ending then return end
	self.ending = true
	local me = self
	Dota688Timers:After(self:GetParent():IsRangedAttacker() and 1.5 or 0.3, function() if not me:IsNull() then me:Destroy() end end)
end
function modifier_dota688_silver_edge_invis:GetModifierInvisibilityLevel() return self:Faded() and 1 or 0 end
function modifier_dota688_silver_edge_invis:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "windwalk_movement_speed") end
function modifier_dota688_silver_edge_invis:GetModifierProcAttack_BonusDamage_Physical(params)
	if params.target and not params.target:IsBuilding() and not params.target:IsOther() then return Dota688Val(self, "windwalk_bonus_damage") end
	return 0
end
function modifier_dota688_silver_edge_invis:OnAttackLanded(params)
	if not IsServer() or params.attacker ~= self:GetParent() then return end
	local t = params.target
	if t and t:IsHero() and not t:IsMagicImmune() then t:AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_dota688_silver_edge_debuff", { duration = Dota688Val(self, "backstab_duration") }) end   -- Break nu trece prin imunitate
	self:Destroy()
end
function modifier_dota688_silver_edge_invis:OnAbilityExecuted(params)
	if IsServer() and params.unit == self:GetParent() and params.ability ~= self:GetAbility() then self:Destroy() end
end
modifier_dota688_silver_edge_debuff = class({})
function modifier_dota688_silver_edge_debuff:IsDebuff() return true end
function modifier_dota688_silver_edge_debuff:IsPurgable() return true end
function modifier_dota688_silver_edge_debuff:CheckState() return { [MODIFIER_STATE_PASSIVES_DISABLED] = true } end
function modifier_dota688_silver_edge_debuff:DeclareFunctions() return { MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE } end
function modifier_dota688_silver_edge_debuff:GetModifierTotalDamageOutgoing_Percentage() return Dota688Val(self, "backstab_reduction") end
