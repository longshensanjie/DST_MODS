local InventoryFunctions = require "util/inventoryfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE
local ConfigFunctions = require "util/configfunctions"

local AUTO_EQUIP_LIGHTSOURCE = GetModConfigData("boas_AUTO_EQUIP_LIGHTSOURCE", MOD_EQUIPMENT_CONTROL.MODNAME)
local AUTO_EQUIP_LIGHTSOURCE_DELAY = AUTO_EQUIP_LIGHTSOURCE and AUTO_EQUIP_LIGHTSOURCE or 0
if AUTO_EQUIP_LIGHTSOURCE == true then  -- 为了适配玩家用旧配置玩新模组
    AUTO_EQUIP_LIGHTSOURCE_DELAY = 0
end
local function GetLightSource(recur)
    if ThePlayer.components.playercontroller then
        local lightsources = ThePlayer.components.actioncontroller:GetItemsFromCategory("LIGHTSOURCE")


        if #lightsources > 0 then
            return lightsources[1]
        end
    end

    return nil
end

local function EquipLight()
    local item = GetLightSource()

    if not item or InventoryFunctions:IsEquipped(item) then
        return item
    end
    Sleep(AUTO_EQUIP_LIGHTSOURCE_DELAY)
    InventoryFunctions:Equip(item)

    return item
end

local function Unequip(item)
    if not InventoryFunctions:IsEquipped(item) or not InventoryFunctions:HasFreeSlot() then
        return false
    end

    SendRPCToServer(RPC.ControllerUseItemOnSelfFromInvTile, ACTIONS.UNEQUIP.code, item)

    return true
end

local EmitLookup =
{
    yellowamulet = 0.788,
    lantern = 0.739,
    minerhat = 0.739,
    torch = 0.730,
    lighter = 0.601,
    molehat = 0.01, -- Kinda hacky
}

local function GetEmitValue()
    local ret = 0

    for _, equip in pairs(InventoryFunctions:GetEquips()) do
        if not equip:HasTag("fueldepleted") and EmitLookup[equip.prefab] then
            ret = ret + EmitLookup[equip.prefab]
        end
    end
    local equipped = InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HANDS)
    if equipped and (equipped.prefab == "myth_redlantern" or equipped.prefab == "redlantern") then return 1 end

    return ret
end

local LightTresh = .051 -- .05 from /prefabs/player_common

local function IsInDarkness()
    local emitVal = GetEmitValue()

    if emitVal > 0 then
        local lightValue = string.format(
                                "%.3f",
                                ThePlayer.LightWatcher:GetLightValue()
                           )
        lightValue = tonumber(lightValue)
        local lightDelta = lightValue - emitVal
        if lightDelta < LightTresh then
            return true
        end
    end

    return false
end

local function Init()
    if not ThePlayer or not ThePlayer.LightWatcher then
        return
    end

    StartThread(function()
        while ThePlayer do
            while not AUTO_EQUIP_LIGHTSOURCE do Sleep(2) end
            if ThePlayer.LightWatcher:GetTimeInDark() > 0 then
                local lightsource = EquipLight()
                if lightsource then
                    Sleep(FRAMES * 4)
                    while IsInDarkness() do
                        Sleep(.25)
                    end
                    Unequip(lightsource)
                end
            end
            Sleep(.5)
        end
    end, "AutoLightThread")
end
if GetModConfigData("boas_AUTO_EQUIP_CANE", MOD_EQUIPMENT_CONTROL.MODNAME) then
    KeybindService:AddKey("boas_TOGGLE", function()
        AUTO_EQUIP_LIGHTSOURCE = ConfigFunctions:DoToggle("自动切装备", AUTO_EQUIP_LIGHTSOURCE)
    end)
end
return Init
