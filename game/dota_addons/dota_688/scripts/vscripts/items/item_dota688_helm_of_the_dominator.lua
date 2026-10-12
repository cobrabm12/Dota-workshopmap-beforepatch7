require("items/dota688_item_base")
-- Helm of the Dominator (6.88): +20 daune, +5 armura, +3 regen, 15% lifesteal; Dominate: preia controlul unui creep (min 1400 HP, 350 MS), cd 60, 75 mana.
Dota688DefineItem("item_dota688_helm_of_the_dominator", "items/item_dota688_helm_of_the_dominator", {
	item = {
		OnSpellStart = function(self)
			local caster, target = self:GetCaster(), self:GetCursorTarget()
			if not target or target:IsHero() or (target.IsAncient and target:IsAncient()) then return end
			local prev = caster.dota688_dominated
			if prev and not prev:IsNull() and prev:IsAlive() then prev:ForceKill(false) end
			target:SetTeam(caster:GetTeamNumber())
			target:SetOwner(caster:GetPlayerOwner())
			target:SetControllableByPlayer(caster:GetPlayerOwnerID(), true)
			target:AddNewModifier(caster, self, "modifier_dominated", { duration = self:GetSpecialValueFor("dominate_duration") })
			target:SetBaseMaxHealth(math.max(target:GetBaseMaxHealth(), self:GetSpecialValueFor("health_min")))
			target:SetMaxHealth(math.max(target:GetMaxHealth(), self:GetSpecialValueFor("health_min")))
			target:SetHealth(target:GetMaxHealth())
			target:SetBaseMoveSpeed(math.max(target:GetBaseMoveSpeed(), self:GetSpecialValueFor("speed_base")))
			target:EmitSound("DOTA_Item.HotD.Activate")
			caster.dota688_dominated = target
		end,
	},
})
