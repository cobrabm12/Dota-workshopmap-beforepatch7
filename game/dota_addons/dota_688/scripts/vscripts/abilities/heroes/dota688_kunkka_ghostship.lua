-- Ghostship (6.88): corabia porneste de la 1000 in spatele lui Kunkka (opus punctului tintit) si se sfarama la punctul tintit (viteza 650;
-- la raza maxima 1000 parcurge 2000, ~3 s - Liquipedia, Archive:Kunkka): 400/500/600 daune magice + stun 1.4 in 425.
-- Aliatii atinsi de corabie primesc Rum: +10% viteza si 40/45/50% din daunele primite sunt amanate 10 s.
-- Scepter: corabia (latime 200) trage inamicii atinsi pana la locul naufragiului (ei pot actiona in continuare).
require("dota688/val")
require("dota688/aghanim")
require("dota688/stun")
local F = "abilities/heroes/dota688_kunkka_ghostship"
LinkLuaModifier("modifier_dota688_ghostship", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_ghostship_rum", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_ghostship_drag", F, LUA_MODIFIER_MOTION_NONE)
dota688_kunkka_ghostship = class({})
function dota688_kunkka_ghostship:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	local dir = target - caster:GetAbsOrigin(); dir.z = 0
	if dir:Length2D() < 1 then dir = caster:GetForwardVector() end
	dir = dir:Normalized()
	local dist = self:GetSpecialValueFor("ghostship_distance")   -- 1000 in spatele lui Kunkka
	local start = caster:GetAbsOrigin() - dir * dist
	local travel = dist + (target - caster:GetAbsOrigin()):Length2D()
	caster:EmitSound("Ability.Ghostship")
	CreateModifierThinker(caster, self, "modifier_dota688_ghostship", { duration = travel / self:GetSpecialValueFor("ghostship_speed") + 0.2, dx = dir.x, dy = dir.y, tx = target.x, ty = target.y }, start, caster:GetTeamNumber(), false)
end
modifier_dota688_ghostship = class({})
function modifier_dota688_ghostship:IsHidden() return true end
function modifier_dota688_ghostship:OnCreated(kv)
	if not IsServer() then return end
	local a, caster = self:GetAbility(), self:GetCaster()
	self.dir = Vector(kv.dx, kv.dy, 0)
	self.pos = self:GetParent():GetAbsOrigin()
	self.target = Vector(kv.tx, kv.ty, self.pos.z)
	self.speed = a:GetSpecialValueFor("ghostship_speed")
	self.scepter = Dota688HasScepter(caster)
	self.width = self.scepter and a:GetSpecialValueFor("ghostship_width_scepter") or a:GetSpecialValueFor("ghostship_width")
	self.rummed, self.dragged = {}, {}
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_kunkka/kunkka_ghost_ship.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.fx, 0, self.pos)
	-- kunkka_ghost_ship.vpcf: CP0 = pozitia de start, CP1 = vectorul viteza (C_INIT_VelocityFromCP); corabia merge singura
	-- pana la DestroyParticle (endcap = sfaramarea). Cu tinta in CP1 corabia zbura intr-o directie gresita.
	ParticleManager:SetParticleControl(self.fx, 1, self.dir * self.speed)
	self:StartIntervalThink(0.03)
end
function modifier_dota688_ghostship:OnIntervalThink()
	local a, caster = self:GetAbility(), self:GetCaster()
	if not a or a:IsNull() or not caster or caster:IsNull() then self:Destroy(); return end   -- abilitatea/caster-ul au disparut (Rubick, iluzie moarta)
	local to = self.target - self.pos; to.z = 0
	local d = to:Length2D()
	local step = self.speed * 0.03
	if d <= step then self:Crash() return end
	self.pos = self.pos + self.dir * step
	for _, u in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), self.pos, nil, self.width / 2, DOTA_UNIT_TARGET_TEAM_BOTH,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		if u:GetTeamNumber() == caster:GetTeamNumber() then
			if u:IsHero() and not self.rummed[u:entindex()] then
				self.rummed[u:entindex()] = true
				u:AddNewModifier(caster, a, "modifier_dota688_ghostship_rum", { duration = a:GetSpecialValueFor("buff_duration") })
			end
		elseif self.scepter and not self.dragged[u:entindex()] and not u:IsMagicImmune() then
			self.dragged[u:entindex()] = u
			u:AddNewModifier(caster, a, "modifier_dota688_ghostship_drag", {})
		end
	end
	for _, u in pairs(self.dragged) do
		if not u:IsNull() and u:IsAlive() then u:SetAbsOrigin(GetGroundPosition(u:GetAbsOrigin() + self.dir * step, u)) end
	end
end
function modifier_dota688_ghostship:Crash()
	local a, caster = self:GetAbility(), self:GetCaster()
	EmitSoundOnLocationWithCaster(self.target, "Ability.Ghostship.crash", caster)
	for _, e in ipairs(FindUnitsInRadius(caster:GetTeamNumber(), self.target, nil, a:GetSpecialValueFor("ghostship_width"), DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)) do
		ApplyDamage({ victim = e, attacker = caster, damage = a:GetAbilityDamage(), damage_type = DAMAGE_TYPE_MAGICAL, ability = a })
		Dota688Stun(e, caster, a, a:GetSpecialValueFor("stun_duration"))
	end
	self:Destroy()
end
function modifier_dota688_ghostship:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.fx, false)
	for _, u in pairs(self.dragged or {}) do
		if not u:IsNull() then u:RemoveModifierByName("modifier_dota688_ghostship_drag"); FindClearSpaceForUnit(u, u:GetAbsOrigin(), false) end
	end
	-- thinker-ul (CreateModifierThinker) se sterge singur cand modifierul dispare; UTIL_Remove din OnDestroy l-ar sterge
	-- in timp ce motorul inca proceseaza modifierul lui
end
modifier_dota688_ghostship_drag = class({})
function modifier_dota688_ghostship_drag:IsHidden() return true end
function modifier_dota688_ghostship_drag:IsPurgable() return false end
function modifier_dota688_ghostship_drag:CheckState() return { [MODIFIER_STATE_NO_UNIT_COLLISION] = true } end
-- Rum
modifier_dota688_ghostship_rum = class({})
function modifier_dota688_ghostship_rum:IsPurgable() return false end
function modifier_dota688_ghostship_rum:GetTexture() return "kunkka_ghostship" end
function modifier_dota688_ghostship_rum:GetEffectName() return "particles/units/heroes/hero_kunkka/kunkka_admirals_rum.vpcf" end
function modifier_dota688_ghostship_rum:OnCreated() self.delayed = 0 end
function modifier_dota688_ghostship_rum:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE } end
function modifier_dota688_ghostship_rum:GetModifierMoveSpeedBonus_Percentage() return Dota688Val(self, "movespeed_bonus") end
function modifier_dota688_ghostship_rum:GetModifierIncomingDamage_Percentage(params)
	local pct = Dota688Val(self, "ghostship_absorb")
	if IsServer() and params and params.damage and params.damage > 0 then self.delayed = (self.delayed or 0) + params.damage * pct / 100 end
	return -pct
end
function modifier_dota688_ghostship_rum:OnDestroy()
	if not IsServer() then return end
	local p = self:GetParent()
	if self.delayed and self.delayed > 0 and p:IsAlive() then
		ApplyDamage({ victim = p, attacker = p, damage = self.delayed, damage_type = DAMAGE_TYPE_PURE, ability = self:GetAbility(), damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NON_LETHAL })
	end
end
