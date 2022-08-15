local InventoryFunctions = require "util/inventoryfunctions"
local ConfigFunctions = require "util/configfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

local UpdateRateInFrames = 5
-- local EPIC_TAGS = { "epic" }

-- local function IsNearBoss()
--     local x, y, z = ThePlayer.Transform:GetWorldPosition()
--     return #TheSim:FindEntities(x, y, z, 30, EPIC_TAGS) > 0
-- end

local AUTO_RE_EQUIP_ARMOR = GetModConfigData("boas_AUTO_RE_EQUIP_ARMOR", MOD_EQUIPMENT_CONTROL.MODNAME)


local function IsSleeping(target)
    return target.AnimState:IsCurrentAnimation("sleep_pre")
        or target.AnimState:IsCurrentAnimation("sleep_loop")
        or target.AnimState:IsCurrentAnimation("sleep_pst")
end

local function IsInCombat()
    local x, y, z = ThePlayer.Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x, y, z, 30, {"_combat"})

    for i = 1, #ents do
        if ents[i].replica and ents[i].replica.combat then
            if ents[i].replica.combat:GetTarget() == ThePlayer and not IsSleeping(ents[i]) then
                return true
            end
        end
    end

    -- @TODO This could be better
    -- return IsNearBoss()
end

local function EquipHelm()
    InventoryFunctions:Equip(
        ThePlayer.components.actioncontroller:GetItemFromCategory("ARMORHAT"),
        true
    )
end

local function UnEquipHelm()
    local item = InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HEAD)

    if not item then
        return
    end

    SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.UNEQUIP.code, item)
end

local function IsWearingHelm()
    return Categories.ARMORHAT.fn(InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HEAD))
end

local function AmountOfEquippedLightSources()
    local ret = 0

    for _, item in pairs(InventoryFunctions:GetEquips()) do
        if (Categories.LIGHTSOURCE.fn(item)) then
            ret = ret + 1
        end
    end

    return ret
end

local function CanEquipHelm()
    local equippedItem = InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HEAD)

    if not equippedItem then
        return true
    end

    return (AmountOfEquippedLightSources() > 1) or not Categories.LIGHTSOURCE.fn(equippedItem)
end

local function Init()
    if not ThePlayer then
        return
    end

    local trigger = nil
    local oldHelm = nil

    StartThread(function()
        while ThePlayer do
            while not AUTO_RE_EQUIP_ARMOR do Sleep(2) end
            if CanEquipHelm() and not IsWearingHelm() and IsInCombat() then
                oldHelm = InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HEAD)
                EquipHelm()
                trigger = true
            elseif trigger and not IsInCombat() and IsWearingHelm() then
                if oldHelm then
                    InventoryFunctions:Equip(oldHelm)
                elseif InventoryFunctions:HasFreeSlot() then
                    UnEquipHelm()
                end
                oldHelm = nil
                trigger = false
            end
            Sleep(UpdateRateInFrames * FRAMES)
        end
    end, "AutoHelmThread")
end
if GetModConfigData("boas_AUTO_EQUIP_CANE", MOD_EQUIPMENT_CONTROL.MODNAME) then
    KeybindService:AddKey("boas_TOGGLE", function()
        AUTO_RE_EQUIP_ARMOR = ConfigFunctions:DoToggle("自动切装备", AUTO_RE_EQUIP_ARMOR)
    end)
end
return Init
