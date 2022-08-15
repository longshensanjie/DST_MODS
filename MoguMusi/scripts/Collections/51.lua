local drop_mode = "controller_drop"


local haha = GetModConfigData("sw_shadowheart")
if type(haha) == "boolean" and haha == true then
    haha = "knight"
end


local SLEEP_TIME = GLOBAL.FRAMES * 2
local ACTIONBUTTON = "actionbutton"
local LEFTCLICK = "leftclick"
local sutip = false

local buildingthread

local STRINGS_CHS = {
    ["start"] = "建造开始",
    ["stop"] = "建造停止",
    ["item_not_enough"] = "材料不足",
    ["count_msg"] = "在5个地皮范围内有 %d 个此类雕像",
    ["end_count_msg"] = "建造结束，在5个地皮范围内有 %d 个此类雕像",
}

local function GetString(stringtype)
    return STRINGS_CHS[stringtype]
end



local function Say(str, isgreen)
    if isgreen then
        TIP("金手指：黑心工厂", "green", str)
    else
        TIP("金手指：黑心工厂", "red", str)
    end
end

local MOONEVENT_MUSTTAGS = { "chess_moonevent" }

local function SendAction(act, act_type)

    local target = act.target
    if act_type == ACTIONBUTTON and not GLOBAL.ThePlayer:IsNear(target, 6) then
        act_type = LEFTCLICK
    end

    act.forced = GLOBAL.ThePlayer:IsNear(target, 4)

    local playercontroller = GLOBAL.ThePlayer.components.playercontroller
    if playercontroller.ismastersim then
        GLOBAL.ThePlayer.components.combat:SetTarget(nil)
        playercontroller:DoAction(act)
    end

    local pos = GLOBAL.ThePlayer:GetPosition()
    local function send()
        if act_type == ACTIONBUTTON then
            GLOBAL.SendRPCToServer(GLOBAL.RPC.ActionButton, act.action.code, target, true, not act.forced)
        elseif act_type == LEFTCLICK then
            GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, act.action.code, pos.x, pos.z, target, true, nil, not act.forced)
        end
    end

    if act_type == LEFTCLICK and act.action == GLOBAL.ACTIONS.PICK and GLOBAL.ThePlayer.replica.inventory:GetActiveItem() then
        GLOBAL.ThePlayer.replica.inventory:ReturnActiveItem()
    end
    if playercontroller.locomotor then
        act.preview_cb = send
        playercontroller:DoAction(act)
    else
        send()
    end

end

local function GetCheckContainers()
    local inventory = GLOBAL.ThePlayer.replica.inventory
    local check_list = { inventory:GetActiveItem(), inventory }

    local open_containers = inventory:GetOpenContainers()
    if open_containers then
        for container in pairs(open_containers) do
            local container_replica = container and container.replica.container
            if container_replica then
                table.insert(check_list, container_replica)
            end
        end
    end
    return check_list
end

local function HaveEnoughItems(items)

    local item_amount = {}
    for k in pairs(items) do
        item_amount[k] = 0
    end

    local function try_add(item)
        local prefab = item.prefab
        if items[prefab] then
            if item.replica.stackable then
                item_amount[prefab] = item_amount[prefab] + item.replica.stackable:StackSize()
            else
                item_amount[prefab] = item_amount[prefab] + 1
            end
        end
    end

    for _, container in orderedPairs(GetCheckContainers()) do
        if type(container) == "table" then
            if container.is_a and container:is_a(GLOBAL.EntityScript) then
                try_add(container)
            elseif container.GetItems then
                local items = container:GetItems()
                for _, v in orderedPairs(items) do
                    try_add(v)
                end
            end
        end
    end

    for prefab, amount in pairs(items) do
        if item_amount[prefab] < amount then
            return false
        end
    end
    return true

end

local function GetItem(prefab, allow_active_item)
    for _, container in orderedPairs(GetCheckContainers()) do
        if type(container) == "table" then
            if allow_active_item and container.prefab == prefab then  -- If "container"(active item) is what we're looking for
                return container
            elseif container.GetItems then
                local items = container:GetItems()
                for slot, item in orderedPairs(items) do
                    if item.prefab == prefab then
                        items.__orderedIndex = nil
                        return item, slot, container
                    end
                end
            end
        end
    end
