-- Borrowed Time (6.88): 4/5/6 s in care toate daunele primite il vindeca pe Abaddon; la activare scoate majoritatea debuff-urilor;
-- se activeaza automat (daca nu e pe cooldown) cand HP-ul scade sub 400. Scepter: 5/6/7 s; 50% din daunele primite de eroii aliati din 900 sunt redirectionate la Abaddon.
require("dota688/val")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_abaddon_borrowed_time"
LinkLuaModifier("modifier_dota688_borrowed_time", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_borrowed_time_passive", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_borrowed_time_redirect", F, LUA_MODIFIER_MOTION_NONE)
dota688_abaddon_borrowed_time = class({})
function dota688_abaddon_borrowed_time:GetIntrinsicModifierName() return "modifier_dota688_borrowed_time_passive" end
function dota688_abaddon_borrowed_time:Activate()
	local caster = self:GetCaster()
	local dur = Dota688HasScepter(caster) and self:GetSpecialValueFor("duration_scepter") or self:GetSpecialValueFor("duration")
	caster:EmitSound("Hero_Abaddon.BorrowedTime")
	caster:Purge(false, true, false, true, true)
	caster:AddNewModifier(caster, self, "modifier_dota688_borrowed_time", { duration = dur })
end
function dota688_abaddon_borrowed_time:OnSpellStart() self:Activate() end
modifier_dota688_borrowed_time_passive = class({})
function modifier_dota688_borrowed_time_passive:IsHidden() return true end
function modifier_dota688_borrowed_time_passive:IsPurgable() return false end
function modifier_dota688_borrowed_time_passive:RemoveOnDeath() return false end
function modifier_dota688_borrowed_time_passive:DeclareFunctions() return { MODIFIER_EVENT_ON_TAKEDAMAGE } end
function modifier_dota688_borrowed_time_passive:OnTakeDamage(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	local p, a = self:GetParent(), self:GetAbility()
	if not p:IsAlive() or a:GetLevel() < 1 or not a:IsCooldownReady() or p:HasModifier("modifier_dota688_borrowed_time") or p:PassivesDisabled() then return end
	if p:GetHealth() < a:GetSpecialValueFor("hp_threshold") then
		a:Activate()
		a:StartCooldown(a:GetCooldown(a:GetLevel() - 1))
	end
end
modifier_dota688_borrowed_time = class({})
function modifier_dota688_borrowed_time:IsPurgable() return false end
function modifier_dota688_borrowed_time:GetTexture() return "abaddon_borrowed_time" end
function modifier_dota688_borrowed_time:GetEffectName() return "particles/units/heroes/hero_abaddon/abaddon_borrowed_time.vpcf" end
function modifier_dota688_borrowed_time:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_borrowed_time:DeclareFunctions() return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_dota688_borrowed_time:GetModifierIncomingDamage_Percentage(params)
	if IsServer() and params and params.damage and params.damage > 0 then
		self:GetParent():Heal(params.damage, self:GetAbility())
	end
	return -100
end
function modifier_dota688_borrowed_time:IsAura() return Dota688HasScepter(self:GetParent()) end
function modifier_dota688_borrowed_time:GetAuraRadius() return Dota688Val(self, "redirect_range_tooltip_scepter") end
function modifier_dota688_borrowed_time:GetAuraSearchTeam() return DOTA_UNIT_TARGET_TEAM_FRIENDLY end
function modifier_dota688_borrowed_time:GetAuraSearchType() return DOTA_UNIT_TARGET_HERO end
function modifier_dota688_borrowed_time:GetModifierAura() return "modifier_dota688_borrowed_time_redirect" end
function modifier_dota688_borrowed_time:GetAuraEntityReject(unit) return unit == self:GetParent() end
modifier_dota688_borrowed_time_redirect = class({})
function modifier_dota688_borrowed_time_redirect:IsPurgable() return false end
function modifier_dota688_borrowed_time_redirect:GetTexture() return "abaddon_borrowed_time" end
function modifier_dota688_borrowed_time_redirect:DeclareFunctions() return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_dota688_borrowed_time_redirect:GetModifierIncomingDamage_Percentage(params)
	local pct = Dota688Val(self, "redirect") * 100
	if IsServer() and params and params.damage and params.damage > 0 and not self.redirecting then
		local ab = self:GetCaster()
		if ab and not ab:IsNull() and ab:IsAlive() then
			self.redirecting = true
			ApplyDamage({ victim = ab, attacker = params.attacker or ab, damage = params.damage * pct / 100, damage_type = params.damage_type or DAMAGE_TYPE_PURE, ability = self:GetAbility() })
			self.redirecting = false
		end
	end
	return -pct
end
