local SLEEP_TIME = GLOBAL.FRAMES * 3

local BEEBOX_MUSTTAGS = {"harvestable", "beebox"}
local FIRESUPPRESSOR_MUSTTAGS = {"turnedon"}
local TARGET_EXCLUDE_TAGS = {"INLIMBO"}

local collectorthread

local function SendAction(act)
    local x, _, z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
    SendActionAndFn(act, function()
        if GLOBAL.ThePlayer.replica.inventory:GetActiveItem() then
            GLOBAL.SendRPCToServer(GLOBAL.RPC.ActionButton, act.action.code, act.target, true) -- If you're too far away (dist > 6) from target, it still can't handle that
        else
            GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, act.action.code, x, z, act.target, true)
        end
    end)
end

local function Wait()
    repeat
        GLOBAL.Sleep(SLEEP_TIME)
    until not (GLOBAL.ThePlayer.sg and GLOBAL.ThePlayer.sg:HasStateTag("moving")) and not GLOBAL.ThePlayer:HasTag("moving")
end

local function SendActionAndWait(act)
    SendAction(act)
    Wait()
end

local function StopThread()
    if collectorthread then
        collectorthread:SetList(nil)
    end
    collectorthread = nil
    TIP("引火取蜜","red","停止")
end

local function find_firesuppressor(inst)
    return inst.prefab == "firesuppressor"
end

local more_honey_beebox_anim = {"honey3", "hit_honey3", "honey2", "hit_honey2"}
local function FindBestBeebox()
    local available_beeboxes = {}
    local x, y, z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
    for _, beebox in ipairs(GLOBAL.TheSim:FindEntities(x, y, z, 30, BEEBOX_MUSTTAGS, TARGET_EXCLUDE_TAGS)) do
        if GLOBAL.FindEntity(beebox, TUNING.FIRE_DETECTOR_RANGE, find_firesuppressor, FIRESUPPRESSOR_MUSTTAGS, TARGET_EXCLUDE_TAGS) then
            table.insert(available_beeboxes, beebox)
        end
    end
    for _, beebox in ipairs(available_beeboxes) do
        for _, anim in ipairs(more_honey_beebox_anim) do
            if beebox.AnimState:IsCurrentAnimation(anim) then
                return beebox
            end
        end
    end
    return available_beeboxes[1]
end

local function CanImmuneFire()
    if GLOBAL.ThePlayer.prefab == "willow" then
        return true
    else
        local body_item = GLOBAL.ThePlayer.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.BODY)
        return body_item and body_item.prefab == "armordragonfly"
    end
end

local function find_lighter(item)
    return item:HasTag("lighter")
end

local function fn()
    if collectorthread then StopThread() return end
    collectorthread = GLOBAL.ThePlayer:StartThread(function()

        while GLOBAL.ThePlayer:IsValid() do

            if not CanImmuneFire() then 
                TIP("引火取蜜","red","玩家不防火, 请换Willow或装备鳞甲")
                return
            end
            local lighter = GetItemFromContainers(nil, nil, nil, find_lighter)
            if not lighter then 
                TIP("引火取蜜","red","未携带火炬")
                return
            end

            local target = FindBestBeebox()
            if not target then
                TIP("引火取蜜","red","蜂箱没有蜂蜜或灭火器未启动")
                return 
            end
            local act = GLOBAL.BufferedAction(GLOBAL.ThePlayer, target, GLOBAL.ACTIONS.LIGHT, lighter)
            while target:IsValid() and target:HasTag("canlight") do
                UseItemOnScene(lighter, act)
                Wait()
            end
            

            local act = GLOBAL.BufferedAction(GLOBAL.ThePlayer, target, GLOBAL.ACTIONS.HARVEST)
            SendActionAndWait(act)
            while target:IsValid() and target:HasTag("harvestable") do
                SendActionAndWait(act)
            end

        end

        StopThread()

    end)
    
end

InterruptedByMobile(function()
    return collectorthread
end, StopThread)

if GetModConfigData("tony_honey") == "biubiu" then
    DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("beebox_crystal.tex"), "beebox_crystal.tex", "引火取蜜", "点燃蜂箱收取蜂蜜", false, fn)
end

AddBindBtn("tony_honey", fn)
