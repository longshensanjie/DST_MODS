-- 使用最近的船锚船舵
-- 该功能在启用tony的开关后强制加载，因为涉及两个配置

local function SendAction(act)
    local x, _, z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
    SendActionAndFn(act, function()
        GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, act.action.code, x, z, act.target, true)
    end)
end

local STEERINGWHEEL_MUSTTAGS = {"steeringwheel"}
local STEERINGWHEEL_CANTTAGS = {"INLIMBO", "burnt", "occupied", "fire"}
local function SteerBoat()
    local target = GLOBAL.FindEntity(GLOBAL.ThePlayer, 5, nil, STEERINGWHEEL_MUSTTAGS, STEERINGWHEEL_CANTTAGS)
    if target then
        if GLOBAL.ThePlayer:HasTag("steeringboat") then
            SendAction(GLOBAL.BufferedAction(GLOBAL.ThePlayer, nil, GLOBAL.ACTIONS.STOP_STEERING_BOAT))
        else
            SendAction(GLOBAL.BufferedAction(GLOBAL.ThePlayer, target, GLOBAL.ACTIONS.STEER_BOAT))
        end
    else
        TIP("快速用舵","red","附近没有需要操作的船舵")
    end
end

local ANCHOR_CANTTAGS = {"INLIMBO", "burnt"}
local ANCHOR_MUSTONOFTAGS = {"anchor_raised", "anchor_lowered"}
local function UseAnchor()
    local target = GLOBAL.FindEntity(GLOBAL.ThePlayer, 5, nil, nil, ANCHOR_CANTTAGS, ANCHOR_MUSTONOFTAGS)
    if target then
        local action
        if not target:HasTag("anchor_raised") or target:HasTag("anchor_transitioning") then
            action = GLOBAL.ACTIONS.RAISE_ANCHOR
        elseif target:HasTag("anchor_raised") then
            action = GLOBAL.ACTIONS.LOWER_ANCHOR
        end
        if action then
            if GLOBAL.ThePlayer:HasTag("steeringboat") then
                SendAction(GLOBAL.BufferedAction(GLOBAL.ThePlayer, nil, GLOBAL.ACTIONS.STOP_STEERING_BOAT))
                GLOBAL.ThePlayer:DoTaskInTime(0, function()
                    SendAction(GLOBAL.BufferedAction(GLOBAL.ThePlayer, target, action))
                end)
            else
                SendAction(GLOBAL.BufferedAction(GLOBAL.ThePlayer, target, action))
            end
        end
    else
        TIP("快速用锚","red","附近没有需要操作的船锚")
    end
end

if GetModConfigData("tony_easy_anchor") then
    if GetModConfigData("tony_easy_anchor") == "biubiu" then
        DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("anchor.tex"), "anchor.tex", "使用船锚", "使用最近的船锚", false, UseAnchor)
    else
        AddBindBtn("tony_easy_anchor", UseAnchor)
    end
end

if GetModConfigData("tony_easy_steering") then
    if GetModConfigData("tony_easy_steering") == "biubiu" then
        DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("steeringwheel.tex"), "steeringwheel.tex", "使用船舵", "使用最近的船舵", false, SteerBoat)
    else
        AddBindBtn("tony_easy_steering", SteerBoat)
    end
end