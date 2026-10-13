-- Invoker (6.88): fiecare nivel de Quas/Wex/Exort da permanent +2 STR/AGI/INT (bonus_strength/bonus_agility/bonus_intelligence
-- 2/4/.../14 in KV-ul 6.88), indiferent de instantele active (orbele moderne nu mai dau atribute: strength_bonus etc. = 0).
-- Scepter 6.88: +1 nivel la orbe DOAR pentru spell-urile invocate (dota688/aghanim_extras.lua ridica nivelul orbelor). Atributele raman
-- la nivelul de baza, iar bonusurile pe instanta (regen / AS + MS / daune) ale orbelor ridicate sunt compensate inapoi la nivelul de baza.
modifier_dota688_invoker_orbs = class({})
local ORBS = { "invoker_quas", "invoker_wex", "invoker_exort" }
function modifier_dota688_invoker_orbs:IsHidden() return true end
function modifier_dota688_invoker_orbs:IsPurgable() return false end
function modifier_dota688_invoker_orbs:RemoveOnDeath() return false end
function modifier_dota688_invoker_orbs:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_dota688_invoker_orbs:AllowIllusionDuplicate() return true end   -- iluziile au aceleasi atribute ca eroul
function modifier_dota688_invoker_orbs:OnCreated()
	self.value = -1
	if IsServer() then self:StartIntervalThink(0.1) end
end
-- stack count = nivelurile de baza (3 biti fiecare) + instantele orbelor ridicate de scepter (2 biti fiecare), ca sa le vada si clientul
function modifier_dota688_invoker_orbs:OnIntervalThink()
	self:EnforceOrbLimit()   -- plasa de siguranta (orbe aparute pe alta cale decat cast-ul eroului)
	local p = self:GetParent()
	-- scepter: nivelul de baza (fara +1) e tinut de modifier_dota688_scepter_invoker
	local base = Dota688HasScepter and Dota688HasScepter(p) and p.dota688_orb_base or nil
	local levels, extra = {}, {}
	for k, orb in ipairs(ORBS) do
		local a = p:FindAbilityByName(orb)
		local lvl = a and a:GetLevel() or 0
		local b = lvl
		if base and base[orb] then b = math.min(lvl, base[orb]) end
		levels[k] = math.min(7, b)
		extra[k] = 0
		if lvl > b then extra[k] = math.min(3, #p:FindAllModifiersByName("modifier_" .. orb .. "_instance")) end
	end
	local v = levels[1] + 8 * levels[2] + 64 * levels[3] + 512 * (extra[1] + 4 * extra[2] + 16 * extra[3])
	if v ~= self.value then
		self.value = v
		self:SetStackCount(v)
		p:CalculateStatBonus(true)
	end
end
-- nivelul de baza al orbului k (1..3) si numarul de instante de compensat
function modifier_dota688_invoker_orbs:Decode(k)
	local v = self:GetStackCount()
	local lvl = math.floor(v / (8 ^ (k - 1))) % 8
	local n = math.floor(v / (512 * 4 ^ (k - 1))) % 4
	return lvl, n
end
-- cat adauga un nivel de orb (cel ridicat de scepter) la valoarea pe instanta
function modifier_dota688_invoker_orbs:LevelDiff(k, key)
	local a = self:GetParent():FindAbilityByName(ORBS[k])
	if not a then return 0 end
	local lvl = a:GetLevel()
	if lvl < 2 then return 0 end
	return a:GetLevelSpecialValueFor(key, lvl - 1) - a:GetLevelSpecialValueFor(key, lvl - 2)
end
function modifier_dota688_invoker_orbs:Compensation(k, key)
	local _, n = self:Decode(k)
	if n == 0 then return 0 end
	return -n * self:LevelDiff(k, key)
end
function modifier_dota688_invoker_orbs:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, MODIFIER_PROPERTY_STATS_AGILITY_BONUS, MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_EVENT_ON_ABILITY_EXECUTED }
end

-- Maxim 3 instante de orbe (6.88): un orb nou o inlocuieste pe cea mai veche. Motorul curent ia limita din Invoke-ul
-- built-in, pe care l-am inlocuit cu dota688_invoker_invoke, deci fara asta instantele se adunau la infinit
-- (testat: 10 x Exort = 10 instante, daune 134 -> 358, iar Invoke nu mai gasea o combinatie de 3).
local INSTANCES = { "modifier_invoker_quas_instance", "modifier_invoker_wex_instance", "modifier_invoker_exort_instance" }
local ORB_NAMES = { invoker_quas = true, invoker_wex = true, invoker_exort = true }
function modifier_dota688_invoker_orbs:EnforceOrbLimit()
	local p = self:GetParent()
	local list = {}
	for _, n in ipairs(INSTANCES) do
		for _, m in ipairs(p:FindAllModifiersByName(n)) do list[#list + 1] = m end
	end
	if #list <= 3 then return end
	table.sort(list, function(a, b) return a:GetCreationTime() < b:GetCreationTime() end)
	for i = 1, #list - 3 do list[i]:Destroy() end
end
function modifier_dota688_invoker_orbs:OnAbilityExecuted(params)
	if not IsServer() or params.unit ~= self:GetParent() or not params.ability or not ORB_NAMES[params.ability:GetAbilityName()] then return end
	self:EnforceOrbLimit()
	-- instanta noua poate aparea dupa eveniment (in OnSpellStart-ul orbului): verificam si in frame-ul urmator
	Dota688Timers:After(0, function() if not self:IsNull() then self:EnforceOrbLimit() end end)
end
function modifier_dota688_invoker_orbs:GetModifierBonusStats_Strength() return 2 * self:Decode(1) end
function modifier_dota688_invoker_orbs:GetModifierBonusStats_Agility() return 2 * self:Decode(2) end
function modifier_dota688_invoker_orbs:GetModifierBonusStats_Intellect() return 2 * self:Decode(3) end
function modifier_dota688_invoker_orbs:GetModifierConstantHealthRegen() return self:Compensation(1, "hp_regen_per_instance") end
function modifier_dota688_invoker_orbs:GetModifierAttackSpeedBonus_Constant() return self:Compensation(2, "attack_speed_per_instance") end
function modifier_dota688_invoker_orbs:GetModifierMoveSpeedBonus_Percentage() return self:Compensation(2, "move_speed_per_instance") end
function modifier_dota688_invoker_orbs:GetModifierPreAttack_BonusDamage() return self:Compensation(3, "bonus_damage_per_instance") end
