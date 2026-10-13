-- Runele de putere 6.88f, reimplementate in Lua. Motorul curent aplica la activare modifierii moderni
-- (modifier_rune_doubledamage/haste/invis/regen/arcane) cu valorile 7.x; dota688/runes.lua ii blocheaza
-- (filtrul de modifieri + evenimentul dota_rune_activated_server) si aplica in locul lor modifierii de mai jos.
-- Valorile 6.88f (reference/6.88f/dota_english.txt, DOTA_Tooltip_rune_* / DOTA_Tooltip_modifier_rune_*):
--   Double Damage: +100% daune de baza, 45 s          (7.x: Amplify Damage, +80% si 15% spell amp)
--   Haste:         viteza de miscare maxima (522), 25 s (7.00 -> 22 s; maximul 7.x e 550)
--   Invisibility:  45 s, 2 s pana devine invizibil; se rupe la atac sau la folosirea unei abilitati/unui item
--   Regeneration:  100 HP si 67 mana pe secunda, pana la plin sau 30 s; se rupe cand primeste daune
--                  (7.07 -> 6% pe secunda; 7.35 -> nu se mai rupe, scade la 1%)
--   Arcane:        -30% cooldown, -40% cost de mana, 50 s (7.x: 25% / 30%)
--   Illusion:      2 iluzii, 35% daune, primesc 200% (melee) / 300% (ranged) daune, 75 s (creare in runes.lua)
-- Fisierul ruleaza si pe client (getter-ele proprietatilor se evalueaza si acolo), deci nu depinde de alte module.

DOTA688_RUNES = DOTA688_RUNES or {}
local R = DOTA688_RUNES
R.DD_DURATION              = 45
R.DD_BASE_DAMAGE_PCT       = 100
R.HASTE_DURATION           = 25
R.HASTE_SPEED              = 522     -- viteza maxima in 6.88
R.INVIS_DURATION           = 45
R.INVIS_FADE               = 2
R.REGEN_DURATION           = 30
R.REGEN_HP                 = 100
R.REGEN_MANA               = 67
R.ARCANE_DURATION          = 50
R.ARCANE_COOLDOWN_PCT      = 30
R.ARCANE_MANACOST_PCT      = 40
R.ILLUSION_COUNT           = 2
R.ILLUSION_DURATION        = 75
R.ILLUSION_OUTGOING        = -65     -- 35% din daune
R.ILLUSION_INCOMING_MELEE  = 100     -- 200% daune primite
R.ILLUSION_INCOMING_RANGED = 200     -- 300% daune primite

local function Common(m, texture, effect)
	function m:IsHidden() return false end
	function m:IsDebuff() return false end
	function m:IsPurgable() return false end
	function m:GetTexture() return texture end
	if effect then
		function m:GetEffectName() return effect end
		function m:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
	end
end

-- Double Damage ---------------------------------------------------------------
modifier_dota688_rune_doubledamage = class({})
Common(modifier_dota688_rune_doubledamage, "rune_doubledamage", "particles/generic_gameplay/rune_doubledamage_owner.vpcf")
function modifier_dota688_rune_doubledamage:DeclareFunctions() return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE } end
function modifier_dota688_rune_doubledamage:GetModifierBaseDamageOutgoing_Percentage() return R.DD_BASE_DAMAGE_PCT end

-- Haste: viteza fixata la maxim (incetinirile nu o scad); Hex-ul (viteza absoluta proprie) are prioritate.
modifier_dota688_rune_haste = class({})
Common(modifier_dota688_rune_haste, "rune_haste", "particles/generic_gameplay/rune_haste_owner.vpcf")
function modifier_dota688_rune_haste:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE } end
function modifier_dota688_rune_haste:GetModifierMoveSpeed_Absolute()
	if self:GetParent():IsHexed() then return 0 end
	return R.HASTE_SPEED
end

-- Invisibility ----------------------------------------------------------------
-- stack 1 cat timp dureaza fade-ul (2 s), apoi 0: schimbarea stack-ului (replicata) reevalueaza starea si pe client
modifier_dota688_rune_invis = class({})
Common(modifier_dota688_rune_invis, "rune_invis", nil)
function modifier_dota688_rune_invis:Faded()
	return self:GetStackCount() == 0 and self:GetElapsedTime() >= R.INVIS_FADE - 0.1
