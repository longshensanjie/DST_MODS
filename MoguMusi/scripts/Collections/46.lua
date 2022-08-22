local anims = {
    "frozen",
    "frozen_loop_pst", "distress_loop", "yawn", "dozy", "sleep_loop",   -- 催眠，冰冻，粘痰等
    "powerdown"                                                     ,   -- 大力士变小
    "buck","mount","dismount","heavy_mount",                                          -- 骑牛相关（来自：圈外人）
    -- "powerup", -- 大力士变大动画, 不推荐解除这个, 影响健身
    -- "useitem_lag","useitem_pst", -- 旺达和蜘蛛人的后摇，不推荐
    "jumpportal_out",                                                   -- 旺达降落疾控
}
local task
local FS = GLOBAL.TheSim:GetTickTime()
local timedelay = 0.25
local WOWData = "WalkOnTheWater"
local WHData = "WHForControl"

local function checkAnims(anims)
    for _, anim in pairs(anims) do
        if GLOBAL.ThePlayer and GLOBAL.ThePlayer.AnimState and
            GLOBAL.ThePlayer.AnimState:IsCurrentAnimation(anim) then
            return true
        end
    end
    return false
end

local function TryCraft(check)
    for recname, rec in pairs(GLOBAL.AllRecipes) do
        if GLOBAL.IsRecipeValid(recname) and rec.placer == nil and rec.sg_state ==
            nil and GLOBAL.ThePlayer.replica.builder:KnowsRecipe(recname) and
            GLOBAL.ThePlayer.replica.builder:CanBuild(recname) then
            if check then return true end
            GLOBAL.SendRPCToServer(GLOBAL.RPC.MakeRecipeFromMenu, rec.rpc_id)
            return rec
        end
    end
end

local function Atest(addtimedelay)
    addtimedelay = addtimedelay or 0
    GLOBAL.ThePlayer:EnableMovementPrediction(false)
    local tryflag = TryCraft()
    GLOBAL.ThePlayer:DoTaskInTime(timedelay, function()
        GLOBAL.ThePlayer:DoTaskInTime(addtimedelay, function ()
            GLOBAL.SendRPCToServer(GLOBAL.RPC.DirectWalking, 0, 0)
            GLOBAL.ThePlayer:DoTaskInTime(FS, function()
                GLOBAL.SendRPCToServer(GLOBAL.RPC.StopWalking)
            end)
        end)
        
        if tryflag then
            TIP("解控", "green", "尝试解控")
        else
            TIP("解控失败", "red", "未找到可制作配方")
        end
    end)
end

local function WowAutoTask()
    task = GLOBAL.ThePlayer:DoPeriodicTask(timedelay, function()
        if checkAnims(anims) then Atest() end
    end)
end


local recordtime = 0
local wormholecheck = LoadModData(WOWData) or false
AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(1.33, function()
        if inst == GLOBAL.ThePlayer then
            local wowflag = LoadModData(WOWData) or false
            if wowflag then WowAutoTask() end
            local pc = inst.player_classified
            if pc then 
                if pc.event_listeners and pc.event_listeners.playerfadedirty then
                    pc.event_listeners.playerfadedirty[pc] = nil
                end
                if pc.event_listening and pc.event_listening.playerfadedirty then
                    pc.event_listening.playerfadedirty[pc] = nil
                end
                pc:ListenForEvent("playerfadedirty",function()
                    if wormholecheck then
                        local now = GLOBAL.GetTime()
                        if now - recordtime > timedelay * 20 then
                            Atest(2*timedelay)
                            recordtime = now
                        end
                    end
                end) 
            end
        end
    end)
end)


local oldSendRPCToServer = GLOBAL.SendRPCToServer
function GLOBAL.SendRPCToServer(rpc, actcode, target, ...)
    -- 右键使用 和 快捷键使用
    if GLOBAL.RPC and (rpc == GLOBAL.RPC.UseItemFromInvTile or rpc == GLOBAL.RPC.ControllerUseItemOnSelfFromInvTile)
    and GLOBAL.ACTIONS and GLOBAL.ACTIONS.CAST_POCKETWATCH and actcode == GLOBAL.ACTIONS.CAST_POCKETWATCH.code
    and type(target) == "table" and (target.prefab == "pocketwatch_recall" or target.prefab == "pocketwatch_warp") then
        if wormholecheck then
            wormholecheck = false
            GLOBAL.ThePlayer:DoTaskInTime(1.5, function()
                wormholecheck = true
            end)
        end
    end
    oldSendRPCToServer(rpc, actcode, target, ...)
end

local function fn()
    if not InGame() then return end

    if task then
        GLOBAL.ThePlayer:EnableMovementPrediction(true)
        task:Cancel()
        task = nil
        wormholecheck = false
        TIP("解除控制", nil, wormholecheck)
        SaveModData(WOWData, false)
        return
    end

    if not TryCraft(true) then
        TIP("功能错误", "red", "没有能搓的东西,请准备点材料")
        SaveModData(WOWData, false)
        return
    else
        wormholecheck = true
        TIP("功能开启", "green", "解控已就绪")
        SaveModData(WOWData, true)
    end

    WowAutoTask()
end



if GetModConfigData("sw_wow") == "biubiu" then
    DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("tophat_witch_pyre.tex"),
    "tophat_witch_pyre.tex", "解除控制",
    "卡海的残党，新时代没有承载我的船",
    false, fn)
end

AddBindBtn("sw_wow", fn)

