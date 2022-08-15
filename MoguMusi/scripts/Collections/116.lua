local input = GLOBAL.TheInput
-- 不知道在哪个文件里
local max_hop_dist = 36

local function InGamePlaying()
    return InGame() and GLOBAL.ThePlayer.prefab == "wortox" and GLOBAL.ThePlayer:GetPosition()
    -- and not input:GetWorldEntityUnderMouse()
end

local function MoveTo(x, y)
    if x and y then
        GLOBAL.SendRPCToServer(GLOBAL.RPC.RightClick, GLOBAL.ACTIONS.BLINK.code, x, y)
    end
end

local function GetMaxHopPos()
    local pos_player = GLOBAL.ThePlayer:GetPosition()
    local pos_screen = input:GetWorldPosition()
    if pos_player.x ~= pos_screen.x and pos_player.z ~= pos_screen.z then
        local r = GetDist(pos_player.x, pos_player.z, pos_screen.x, pos_screen.z)
        local cx = (max_hop_dist*(pos_screen.x-pos_player.x))/r + pos_player.x
        local cy = (max_hop_dist*(pos_screen.z-pos_player.z))/r + pos_player.z
        return cx, cy
    end
end

input:AddMouseButtonHandler(function(button, down, x, y)
    if button == GLOBAL.MOUSEBUTTON_MIDDLE 
    and not down 
    and not input:GetHUDEntityUnderMouse()
    and InGamePlaying()
    then
        local x,y = GetMaxHopPos()
        MoveTo(x, y)
    end
end)

local soul_pointer

local function SpawnPointer()
    soul_pointer = GLOBAL.SpawnPrefab("reticule")
    soul_pointer.AnimState:SetLightOverride(1)
end



local function FlushPointer()
    if soul_pointer and soul_pointer.Transform then
        local a,b = GetMaxHopPos()
        if a and b then
            soul_pointer.Transform:SetPosition(a, 0, b)
            if (not GLOBAL.TheWorld:HasTag("cave") and (soul_pointer:IsOnValidGround() or not soul_pointer:IsOnOcean(false)))
            or (GLOBAL.TheWorld:HasTag("cave") and soul_pointer:IsOnValidGround())
            then
                soul_pointer.AnimState:SetAddColour(0, 1, 0, 0)
            else
                soul_pointer.AnimState:SetAddColour(1, 0, 0, 0)
            end
        end
    elseif InGamePlaying() and not soul_pointer then
        SpawnPointer()
    end
end

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(3, function()
        if inst == GLOBAL.ThePlayer and inst.prefab == "wortox" then
            inst:DoPeriodicTask(1/24, function()
                FlushPointer()
            end)
        end
    end)
end)