-- Meat Hook (6.88): carlig (viteza 1600, latime 100) pe 1000/1100/1200/1300; prima unitate intalnita (aliat sau inamic, si invizibila
-- sau imuna la vraji; trece prin unitatile mecanice) e trasa la Pudge; inamicii iau 90/180/270/360 daune pure.
-- Scepter: cooldown 4, 180/270/360/450 daune.
require("dota688/aghanim")
LinkLuaModifier("modifier_dota688_meat_hook", "abilities/heroes/dota688_pudge_meat_hook", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_meat_hook_target", "abilities/heroes/dota688_pudge_meat_hook", LUA_MODIFIER_MOTION_NONE)
dota688_pudge_meat_hook = class({})
function dota688_pudge_meat_hook:GetCooldown(level)
	if Dota688HasScepter(self:GetCaster()) then return self:GetSpecialValueFor("cooldown_scepter") end
	return self.BaseClass.GetCooldown(self, level)
end
function dota688_pudge_meat_hook:OnSpellStart()
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_dota688_meat_hook") then return end
	local dir = self:GetCursorPosition() - caster:GetAbsOrigin(); dir.z = 0
	if dir:Length2D() < 1 then dir = caster:GetForwardVector() end
	caster:EmitSound("Hero_Pudge.AttackHookExtend")
	caster:AddNewModifier(caster, self, "modifier_dota688_meat_hook", { dx = dir.x, dy = dir.y })
end
modifier_dota688_meat_hook = class({})
function modifier_dota688_meat_hook:IsHidden() return true end
function modifier_dota688_meat_hook:IsPurgable() return false end
function modifier_dota688_meat_hook:OnCreated(kv)
	if not IsServer() then return end
	local a, p = self:GetAbility(), self:GetParent()
	self.dir = Vector(kv.dx, kv.dy, 0):Normalized()
	self.speed = a:GetSpecialValueFor("hook_speed")
	self.maxDist = a:GetSpecialValueFor("hook_distance")
	self.width = a:GetSpecialValueFor("hook_width")
	self.head = p:GetAbsOrigin() + self.dir * 50
	self.start = p:GetAbsOrigin()
	self.phase = "out"
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_pudge/pudge_meathook.vpcf", PATTACH_CUSTOMORIGIN, p)
	ParticleManager:SetParticleControlEnt(self.fx, 0, p, PATTACH_POINT_FOLLOW, "attach_hook", p:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(self.fx, 1, self.head)
	ParticleManager:SetParticleControl(self.fx, 2, Vector(self.speed, self.maxDist, self.width))
	ParticleManager:SetParticleControl(self.fx, 3, Vector(1, 0, 0))
	self:StartIntervalThink(0.03)
end
function modifier_dota688_meat_hook:OnIntervalThink()
	local p, a = self:GetParent(), self:GetAbility()
	local step = self.speed * 0.03
	if self.phase == "out" then
		self.head = self.head + self.dir * step
		local units = FindUnitsInRadius(p:GetTeamNumber(), self.head, nil, self.width, DOTA_UNIT_TARGET_TEAM_BOTH,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
		for _, u in ipairs(units) do
			-- unitatile mecanice (siege, cogs, mine) sunt sarite: "can go through ... mechanical units"
			local cls = u:GetClassname()
			local mechanical = cls == "npc_dota_creep_siege" or u:GetUnitName():find("siege", 1, true) or u:GetUnitName():find("rattletrap_cog", 1, true)
				or u:GetUnitName():find("techies_", 1, true)
			if u ~= p and not u:IsInvulnerable() and not u:IsCourier() and not mechanical then
				self.target = u
				break
			end
		end
		if self.target then
			self.phase = "in"
			local t = self.target
			t:EmitSound("Hero_Pudge.AttackHookImpact")
			AddFOWViewer(p:GetTeamNumber(), t:GetAbsOrigin(), a:GetSpecialValueFor("vision_radius"), a:GetSpecialValueFor("vision_duration"), false)
			if t:GetTeamNumber() ~= p:GetTeamNumber() then
				if not t:TriggerSpellAbsorb(a) then
					local dmg = Dota688HasScepter(p) and a:GetSpecialValueFor("damage_scepter") or a:GetAbilityDamage()
					ApplyDamage({ victim = t, attacker = p, damage = dmg, damage_type = DAMAGE_TYPE_PURE, ability = a })
				end
			end
			if t:IsAlive() then
				t:Stop()
				t:AddNewModifier(p, a, "modifier_dota688_meat_hook_target", {})
			end
		elseif (self.head - self.start):Length2D() >= self.maxDist then
			self.phase = "in"
			p:EmitSound("Hero_Pudge.AttackHookRetract")
		end
	else
		local to = p:GetAbsOrigin() - self.head; to.z = 0
		local d = to:Length2D()
		if d <= step + 80 then self:Destroy() return end
		self.head = self.head + to:Normalized() * step
		local t = self.target
		if t and not t:IsNull() and t:IsAlive() then
			t:SetAbsOrigin(GetGroundPosition(self.head, t))
		end
	end
	ParticleManager:SetParticleControl(self.fx, 1, self.head)
end
function modifier_dota688_meat_hook:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.fx, false)
	local t = self.target
	if t and not t:IsNull() then
		t:RemoveModifierByName("modifier_dota688_meat_hook_target")
		FindClearSpaceForUnit(t, t:GetAbsOrigin(), true)
	end
end
modifier_dota688_meat_hook_target = class({})
function modifier_dota688_meat_hook_target:IsHidden() return true end
function modifier_dota688_meat_hook_target:IsPurgable() return false end
function modifier_dota688_meat_hook_target:CheckState() return { [MODIFIER_STATE_STUNNED] = true, [MODIFIER_STATE_NO_UNIT_COLLISION] = true } end
function modifier_dota688_meat_hook_target:GetOverrideAnimation() return ACT_DOTA_FLAIL end
