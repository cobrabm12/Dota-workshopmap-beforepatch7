-- Iluziile (6.88) nu dau aur si nici XP la moarte. Motorul curent da totusi 2 x nivel aur ucigasului si XP eroilor din
-- jur, ocolind filtrele de aur / XP si ignorand SetMinimumGoldBounty / SetMaximumGoldBounty / SetDeathXP /
-- SetCustomDeathXP (testat). O moarte fara atacator (Kill(nil, nil)) nu da nimic, deci lovitura fatala o transformam
-- in asa ceva: iluzia ramane la 1 HP si e omorata imediat fara atacator. Pus de Dota688GoldXP:OnUnitSpawned.
modifier_dota688_illusion_bounty = class({})

function modifier_dota688_illusion_bounty:IsHidden() return true end
function modifier_dota688_illusion_bounty:IsPurgable() return false end
function modifier_dota688_illusion_bounty:RemoveOnDeath() return true end

function modifier_dota688_illusion_bounty:DeclareFunctions() return { MODIFIER_PROPERTY_MIN_HEALTH } end

-- Wraith Delay (scepter-ul lui Wraith King) are propria regula de 1 HP; il lasam pe el sa decida
local function WraithProtected(p) return p:HasModifier("modifier_dota688_skeleton_king_reincarnation_scepter") end

function modifier_dota688_illusion_bounty:GetMinHealth()
	if not IsServer() or self.dying or WraithProtected(self:GetParent()) then return 0 end   -- Kill respecta si el limita
	return 1
end

-- MODIFIER_EVENT_ON_TAKEDAMAGE nu se declanseaza pe iluzii (testat), deci verificam in fiecare cadru daca lovitura
-- fatala a oprit iluzia la limita de 1 HP
function modifier_dota688_illusion_bounty:OnCreated()
	if IsServer() then self:StartIntervalThink(FrameTime()) end
end

function modifier_dota688_illusion_bounty:OnIntervalThink()
	local p = self:GetParent()
	if not p or p:IsNull() or not p:IsAlive() or p:GetHealth() > 1 or WraithProtected(p) then return end
	self.dying = true
	self:StartIntervalThink(-1)
	p:Kill(nil, nil)
end
