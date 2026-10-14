-- Last Word (6.88): tinta primeste un debuff 4 s; daca nu casteaza o vraja in acest timp, e silence 3/4/5/6 s si ia 150-300 daune; daca o casteaza, e silence imediat si ia daunele.
local F = "abilities/heroes/dota688_silencer_last_word"
LinkLuaModifier("modifier_dota688_silencer_last_word", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_silencer_last_word_silence", F, LUA_MODIFIER_MOTION_NONE)
dota688_silencer_last_word = class({})
function dota688_silencer_last_word:OnSpellStart()
	local t = self:GetCursorTarget()
	if t:TriggerSpellAbsorb(self) then return end
	t:AddNewModifier(self:GetCaster(), self, "modifier_dota688_silencer_last_word", { duration = self:GetSpecialValueFor("debuff_duration") })
	t:EmitSound("Hero_Silencer.LastWord.Cast")
end
function dota688_silencer_last_word:Trigger(t)
	local caster = self:GetCaster()
	ApplyDamage({ victim = t, attacker = caster, damage = self:GetSpecialValueFor("damage"), damage_type = DAMAGE_TYPE_MAGICAL, ability = self })
	t:AddNewModifier(caster, self, "modifier_dota688_silencer_last_word_silence", { duration = self:GetSpecialValueFor("duration") })
	t:EmitSound("Hero_Silencer.LastWord.Target")
end
modifier_dota688_silencer_last_word = class({})
function modifier_dota688_silencer_last_word:IsDebuff() return true end
function modifier_dota688_silencer_last_word:IsPurgable() return true end
function modifier_dota688_silencer_last_word:GetEffectName() return "particles/units/heroes/hero_silencer/silencer_last_word_status.vpcf" end
function modifier_dota688_silencer_last_word:DeclareFunctions() return { MODIFIER_EVENT_ON_ABILITY_EXECUTED } end
function modifier_dota688_silencer_last_word:OnAbilityExecuted(params)
	if not IsServer() or params.unit ~= self:GetParent() or not params.ability or params.ability:IsItem() then return end
	self.triggered = true
	local a = self:GetAbility()
	if a and not a:IsNull() then a:Trigger(self:GetParent()) end
	self:Destroy()
end
function modifier_dota688_silencer_last_word:OnDestroy()
	local a = self:GetAbility()
	if IsServer() and not self.triggered and self:GetParent():IsAlive() and self:GetRemainingTime() <= 0.05 and a and not a:IsNull() then a:Trigger(self:GetParent()) end
end
modifier_dota688_silencer_last_word_silence = class({})
function modifier_dota688_silencer_last_word_silence:IsDebuff() return true end
function modifier_dota688_silencer_last_word_silence:IsPurgable() return true end
function modifier_dota688_silencer_last_word_silence:GetEffectName() return "particles/generic_gameplay/generic_silenced.vpcf" end
function modifier_dota688_silencer_last_word_silence:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_dota688_silencer_last_word_silence:CheckState() return { [MODIFIER_STATE_SILENCED] = true } end