end

local function GetMaterial(allow_active_item)
    local rt = { GetItem("marble", allow_active_item) }
    if GLOBAL.next(rt) then
        return GLOBAL.unpack(rt)
    else
        return GetItem("cutstone", allow_active_item)
    end
end

local ROCKS = { rocks = 2 }
local function HasEnoughRocks()
    local player_classified = GLOBAL.ThePlayer.player_classified
    return player_classified and player_classified.isfreebuildmode:value() or HaveEnoughItems(ROCKS)
end

local function StopBuilding(silence)
    if not silence then Say(GetString("stop"), true) end
    if buildingthread then
        buildingthread:SetList(nil)
    end
    buildingthread = nil
end

local SCULPTINGTABLE_CANTTAGS = { "INLIMBO", "burnt" }
local function find_sculptingtable(inst)
    return inst.prefab == "sculptingtable"
end

local function find_winchtable(inst)
    return inst.prefab == "winch"
end


local function fn()
    if not InGame() then return end
    if buildingthread then StopBuilding() return end
    local ThePlayer = GLOBAL.ThePlayer


    -- 没有陶轮就别吵吵了
    local sculptingtable = GLOBAL.FindEntity(ThePlayer, 30, find_sculptingtable, nil, SCULPTINGTABLE_CANTTAGS)
    if not sculptingtable then
        TIP("黑心工厂", "red", "未找到陶轮")
        return
    end

    if not (HasEnoughRocks() and GetMaterial(true)) then
        Say(GetString("item_not_enough"), false)
        return
    end

    local playercontroller = ThePlayer.components.playercontroller
    local builder = ThePlayer.replica.builder
    local inventory = ThePlayer.replica.inventory

    Say(GetString("start"), true)

    buildingthread = ThePlayer:StartThread(function()

        while ThePlayer:IsValid() and sculptingtable:IsValid() do

            -- 适配多格物品栏
            local loca = GLOBAL.EQUIPSLOTS.BACK or GLOBAL.EQUIPSLOTS.BODY or GLOBAL.EQUIPSLOTS.WAIST
            local body_item = inventory:GetEquippedItem(loca)
            if body_item and body_item:HasTag("heavy") then
                if drop_mode == "controller_drop" then
                    inventory:DropItemFromInvTile(body_item)
                else
                    inventory:ReturnActiveItem()
                    inventory:TakeActiveItemFromEquipSlot(loca)
                end

            elseif sculptingtable:HasTag("chess_moonevent") then
                local act = GLOBAL.BufferedAction(ThePlayer, sculptingtable, GLOBAL.ACTIONS.PICK, nil, ThePlayer:GetPosition())
                SendAction(act, ACTIONBUTTON)

            elseif builder:CanBuild("chesspiece_"..haha.."_builder") and not ThePlayer.components.playercontroller:IsDoingOrWorking() then
                builder:MakeRecipeFromMenu(GLOBAL.AllRecipes["chesspiece_"..haha.."_builder"])

            elseif ThePlayer:HasTag("idle") and not sculptingtable:HasTag("pickable") then
                if not HasEnoughRocks() then return end
                local act
                local active_item = inventory:GetActiveItem()
                local pos = ThePlayer:GetPosition()
                if active_item and (active_item.prefab == "marble" or active_item.prefab == "cutstone") then
                    act = GLOBAL.BufferedAction(ThePlayer, sculptingtable, GLOBAL.ACTIONS.GIVE, active_item, pos)
                else
                    local item, slot, container = GetMaterial()
                    if not item then return end
                    container:TakeActiveItemFromAllOfSlot(slot)
                    act = GLOBAL.BufferedAction(ThePlayer, sculptingtable, GLOBAL.ACTIONS.GIVE, item, nil, pos)
                end
                SendAction(act, LEFTCLICK)

            end

            GLOBAL.Sleep(SLEEP_TIME)

        end

        StopBuilding(true)

    end)

end


InterruptedByMobile(function()
    return buildingthread
end, StopBuilding)



DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("shadowheart.tex"), "shadowheart.tex", "黑心工厂", "靠近陶轮时制作暗影雕像", false, fn)

