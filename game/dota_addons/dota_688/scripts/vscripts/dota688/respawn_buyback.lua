-- Timpi de respawn si buyback dupa 6.88.
local C = DOTA688
Dota688Respawn = Dota688Respawn or {}
local M = Dota688Respawn

function M:Init(gamemode)
	self.gamemode = gamemode
	-- costul de buyback depinde de timpul de joc: il recalculam periodic pentru toti eroii
	Dota688Timers:Every(1.0, function() M:UpdateBuybackCosts() end)
end

function M:OnHeroSpawned(hero)
	hero:SetBuybackCooldownTime(0)
	self:UpdateBuybackCost(hero)
end

function M:OnHeroKilled(hero, attacker)
	local t = C.RespawnTime(hero:GetLevel())
	-- Nota: 6.88 nu avea timp minim de 26 s pentru moartea la neutrali (adaugat in 7.00).
	-- Reaper's Scythe (6.88): +10/20/30 s la respawn daca eroul moare sub efectul lui
	local scythe = hero:FindModifierByName("modifier_necrolyte_reapers_scythe")
	if scythe and scythe:GetAbility() then
		t = t + scythe:GetAbility():GetSpecialValueFor("respawn_constant")
	end
	hero:SetTimeUntilRespawn(t)
	self:UpdateBuybackCost(hero)
end

function M:UpdateBuybackCost(hero)
	if not hero or hero:IsNull() then return end
	local cost = C.BuybackCost(hero:GetLevel(), GameRules:GetDOTATime(false, false))
	hero:SetBuybackCost(cost)
end

function M:UpdateBuybackCosts()
	for pid = 0, DOTA_MAX_TEAM_PLAYERS - 1 do
		if PlayerResource:IsValidPlayerID(pid) and PlayerResource:HasSelectedHero(pid) then
			local hero = PlayerResource:GetSelectedHeroEntity(pid)
			if hero then self:UpdateBuybackCost(hero) end
		end
	end
end

function M:OnBuyback(ev)
	local pid = ev.player_id
	if pid == nil then return end
	local hero = PlayerResource:GetSelectedHeroEntity(pid)
	if not hero then return end
	-- 6.84-7.10: dupa buyback, tot aurul castigat este redus cu 60% pana expira timpul de respawn pe care l-ai fi avut
	local remaining = hero:GetTimeUntilRespawn()
	if remaining and remaining > 0 then
		Dota688GoldXP:SetBuybackPenalty(pid, remaining)
	end
	hero:SetBuybackCooldownTime(C.BUYBACK_COOLDOWN)
end
