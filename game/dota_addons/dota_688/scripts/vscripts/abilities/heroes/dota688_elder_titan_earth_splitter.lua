-- Earth Splitter (6.88): crapatura de 2400 (latime 300) care dupa 3.14 s implodeaza: inamicii sunt trasi spre centru, iau 30/40/50% din HP maxim
-- (jumatate magic, jumatate fizic) si sunt incetiniti 30/40/50% 3/4/5 s. Scepter: incetinire 4/5/6 s si dezarmare.
require("dota688/val")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_elder_titan_earth_splitter"
LinkLuaModifier("modifier_dota688_earth_splitter_thinker", F, LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_earth_splitter_slow", F, LUA_MODIFIER_MOTION_NONE)
dota688_elder_titan_earth_splitter = class({})
function dota688_elder_titan_earth_splitter:OnSpellStart()
	local caster = self:GetCaster()
	local dir = self:GetCursorPosition() - caster:GetAbsOrigin(); dir.z = 0
	if dir:Length2D() < 1 then dir = caster:GetForwardVector() end
	dir = dir:Normalized()
	caster:EmitSound("Hero_EldarTitan.EarthSplitter.Cast")
	CreateModifierThinker(caster, self, "modifier_dota688_earth_splitter_thinker", { duration = self:GetSpecialValueFor("crack_time"), dx = dir.x, dy = dir.y }, caster:GetAbsOrigin(), caster:GetTeamNumber(), false)
end
modifier_dota688_earth_splitter_thinker = class({})
function modifier_dota688_earth_splitter_thinker:IsHidden() return true end
function modifier_dota688_earth_splitter_thinker:OnCreated(kv)
	if not IsServer() then return end
	local a = self:GetAbility()
	self.dir = Vector(kv.dx, kv.dy, 0)
	self.start = self:GetParent():GetAbsOrigin()
	self.finish = self.start + self.dir * a:GetSpecialValueFor("crack_distance")
	self.fx = ParticleManager:CreateParticle("particles/units/heroes/hero_elder_titan/elder_titan_earth_splitter.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(self.fx, 0, self.start); ParticleManager:SetParticleControl(self.fx, 1, self.finish)
	-- viziune de-a lungul crapaturii
	local steps = a:GetSpecialValueFor("total_steps")
	for i = 0, steps do
		AddFOWViewer(self:GetCaster():GetTeamNumber(), self.start + self.dir * (a:GetSpecialValueFor("crack_distance") * i / steps), a:GetSpecialValueFor("vision_width"), a:GetSpecialValueFor("vision_duration") + a:GetSpecialValueFor("crack_time"), false)
	end
end
function modifier_dota688_earth_splitter_thinker:OnDestroy()
	if not IsServer() then return end
	ParticleManager:DestroyParticle(self.fx, false)
	local a, caster = self:GetAbility(), self:GetCaster()
	if caster and not caster:IsNull() then
		EmitSoundOnLocationWithCaster(self.start, "Hero_EldarTitan.EarthSplitter.Destroy", caster)
		local scepter = Dota688HasScepter(caster)
		local slowDur = scepter and a:GetSpecialValueFor("slow_duration_scepter") or a:GetSpecialValueFor("slow_duration")
		for _, e in ipairs(FindUnitsInLine(caster:GetTeamNumber(), self.start, self.finish, nil, a:GetSpecialValueFor("crack_width") / 2, DOTA_UNIT_TARGET_TEAM_ENEMY,
			DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)) do
			-- tras spre linia crapaturii
			local rel = e:GetAbsOrigin() - self.start
			local proj = self.start + self.dir * rel:Dot(self.dir)
			FindClearSpaceForUnit(e, GetGroundPosition(proj, e), false)
			local dmg = e:GetMaxHealth() * a:GetSpecialValueFor("damage_pct") / 100
			-- SPELL_IMMUNITY_ENEMIES_YES: jumatatea magica se da ca daune pure cand tinta e imuna (motorul ar bloca-o)
			ApplyDamage({ victim = e, attacker = caster, damage = dmg / 2, damage_type = e:IsMagicImmune() and DAMAGE_TYPE_PURE or DAMAGE_TYPE_MAGICAL, ability = a })
			ApplyDamage({ victim = e, attacker = caster, damage = dmg / 2, damage_type = DAMAGE_TYPE_PHYSICAL, ability = a })
			e:AddNewModifier(caster, a, "modifier_dota688_earth_splitter_slow", { duration = slowDur, scepter = scepter and 1 or 0 })
		end
	end
	UTIL_Remove(self:GetParent())
end
modifier_dota688_earth_splitter_slow = class({})
function modifier_dota688_earth_splitter_slow:IsDebuff() return true end
function modifier_dota688_earth_splitter_slow:IsPurgable() return true end
function modifier_dota688_earth_splitter_slow:GetTexture() return "elder_titan_earth_splitter" end
function modifier_dota688_earth_splitter_slow:OnCreated(kv) self.scepter = kv.scepter == 1 end
function modifier_dota688_earth_splitter_slow:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_earth_splitter_slow:GetModifierMoveSpeedBonus_Percentage() return -Dota688Val(self, "slow_pct") end
function modifier_dota688_earth_splitter_slow:CheckState() return { [MODIFIER_STATE_DISARMED] = self.scepter == true } end
