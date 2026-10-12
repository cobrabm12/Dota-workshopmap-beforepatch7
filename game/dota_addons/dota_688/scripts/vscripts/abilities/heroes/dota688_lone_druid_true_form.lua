-- True Form (6.88): Lone Druid se transforma in urs (1.933 s in care nu poate actiona si "evita" stun-urile primite) si ramane asa
-- pana foloseste Druid Form (tot 1.933 s): melee (raza 128), BAT 1.5, +4/6/8 armura, +300/600/900 HP, -45 viteza de miscare de baza;
-- in forma de urs are Battle Cry (acelasi nivel). Forma se pastreaza si dupa moarte.
-- (Varianta moderna: forma temporara de 25 s cu cooldown, +daune - nu exista in 6.88.)
-- Druid Form (dota688_lone_druid_true_form_druid.lua) foloseste modifierii de aici.
require("dota688/val")
local F = "abilities/heroes/dota688_lone_druid_true_form"
LinkLuaModifier("modifier_dota688_lone_druid_true_form", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_lone_druid_true_form_transform", F, LUA_MODIFIER_MOTION_NONE)

local TF, DRUID, CRY = "dota688_lone_druid_true_form", "dota688_lone_druid_true_form_druid", "dota688_lone_druid_true_form_battle_cry"

-- True Form <-> Druid Form pe acelasi slot; Battle Cry vizibil doar in forma de urs
local function SetFormAbilities(hero, bear)
	local tf, druid, cry = hero:FindAbilityByName(TF), hero:FindAbilityByName(DRUID), hero:FindAbilityByName(CRY)
	if tf and druid then
		if bear and not tf:IsHidden() then
			hero:SwapAbilities(TF, DRUID, false, true)
		elseif not bear and tf:IsHidden() then
			hero:SwapAbilities(TF, DRUID, true, false)
		end
	end
	if cry then cry:SetHidden(not bear) end
end

-- incepe transformarea (in urs sau inapoi in druid); efectul se aplica la sfarsitul ei
function Dota688LoneDruidTransform(hero, ability, toBear)
	hero:Stop()
	hero:AddNewModifier(hero, ability, "modifier_dota688_lone_druid_true_form_transform", { duration = ability:GetSpecialValueFor("transformation_time"), bear = toBear and 1 or 0 })
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_lone_druid/lone_druid_true_form.vpcf", PATTACH_ABSORIGIN_FOLLOW, hero)
	ParticleManager:ReleaseParticleIndex(fx)
end

-- True Form, Druid Form si Battle Cry au mereu acelasi nivel: in forma de urs se invata Druid Form (True Form e ascuns)
function Dota688LoneDruidSyncLevels(hero, lvl)
	for _, n in ipairs({ TF, DRUID, CRY }) do
		local a = hero:FindAbilityByName(n)
		if a and a:GetLevel() ~= lvl then a:SetLevel(lvl) end
	end
	if hero:HasModifier("modifier_dota688_lone_druid_true_form") and hero.CalculateStatBonus then hero:CalculateStatBonus(true) end
end

dota688_lone_druid_true_form = class({})
function dota688_lone_druid_true_form:IsStealable() return false end   -- fara Druid Form, Rubick ar ramane urs
function dota688_lone_druid_true_form:OnUpgrade() Dota688LoneDruidSyncLevels(self:GetCaster(), self:GetLevel()) end
function dota688_lone_druid_true_form:OnSpellStart()
	local caster = self:GetCaster()
	caster:EmitSound("Hero_LoneDruid.TrueForm.Cast")
	Dota688LoneDruidTransform(caster, self, true)
end

------------------------------------------------------------------------------------------------
-- transformarea: nu poate actiona; stun-urile primite in acest timp sunt anulate (nota 6.88: "you can dodge stuns while transforming")
modifier_dota688_lone_druid_true_form_transform = class({})
function modifier_dota688_lone_druid_true_form_transform:IsHidden() return true end
function modifier_dota688_lone_druid_true_form_transform:IsPurgable() return false end
function modifier_dota688_lone_druid_true_form_transform:OnCreated(kv)
	if not IsServer() then return end
	self:SetStackCount(kv.bear == 1 and 1 or 0)
	self:StartIntervalThink(0.03)
end
function modifier_dota688_lone_druid_true_form_transform:CheckState() return { [MODIFIER_STATE_STUNNED] = true } end
function modifier_dota688_lone_druid_true_form_transform:DeclareFunctions() return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION } end
function modifier_dota688_lone_druid_true_form_transform:GetOverrideAnimation()
	if self:GetStackCount() == 1 then return ACT_DOTA_OVERRIDE_ABILITY_3 end
	return ACT_DOTA_IDLE
