local _G = GLOBAL
local IsClinet = not _G.TheNet:IsDedicated()

local armor_prefab = "armorskeleton"
local furl_prefab = "nightmarefuel"
local itemcd = 5
local mincd = 0

local itemcdlist = {}
local lastunequiptime
local unequiptask

local modconfig_autoaddfuel = true

local modconfig_autoaddfuelpercent
local judge = GetModConfigData("sw_skeleton")
if judge == true then
    modconfig_autoaddfuelpercent = 30
else
    modconfig_autoaddfuelpercent = judge
end

local modconfig_forceequip = true

local function GetItemPercentused(item)
    local classified = item.replica and item.replica._ and
                           item.replica._.inventoryitem and
                           item.replica._.inventoryitem.classified

    local percentused = classified and classified.percentused:value() or nil
    return percentused
end


local function GetPlayerArmorList()
    local itemlist = {}
    local _itemlist = GetItemsFromAll(armor_prefab)
    for k, v in pairs(_itemlist) do
        if v and v.prefab == armor_prefab then

            local percentused = GetItemPercentused(v) or 0

            local outcd = itemcdlist[v.GUID] and _G.GetTime() -
                              itemcdlist[v.GUID] or nil
            local cd = (outcd and itemcd - outcd <= 0 and 0) or
                           (outcd and itemcd - outcd) or 0

            local objparam = {
                GUID = v.GUID,
                ent = v,
                percentused = percentused,
                cd = cd
            }

            table.insert(itemlist, objparam)
        end
    end
    return itemlist
end

local function ChooseItemInPlayerInv()

    local itemlist = GetPlayerArmorList()
    if _G.next(itemlist) then

        table.sort(itemlist, function(a, b)
            local acd = a.cd or 0
            local bcd = b.cd or 0

            if acd == bcd then
                a = a.percentused or 0
                b = b.percentused or 0
                return a > b
            else
                a = a.cd or 0
                b = b.cd or 0
                return a < b
            end
        end)

        for k, v in pairs(itemlist) do

            if v.percentused ~= 0 then return v.ent end
        end

    end

    return nil
end

local function AddFuelAct(item, fuel)
    if item == nil or fuel == nil then return end
    local playercontroller = _G.ThePlayer.components.playercontroller
    local act = _G.BufferedAction(_G.ThePlayer, item, _G.ACTIONS.ADDFUEL, fuel)
    local function cb()
        _G.SendRPCToServer(_G.RPC.ControllerUseItemOnItemFromInvTile,
                           _G.ACTIONS.ADDFUEL.code, item, fuel)
    end
    if _G.ThePlayer.components.locomotor then
        act.preview_cb = cb
		playercontroller:DoAction(act)
    else
        cb()
    end
end
--[[
  GLOBAL.TheInput:AddKeyUpHandler(GLOBAL.KEY_Z, function() 
      local nowarmor = ChooseItemInPlayerInv()
	  local fuel = GetItemsFromAll(furl_prefab)
                        if _G.next(fuel) then
                            fuel = fuel[1]
                            AddFuelAct(nowarmor, fuel)
                        end
    end)
--]]

-- https://steamcommunity.com/sharedfiles/filedetails/?id=1581892848
local function Unequip(inst, wantitem)
    if inst == wantitem then
        if unequiptask ~= nil then
            unequiptask:Cancel()
            unequiptask = nil
        end
        return
    end

    if inst.replica.equippable:IsEquipped() then
        _G.ThePlayer.replica.inventory:UseItemFromInvTile(wantitem)
    end

    if wantitem.replica.equippable and wantitem.replica.equippable:IsEquipped() and unequiptask ~= nil then
        unequiptask:Cancel()
        unequiptask = nil
    end

end

local function AutoEquip(inst)
    local item = inst.entity:GetParent()

    if _G.ThePlayer.replica.inventory:IsHolding(item) and
        item.replica.equippable:IsEquipped() then
        -- _G.ThePlayer.replica.inventory:UseItemFromInvTile(item) --取 穿
        -- _G.ThePlayer.replica.inventory:ControllerUseItemOnSelfFromInvTile(nowarmor)--取
        local nowtime = _G.GetTime()
        itemcdlist[item.GUID] = nowtime

        if lastunequiptime == nil or nowtime - lastunequiptime >= mincd then
            local choiceitem = ChooseItemInPlayerInv()
            -- local nowarmor = _G.ThePlayer.replica.inventory:GetEquippedItem(_G.EQUIPSLOTS.BODY)
            local nowarmor = item

            if choiceitem then

                -- note

                if modconfig_forceequip then

                    if unequiptask ~= nil then
                        unequiptask:Cancel()
                        unequiptask = nil
                    end

                    unequiptask = item:DoPeriodicTask(0, function()
                        Unequip(item, choiceitem)
                    end)
                end

                Unequip(item, choiceitem)

                -- add fuel
                inst:DoTaskInTime(.1, function(inst)
                    local _itemlist = GetItemsFromAll(armor_prefab)

                    local armor
                    if _G.next(_itemlist) then
                        for k, v in pairs(_itemlist) do
                            local percentused =
                                v and GetItemPercentused(v) or 100
                            if percentused == 0 then
                                armor = v
                            end
                        end
                    end

                    local percentused = armor and GetItemPercentused(armor) or 0
                    if armor and percentused <= 1 then
                        local fuel = GetItemsFromAll(furl_prefab)
                        if _G.next(fuel) then
                            fuel = fuel[1]
                            AddFuelAct(armor, fuel)
                        end
                    end
                end)

                inst:DoTaskInTime(.7, function(inst)
                    local percentused = GetItemPercentused(nowarmor) or 0
                    if modconfig_autoaddfuel == true and percentused <=
                        modconfig_autoaddfuelpercent then
                        local fuel = GetItemsFromAll(furl_prefab)
                        if _G.next(fuel) then
                            fuel = fuel[1]
                            AddFuelAct(nowarmor, fuel)
                        end
                    end
                end)

            end
        end
        lastunequiptime = nowtime
    end

end

local function fn(inst)
    local item = inst.entity:GetParent()

    if item and item.prefab == armor_prefab then

        inst:ListenForEvent("percentuseddirty", function(inst)

            inst:DoTaskInTime(0, function(inst)
                item.logpercentused2 = inst.percentused:value()
                if (item.logpercentused1 and item.logpercentused2 and
                    item.logpercentused1 >= item.logpercentused2) then
                    AutoEquip(inst)
                end
                item.logpercentused1 = inst.percentused:value()
            end)
        end)

    end
end

local function fn2(inst)
    inst:ListenForEvent("equip", function(inst, data)
        inst:DoTaskInTime(0, function(inst)
            if data and data.item and data.item.prefab == armor_prefab then
                data.item.logpercentused1 = GetItemPercentused(data.item) or 0
            end
        end)
    end)
	
		local nowequip = inst.replica and inst.replica.inventory and inst.replica.inventory:GetEquippedItem(_G.EQUIPSLOTS.BODY)
		if nowequip and nowequip.prefab == armor_prefab then
			nowequip.logpercentused1 = GetItemPercentused(nowequip) or 0
		end
end

AddPrefabPostInit("inventoryitem_classified", function(inst)
    if IsClinet == true then inst:DoTaskInTime(0, function() fn(inst) end) end
end)

AddPlayerPostInit(function(inst)
    if IsClinet == true then inst:DoTaskInTime(0, function() fn2(inst) end) end
end)
