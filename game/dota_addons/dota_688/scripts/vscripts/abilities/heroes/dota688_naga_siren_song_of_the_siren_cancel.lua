-- Song of the Siren Cancel (6.88): opreste cantecul mai devreme.
dota688_naga_siren_song_of_the_siren_cancel = class({})
function dota688_naga_siren_song_of_the_siren_cancel:OnSpellStart()
	local song = self:GetCaster():FindAbilityByName("dota688_naga_siren_song_of_the_siren")
	if song then song:Stop() end
end