end
function modifier_dota688_rune_invis:OnCreated()
	if not IsServer() then return end
	self:SetStackCount(1)
	self:StartIntervalThink(R.INVIS_FADE)
	local fx = ParticleManager:CreateParticle("particles/generic_hero_status/status_invisibility_start.vpcf", PATTACH_ABSORIGIN, self:GetParent())
	ParticleManager:ReleaseParticleIndex(fx)
end
function modifier_dota688_rune_invis:OnIntervalThink()
	self:SetStackCount(0)
	self:StartIntervalThink(-1)
end
function modifier_dota688_rune_invis:CheckState()
	if self:Faded() then return { [MODIFIER_STATE_INVISIBLE] = true } end
	return {}
end
function modifier_dota688_rune_invis:DeclareFunctions()
	return { MODIFIER_PROPERTY_INVISIBILITY_LEVEL, MODIFIER_EVENT_ON_ATTACK, MODIFIER_EVENT_ON_ABILITY_EXECUTED }
end
function modifier_dota688_rune_invis:GetModifierInvisibilityLevel()
	if self:Faded() then return 1 end
	return math.min(1, self:GetElapsedTime() / R.INVIS_FADE)
end
function modifier_dota688_rune_invis:OnAttack(params)
	if IsServer() and params.attacker == self:GetParent() then self:Destroy() end
end
-- comutarile (Armlet, abilitati toggle) si schimbarea atributului la Power Treads nu rup invizibilitatea
local function KeepsInvisibility(ability)
	if not ability or ability:IsNull() then return true end
	if ability:IsToggle() then return true end
	return string.find(ability:GetAbilityName(), "power_treads", 1, true) ~= nil
end
function modifier_dota688_rune_invis:OnAbilityExecuted(params)
	if IsServer() and params.unit == self:GetParent() and not KeepsInvisibility(params.ability) then self:Destroy() end
end

-- Regeneration ----------------------------------------------------------------
modifier_dota688_rune_regen = class({})
Common(modifier_dota688_rune_regen, "rune_regen", "particles/generic_gameplay/rune_regen_owner.vpcf")
function modifier_dota688_rune_regen:OnCreated()
	if IsServer() then self:StartIntervalThink(0.1) end
end
function modifier_dota688_rune_regen:OnIntervalThink()
	local p = self:GetParent()
	if p:GetHealth() >= p:GetMaxHealth() and p:GetMana() >= p:GetMaxMana() then self:Destroy() end
end
function modifier_dota688_rune_regen:DeclareFunctions()
	return { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, MODIFIER_PROPERTY_MANA_REGEN_CONSTANT, MODIFIER_EVENT_ON_TAKEDAMAGE }
end
function modifier_dota688_rune_regen:GetModifierConstantHealthRegen() return R.REGEN_HP end
function modifier_dota688_rune_regen:GetModifierConstantManaRegen() return R.REGEN_MANA end
-- se rupe la daunele primite de la o unitate inamica controlata de un jucator (eroi, iluzii, invocari) sau de la Roshan
function modifier_dota688_rune_regen:OnTakeDamage(params)
	if not IsServer() then return end
	local p = self:GetParent()
	local a = params.attacker
	if params.unit ~= p or not a or a:IsNull() or a == p or (params.damage or 0) <= 0 then return end
	if a:GetTeamNumber() == p:GetTeamNumber() then return end
	if a:GetUnitName() == "npc_dota_roshan" or (a.GetPlayerOwnerID and a:GetPlayerOwnerID() >= 0) then self:Destroy() end
end

-- Arcane: variantele *_STACKING se inmultesc cu celelalte surse (Octarine Core), ca in 6.88
-- (din 7.30 sursele procentuale ne-stacking nu se mai cumuleaza)
modifier_dota688_rune_arcane = class({})
Common(modifier_dota688_rune_arcane, "rune_arcane", "particles/generic_gameplay/rune_arcane_owner.vpcf")
function modifier_dota688_rune_arcane:DeclareFunctions()
	return { MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE_STACKING, MODIFIER_PROPERTY_MANACOST_PERCENTAGE_STACKING }
end
function modifier_dota688_rune_arcane:GetModifierPercentageCooldownStacking() return R.ARCANE_COOLDOWN_PCT end
function modifier_dota688_rune_arcane:GetModifierPercentageManacostStacking() return R.ARCANE_MANACOST_PCT end
