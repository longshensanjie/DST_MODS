local TLC_TOGGLE_KEY = GetModConfigData("sw_toggle")

local function GetActiveScreenName()
	local screen = GLOBAL.TheFrontEnd:GetActiveScreen()
	return screen and screen.name or ""
end


local function ToggleLagCompensation(self)
    if not InGame() or GLOBAL.ThePlayer == nil then
        return
    end
    local player = GLOBAL.ThePlayer
    local playercontroller = player.components.playercontroller
    local profile = GLOBAL.Profile
    local movementprediction = not profile:GetMovementPredictionEnabled()
    if playercontroller:CanLocomote() then
        playercontroller.locomotor:Stop()
    else
        playercontroller:RemoteStopWalking()
    end
    player:EnableMovementPrediction(movementprediction)
    profile:SetMovementPredictionEnabled(movementprediction)
    if movementprediction then
        TIP("开启", "green", "延迟补偿已开启")
    else
        TIP("关闭", "red", "延迟补偿已关闭")
    end
end

GLOBAL.TheInput:AddKeyUpHandler(TLC_TOGGLE_KEY, ToggleLagCompensation)
