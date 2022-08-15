local FIND_RANGE = 40
local WAIT_TIME = GLOBAL.FRAMES * 3

local comparingthread
local done_items = {}

local function StopThread()
    if comparingthread then
        comparingthread:SetList(nil)
        TIP("笼鸟池鱼", "red", "结束")
    end
    comparingthread = nil
    done_items = {}
end

local TROPHYSCALE_CANTTAGS = { "burnt" }
local function find_trophyscale(inst)
    return inst.prefab == "trophyscale_fish"
end

local function weighable_fish_test_fn(item)
    return not done_items[item] and item:HasTag("weighable_fish")
end

local function is_trophyscale_idle(trophyscale)
    return trophyscale.AnimState:IsCurrentAnimation("fish_idle")
        or trophyscale.AnimState:IsCurrentAnimation("nofish_idle")
end

local function fn()
    local ThePlayer = GLOBAL.ThePlayer
    local Sleep = GLOBAL.Sleep

    if comparingthread then StopThread() return end

    local trophyscale = GLOBAL.FindEntity(ThePlayer, FIND_RANGE, find_trophyscale, nil, TROPHYSCALE_CANTTAGS)
    if not trophyscale then 
        TIP("笼鸟池鱼","green","无鱼类计重器")
    return end
    TIP("笼鸟池鱼","green","开始")

    comparingthread = ThePlayer:StartThread(function()

        while ThePlayer:IsValid() and trophyscale:IsValid() do

            local item = GetItemFromContainers(nil, nil, nil, weighable_fish_test_fn)
            if not item then 
                TIP("笼鸟池鱼","green","结束")
                return 
            end

            while not is_trophyscale_idle(trophyscale) do  -- Wait until it can accept items again
                Sleep(WAIT_TIME)
            end

            local act = GLOBAL.BufferedAction(ThePlayer, trophyscale, GLOBAL.ACTIONS.COMPARE_WEIGHABLE, item)
            UseItemOnScene(item, act)
            while ThePlayer:HasTag("idle") do
                UseItemOnScene(item, act)
                Sleep(WAIT_TIME)
            end

            repeat
                Sleep(WAIT_TIME)
            until ThePlayer:HasTag("idle") and not ThePlayer.components.playercontroller:IsDoingOrWorking()
                and not (ThePlayer.sg and ThePlayer.sg:HasStateTag("moving"))
                and not ThePlayer:HasTag("moving")

            done_items[item] = true

        end

        StopThread()

    end)
end

InterruptedByMobile(function()
    return comparingthread
end, StopThread)

if GetModConfigData("tony_compare_fish") == "biubiu" then
    DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("trophyscale_fish.tex"), "trophyscale_fish.tex", "笼鸟池鱼", "观赏最大的鱼", false, fn)
end
    
AddBindBtn("tony_compare_fish", fn)
