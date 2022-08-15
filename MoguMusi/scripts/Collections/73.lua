local MAX = GetModConfigData("wortox_ex")
local Btn = GetModConfigData("wortox_ex_btn")


-- 默认是关的，方便上下洞穴保留魂
local allow_drop = false
local function IsSoul(item)
    return item.prefab == "wortox_soul"
end

local function GetStackSize(item)
    return item.replica.stackable and item.replica.stackable:StackSize() or 1
end

local function TheDrop(inst)
    if not allow_drop then return end
    local count = 0
    for i, v in pairs(inst.replica.inventory:GetItems()) do
        if v  and v.prefab == "wortox_soul" then
            count = count + GetStackSize(v)
        end
        if count > MAX then
            if v  and v.prefab == "wortox_soul" then
                inst.replica.inventory:DropItemFromInvTile(v)
            end
        end
    end
end


AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(2.5, function()
        if inst == GLOBAL.ThePlayer and inst.prefab == "wortox" then
            inst:DoPeriodicTask(0.5, function()
                TheDrop(inst)
            end)
        end
    end)
end)

GLOBAL.TheInput:AddKeyUpHandler(Btn, function ()
    if InGame() and GLOBAL.ThePlayer.prefab == "wortox" then 
        allow_drop = not allow_drop
        TIP("防止爆魂","yellow", allow_drop)
    end
end)
