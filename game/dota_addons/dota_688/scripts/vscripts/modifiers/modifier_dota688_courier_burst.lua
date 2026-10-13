-- Speed Burst (6.88): curierul zburator merge cu 800 viteza timp de 4 s (reference/6.88f: courier_burst, duration 4,
-- movement_speed 800, cooldown 90). Abilitatea moderna citeste movement_speed ca procent (+50 % in 7.x): cu 800 dadea
-- +800 % (testat: 3420 viteza). Ordinele de burst sunt preluate de Dota688Courier, care pune modifier-ul asta.
modifier_dota688_courier_burst = class({})

function modifier_dota688_courier_burst:IsHidden() return false end
function modifier_dota688_courier_burst:IsPurgable() return false end
function modifier_dota688_courier_burst:IsDebuff() return false end
function modifier_dota688_courier_burst:GetTexture() return "courier_burst" end
function modifier_dota688_courier_burst:GetEffectName() return "particles/items_fx/courier_speed.vpcf" end
function modifier_dota688_courier_burst:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end

function modifier_dota688_courier_burst:OnCreated()
	if not IsServer() then return end
	local a = self:GetAbility()
	self:SetStackCount(a and not a:IsNull() and a:GetSpecialValueFor("movement_speed") or 800)
end

function modifier_dota688_courier_burst:DeclareFunctions()
	return { MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE, MODIFIER_PROPERTY_IGNORE_MOVESPEED_LIMIT }
end

function modifier_dota688_courier_burst:GetModifierMoveSpeed_Absolute() return self:GetStackCount() end
function modifier_dota688_courier_burst:GetModifierIgnoreMovespeedLimit() return 1 end
