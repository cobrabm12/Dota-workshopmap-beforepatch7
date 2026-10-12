-- Nature's Guise (6.88): tinta aliata devine invizibila (dupa 2 s) cat timp e la 350 de un copac, 15/30/45/60 s, +14/16/18/20% MS; se rupe la atac/cast.
require("dota688/val")
LinkLuaModifier("modifier_dota688_treant_natures_guise", "abilities/heroes/dota688_treant_natures_guise", LUA_MODIFIER_MOTION_NONE)
dota688_treant_natures_guise = class({})
function dota688_treant_natures_guise:OnSpellStart()
	local target = self:GetCursorTarget()
	target:AddNewModifier(self:GetCaster(), self, "modifier_dota688_treant_natures_guise", { duration = self:GetSpecialValueFor("duration") })
	target:EmitSound("Hero_Treant.NaturesGuise.Cast")
end
modifier_dota688_treant_natures_guise = class({})
function modifier_dota688_treant_natures_guise:IsPurgable() return true end
function modifier_dota688_treant_natures_guise:OnCreated()
	self.start = GameRules:GetGameTime(); self.lastNear = GameRules:GetGameTime()
	if IsServer() then self:StartIntervalThink(Dota688Val(self, "search_interval")) end
end
function modifier_dota688_treant_natures_guise:OnIntervalThink()
	local p, a = self:GetParent(), self:GetAbility()
	if #GridNav:GetAllTreesAroundPoint(p:GetAbsOrigin(), a:GetSpecialValueFor("radius"), false) > 0 then
		self.lastNear = GameRules:GetGameTime()
	elseif GameRules:GetGameTime() - self.lastNear > a:GetSpecialValueFor("grace_time") then
		self:Destroy()
	end
end
function modifier_dota688_treant_natures_guise:Faded() return GameRules:GetGameTime() - self.start >= Dota688Val(self, "fade_time") end
function modifier_dota688_treant_natures_guise:CheckState() return { [MODIFIER_STATE_INVISIBLE] = self:Faded() } end
function modifier_dota688_treant_natures_guise:DeclareFunctions() return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_EVENT_ON_ATTACK, MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
function modifier_dota688_treant_natures_guise:GetModifierInvisibilityLevel() return self:Faded() and 1 or 0 end
function modifier_dota688_treant_natures_guise:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "bonus_move_speed") end
function modifier_dota688_treant_natures_guise:OnAttack(params) if IsServer() and params.attacker == self:GetParent() then self:Destroy() end end
function modifier_dota688_treant_natures_guise:OnAbilityExecuted(params) if IsServer() and params.unit == self:GetParent() then self:Destroy() end end
