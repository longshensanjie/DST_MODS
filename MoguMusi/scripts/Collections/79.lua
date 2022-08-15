local _G = GLOBAL

local function CancelTask(inst)
    if inst.autoliftgym_task ~= nil then
        inst.autoliftgym_task:Cancel()
        inst.autoliftgym_task = nil
    end
end

local function DoActionLiftGym(inst, perfect)
    local action = perfect and _G.ACTIONS.LIFT_GYM_SUCCEED_PERFECT or _G.ACTIONS.LIFT_GYM_SUCCEED
    local pos = inst:GetPosition()
    SendRPCclk(_G.RPC.LeftClick, action, pos)
end

local function OnUpdate(inst)
    if inst:HasTag("ingym") then
        if not inst:HasTag("busy") then
            local percent = inst.bell_percent
            local issuccess = false
            local isperfect = false

            local level = inst.player_classified.inmightygym:value() + 1
            local success_min = _G.TUNING["BELL_SUCCESS_MIN_"..level]
            local success_max = _G.TUNING["BELL_SUCCESS_MAX_"..level]
            local success_mid_min = _G.TUNING["BELL_MID_SUCCESS_MIN_"..level]
            local success_mid_max = _G.TUNING["BELL_MID_SUCCESS_MAX_"..level]

            if success_min and success_max and percent >= success_min and percent <= success_max then
                issuccess = true
                isperfect = true
            elseif success_mid_min and success_mid_max and percent >= success_mid_min and percent <= success_mid_max then
                issuccess = true
            end

            if issuccess then
                if level >= 4 and isperfect then
                    DoActionLiftGym(inst, true)
                elseif level < 4 then
                    DoActionLiftGym(inst, false)
                end
            end
        end
    else
        CancelTask(inst) --paranoic, I want to end task successfully in any case
    end
end

local function OnGymCheck(inst, data)
    CancelTask(inst)

    if data.ingym > 1 then
        inst.autoliftgym_task = inst:DoPeriodicTask(_G.FRAMES * 3, OnUpdate) --skip 3 frames, I don't want to spam the calculations
    end
end

AddPlayerPostInit(function(inst)
    if inst:HasTag("strongman") then
        inst:ListenForEvent("inmightygym", OnGymCheck)
    end
end)
