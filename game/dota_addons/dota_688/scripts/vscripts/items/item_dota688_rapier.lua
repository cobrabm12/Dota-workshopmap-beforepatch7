require("items/dota688_item_base")
-- Divine Rapier (6.88): pasiv +330 daune (fara toggle si fara bonusul de baza din 7.x). Nu se vinde, nu poate fi distrus.
-- Cade pe jos la moartea purtatorului (nu la moartea iluziilor/Tempest Double si nici cand eroul reinvie cu Aegis/Reincarnation).
-- Ridicat de un aliat al proprietarului: nu da bonusul pana nu ajunge inapoi la proprietar.
-- Ridicat de un inamic al proprietarului: devine al lui (bonus imediat) si nu mai poate fi aruncat decat prin moarte.
-- Un Rapier care a stat pe jos nu poate fi ridicat de un curier (curierul il lasa imediat jos).
-- Stare: stack 1 = bonus activ (calculat pe server, vazut si de client).

local function Later(fn)
	if Dota688Timers then Dota688Timers:After(0, fn) else fn() end
end

local function InInventory(unit, item)
	for s = DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9 do
		if unit:GetItemInSlot(s) == item then return true end
	end
	return false
end

local function OwnerHero(unit)
	if unit:IsRealHero() then return unit end
	local pid = unit:GetPlayerOwnerID()
	if pid ~= nil and pid >= 0 then return PlayerResource:GetSelectedHeroEntity(pid) end
	return nil
end

Dota688DefineItem("item_dota688_rapier", "items/item_dota688_rapier", {
	extraFunctions = { MODIFIER_EVENT_ON_DEATH },
	onCreated = function(self)
		if not IsServer() then return end
		local a = self:GetAbility()
		local parent = self:GetParent()
		if not a or a:IsNull() then return end
		if parent:IsCourier() then
			if a.dota688_dropped then
				Later(function()
					if a:IsNull() or parent:IsNull() or not InInventory(parent, a) then return end
					parent:DropItemAtPositionImmediate(a, parent:GetAbsOrigin())
				end)
			end
			return
		end
		a.dota688_dropped = false
		local owner = a:GetPurchaser()
		if owner == nil or owner:IsNull() then
			owner = OwnerHero(parent)
			if owner then a:SetPurchaser(owner) end
		elseif owner:GetTeamNumber() ~= parent:GetTeamNumber() then
			-- luat de la un inamic: devine al noului purtator si nu mai poate fi aruncat
			local hero = OwnerHero(parent)
			if hero then
				a:SetPurchaser(hero)
				a:SetDroppable(false)
				owner = hero
			end
		end
		local usable = owner == nil or owner:IsNull() or owner:GetPlayerOwnerID() == parent:GetPlayerOwnerID()
		self:SetStackCount(usable and 1 or 0)
	end,
	modifier = {
		GetModifierPreAttack_BonusDamage = function(self)
			if self:GetStackCount() == 0 then return 0 end
			return self:GetAbility():GetSpecialValueFor("bonus_damage")
		end,
		OnDeath = function(self, params)
			if not IsServer() then return end
			local parent = self:GetParent()
			if params.unit ~= parent then return end
			if parent:IsIllusion() or parent:IsTempestDouble() or parent:IsCourier() or parent:IsReincarnating() then return end
			local a = self:GetAbility()
			local pos = parent:GetAbsOrigin()
			a.dota688_dropped = true
			Later(function()
				if a:IsNull() or parent:IsNull() or not InInventory(parent, a) then return end
				parent:DropItemAtPositionImmediate(a, pos)
			end)
		end,
		-- aruncat de purtator: tinem minte ca a stat pe jos (curierii nu il pot ridica)
		OnDestroy = function(self)
			if not IsServer() then return end
			local a = self:GetAbility()
			Later(function()
				if a and not a:IsNull() and a:GetContainer() ~= nil then a.dota688_dropped = true end
			end)
		end,
	},
})
