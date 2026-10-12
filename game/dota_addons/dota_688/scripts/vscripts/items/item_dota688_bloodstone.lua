require("items/dota688_item_base")
-- Bloodstone (6.88): +475 HP, +425 mana, +9 regen, +200% regen mana; incarcaturi (12 initial): +1 la eroi inamici morti in 1600, -1/3 la moarte;
-- fiecare incarcatura +1 regen mana? (6.88: +1 HP regen si +... ) – simplificat: la moarte vindeca 500 + 30/incarcatura aliatii din 1675 si reduce respawn-ul cu 3 s/incarcatura. Activ: Pocket Suicide.
Dota688DefineItem("item_dota688_bloodstone", "items/item_dota688_bloodstone", {
	extraFunctions = { MODIFIER_EVENT_ON_DEATH },
	onCreated = function(self)
		local a = self:GetAbility()
		if IsServer() and not a.dota688_init then a.dota688_init = true; a:SetCurrentCharges(a:GetSpecialValueFor("charges") ~= 0 and a:GetSpecialValueFor("charges") or 12) end
	end,
	modifier = {
		OnDeath = function(self, params)
			if not IsServer() then return end
			local parent, unit, a = self:GetParent(), params.unit, self:GetAbility()
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
				a:SetCurrentCharges(math.floor(charges * (1 - a:GetSpecialValueFor("on_death_removal"))))
			elseif unit:IsRealHero() and not unit:IsIllusion() and unit:GetTeamNumber() ~= parent:GetTeamNumber()
				and (unit:GetAbsOrigin() - parent:GetAbsOrigin()):Length2D() <= a:GetSpecialValueFor("charge_range") then
				a:SetCurrentCharges(a:GetCurrentCharges() + 1)
			end
		end,
	},
	item = {
		OnSpellStart = function(self)
			-- Pocket Suicide (6.88): Bloodstone te omoara (fara penalizare de aur? – in 6.88: moarte normala)
			local caster = self:GetCaster()
			caster:EmitSound("DOTA_Item.Bloodstone.Activate")
			caster:Kill(self, caster)
		end,
	},
})
