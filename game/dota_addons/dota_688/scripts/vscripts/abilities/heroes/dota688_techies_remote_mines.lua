-- Remote Mines (6.88): mina invizibila detonabila manual (sau prin Focused Detonate), 300/450/600 daune magice in 425, dureaza 10 min, max 21.
require("abilities/heroes/dota688_techies_shared")
local F = "abilities/heroes/dota688_techies_remote_mines"
LinkLuaModifier("modifier_dota688_techies_remote_mine", F, LUA_MODIFIER_MOTION_NONE)
dota688_techies_remote_mines = class({})
function dota688_techies_remote_mines:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_techies_remote_mines:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	caster.dota688_remote_mines = caster.dota688_remote_mines or {}
	local alive = {}
	for _, m in ipairs(caster.dota688_remote_mines) do if not m:IsNull() and m:IsAlive() then table.insert(alive, m) end end
	while #alive >= self:GetSpecialValueFor("max_mines") do table.remove(alive, 1):ForceKill(false) end
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
	if GameRules:GetGameTime() - m.start < a:GetSpecialValueFor("activation_time") then return end
	Dota688Techies.Explode(mine, caster, a, a:GetSpecialValueFor("damage"), DAMAGE_TYPE_MAGICAL, a:GetSpecialValueFor("radius"),
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
