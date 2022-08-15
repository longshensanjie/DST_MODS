local _G = GLOBAL

local watch_prefab = "pocketwatch_weapon" 


local modconfig_autoaddfuelpercent
local judge = GetModConfigData("wanda_weapon")
if judge == true then
    modconfig_autoaddfuelpercent = 5
else
    modconfig_autoaddfuelpercent = judge
end

local AddFuelThread

local function GetItemPercentused(item)
    local classified = item.replica and item.replica._ and
                           item.replica._.inventoryitem and
                           item.replica._.inventoryitem.classified

    local percentused = classified and classified.percentused:value() or nil
    return percentused
end


local function AddFuelAct(item, fuel)

    if item == nil or fuel == nil then return end

    local actions = fuel:GetIsWet() and _G.ACTIONS.ADDWETFUEL or
                        _G.ACTIONS.ADDFUEL

    local playercontroller = _G.ThePlayer.components.playercontroller
    local act = _G.BufferedAction(_G.ThePlayer, item, actions, fuel)
    local function cb()
        _G.SendRPCToServer(_G.RPC.ControllerUseItemOnItemFromInvTile,
                           actions.code, item, fuel)
    end
    if _G.ThePlayer.components.locomotor then
        act.preview_cb = cb
    else
        cb()
    end
    playercontroller:DoAction(act)
end

-- https://steamcommunity.com/sharedfiles/filedetails/?id=1581892848
local function Unequip(inst)
    if inst.replica.equippable:IsEquipped() then
        _G.ThePlayer.replica.inventory:ControllerUseItemOnSelfFromInvTile(inst)
    end

    if not inst.replica.equippable:IsEquipped() and inst.unequiptask ~= nil then
        inst.unequiptask:Cancel()
        inst.unequiptask = nil
    end

end

local function KillAddFuelThread()
    if AddFuelThread then
        AddFuelThread:SetList(nil)
        AddFuelThread = nil
    end
end


local function StartAddFuelThread(inst)
    KillAddFuelThread()
    AddFuelThread = _G.ThePlayer:StartThread(
                        function()
            while true do

                local item = inst.entity and inst.entity:GetParent()
                local percentused = item and GetItemPercentused(item) or 0

                if item and _G.ThePlayer.replica.inventory:IsHolding(item) and
                    item.replica.equippable:IsEquipped() and percentused <=
                    modconfig_autoaddfuelpercent then

                    local fuel = GetItemsFromAll("nightmarefuel")

					if _G.next(fuel) then
                        if percentused <= 3 then -- 小于3%强制加燃料
                            AddFuelAct(item, fuel[1])
                            break
						elseif not _G.ThePlayer:HasTag("moving") then -- 正常情况下不移动时加燃料
							AddFuelAct(item, fuel[1])
							break
						end
					end
				else
					break
                end
                _G.Sleep(0)

            end
        end)
end

local function fn(inst)
    local item = inst.entity:GetParent()

    if item and item.prefab == watch_prefab then
        inst:ListenForEvent("percentuseddirty",
                            function(inst) StartAddFuelThread(inst) end)

    end
end

AddPrefabPostInit("inventoryitem_classified", function(inst)
    inst:DoTaskInTime(0, function() fn(inst) end)
end)
