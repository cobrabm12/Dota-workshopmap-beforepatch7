-- Focused Detonate (6.88): detoneaza toate Remote Mines din raza 700 de punctul ales.
require("abilities/heroes/dota688_techies_remote_mines")
dota688_techies_focused_detonate = class({})
function dota688_techies_focused_detonate:GetAOERadius() return self:GetSpecialValueFor("radius") end
function dota688_techies_focused_detonate:OnSpellStart()
	local caster, pos = self:GetCaster(), self:GetCursorPosition()
	for _, m in ipairs(caster.dota688_remote_mines or {}) do
		if not m:IsNull() and m:IsAlive() and (m:GetAbsOrigin() - pos):Length2D() <= self:GetSpecialValueFor("radius") then
			Dota688Techies.DetonateRemote(m)
		end
	end
end
