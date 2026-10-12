require("items/dota688_item_base")
-- Dust of Appearance (6.88): 2 incarcaturi, 5 mana, cd 30. La folosire pune un debuff pe unitatile inamice aflate
-- atunci in raza de 1050 (fara zona pe sol, fara daune): 12 s sunt vazute de inamici cand sunt invizibile
-- (true sight, ca un Gem/Sentry - Shadow Dance ramane imun) si sunt incetinite cu 20% cat timp sunt invizibile.
-- Debuff-ul se poate purja (ex. Manta). Nu afecteaza ward-urile si minele lui Techies.
LinkLuaModifier("modifier_dota688_dust", "items/item_dota688_dust", LUA_MODIFIER_MOTION_NONE)

Dota688DefineItem("item_dota688_dust", "items/item_dota688_dust", {
	item = {
		OnSpellStart = function(self)
			local caster = self:GetCaster()
			local pos = caster:GetAbsOrigin()
			local radius = self:GetSpecialValueFor("radius")
			local kv = { duration = self:GetSpecialValueFor("duration"), slow = -self:GetSpecialValueFor("movespeed") }
			caster:EmitSound("DOTA_Item.DustOfAppearance.Activate")
			local fx = ParticleManager:CreateParticle("particles/items_fx/dust_of_appearance.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(fx, 0, pos)
			ParticleManager:SetParticleControl(fx, 1, Vector(radius, radius, radius))
			ParticleManager:ReleaseParticleIndex(fx)
			local enemies = FindUnitsInRadius(caster:GetTeamNumber(), pos, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY,
				DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE,
				FIND_ANY_ORDER, false)
			for _, e in ipairs(enemies) do
				if not e:IsOther() and string.find(e:GetUnitName(), "npc_dota688_techies_", 1, true) ~= 1 then
					e:AddNewModifier(caster, self, "modifier_dota688_dust", kv)
				end
			end
			self:SpendCharge(0)
		end,
	},
})

-- itemul dispare dupa ultima incarcatura: valorile vin prin kv, nu din GetAbility()
modifier_dota688_dust = class({})
function modifier_dota688_dust:IsDebuff() return true end
function modifier_dota688_dust:IsPurgable() return true end
function modifier_dota688_dust:GetTexture() return "item_dust" end
function modifier_dota688_dust:GetEffectName() return "particles/items_fx/dust_of_appearance_debuff.vpcf" end
function modifier_dota688_dust:GetEffectAttachType() return PATTACH_ABSORIGIN_FOLLOW end
function modifier_dota688_dust:OnCreated(kv)
	if not IsServer() then return end
	self.slow = kv.slow or 20
	self:Reveal(kv.duration)
	self:OnIntervalThink()
	self:StartIntervalThink(0.1)
end
function modifier_dota688_dust:OnRefresh(kv)
	if not IsServer() then return end
	self.slow = kv.slow or self.slow
	self:Reveal(kv.duration)
end
-- dezvaluirea: modifier-ul motorului "modifier_truesight" (acelasi pe care il pun Gem/Sentry), vazut de echipa caster-ului
function modifier_dota688_dust:Reveal(duration)
	if self.ts and not self.ts:IsNull() then self.ts:Destroy() end
	self.ts = self:GetParent():AddNewModifier(self:GetCaster(), nil, "modifier_truesight", { duration = duration or 12 })
end
-- incetinirea doar cat timp unitatea e invizibila: stack = % incetinire (calculat pe server, vazut si de client)
function modifier_dota688_dust:OnIntervalThink()
	self:SetStackCount(self:GetParent():IsInvisible() and self.slow or 0)
end
function modifier_dota688_dust:OnDestroy()
	if IsServer() and self.ts and not self.ts:IsNull() then self.ts:Destroy() end
end
function modifier_dota688_dust:DeclareFunctions() return { MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE } end
function modifier_dota688_dust:GetModifierMoveSpeedBonus_Percentage() return -self:GetStackCount() end
