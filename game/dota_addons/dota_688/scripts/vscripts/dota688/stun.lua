-- Modifier generic de stun / knockback pentru abilitatile 6.88 rescrise in Lua.
LinkLuaModifier("modifier_dota688_stunned", "dota688/stun", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_knockback", "dota688/stun", LUA_MODIFIER_MOTION_HORIZONTAL)

function Dota688Stun(target, caster, ability, duration)
	if not target or target:IsNull() or not target:IsAlive() then return nil end
	return target:AddNewModifier(caster, ability, "modifier_dota688_stunned", { duration = duration })
end

modifier_dota688_stunned = class({})
function modifier_dota688_stunned:IsDebuff() return true end
function modifier_dota688_stunned:IsPurgable() return false end
function modifier_dota688_stunned:IsStunDebuff() return true end
function modifier_dota688_stunned:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_dota688_stunned:GetEffectName() return "particles/generic_gameplay/generic_stunned.vpcf" end
function modifier_dota688_stunned:GetEffectAttachType() return PATTACH_OVERHEAD_FOLLOW end
function modifier_dota688_stunned:DeclareFunctions() return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION } end
function modifier_dota688_stunned:GetOverrideAnimation() return ACT_DOTA_DISABLED end
function modifier_dota688_stunned:CheckState() return { [MODIFIER_STATE_STUNNED] = true } end

-- knockback: kv.dx, kv.dy (directie), kv.distance, kv.duration (timpul miscarii); tinta e stunata pe durata miscarii
function Dota688Knockback(target, caster, ability, dir, distance, duration, height)
	if not target or target:IsNull() then return end
	target:AddNewModifier(caster, ability, "modifier_dota688_knockback", { duration = duration, dx = dir.x, dy = dir.y, distance = distance, height = height or 0 })
end
modifier_dota688_knockback = class({})
function modifier_dota688_knockback:IsHidden() return true end
function modifier_dota688_knockback:IsPurgable() return false end
function modifier_dota688_knockback:OnCreated(kv)
	if not IsServer() then return end
	self.dir = Vector(kv.dx, kv.dy, 0)
	self.speed = kv.distance / math.max(0.03, kv.duration)
	if self:ApplyHorizontalMotionController() == false then self:Destroy() end
end
function modifier_dota688_knockback:UpdateHorizontalMotion(me, dt)
	me:SetAbsOrigin(me:GetAbsOrigin() + self.dir * self.speed * dt)
end
function modifier_dota688_knockback:OnHorizontalMotionInterrupted() self:Destroy() end
function modifier_dota688_knockback:OnDestroy()
	if IsServer() then self:GetParent():RemoveHorizontalMotionController(self); FindClearSpaceForUnit(self:GetParent(), self:GetParent():GetAbsOrigin(), false) end
end
function modifier_dota688_knockback:CheckState() return { [MODIFIER_STATE_STUNNED] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true } end
