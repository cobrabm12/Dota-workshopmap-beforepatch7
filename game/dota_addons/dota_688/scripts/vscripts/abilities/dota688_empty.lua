-- Slot gol: abilitate pasiva, ascunsa, fara efect.
dota688_empty = class({})
function dota688_empty:IsHidden() return true end
function dota688_empty:ProcsMagicStick() return false end
function dota688_empty:GetIntrinsicModifierName() return nil end
