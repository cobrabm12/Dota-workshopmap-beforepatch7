-- Multicast (6.88, pasiv): Fireblast, Unrefined Fireblast, Ignite si Bloodlust (doar ele, nu si itemele) au sansa sa se lanseze
-- de mai multe ori: 2x 40/50/60%, 3x 0/20/25%, 4x 0/0/12.5% (o singura aruncare: sub 4x -> 4x, sub 3x -> 3x, sub 2x -> 2x).
-- Pe langa sansa: Fireblast +20/40/60 mana si -2/4/6 s cooldown; Ignite loveste in raza 150/300/450 si are +150/300/450 cast range;
-- Bloodlust -5/10/15 s cooldown. Lansarile in plus: Fireblast pe aceeasi tinta (la 0.5 s), Ignite pe inamici aleatori din 1400
-- (la 0.5 s), Bloodlust pe aliati aleatori din 575. (In 7.x Multicast creste cu STR si merge si pe iteme.)
-- Logica e apelata din abilitatile Lua ale lui Ogre (dota688_ogre_magi_*), care fac require pe acest fisier.
dota688_ogre_magi_multicast = dota688_ogre_magi_multicast or class({})

Dota688OgreMulticast = Dota688OgreMulticast or {}
local OM = Dota688OgreMulticast
OM.NAME = "dota688_ogre_magi_multicast"
OM.IGNITE_SEARCH = 1400   -- "random enemy units with 1400 area of effect" (nota 6.88 a lui Ignite)

-- abilitatea Multicast invatata (nil daca lipseste: Rubick, nivel 0). Merge si pe client (mana/cooldown/raza afisate).
function OM.Ability(caster)
	if not caster or caster:IsNull() then return nil end
	local mc = caster:FindAbilityByName(OM.NAME)
	if mc and mc:GetLevel() > 0 then return mc end
	return nil
end
function OM.Value(caster, key)
	local mc = OM.Ability(caster)
	if not mc then return 0 end
	return mc:GetSpecialValueFor(key)
end
-- sansa ca fractie (KV 6.88: 0.4; tolereaza si procentul 40 daca generatorul converteste cheia)
local function chance(mc, key)
	local v = mc:GetSpecialValueFor(key)
	if v > 1 then v = v / 100 end
	return v
end
-- de cate ori se lanseaza vraja (1 = fara multicast)
function OM.Roll(caster)
	local mc = OM.Ability(caster)
	if not mc or caster:IsIllusion() or caster:PassivesDisabled() then return 1 end
	local r = RandomFloat(0, 1)
	if r < chance(mc, "multicast_4_times") then return 4 end
	if r < chance(mc, "multicast_3_times") then return 3 end
	if r < chance(mc, "multicast_2_times") then return 2 end
	return 1
end
-- cifra "x2/x3/x4" deasupra lui Ogre + sunetul, la fiecare lansare in plus
function OM.Effect(caster, n)
	if not caster or caster:IsNull() then return end
	local fx = ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_multicast.vpcf", PATTACH_OVERHEAD_FOLLOW, caster)
	ParticleManager:SetParticleControl(fx, 1, Vector(n, 2, 1))
	ParticleManager:ReleaseParticleIndex(fx)
	caster:EmitSound("Hero_OgreMagi.Fireblast.x" .. math.min(3, math.max(1, n - 1)))
end
-- ruleaza fn(i) pentru lansarile 2..count, la `delay` secunde una de alta (delay 0 = toate deodata)
function OM.Repeat(ability, count, delay, fn)
	for i = 2, count do
		if delay > 0 then
			Dota688Timers:After(delay * (i - 1), function()
				if ability:IsNull() then return end
				fn(i)
			end)
		else
			fn(i)
		end
	end
end
-- Fireblast / Unrefined Fireblast: daune magice + stun; la multicast, aceeasi tinta din nou la multicast_delay (0.5 s)
function OM.Fireblast(ability, target, damage, stun, fxName)
	local caster = ability:GetCaster()
	local function blast()
		if target:IsNull() or not target:IsAlive() then return end
		if target:TriggerSpellAbsorb(ability) then return end
		local fx = ParticleManager:CreateParticle(fxName, PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControl(fx, 1, target:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(fx)
		target:EmitSound("Hero_OgreMagi.Fireblast.Target")
		ApplyDamage({ victim = target, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL, ability = ability })
		if target:IsAlive() then target:AddNewModifier(caster, ability, "modifier_stunned", { duration = stun }) end
	end
	local count = OM.Roll(caster)
	blast()
	OM.Repeat(ability, count, ability:GetSpecialValueFor("multicast_delay"), function(i)
		if caster:IsNull() or target:IsNull() or not target:IsAlive() or target:IsMagicImmune() or target:IsInvulnerable() then return end
		OM.Effect(caster, i)
		blast()
	end)
end
