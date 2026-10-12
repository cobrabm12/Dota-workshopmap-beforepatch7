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
	-- (marcajele sunt puse de abilities/heroes/dota688_necrolyte_reapers_scythe.lua in momentul loviturii)
	local noBuyback = false
	if hero.dota688_scythe_time and GameRules:GetGameTime() - hero.dota688_scythe_time < 0.5 then
		t = t + (hero.dota688_scythe_respawn or 0)
		-- Scepter 6.88: eroii omorati de Reaper's Scythe nu pot face buyback
		noBuyback = Dota688HasScepter and Dota688HasScepter(hero.dota688_scythe_caster)
	end
	hero.dota688_scythe_time = nil
	hero:SetTimeUntilRespawn(t)
	if noBuyback then hero:SetBuybackCooldownTime(t) end
	self:UpdateBuybackCost(hero)
end

function M:UpdateBuybackCost(hero)
	if not hero or hero:IsNull() then return end
	local cost = C.BuybackCost(hero:GetLevel(), GameRules:GetDOTATime(false, false))
	-- CDOTA_BaseNPC_Hero:SetBuybackCost nu mai exista; costul se seteaza pe jucator
	local pid = hero:GetPlayerOwnerID()
	if pid and pid >= 0 then PlayerResource:SetCustomBuybackCost(pid, math.floor(cost)) end
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
