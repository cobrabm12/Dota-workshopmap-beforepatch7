-- Remote Mines (6.88): mina invizibila detonabila manual (sau prin Focused Detonate), 300/450/600 daune magice in 425, dureaza 10 min, max 21.
-- Scepter: 450/600/750 daune, raza de plantare 700 (raza exploziei 425).
require("abilities/heroes/dota688_techies_shared")
require("dota688/aghanim")
local F = "abilities/heroes/dota688_techies_remote_mines"
LinkLuaModifier("modifier_dota688_techies_remote_mine", F, LUA_MODIFIER_MOTION_NONE)
dota688_techies_remote_mines = class({})
function dota688_techies_remote_mines:GetAOERadius() return self:GetSpecialValueFor("radius") end
-- Focused Detonate este NOT_LEARNABLE: in 6.88 il activa (nivel 1) invatarea Remote Mines
function dota688_techies_remote_mines:OnUpgrade()
	local fd = self:GetCaster():FindAbilityByName("dota688_techies_focused_detonate")
	if fd and fd:GetLevel() < 1 then fd:SetLevel(1) end
end
function dota688_techies_remote_mines:GetCastRange(location, target)
	if Dota688HasScepter(self:GetCaster()) then return self:GetSpecialValueFor("cast_range_scepter") end
	return self.BaseClass.GetCastRange(self, location, target)
end
function dota688_techies_remote_mines:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	caster.dota688_remote_mines = caster.dota688_remote_mines or {}
	local alive = {}
	for _, m in ipairs(caster.dota688_remote_mines) do if not m:IsNull() and m:IsAlive() then table.insert(alive, m) end end
	local max = math.max(1, self:GetSpecialValueFor("max_mines"))
	while #alive >= max do table.remove(alive, 1):ForceKill(false) end
	local mine = Dota688Techies.Spawn("npc_dota688_techies_remote_mine", caster, self, pos, "modifier_dota688_techies_remote_mine", self:GetSpecialValueFor("duration"))
	if mine then
		table.insert(alive, mine)
		mine:AddAbility("dota688_techies_remote_mine_detonate"):SetLevel(1)
		EmitSoundOnLocationWithCaster(pos, "Hero_Techies.RemoteMine.Plant", caster)
	end
	caster.dota688_remote_mines = alive
end
function Dota688Techies.DetonateRemote(mine)
	if not mine or mine:IsNull() or not mine:IsAlive() then return end
	local m = mine:FindModifierByName("modifier_dota688_techies_remote_mine")
	if not m then return end
	local a, caster = m:GetAbility(), m:GetCaster()
	if not caster or caster:IsNull() then return end
	if GameRules:GetGameTime() - m.start < Dota688Val(m, "activation_time") then return end
	local damage, radius = Dota688Val(m, "damage"), Dota688Val(m, "radius")
	if Dota688HasScepter(caster) then damage, radius = Dota688Val(m, "damage_scepter"), Dota688Val(m, "radius_scepter") end
	Dota688Techies.Explode(mine, caster, a, damage, DAMAGE_TYPE_MAGICAL, radius,
		"particles/units/heroes/hero_techies/techies_remote_mines_detonate.vpcf", "Hero_Techies.RemoteMine.Detonate")
	AddFOWViewer(caster:GetTeamNumber(), mine:GetAbsOrigin(), a:GetSpecialValueFor("vision_radius"), a:GetSpecialValueFor("vision_duration"), false)
	mine:ForceKill(false)
end
modifier_dota688_techies_remote_mine = Dota688Techies.MineModifier("activation_time")
function modifier_dota688_techies_remote_mine:OnIntervalThink() end
function modifier_dota688_techies_remote_mine:CheckState()
	return { [MODIFIER_STATE_INVISIBLE] = self:Faded(), [MODIFIER_STATE_ROOTED] = true, [MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true, [MODIFIER_STATE_NO_HEALTH_BAR] = true, [MODIFIER_STATE_MAGIC_IMMUNE] = true }
end
-- abilitatea de pe mina: detonare individuala
dota688_techies_remote_mine_detonate = class({})
function dota688_techies_remote_mine_detonate:OnSpellStart() Dota688Techies.DetonateRemote(self:GetCaster()) end
