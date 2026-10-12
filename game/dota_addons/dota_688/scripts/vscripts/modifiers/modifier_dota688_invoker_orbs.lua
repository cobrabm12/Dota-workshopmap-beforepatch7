-- Invoker (6.88): fiecare instanta de Quas/Wex/Exort da +2 x nivelul orbului la STR/AGI/INT (orbele moderne nu mai dau atribute).
modifier_dota688_invoker_orbs = class({})
function modifier_dota688_invoker_orbs:IsHidden() return true end
function modifier_dota688_invoker_orbs:IsPurgable() return false end
function modifier_dota688_invoker_orbs:RemoveOnDeath() return false end
function modifier_dota688_invoker_orbs:GetAttributes() return MODIFIER_ATTRIBUTE_PERMANENT end
function modifier_dota688_invoker_orbs:OnCreated()
	self.str, self.agi, self.int = 0, 0, 0
	if IsServer() then self:StartIntervalThink(0.2) end
end
function modifier_dota688_invoker_orbs:OnIntervalThink()
	local p = self:GetParent()
	local function count(orb, inst)
		local a = p:FindAbilityByName(orb)
		if not a or a:GetLevel() == 0 then return 0 end
		local n = 0
		for _, m in ipairs(p:FindAllModifiersByName(inst)) do n = n + 1 end
		return n * 2 * a:GetLevel()
	end
	local s, g, i = count("invoker_quas", "modifier_invoker_quas_instance"), count("invoker_wex", "modifier_invoker_wex_instance"), count("invoker_exort", "modifier_invoker_exort_instance")
	if s ~= self.str or g ~= self.agi or i ~= self.int then
		self.str, self.agi, self.int = s, g, i
		self:SetStackCount(s * 10000 + g * 100 + i)   -- transmis clientului intr-un singur numar
		p:CalculateStatBonus(true)
	end
end
function modifier_dota688_invoker_orbs:Decode()
	local v = self:GetStackCount()
	return math.floor(v / 10000), math.floor((v % 10000) / 100), v % 100
end
function modifier_dota688_invoker_orbs:DeclareFunctions() return { MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, MODIFIER_PROPERTY_STATS_AGILITY_BONUS, MODIFIER_PROPERTY_STATS_INTELLECT_BONUS } end
function modifier_dota688_invoker_orbs:GetModifierBonusStats_Strength() local s = self:Decode(); return s end
function modifier_dota688_invoker_orbs:GetModifierBonusStats_Agility() local _, g = self:Decode(); return g end
function modifier_dota688_invoker_orbs:GetModifierBonusStats_Intellect() local _, _, i = self:Decode(); return i end
