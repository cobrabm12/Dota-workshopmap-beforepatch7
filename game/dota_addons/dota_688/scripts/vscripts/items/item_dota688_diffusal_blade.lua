require("items/dota688_item_base")
-- Diffusal Blade 1/2 (6.88): +25/35 AGI, +10/15 INT; Feedback: atacurile ard 40 mana (+1 dauna per mana); Purge (8 incarcaturi): dispel + slow 4 s (5 s pe non-eroi), summonii mor; cd 4.
LinkLuaModifier("modifier_dota688_diffusal_purge", "items/item_dota688_diffusal_blade", LUA_MODIFIER_MOTION_NONE)
local function Feedback(self, params)
	local target = params.target
	if not target or target:IsBuilding() or target:IsOther() or target:GetTeamNumber() == self:GetParent():GetTeamNumber() or target:IsMagicImmune() then return end
	local a = self:GetAbility()
	local parent = self:GetParent()
	local burn = a:GetSpecialValueFor("feedback_mana_burn")
	if parent:IsIllusion() then burn = parent:IsRangedAttacker() and a:GetSpecialValueFor("feedback_mana_burn_illusion_ranged") or a:GetSpecialValueFor("feedback_mana_burn_illusion_melee") end
	burn = math.min(burn, target:GetMana())
	if burn <= 0 then return end
	target:ReduceMana(burn)
	ApplyDamage({ victim = target, attacker = parent, damage = burn * a:GetSpecialValueFor("damage_per_burn"), damage_type = DAMAGE_TYPE_PHYSICAL, ability = a })
	local fx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_manaburn.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:ReleaseParticleIndex(fx)
end
local function Purge(self)
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	if self:GetCurrentCharges() <= 0 then return end
	if target:GetTeamNumber() == caster:GetTeamNumber() then
		target:Purge(false, true, false, false, false)
	else
		if target:TriggerSpellAbsorb(self) then return end
		if target:IsSummoned() and not target:IsHero() then
			ApplyDamage({ victim = target, attacker = caster, damage = self:GetSpecialValueFor("purge_summoned_damage"), damage_type = DAMAGE_TYPE_PURE, ability = self })
		else
			target:Purge(true, false, false, false, false)
			local d = target:IsHero() and self:GetSpecialValueFor("purge_slow_duration") or 5
			target:AddNewModifier(caster, self, "modifier_dota688_diffusal_purge", { duration = d })
		end
	end
	self:SetCurrentCharges(self:GetCurrentCharges() - 1)
	target:EmitSound("DOTA_Item.DiffusalBlade.Target")
end
for _, n in ipairs({ "item_dota688_diffusal_blade", "item_dota688_diffusal_blade_2" }) do
	Dota688DefineItem(n, "items/item_dota688_diffusal_blade", { onAttackLanded = Feedback, item = { OnSpellStart = Purge,
		CastFilterResultTarget = function(self, target) if self:GetCurrentCharges() <= 0 then return UF_FAIL_CUSTOM end return UF_SUCCESS end,
		GetCustomCastErrorTarget = function(self, target) return "#dota_hud_error_item_no_charges" end } })
end
modifier_dota688_diffusal_purge = class({})
function modifier_dota688_diffusal_purge:IsDebuff() return true end
function modifier_dota688_diffusal_purge:IsPurgable() return true end
function modifier_dota688_diffusal_purge:OnCreated()
	if IsServer() then self:StartIntervalThink(1.0) end
	self.elapsed = 0
end
function modifier_dota688_diffusal_purge:OnIntervalThink() self.elapsed = self.elapsed + 1 end
function modifier_dota688_diffusal_purge:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_diffusal_purge:GetModifierMoveSpeedBonus_Percentage()
	-- -100% la inceput, revine in trepte de 20% pe secunda
	return -math.max(0, 100 - 20 * (self.elapsed or 0))
end
