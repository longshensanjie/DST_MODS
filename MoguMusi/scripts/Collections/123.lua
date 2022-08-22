-- 内测功能
local function MoveTo(x, y)
    if x and y then
        GLOBAL.SendRPCToServer(GLOBAL.RPC.RightClick, GLOBAL.ACTIONS.BLINK.code, x, y)
    end
end

local function GetEntDist(ent1, ent2)
    if ent1 and ent2 then
        local pos1 = ent1:GetPosition()
        local pos2 = ent2:GetPosition()
        return GetDist(pos1.x, pos1.z, pos2.x, pos2.z)
    end
    return 10000
end


local function CheckLateFrame(ent, judgedelay)
    if ent and ent:IsValid() and ent.entity then
        local DebugString = ent.entity:GetDebugString()
        local bank,build,anim,zip,frame,facing=DebugString:match("bank: (.+) build: (.+) anim: ([^ .]+) anim/(.+).zip[^ .]+ Frame: (.+) Facing: ([^ .]+)\n")
        if frame then
            local now,all = frame:match("(.+)\/(.+)")
            now,all= tonumber(now),tonumber(all)
            if now and all and now > 0.5*all then
                return false
            end
        end
        -- print(frame)
    end
    return true
end

local TUNING = GLOBAL.TUNING
local atk_table = {
    dragonfly = {
        range = TUNING.DRAGONFLY_HIT_RANGE,
        anim = {atk = 15},
    },
    moose = {
        range = TUNING.MOOSE_ATTACK_RANGE,
        anim = {atk = 20},
    },
    bearger = {
        range = TUNING.BEARGER_ATTACK_RANGE,
        anim = {atk = 35+2, ground_pound = 20+3},
        aoe = true,
    },
    deerclops = {
        range = TUNING.DEERCLOPS_AOE_RANGE,
        anim = {atk = 29+3, atk2 = 19},
        aoe = true,
    },
    bishop = {
        range = 20,
        anim = {atk = 24},
    },
    bishop_nightmare = {
        range = 20,
        anim = {atk = 24},
    }
}
local ATK_KEY = false
local initdelay = 14
local avaping = 1


for bossname,boss in pairs(atk_table)do
    AddPrefabPostInit(bossname, function(inst)
        avaping = GLOBAL.TheNet:GetAveragePing() or 1
        inst:DoPeriodicTask(GLOBAL.FRAMES, function()
            local animing = SearchForReturnAnim(boss.anim, inst)
            if animing
            and (GetAggro(inst) == GLOBAL.ThePlayer or boss.aoe)
            then
                local function player_aviod()
                    if ATK_KEY
                    and GetEntDist(GLOBAL.ThePlayer, inst) <= boss.range + 2.5
                    and CheckLateFrame(inst, initdelay)
                    then
                        ATK_KEY = false
                        local pocketwatch = GetItemFromAll("pocketwatch_warp", "pocketwatch_inactive")
                        if pocketwatch and GLOBAL.ThePlayer and GLOBAL.ThePlayer:HasTag("pocketwatchcaster") then
                            SendRPCAwithB(GLOBAL.RPC.ControllerUseItemOnSelfFromInvTile, GLOBAL.ACTIONS.CAST_POCKETWATCH, pocketwatch)
                        else
                            local pos = GLOBAL.ThePlayer:GetPosition()
                            MoveTo(pos.x, pos.z)   
                        end
                        GLOBAL.ThePlayer:DoTaskInTime(2, function()                     -- 闪现CD
                            ATK_KEY = true
                        end)
                    end
                end

            
                local timeing = (boss.anim[animing]-initdelay) * GLOBAL.FRAMES - avaping * 0.001
                if timeing < 0 then timeing = 0 end
                GLOBAL.ThePlayer:DoTaskInTime(timeing, player_aviod)
                -- print(timeing, initdelay)
            end
        end)
    end)
end

DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("wortox_soul.tex"), "wortox_soul.tex", "测试躲避", "【测试功能，请勿开启】龙蝇、巨鹿、鹿鸭、熊大、主教", false, function()
    ATK_KEY = not ATK_KEY
    TIP("躲避辅助", "PURPLE", ATK_KEY)
end)