end
function modifier_dota688_lone_druid_true_form_transform:OnIntervalThink()
	for _, m in ipairs(self:GetParent():FindAllModifiers()) do
		if m ~= self and m.IsStunDebuff and m:IsStunDebuff() then m:Destroy() end
	end
end
function modifier_dota688_lone_druid_true_form_transform:OnDestroy()
	if not IsServer() then return end
	local p = self:GetParent()
	if p:IsNull() or not p:IsAlive() then return end
	if self:GetStackCount() == 1 then
		local tf = p:FindAbilityByName(TF) or self:GetAbility()
		if tf and not tf:IsNull() then p:AddNewModifier(p, tf, "modifier_dota688_lone_druid_true_form", {}) end
	else
		p:RemoveModifierByName("modifier_dota688_lone_druid_true_form")
		SetFormAbilities(p, false)
	end
end

------------------------------------------------------------------------------------------------
-- forma de urs (permanenta pana la Druid Form)
modifier_dota688_lone_druid_true_form = class({})
function modifier_dota688_lone_druid_true_form:IsHidden() return true end   -- 6.88 nu avea tooltip de modifier pentru forma
function modifier_dota688_lone_druid_true_form:IsPurgable() return false end
function modifier_dota688_lone_druid_true_form:RemoveOnDeath() return false end
function modifier_dota688_lone_druid_true_form:AllowIllusionDuplicate() return true end   -- iluziile lui LD in forma de urs sunt tot ursi
function modifier_dota688_lone_druid_true_form:GetTexture() return "lone_druid_true_form" end
function modifier_dota688_lone_druid_true_form:OnCreated()
	local p = self:GetParent()
	self.rangedRange = p.GetBaseAttackRange and p:GetBaseAttackRange() or 550   -- GetBaseAttackRange nu exista pe client
	if not IsServer() then return end
	p:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
	SetFormAbilities(p, true)
end
function modifier_dota688_lone_druid_true_form:OnDestroy()
	if not IsServer() then return end
	local p = self:GetParent()
	if p:IsNull() then return end
	p:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
	SetFormAbilities(p, false)
end
function modifier_dota688_lone_druid_true_form:DeclareFunctions()
	return { MODIFIER_PROPERTY_MODEL_CHANGE, MODIFIER_PROPERTY_ATTACK_RANGE_BONUS, MODIFIER_PROPERTY_BASE_ATTACK_TIME_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_HEALTH_BONUS, MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT }
end
function modifier_dota688_lone_druid_true_form:GetModifierModelChange() return "models/heroes/lone_druid/true_form.vmdl" end
function modifier_dota688_lone_druid_true_form:GetModifierAttackRangeBonus() return 128 - (self.rangedRange or 550) end
function modifier_dota688_lone_druid_true_form:GetModifierBaseAttackTimeConstant() return Dota688Val(self, "base_attack_time") end
function modifier_dota688_lone_druid_true_form:GetModifierPhysicalArmorBonus() return Dota688Val(self, "bonus_armor") end
function modifier_dota688_lone_druid_true_form:GetModifierHealthBonus() return Dota688Val(self, "bonus_hp") end
function modifier_dota688_lone_druid_true_form:GetModifierMoveSpeedBonus_Constant() return -Dota688Val(self, "speed_loss") end
