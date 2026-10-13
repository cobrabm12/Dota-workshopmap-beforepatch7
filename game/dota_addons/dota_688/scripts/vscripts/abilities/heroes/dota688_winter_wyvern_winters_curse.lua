-- Winter's Curse (6.88): tinta inamica este inghetata (stun, nu poate actiona) 3.25/4/4.75 s si devine imuna la toate daunele
-- echipei lui Winter Wyvern; aliatii tintei din 500 in jurul ei sunt blestemati: sunt fortati sa o atace cu +70 viteza de atac
-- si sunt si ei imuni la daunele echipei lui Wyvern (blestemul se comporta ca o aura: prinde si unitatile care intra in raza
-- si se pierde la iesire). Daca tinta moare din mana aliatilor ei, Wyvern primeste kill-ul. Strapunge imunitatea la magie
-- doar pentru tinta principala, nu si pentru aliatii din jur.
-- Abilitatea curenta face dispel pe tinta la lansare si lasa sa treaca daunele lui Wyvern insasi; 6.88 nu avea niciuna.
require("dota688/val")
local F = "abilities/heroes/dota688_winter_wyvern_winters_curse"
LinkLuaModifier("modifier_dota688_winters_curse_target", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_winters_curse", F, LUA_MODIFIER_MOTION_NONE)

dota688_winter_wyvern_winters_curse = class({})
function dota688_winter_wyvern_winters_curse:GetCastAnimation() return ACT_DOTA_CAST_ABILITY_4 end
function dota688_winter_wyvern_winters_curse:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_winter_wyvern_winters_curse:OnSpellStart()
	local caster, target = self:GetCaster(), self:GetCursorTarget()
	caster:EmitSound("Hero_Winter_Wyvern.WintersCurse.Cast")
	if not target or target:TriggerSpellAbsorb(self) then return end
	target:AddNewModifier(caster, self, "modifier_dota688_winters_curse_target", { duration = self:GetSpecialValueFor("duration") })
end

-- pe tinta principala: inghetata, imuna la daunele echipei lui Wyvern, kill-ul trece la Wyvern daca o omoara aliatii ei
modifier_dota688_winters_curse_target = class({})
function modifier_dota688_winters_curse_target:IsDebuff() return true end
function modifier_dota688_winters_curse_target:IsPurgable() return false end
function modifier_dota688_winters_curse_target:GetEffectName() return "particles/units/heroes/hero_winter_wyvern/wyvern_winters_curse.vpcf" end
function modifier_dota688_winters_curse_target:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_winters_curse_target:GetStatusEffectName() return "particles/status_fx/status_effect_wyvern_curse_target.vpcf" end
function modifier_dota688_winters_curse_target:StatusEffectPriority() return 15 end
function modifier_dota688_winters_curse_target:OnCreated()
	if not IsServer() then return end
	self.team = self:GetCaster():GetTeamNumber()
	self.radius = self:GetAbility():GetSpecialValueFor("radius")
	self.cursed = {}
	local p = self:GetParent()
	p:EmitSound("Hero_Winter_Wyvern.WintersCurse.Target")
	p:Interrupt()
	self:UpdateCursed()
	self:StartIntervalThink(0.1)
end
function modifier_dota688_winters_curse_target:OnIntervalThink() self:UpdateCursed() end
-- aliatii tintei din raza (fara cei imuni la magie) sunt blestemati; cei care ies din raza sau devin imuni scapa
function modifier_dota688_winters_curse_target:UpdateCursed()
	local p = self:GetParent()
	if not p:IsAlive() then return end
	local remaining = self:GetRemainingTime()
	local inRange = {}
	for _, u in ipairs(FindUnitsInRadius(p:GetTeamNumber(), p:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if u ~= p and u:IsAlive() and not u:IsMagicImmune() then
			local idx = u:entindex()
			inRange[idx] = true
			local m = self.cursed[idx]
			if (not m or m:IsNull()) and remaining > 0 then
				local a = self:GetAbility()
				if a and not a:IsNull() then
					self.cursed[idx] = u:AddNewModifier(self:GetCaster(), a, "modifier_dota688_winters_curse",
						{ duration = remaining, target = p:entindex(), team = self.team })
				end
			end
		end
	end
	for idx, m in pairs(self.cursed) do
		if m:IsNull() then
			self.cursed[idx] = nil
		elseif not inRange[idx] then
			m:Destroy()
			self.cursed[idx] = nil
		end
	end
end
function modifier_dota688_winters_curse_target:OnDestroy()
	if not IsServer() then return end
	self:GetParent():StopSound("Hero_Winter_Wyvern.WintersCurse.Target")
	for _, m in pairs(self.cursed or {}) do
		if not m:IsNull() then m:Destroy() end
	end
	self.cursed = {}
end
function modifier_dota688_winters_curse_target:CheckState() return { [MODIFIER_STATE_STUNNED] = true, [MODIFIER_STATE_FROZEN] = true } end
function modifier_dota688_winters_curse_target:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_PROPERTY_MIN_HEALTH, MODIFIER_EVENT_ON_TAKEDAMAGE }
end
function modifier_dota688_winters_curse_target:GetModifierIncomingDamage_Percentage(params)
	if IsServer() and params and params.attacker and not params.attacker:IsNull() and params.attacker:GetTeamNumber() == self.team then
		return -Dota688Val(self, "damage_reduction")
	end
	return 0
end
-- o lovitura fatala nu omoara direct: tinta ramane la 1 HP si e omorata imediat, cu kill-ul dat lui Wyvern daca a lovit-o
-- un aliat al ei (sau ea insasi), altfel celui care a lovit (de ex. neutrii)
function modifier_dota688_winters_curse_target:GetMinHealth()
	if not IsServer() or self.dying then return 0 end
	return 1
end
function modifier_dota688_winters_curse_target:OnTakeDamage(params)
	if not IsServer() or params.unit ~= self:GetParent() then return end
	local p = self:GetParent()
	if self.dying or (params.damage or 0) <= 0 or p:GetHealth() > 1 or not p:IsAlive() then return end
	local caster, a = self:GetCaster(), self:GetAbility()
	local attacker = params.attacker
	local killer, inflictor = attacker, params.inflictor
	if not attacker or attacker:IsNull() or attacker:GetTeamNumber() == p:GetTeamNumber() then
		if caster and not caster:IsNull() then
			killer = caster
			inflictor = (a and not a:IsNull()) and a or nil
		end
	end
	self.dying = true
	if killer and not killer:IsNull() then p:Kill(inflictor, killer) else p:ForceKill(false) end
	self.dying = nil
end

-- pe aliatii tintei: o ataca cu viteza de atac marita, nu pot primi alte comenzi, sunt imuni la daunele echipei lui Wyvern
modifier_dota688_winters_curse = class({})
function modifier_dota688_winters_curse:IsDebuff() return true end
function modifier_dota688_winters_curse:IsPurgable() return false end
function modifier_dota688_winters_curse:GetEffectName() return "particles/units/heroes/hero_winter_wyvern/wyvern_winters_curse_buff.vpcf" end
function modifier_dota688_winters_curse:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_winters_curse:GetStatusEffectName() return "particles/status_fx/status_effect_wyvern_curse_buff.vpcf" end
function modifier_dota688_winters_curse:StatusEffectPriority() return 10 end
function modifier_dota688_winters_curse:OnCreated(kv)
	if not IsServer() then return end
	self.target = kv.target and EntIndexToHScript(kv.target) or nil
	self.team = kv.team or self:GetCaster():GetTeamNumber()
	self:ForceAttack()
	self:StartIntervalThink(0.1)
end
function modifier_dota688_winters_curse:ForceAttack()
	local p, t = self:GetParent(), self.target
	if not t or t:IsNull() or not t:IsAlive() then self:Destroy() return end
	if p:GetForceAttackTarget() ~= t then p:SetForceAttackTargetAlly(t) end
end
function modifier_dota688_winters_curse:OnIntervalThink() self:ForceAttack() end
function modifier_dota688_winters_curse:OnDestroy()
	if not IsServer() then return end
	local p = self:GetParent()
	if p:IsNull() then return end
	p:SetForceAttackTargetAlly(nil)
	if p:IsAlive() then p:Stop() end
end
function modifier_dota688_winters_curse:CheckState() return { [MODIFIER_STATE_COMMAND_RESTRICTED] = true } end
function modifier_dota688_winters_curse:DeclareFunctions() return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_dota688_winters_curse:GetModifierAttackSpeedBonus_Constant() return Dota688Val(self, "bonus_attack_speed") end
function modifier_dota688_winters_curse:GetModifierIncomingDamage_Percentage(params)
	if IsServer() and params and params.attacker and not params.attacker:IsNull() and params.attacker:GetTeamNumber() == self.team then
		return -Dota688Val(self, "damage_reduction")
	end
	return 0
end
