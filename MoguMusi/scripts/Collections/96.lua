-- 大力士打转【看起来很傻】
local keybind = GetModConfigData("sw_lx_wait")
if not keybind then
    return
end

local bellT = {"dumbbell_gem", "dumbbell_marble", "dumbbell_golden", "dumbbell"}
local MPE = false

local function setMP(mp)
    local playercontroller = ThePlayer.components.playercontroller
    if playercontroller:CanLocomote() then playercontroller.locomotor:Stop()
    else playercontroller:RemoteStopWalking() end
    ThePlayer:EnableMovementPrediction(mp)
    GLOBAL.Profile:SetMovementPredictionEnabled(mp)
end

local function StopTurnAround()
    if ThePlayer.TurnAroundTask then
		ThePlayer.TurnAroundTask:Cancel()
		ThePlayer.TurnAroundTask = nil
        -- TheCamera.target = ThePlayer
		TIP("力士挂机", "red", "停止", "chat")
        -- print(MPE)
        setMP(MPE)
	end
end


local function startWait()
    local pos = ThePlayer:GetPosition()
    local offset = 0.5
    local speed = 6
    if ThePlayer.components and ThePlayer.components.locomotor then
        speed = ThePlayer.components.locomotor:GetSpeedMultiplier()*ThePlayer.components.locomotor:RunSpeed()
        MPE = true
    end
    local looptime = 2*offset / speed
    local frames = TheSim:GetTickTime()
    if looptime < frames then looptime = frames end
    -- TheCamera.target = nil
    local posies = {
        {pos.x+offset, pos.y, pos.z+offset},
        {pos.x+offset, pos.y, pos.z-offset},
        {pos.x-offset, pos.y, pos.z-offset},
        {pos.x-offset, pos.y, pos.z+offset},
    }
    local posID = 1

    
	TIP("力士挂机", "green", "启动, 玩家位置已锁定", "chat")
    ThePlayer.TurnAroundTask =  ThePlayer:DoPeriodicTask(looptime, function (inst)
        setMP(true)
        if posID > #posies then posID = 1 end
        GLOBAL.SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, posies[posID][1], posies[posID][3])
        posID = posID + 1
    end)
end

GLOBAL.TheInput:AddKeyUpHandler(keybind, function()
    if not InGame() then
        return
    end
    if not ThePlayer or ThePlayer.prefab ~= "wolfgang" then
        return
    end
    if ThePlayer.TurnAroundTask then
        return StopTurnAround()
    end
    MPE = false
    local eq = GetEquippedItemFrom("hands")
    if eq and eq:HasTag("dumbbell") and ThePlayer.replica and ThePlayer.replica.inventory then
        startWait()
    else
        for _, v in pairs(bellT) do
            local eqs = GetItemsFromAll(v)
            for _,eq in pairs(eqs)do
                if eq and eq:HasTag("dumbbell") and ThePlayer.replica and ThePlayer.replica.inventory then
                    ThePlayer.replica.inventory:UseItemFromInvTile(eq)
                        startWait()
                    return
                end
            end
        end
    end
end)
