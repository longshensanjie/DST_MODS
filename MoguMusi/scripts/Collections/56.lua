-- 自动换武器
local low_dur_first = true


local EXTRA_ITEMS = {
    "orangeamulet",
    "greenamulet",
    "brainhat",
}

local equiptask
local equips = {}

local function CancelEquipTask()
    if equiptask then
        equiptask:Cancel()
        equiptask = nil
    end
end

local function DoEquip(item)
    local playercontroller = GLOBAL.ThePlayer.components.playercontroller
    local playercontroller_deploy_mode = playercontroller.deploy_mode
    playercontroller.deploy_mode = false
    GLOBAL.ThePlayer.replica.inventory:ControllerUseItemOnSelfFromInvTile(item)
    playercontroller.deploy_mode = playercontroller_deploy_mode
end

local function equip_task_fn(_, item)
    if not item:IsValid()
        or GLOBAL.ThePlayer.replica.inventory:GetEquippedItem(item.replica.equippable:EquipSlot()) then
        -- Try equip until the item is not valid or we already have something equipped
        CancelEquipTask()
    else
        DoEquip(item)
    end
end

local function TryEquip(item)
    DoEquip(item)
    equiptask = GLOBAL.ThePlayer:DoPeriodicTask(0, equip_task_fn, nil, item)
end

local function TryAutoReEquip(inst, eslot)

    if equiptask then
        CancelEquipTask()
    end

    local inventory = GLOBAL.ThePlayer.replica.inventory
    if inventory:GetEquippedItem(eslot) then return end

    local right_weapons = {}
    local check_list = {{_ = inventory:GetActiveItem()}, inventory:GetItems()}

    local open_containers = inventory:GetOpenContainers()
    if open_containers then
        for container in pairs(open_containers) do
            local container_replica = container and container.replica.container
            if container_replica then
                table.insert(check_list, container_replica:GetItems())
            end
        end
    end
    for _, items in ipairs(check_list) do
        for _, item in pairs(items) do
            if item.prefab == inst.prefab then
                if not low_dur_first then
                    TryEquip(item)
                    return
                end
                table.insert(right_weapons, item)
            end
        end
    end

    local min_durability, final_weapon
    for _, weapon in ipairs(right_weapons) do
        local inventoryitem = weapon.replica.inventoryitem
        local cur_durability = inventoryitem.classified and inventoryitem.classified.percentused:value() or 0
        if not min_durability or cur_durability < min_durability then
            min_durability = cur_durability
            final_weapon = weapon
        end
    end
    if final_weapon then
        TryEquip(final_weapon)
    end

end

local function HandleUnequippedItem(item, eslot)
    if not item:IsValid() or item:HasTag("projectile") and item:HasTag("NOCLICK") then
        -- If it's not valid, basically means it has been removed
        -- (or may be use Ents[item.GUID] instead?)
        -- And for projectiles, most of them will having a NOCLICK tag after thrown
        -- (not getting removed after the unequip)
        TryAutoReEquip(item, eslot)
    end
end

local function master_handle_unequip(_, ...)
    HandleUnequippedItem(...)
end

local function onequip(inst, data)
    if type(data) == "table" and data.eslot and data.item
        and (
            data.eslot == GLOBAL.EQUIPSLOTS.HANDS or
            table.contains(EXTRA_ITEMS, data.item.prefab)
        ) then

        equips[data.eslot] = data.item
    end
end

local function onunequip(inst, data)
    if type(data) ~= "table" then return end
    local item = equips[data.eslot]
    if item ~= nil then
        -- Mastersim's events are pushed during the remove/thrown,
        -- so delay one frame to wait for them to finish
        if GLOBAL.TheWorld.ismastersim then
            inst:DoTaskInTime(0, master_handle_unequip, item, data.eslot)
        else
            HandleUnequippedItem(item, data.eslot)
        end
    end
    equips[data.eslot] = nil
end

local function register_equipped_items(inst)
    for _, eslot in pairs(GLOBAL.EQUIPSLOTS) do
        onequip(inst, {
            eslot = eslot,
            item = inst.replica.inventory:GetEquippedItem(eslot)
        })
    end
end

AddComponentPostInit("playercontroller", function(self)
    if self.inst ~= GLOBAL.ThePlayer then return end

    self.inst:ListenForEvent("equip", onequip)
    self.inst:ListenForEvent("unequip", onunequip)

    if not self.ismastersim then
        self.inst:DoTaskInTime(0, register_equipped_items)
    end

    local OnRemoveFromEntity = self.OnRemoveFromEntity
    self.OnRemoveFromEntity = function(self, ...)
        self.inst:RemoveEventCallback("equip", onequip)
        self.inst:RemoveEventCallback("unequip", onunequip)
        return OnRemoveFromEntity(self, ...)
    end
end)
