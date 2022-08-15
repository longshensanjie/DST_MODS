local WAGSTAFF_RANGE = 60
local TOOLS_RANGE = 10
local SLEEP_TIME = GLOBAL.FRAMES * 3
local TOOL_CANTTAGS = {"INLIMBO"}

local ActionQueuer
local working_thread
local target_mark

local function Stop()
    if working_thread then
        working_thread:SetList(nil)
        working_thread = nil
    end
    if target_mark then
        target_mark:Remove()
    end
    TIP("走近科学", "red", "结束")
end

-- For bypass the entity morph check
local function prefab_test(inst, prefab)
    return inst.prefab == prefab
end

local function GetTool(tool_prefab, wagstaff)
    local tool = GetItemFromContainers(nil, tool_prefab, nil, prefab_test)
    if not tool then
        local target = GLOBAL.FindEntity(wagstaff, TOOLS_RANGE, function(inst)
            return inst.prefab == tool_prefab
        end, nil, TOOL_CANTTAGS)
        if target then
            ActionQueuer:SendActionAndWait(GLOBAL.BufferedAction(GLOBAL.ThePlayer, target, GLOBAL.ACTIONS.PICKUP), false, target)
            tool = GetItemFromContainers(nil, tool_prefab, nil, prefab_test)
        end
    end
    return tool
end

local function find_wagstaff(inst)
    return inst.prefab == "wagstaff_npc"
end

local recordTime = 0
local function IsControlButtonDown(player)
    local ispressed = player and player.components and player.components.playercontroller:IsAnyOfControlsPressed(
        GLOBAL.CONTROL_MOVE_UP, 
        GLOBAL.CONTROL_MOVE_DOWN, 
        GLOBAL.CONTROL_MOVE_LEFT, 
        GLOBAL.CONTROL_MOVE_RIGHT,
        GLOBAL.CONTROL_ATTACK
    )
    if ispressed then
        recordTime = GLOBAL.GetTime()
        return true
    else
        if GLOBAL.GetTime() - recordTime > 3 then
            return false
        else
            return true
        end
    end
end

local function fn()

    if working_thread then return end
    local ThePlayer = GLOBAL.ThePlayer

    ActionQueuer = ThePlayer.components.actionqueuer
    if not ActionQueuer then
        TIP("走近科学","red", "未安装行为排队论！")  
    return end

    local wagstaff = GLOBAL.FindEntity(ThePlayer, WAGSTAFF_RANGE, find_wagstaff)
    if not wagstaff then 
        TIP("走近科学","red", "未发现瓦格斯塔夫")  
        return 
    end

    if not wagstaff.tool_wanted and not wagstaff.AnimState:IsCurrentAnimation("build_loop") then
        ActionQueuer:SendAction(GLOBAL.BufferedAction(ThePlayer, wagstaff, GLOBAL.ACTIONS.WALKTO, nil, wagstaff:GetPosition()))
        TIP("走近科学","red", "瓦格斯塔夫不需要你的帮助")  
        return
    end

    target_mark = wagstaff:SpawnChild("reticule")
    recordTime = 0                  -- 启动会使得任务立即开始

    working_thread = ThePlayer:StartThread(function()
        TIP("走近科学","green", "启动") 
        ThePlayer:PushEvent("stop_aqp_thread")
        while ThePlayer:IsValid() and wagstaff:IsValid() do
            if wagstaff.tool_wanted and not wagstaff.AnimState:IsCurrentAnimation("build_loop") and not IsControlButtonDown(GLOBAL.ThePlayer) then
                local tool = GetTool(wagstaff.tool_wanted, wagstaff)
                if tool then
                    UseItemOnScene(tool, GLOBAL.BufferedAction(ThePlayer, wagstaff, GLOBAL.ACTIONS.GIVE, tool))
                end
            end
            GLOBAL.Sleep(SLEEP_TIME)
        end
        Stop()
    end)
end

-- InterruptedByMobile(function ()
--     return working_thread
-- end, Stop)

if GetModConfigData("tony_wagstaff_tool_giver") == "biubiu" then
    DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("moonstorm_static_item.tex"), "moonstorm_static_item.tex", "走近科学", "帮助瓦格斯塔夫完成天体实验", false, fn)
end
    
AddBindBtn("tony_wagstaff_tool_giver", fn)

-- For compatible with server-client language diff
local PREPARED_STRINGS =
{
    en =
    {
        WAGSTAFF_NPC_WANT_TOOL_1 = "Quick, I need my Reticulating Buffer!",
        WAGSTAFF_NPC_WANT_TOOL_2 = "Someone find me a Widget Deflubber!",
        WAGSTAFF_NPC_WANT_TOOL_3 = "Has anyone seen my Grommet Scriber?",
        WAGSTAFF_NPC_WANT_TOOL_4 = "Can someone hand me the Conceptual Scrubber?",
        WAGSTAFF_NPC_WANT_TOOL_5 = "I'm certain I put the Calibrated Perceiver down here somewhere...",

        WAGSTAFF_NPC_EXPERIMENT_DONE_1 = "It's done!",
    },
    zh =
    {
        WAGSTAFF_NPC_WANT_TOOL_1 = "快，我需要我的网状缓冲器！",
        WAGSTAFF_NPC_WANT_TOOL_2 = "给我找个装置除垢器去！",
        WAGSTAFF_NPC_WANT_TOOL_3 = "有没有看到我的垫圈开槽器？",
        WAGSTAFF_NPC_WANT_TOOL_4 = "能不能给我递一下概念刷洗器？",
        WAGSTAFF_NPC_WANT_TOOL_5 = "我分明记得把校准观察机放在附近的……",

        WAGSTAFF_NPC_EXPERIMENT_DONE_1 = "完成了！",
    },
}

local tools =
{
    "wagstaff_tool_1",
    "wagstaff_tool_2",
    "wagstaff_tool_3",
    "wagstaff_tool_4",
    "wagstaff_tool_5",
}

local function CheckString(script, str)
    if script == GLOBAL.STRINGS[str] then
        return true
    end
    for _, strings in pairs(PREPARED_STRINGS) do
        if script == strings[str] then
            return true
        end
    end
end

local max_range = TUNING.MAX_INDICATOR_RANGE * 1.5

local function ShouldTrackfn(inst, viewer)
    return inst:IsValid()
        -- and viewer:HasTag("wagstaff_detector")
        and inst:IsNear(inst, max_range)
        and not inst.entity:FrustumCheck()
        -- and CanEntitySeeTarget(viewer, inst)
end

AddPrefabPostInit("wagstaff_npc", function(inst)
    if GLOBAL.TheWorld.ismastersim then
        inst:ListenForEvent("doneexperiment", Stop)
    else
        local say = inst.components.talker.Say
        inst.components.talker.Say = function(self, script, ...)
            if type(script) == "string" then
                if working_thread and CheckString(script, "WAGSTAFF_NPC_EXPERIMENT_DONE_1") then
                    Stop()
                else
                    for i, v in ipairs(tools) do
                        if CheckString(script, "WAGSTAFF_NPC_WANT_TOOL_"..i) then
                            inst.tool_wanted = v
                            break
                        end
                    end
                end
            end
            return say(self, script, ...)
        end
    end
    inst.components.hudindicatable:SetShouldTrackFunction(ShouldTrackfn)
end)
