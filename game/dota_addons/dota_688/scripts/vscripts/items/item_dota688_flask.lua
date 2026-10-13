require("items/dota688_item_base")
-- Healing Salve (6.88): consumabil (1 incarcatura, se cumuleaza in slot, fara stoc in shop), tinta: eroul propriu sau un erou aliat
-- (raza 250). Reface 400 HP in 8 s (50/s) - intreg si pe aliati (motorul curent injumatateste pe aliati).
-- "If the unit is attacked, the effect is lost": in 6.88 efectul se pierdea la daune (atac sau spell) de la o sursa inamica
-- controlata de un jucator (eroi, iluzii, unitati invocate/controlate) sau de la Roshan; daunele de la creep-uri, neutrali si
-- turnuri si cele proprii/aliate nu il opresc. O noua folosire cat timp efectul e activ doar reimprospateaza durata.
LinkLuaModifier("modifier_dota688_flask_healing", "items/item_dota688_flask", LUA_MODIFIER_MOTION_NONE)

Dota688DefineItem("item_dota688_flask", "items/item_dota688_flask", {
	item = {
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			local target = self:GetCursorTarget()
			if not target or target:IsNull() then return end
			local duration = self:GetSpecialValueFor("buff_duration")
			local regen = duration > 0 and self:GetSpecialValueFor("total_health") / duration or 0
			target:AddNewModifier(caster, self, "modifier_dota688_flask_healing", { duration = duration, regen = regen })
			target:EmitSound("DOTA_Item.HealingSalve.Activate")
			self:SpendCharge(0)
		end,
	},
})

-- regenerarea (total_health / buff_duration); stack = regen x 100 (vazut si de client). Valorile vin prin kv:
-- itemul dispare dupa ultima incarcatura, deci modifier-ul nu depinde de GetAbility().
modifier_dota688_flask_healing = class({})
function modifier_dota688_flask_healing:IsPurgable() return true end
function modifier_dota688_flask_healing:GetTexture() return "item_flask" end
function modifier_dota688_flask_healing:GetEffectName() return "particles/items_fx/healing_flask.vpcf" end
function modifier_dota688_flask_healing:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_flask_healing:OnCreated(kv)
	if IsServer() then self:SetStackCount(math.floor((kv.regen or 0) * 100 + 0.5)) end
end
function modifier_dota688_flask_healing:OnRefresh(kv)
	if IsServer() then self:SetStackCount(math.floor((kv.regen or 0) * 100 + 0.5)) end
end
function modifier_dota688_flask_healing:DeclareFunctions() return { MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, MODIFIER_EVENT_ON_TAKEDAMAGE } end
function modifier_dota688_flask_healing:GetModifierConstantHealthRegen() return self:GetStackCount() / 100 end
function modifier_dota688_flask_healing:OnTakeDamage(params)
	if not IsServer() then return end
	local parent = self:GetParent()
	if params.unit ~= parent or (params.damage or 0) <= 0 then return end
	local att = params.attacker
	if not att or att:IsNull() or att == parent or att:GetTeamNumber() == parent:GetTeamNumber() then return end
	-- sursa controlata de un jucator: eroi (si iluzii) sau unitati cu proprietar jucator; plus Roshan
	local player = att:IsHero() or (att.GetPlayerOwnerID and att:GetPlayerOwnerID() >= 0)
	if player or att:GetUnitName() == "npc_dota_roshan" then self:Destroy() end
end
