local InventoryFunctions = require "util/inventoryfunctions"
local ConfigFunctions = require "util/configfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

-- 
-- Logic
-- 

local AutoEquipFns = {}

local function AddAutoEquip(config, trigger, fn)
    if GetModConfigData("boas_AUTO_RE_EQUIP_WEAPON", MOD_EQUIPMENT_CONTROL.MODNAME) then
        AutoEquipFns[#AutoEquipFns + 1] =
        {
            trigger = trigger,
            fn = fn
        }
    end
end

-- 
-- Helpers
-- 

local function GlasscutterTrigger(target)
    return target:HasTag("shadow")
        or target:HasTag("shadowminion")
        or target:HasTag("shadowchesspiece")
        or target:HasTag("stalker")
        or target:HasTag("stalkerminion")
end

local AUTO_EQUIP_WEAPON = GetModConfigData("boas_AUTO_RE_EQUIP_WEAPON", MOD_EQUIPMENT_CONTROL.MODNAME)

local function IsRangeWeaponEquipped()
    local equipped = InventoryFunctions:GetEquippedItem(EQUIPSLOTS.HANDS)

    if not equipped then
        return false
    end

    return Categories.RANGED.fn(equipped)
end
local weaponot = {"icestaff", "firestaff"}

local function WeaponTrigger(target)
    local handsitem = ThePlayer and EQUIPSLOTS and ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    return AUTO_EQUIP_WEAPON
       and not IsRangeWeaponEquipped()
       -- 打蝴蝶不切武器
       and not target:HasTag("butterfly")
       and not (ThePlayer and  ThePlayer.replica.rider and ThePlayer.replica.rider:IsRiding())   -- 骑牛不切
        -- 打鬼手不切武器
       and not (target.prefab == "shadowchanneler")
       and not (target.prefab == "stalker_minion")
       and not (target.prefab == "stalker_minion1")
       and not (target.prefab == "stalker_minion2")
       -- 装备这些不要自动切武器
       and not (handsitem and table.contains(weaponot, handsitem.prefab))
end

local function GetPrefabFromInventory(prefab)
    for _, invItem in pairs(InventoryFunctions:GetPlayerInventory(true)) do
        if invItem.prefab == prefab then
            return invItem
        end
    end

    return nil
end

local function EquipWeapon(target)
    if not ThePlayer or not ThePlayer.components.actioncontroller then
        return
    end


    local weapon = ThePlayer.components.actioncontroller:GetAutoEquipCategoryItem(target)

    InventoryFunctions:Equip(weapon, true)
end

local function EquipGlasscutter()
    local weapon = GetPrefabFromInventory("glasscutter")

    if not weapon then
        EquipWeapon()
        return
    end

    InventoryFunctions:Equip(weapon, true)
end

-- 
-- Auto equips
-- 

-- AddAutoEquip("AUTO_EQUIP_GLASSCUTTER", GlasscutterTrigger, EquipGlasscutter)
AddAutoEquip("AUTO_EQUIP_WEAPON", WeaponTrigger, EquipWeapon)

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller

    if not PlayerController then
        return
    end

    -- local PlayerControllerDoAttackButton = PlayerController.DoAttackButton
    -- function PlayerController:DoAttackButton(retarget)
    --     local force_attack = TheInput:IsControlPressed(CONTROL_FORCE_ATTACK)
    --     local target = self:GetAttackTarget(force_attack, retarget, retarget ~= nil)

    --     if target then
    --         for i = 1, #AutoEquipFns do
    --             if AutoEquipFns[i].trigger(target) then
    --                 AutoEquipFns[i].fn(target)
    --                 break
    --             end
    --         end
    --     end

    --     PlayerControllerDoAttackButton(self, retarget)
    -- end

    local OldGetAttackTarget = PlayerController.GetAttackTarget
    function PlayerController:GetAttackTarget(...)
        local force_target = OldGetAttackTarget(self, ...)

        if force_target then
            for i = 1, #AutoEquipFns do
                if AutoEquipFns[i].trigger(force_target) then
                    AutoEquipFns[i].fn(force_target)
                    break
                end
            end
        end

        return force_target
    end
end
if GetModConfigData("boas_AUTO_EQUIP_CANE", MOD_EQUIPMENT_CONTROL.MODNAME) then
    KeybindService:AddKey("boas_TOGGLE", function()
        AUTO_EQUIP_WEAPON = ConfigFunctions:DoToggle("自动切装备", AUTO_EQUIP_WEAPON)
    end)
end
return Init
