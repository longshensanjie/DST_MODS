-- 鸟吃虫虫

local STATION_RANGE = 40
local FEED_RANGE = 6

local ActionQueuer
local feeding_thread

local function ClearAQThreads()
    if ActionQueuer then
        ActionQueuer:ClearActionThread()
        ActionQueuer:ClearSelectedEntities()
        ActionQueuer:ClearEndlessRepeatThread(true)
    end
end

local function Stop()
    if feeding_thread then
        feeding_thread:SetList(nil)
        ClearAQThreads()
        TIP("鸟吃虫虫", "red", "结束")
    end
    feeding_thread = nil
end

local function Wait(frames)
    GLOBAL.Sleep(GLOBAL.FRAMES * (frames or 3))
end

local function find_station(inst)
    return inst.prefab == "carnivalgame_feedchicks_station"
end

local function find_food(inst)
    return inst.prefab == "carnivalgame_feedchicks_food"
end

local function find_feed_target(inst)
    local act = ActionQueuer:GetAction(inst, false)
    return act and act.action == GLOBAL.ACTIONS.CARNIVALGAME_FEED
end

local function has_equipped_food()
    local equiped_item = GLOBAL.ThePlayer.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
    return equiped_item and equiped_item.prefab == "carnivalgame_feedchicks_food"
end

local function has_food(station)
    return has_equipped_food()
        or GetItemFromContainers(nil, "carnivalgame_feedchicks_food")
        or GLOBAL.FindEntity(station, FEED_RANGE, find_food)
end

local function TryEquipFood(station)
    while not has_equipped_food() do
        if not GetItemFromContainers(nil, "carnivalgame_feedchicks_food") then
            local food = GLOBAL.FindEntity(station, FEED_RANGE, find_food)
            if food then
                ActionQueuer:SelectEntity(food, false)
                if not ActionQueuer.action_thread then
                    ActionQueuer:ApplyToSelection()
                end
                repeat
                    Wait()
                    if has_equipped_food() then return end
                until GetItemFromContainers(nil, "carnivalgame_feedchicks_food")
            end
        else
            ActionQueuer:GetNewEquippedItemInHand("carnivalgame_feedchicks_food")
            Wait()
        end
    end
end

local function fn()
    if feeding_thread then Stop() return end
    local ThePlayer = GLOBAL.ThePlayer


    ActionQueuer = ThePlayer.components.actionqueuer
    if not ActionQueuer then TIP("鸟吃虫虫", "red", "未安装行为排队论") return end

    local station = GLOBAL.FindEntity(ThePlayer, STATION_RANGE, find_station)
    if not station then
        TIP("鸟吃虫虫", "red", "未发现游戏装置")
        return 
    end

    feeding_thread = ThePlayer:StartThread(function()
        TIP("鸟吃虫虫", "green", "启动")

        local first_time = true

        while ThePlayer:IsValid() and station:IsValid() do

            if not (first_time and has_food(station)) then  -- Skip this part if it's first time and having / can find a food

                while not station:HasTag("trader") do
                    Wait()
                end

                local gametoken = GetItemFromContainers(nil, "carnival_gametoken")
                if not gametoken then 
                    TIP("鸟吃虫虫", "red", "缺少游戏代币")
                    return
                end

                local act = GLOBAL.BufferedAction(ThePlayer, station, GLOBAL.ACTIONS.GIVE, gametoken)
                repeat
                    UseItemOnScene(gametoken, act)
                    Wait()
                until not station:HasTag("trader")

            end
            first_time = false

            TryEquipFood(station)

            local first_ent
            repeat
                first_ent = GLOBAL.FindEntity(station, FEED_RANGE, find_feed_target)
                Wait()
            until first_ent

            ClearAQThreads()
            ActionQueuer:SelectEntity(first_ent, false)
            ActionQueuer:EndlessRepeat({ pos = station:GetPosition(), range = 6 })

        end

        Stop()

    end)
end

InterruptedByMobile(function ()
    return feeding_thread
end, Stop)


if GetModConfigData("tony_auto_carnival_feeding") == "biubiu" then
    DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("carnivalgame_feedchicks_kit.tex"), "carnivalgame_feedchicks_kit.tex", "鸟吃虫虫", "帮你做鸟吃虫虫游戏", false, fn)
end
    
AddBindBtn("tony_auto_carnival_feeding", fn)
