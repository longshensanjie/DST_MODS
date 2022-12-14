local InventoryFunctions = require "util/inventoryfunctions"
local ConfigFunctions = require "util/configfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

local CanWalkTo = {
    [ACTIONS.RUMMAGE] = true,
    [ACTIONS.DRY] = true,
    [ACTIONS.BAIT] = true,
    [ACTIONS.ADDFUEL] = true,
    [ACTIONS.ADDWETFUEL] = true,
    [ACTIONS.PICK] = true,
    [ACTIONS.GIVE] = true,
    [ACTIONS.GIVETOPLAYER] = true,
    [ACTIONS.GIVEALLTOPLAYER] = true,
    [ACTIONS.FEEDPLAYER] = true,
    [ACTIONS.COOK] = true,
    [ACTIONS.SLEEPIN] = true,
    [ACTIONS.PLANT] = true,
    [ACTIONS.HARVEST] = true,
    [ACTIONS.SMOTHER] = true,
    [ACTIONS.PICKUP] = true,
    [ACTIONS.JUMPIN] = true,
    [ACTIONS.MIGRATE] = true,
    [ACTIONS.STEER_BOAT] = true,
    [ACTIONS.MOUNT_PLANK] = true
}

local function IsShenHuaClickAction()
    local right_buffaction = ThePlayer.components.playercontroller:GetRightMouseAction()
    if right_buffaction and right_buffaction.action.id == "CASTAOE" then return false end
    return true
end

local function IsCompatibleLeftClickAction()
    local buffaction = ThePlayer.components.playercontroller:GetLeftMouseAction()
    if not buffaction then
        return true
    end

    return CanWalkTo[buffaction.action]
end

local AUTO_EQUIP_CANE = GetModConfigData("boas_AUTO_EQUIP_CANE", MOD_EQUIPMENT_CONTROL.MODNAME)

local function ValidateCaneClick()
    return IsCompatibleLeftClickAction() and TheInput:GetHUDEntityUnderMouse() == nil
end

local function IsLightSourceEquipped()
    local equipped = InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HANDS)

    if not equipped then
        return false
    end

    return Categories.LIGHTSOURCE.fn(equipped)
end

local function IsElseEquipped()
    local equipped = InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HANDS)
    if not equipped then
        return false
    end
    -- 不要切手杖
    local dt = {"reskin_tool","umbrella", "thurible","farm_hoe", "golden_farm_hoe", "pitchfork", "wateringcan", "premiumwateringcan",
                "lureplant_rod", "grass_umbrella", "bugnet", "malbatross_beak", "oar", "oar_driftwood",
                "yellowstaff","opalstaff","greenstaff","telestaff","purple_gourd",
                "oceanfishingrod", "fishingrod","oar_monkey"}
    if table.contains(dt, equipped.prefab) then
        return true
    end
    return false
end

local function ShouldEquipCane()
    return not Categories.CANE.fn(InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HANDS))
end

local function CanEquipCane()
    return AUTO_EQUIP_CANE and not IsLightSourceEquipped() and not InventoryFunctions:IsHeavyLifting() and
               not IsElseEquipped() and ShouldEquipCane() and IsShenHuaClickAction()
end

local function EquipCane()
    InventoryFunctions:Equip(ThePlayer.components.actioncontroller:GetItemFromCategory("CANE"), true)
end

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller

    if not PlayerController then
        return
    end

    local PlayerControllerOnLeftClick = PlayerController.OnLeftClick
    function PlayerController:OnLeftClick(down)
        if down and CanEquipCane() and ValidateCaneClick() then
            EquipCane()

            -- Avoid action interference
            self.inst:DoTaskInTime(GetTickTime(), function()
                PlayerControllerOnLeftClick(self, down)
            end)
            return
        end

        PlayerControllerOnLeftClick(self, down)
    end

    local PlayerControllerDoDragWalking = PlayerController.DoDragWalking
    function PlayerController:DoDragWalking(...)
        local isDragWalking = PlayerControllerDoDragWalking(self, ...)

        if isDragWalking and CanEquipCane() then
            EquipCane()
        end

        return isDragWalking
    end

    local PlayerControllerDoDirectWalking = PlayerController.DoDirectWalking
    function PlayerController:DoDirectWalking(...)
        PlayerControllerDoDirectWalking(self, ...)
        if self.directwalking and CanEquipCane() then
            EquipCane()
        end
    end
end

if GetModConfigData("boas_AUTO_EQUIP_CANE", MOD_EQUIPMENT_CONTROL.MODNAME) then
    KeybindService:AddKey("boas_TOGGLE", function()
        AUTO_EQUIP_CANE = ConfigFunctions:DoToggle("自动切装备", AUTO_EQUIP_CANE)
    end)
end
return Init
