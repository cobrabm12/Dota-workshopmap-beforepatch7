-- Glyph of Fortification (6.88): 5 s de invulnerabilitate pentru cladirile echipei (turnuri, baraci, Ancient, fillere).
-- Nu afecteaza creepii si nu da turnurilor tinte in plus (glyph-ul modern). Aplicat de Dota688Buildings:UseGlyph;
-- glyph-ul motorului e oprit din filtrul de ordine.
modifier_dota688_glyph = class({})

function modifier_dota688_glyph:IsHidden() return false end
function modifier_dota688_glyph:IsPurgable() return false end
function modifier_dota688_glyph:IsDebuff() return false end
function modifier_dota688_glyph:GetTexture() return "fountain_glyph" end
function modifier_dota688_glyph:GetAttributes() return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE end

function modifier_dota688_glyph:CheckState()
	return { [MODIFIER_STATE_INVULNERABLE] = true }
end

function modifier_dota688_glyph:GetEffectName() return "particles/items_fx/glyph.vpcf" end
function modifier_dota688_glyph:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
