-- Modifierii globali ai addon-ului. Fisierul se incarca si pe client (din abilities/dota688_attribute_bonus.lua,
-- pe care o au toti eroii): LinkLuaModifier facut doar pe server lasa clientul fara clasa modifier-ului
-- ("Attempted to create unknown modifier type"), deci fara stari/proprietati/tooltip pe client.
LinkLuaModifier("modifier_dota688_attributes", "modifiers/modifier_dota688_attributes", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_roshan", "modifiers/modifier_dota688_roshan", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_invoker_orbs", "modifiers/modifier_dota688_invoker_orbs", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_familiar", "modifiers/modifier_dota688_familiar", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_glyph", "modifiers/modifier_dota688_glyph", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_tower_aura", "modifiers/modifier_dota688_tower_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_tower_aura_effect", "modifiers/modifier_dota688_tower_aura", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_fountain", "modifiers/modifier_dota688_fountain", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_fountain_effect", "modifiers/modifier_dota688_fountain", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_courier", "modifiers/modifier_dota688_courier", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_courier_burst", "modifiers/modifier_dota688_courier_burst", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_dota688_courier_dead", "modifiers/modifier_dota688_courier_dead", LUA_MODIFIER_MOTION_NONE)
require("dota688/runes_link")   -- modifierii runelor de putere 6.88 (si pe client)
