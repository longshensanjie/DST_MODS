local dont_kill_thermal_fishes = GetModConfigData("tony_killfish") == "yhz" and
{
    "oceanfish_small_6_inv",
    "oceanfish_small_7_inv",
    "oceanfish_small_8_inv",
    "oceanfish_small_9_inv",
    "oceanfish_medium_8_inv",
}

local WAIT_TIME = GLOBAL.FRAMES * 2

local killingthread

local function StopKilling()
    if killingthread then
        killingthread:SetList(nil)
        TIP("金手指：宰鱼队列","red" ,"停止")
    end
    killingthread = nil
end

local function find_fish(item)
    return (item:HasTag("fish") or item:HasTag("spider"))
        and not (dont_kill_thermal_fishes and table.contains(dont_kill_thermal_fishes, item.prefab))
end

local function fn()
    local ThePlayer = GLOBAL.ThePlayer
    if killingthread then StopKilling() return end
    if GetModConfigData("tony_killfish") ~= "yhz" then
        TIP("宰鱼队列", "green", "自动杀鱼和蜘蛛")
    else
        TIP("宰鱼队列", "green", "不杀季节鱼和口水鱼")
    end
    killingthread = ThePlayer:StartThread(function()
        local inv = ThePlayer.replica.inventory
        while ThePlayer:IsValid() do
            local containers = GetDefaultCheckingContainers()
            for k in pairs(inv:GetOpenContainers()) do
                local container = k.replica.container
                if not table.contains(containers, container) then
                    table.insert(containers, container)
                end
            end
            local item = GetItemFromContainers(containers, nil, nil, find_fish)
            if not item then
                local active_item = inv:GetActiveItem()
                if active_item and active_item:HasTag("fishmeat")
                    and (
                        IsValidContainer(inv, active_item) or
                        IsValidContainer(inv:GetOverflowContainer(), active_item)
                    ) then

                    inv:ReturnActiveItem()
                end
                return
            end
            UseItemOnSelf(item)
            GLOBAL.Sleep(WAIT_TIME)
        end
        StopKilling()
    end)
end

InterruptedByMobile(function ()
    return killingthread
end, fn)

DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("pondfish.tex"), "pondfish.tex", "自动宰鱼", "宰杀身上的鱼和蜘蛛", false, fn)