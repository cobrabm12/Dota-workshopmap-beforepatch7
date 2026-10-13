require("items/dota688_item_base")
-- Bloodstone (6.88): +475 HP, +425 mana, +9 regen HP, +200% regen mana. Bloodpact: 12 incarcaturi la inceput, +1 cand moare
-- un erou inamic in 1600; fiecare incarcatura da +1 mana pe secunda si -3 s la respawn. La moarte: aliatii din 1675 primesc
-- 500 + 30/incarcatura HP, iar Bloodstone-ul pierde o treime din incarcaturi (on_death_removal 0.67 = cat ramane).
-- Doar primul Bloodstone din inventar primeste incarcaturi (si se aplica la moarte). Activ: Pocket Deny (te omoara).
local function IsFirstBloodstone(parent, a)
	for s = 0, 5 do
		local it = parent:GetItemInSlot(s)
		if it and it:GetAbilityName() == a:GetAbilityName() then return it == a end
	end
	return false
end

Dota688DefineItem("item_dota688_bloodstone", "items/item_dota688_bloodstone", {
	extraFunctions = { MODIFIER_EVENT_ON_DEATH },
	onCreated = function(self)
		local a = self:GetAbility()
		if IsServer() and not a.dota688_init then a.dota688_init = true; a:SetCurrentCharges(a:GetSpecialValueFor("charges") ~= 0 and a:GetSpecialValueFor("charges") or 12) end
	end,
	-- +1 mana pe secunda pentru fiecare incarcatura
	manaRegen = function(self)
		local a = self:GetAbility()
		return (a and not a:IsNull()) and a:GetCurrentCharges() or 0
	end,
	modifier = {
		OnDeath = function(self, params)
			if not IsServer() then return end
			local parent, unit, a = self:GetParent(), params.unit, self:GetAbility()
			if not IsFirstBloodstone(parent, a) then return end
			if unit == parent then
				local charges = a:GetCurrentCharges()
				local heal = a:GetSpecialValueFor("heal_on_death_base") + a:GetSpecialValueFor("heal_on_death_per_charge") * charges
				local allies = FindUnitsInRadius(parent:GetTeamNumber(), parent:GetAbsOrigin(), nil, a:GetSpecialValueFor("heal_on_death_range"), DOTA_UNIT_TARGET_TEAM_FRIENDLY,
					DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
				for _, u in ipairs(allies) do if u ~= parent then u:Heal(heal, a) end end
				if parent:IsRealHero() then
					Dota688Timers:After(0.1, function()
						if not parent:IsNull() and not parent:IsAlive() then
							parent:SetTimeUntilRespawn(math.max(1, parent:GetTimeUntilRespawn() - a:GetSpecialValueFor("respawn_time_reduction") * charges))
						end
					end)
				end
				a:SetCurrentCharges(math.floor(charges * a:GetSpecialValueFor("on_death_removal")))
			elseif unit:IsRealHero() and not unit:IsIllusion() and unit:GetTeamNumber() ~= parent:GetTeamNumber()
				and (unit:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D() <= a:GetSpecialValueFor("charge_range") then
				a:SetCurrentCharges(a:GetCurrentCharges() + 1)
			end
		end,
	},
	item = {
		OnSpellStart = function(self)
			-- Pocket Deny (6.88): te omoara pe loc; fiind sinucidere, inamicii nu primesc aur sau XP
			local caster = self:GetCaster()
			caster:EmitSound("DOTA_Item.Bloodstone.Activate")
			caster:Kill(self, caster)
		end,
	},
})
