require("items/dota688_item_base")
-- Hand of Midas (6.88): +30 AS; Transmute: ucide un creep non-ancient, +190 aur si 2.5x XP, cd 100.
Dota688DefineItem("item_dota688_hand_of_midas", "items/item_dota688_hand_of_midas", {
	item = {
		OnSpellStart = function(self)
			local caster, target = self:GetCaster(), self:GetCursorTarget()
			if not target or not target:IsAlive() then return end
			local xp = target:GetDeathXP() * self:GetSpecialValueFor("xp_multiplier")
			caster:EmitSound("DOTA_Item.Hand_Of_Midas")
			-- 6.88: fara bounty-ul normal al creep-ului si fara XP impartit (doar 190 aur + 2.5x XP pentru caster)
			target:SetMinimumGoldBounty(0)
			target:SetMaximumGoldBounty(0)
			target:SetDeathXP(0)
			target:Kill(self, caster)
			local pid = caster:GetPlayerOwnerID()
			if pid >= 0 then PlayerResource:ModifyGold(pid, self:GetSpecialValueFor("bonus_gold"), true, DOTA_ModifyGold_AbilityGold) end
			if caster:IsRealHero() then caster:AddExperience(xp, DOTA_ModifyXP_CreepKill, false, true) end
		end,
	},
})
