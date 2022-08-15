local WINCH_RANGE = 5
local AREA_FREE_RANGE = 10
local SLEEP_TIME = GLOBAL.FRAMES * 3
local ACTIVATE_DELAY = 1

local FIND_HEAVY_TAGS = {"underwater_salvageable"}

local ActionQueuer
local working_thread

local function StopWinch()
    if working_thread then
        working_thread:SetList(nil)
        TIP("贝壳工厂", "red", "停止")
    end
    working_thread = nil
end

local function GetWinch()
    local x, _, z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
    for _, ent in ipairs(GLOBAL.TheSim:FindEntities(x, 0, z, WINCH_RANGE)) do
        if ent.prefab == "winch" then
            if ent:HasTag("takeshelfitem") then
                return ent, GLOBAL.BufferedAction(GLOBAL.ThePlayer, ent, GLOBAL.ACTIONS.UNLOAD_WINCH), true, "takeshelfitem"
            elseif ent:HasTag("inactive") then
                return ent, GLOBAL.BufferedAction(GLOBAL.ThePlayer, ent, GLOBAL.ACTIONS.ACTIVATE), false, "inactive"
            end
        end
    end
end

local function SendActionAndWait(winch, act, right, tag)
    repeat
        ActionQueuer:SendAction(act, right, winch)
        GLOBAL.Sleep(SLEEP_TIME)
    until not winch:HasTag(tag)

    if act.action == GLOBAL.ACTIONS.UNLOAD_WINCH then
        while not winch:HasTag("inactive") do
            GLOBAL.Sleep(SLEEP_TIME)
        end
        SendActionAndWait(winch, GLOBAL.BufferedAction(GLOBAL.ThePlayer, winch, GLOBAL.ACTIONS.ACTIVATE), false, "inactive")
    else
        GLOBAL.Sleep(ACTIVATE_DELAY)
    end
end

local function find_winchtable(inst)
    return inst.prefab == "winch"
end
local SCULPTINGTABLE_CANTTAGS = {"INLIMBO", "burnt"}

InterruptedByMobile(function()
    return working_thread
end, StopWinch)

local function fn()
    if working_thread then
        StopWinch()
        return
    end

    if not GLOBAL.ThePlayer then
        return
    end

    ActionQueuer = GLOBAL.ThePlayer.components.actionqueuer
    if not ActionQueuer then
        TIP("贝壳工厂", "red", "该功能需要行为排队论！")
        return
    end

    -- 条件不满足时无法执行
    local winchtable = GLOBAL.FindEntity(GLOBAL.ThePlayer, 5, find_winchtable, nil, SCULPTINGTABLE_CANTTAGS)
    if not winchtable then
        TIP("贝壳工厂", "red", "没有夹夹绞盘")
        return
    end

    working_thread = GLOBAL.ThePlayer:StartThread(function()
        TIP("贝壳工厂", "green", "启动")
        while GLOBAL.ThePlayer:IsValid() do
            local winch, act, right, tag = GetWinch()
            if winch then
                SendActionAndWait(winch, act, right, tag)
            else
                GLOBAL.Sleep(SLEEP_TIME)
            end
        end
        StopWinch()
    end)
end

if GetModConfigData("sw_winchactivator") == "biubiu" then
DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("hermit_bundle.tex"), "hermit_bundle.tex", "贝壳工厂", "反复打捞雕像来刷寄居蟹奶奶好感", false, fn)
end

AddBindBtn("sw_winchactivator", fn)