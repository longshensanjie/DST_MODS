-- 111：猛1的mod
local DataUtil = require("QAQ/breathydata")


local function PushHuxi(type, name)
    if GLOBAL.TheWorld then
        GLOBAL.TheWorld:PushEvent("Mod_Shroomcake_Huxi", {type = type, name = name})
    end
end

local function modifyStyle()
    local style = DataUtil.GetStyle()
    if style == "all" then
        style = "buff"
        TIP("呼吸栏","green","仅显示BUFF刷新时间")
    elseif style == "buff" then
        style = "boss"
        TIP("呼吸栏","green","仅显示BOSS刷新时间")
    elseif style == "boss" then
        style = "null"
        TIP("呼吸栏","red","禁用显示")
    else
        style = "all"
        TIP("呼吸栏","green","全部显示")
    end
    DataUtil.SetStyle(style)
    PushHuxi("style", style)
end

if GetModConfigData("sw_huxi") == "biubiu" then
    DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("abigail_flower_handmedown_level3.tex"), "abigail_flower_handmedown_level3.tex", "呼吸栏样式", "设置样式为【仅BOSS / 仅BUFF/ 禁用 / 全显示】", false, modifyStyle)
end
    
AddBindBtn("sw_huxi", modifyStyle)


local function onStartEating(rpc, actcode, ...)
    local food_ent
    if rpc == GLOBAL.RPC.LeftClick then
        food_ent = GLOBAL.ThePlayer.replica.inventory:GetActiveItem()
    elseif rpc == GLOBAL.RPC.UseItemFromInvTile then
        local placeholder
        food_ent, placeholder = ...
        food_ent = type(food_ent) ~= "number" and food_ent or placeholder
    end
    if food_ent and food_ent:HasTag("preparedfood") and food_ent.prefab then
        PushHuxi("food", food_ent.prefab)
    end
end

-- 拦截发送RPC
local oldSendRPCToServer = GLOBAL.SendRPCToServer
function GLOBAL.SendRPCToServer(rpc, actcode, ...)
    if actcode == GLOBAL.ACTIONS.EAT.code then
        onStartEating(rpc, actcode, ...)
    end
    oldSendRPCToServer(rpc, actcode, ...)
end

-- 跨世界传送
local old_DoRestart = GLOBAL.DoRestart
function GLOBAL.DoRestart(val)
	if val then
		PushHuxi("ins", "SaveAllData")
	end
	old_DoRestart(val)
end
local old_MigrateToServer = GLOBAL.MigrateToServer
function GLOBAL.MigrateToServer(ip,port,...)
	if ip and port then
		PushHuxi("ins", "SaveAllData")
	end
	old_MigrateToServer(ip,port,...)
end

-- function GLOBAL.happy_push(type, name)
--     PushHuxi(type, name)
-- end

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0.66, function()
        if GLOBAL.TheWorld.ismastersim then
            inst:ListenForEvent("oneat", function(src, data)
                if data.food:HasTag("preparedfood") then
                    PushHuxi("food", data.food.prefab)
                end
            end)
        end
    end)
end)


local r_interval = 1/30
local bosses_data = DataUtil.GetBossAnim()
local mana_boss_tasks = {}

for _, boss_data in pairs(bosses_data)do
    if boss_data.anims then
        AddPrefabPostInit(boss_data.name, function(inst)
            PushHuxi("removeboss", boss_data.name)
            local key = true
            inst:DoPeriodicTask(r_interval, function()
                if SearchForAnim(boss_data.anims, inst) and key then
                    PushHuxi("boss", boss_data.alias)
                    key = false                                             -- 这样写会有一个bug, 克劳斯会死两次, 只有第一次死亡才会记录
                end
            end)
        end)
    end
end

AddPrefabPostInit("stalker_atrium", function(inst)
    local key = true
    inst:DoPeriodicTask(r_interval, function()
        if SearchForAnim({"death3"}, inst) and key then
            PushHuxi("fallInLove", {warn = "minotaur", time = GLOBAL.TUNING.ATRIUM_GATE_DESTABILIZE_TIME + GLOBAL.TUNING.ATRIUM_GATE_DESTABILIZE_WARNING_TIME,})
            key = false
        end
    end)
end)

local HX_timer_board = require("widgets/huxi_timer")
local HX_text_entry = require("widgets/hx_text_entry")

AddClassPostConstruct("screens/playerhud", function(self)
    self.huxi_timer_board = self:AddChild(HX_timer_board(self.owner))

    function self:hxOpenTextEntry(target)
        self.textBoard = HX_text_entry(self.owner, target)
		self:OpenScreenUnderPause(self.textBoard)
		self.textBoard.nametextedit.textbox:SetEditing(true)
    end

    function self:hxSetBossDuration(boss_name, durationstr)
        local setnum = tonumber(durationstr)
        if setnum then
            if setnum <= 0 then setnum = -99 end        -- 设置为负数或0则该生物不再记录倒计时
            PushHuxi("setBossTimer", {name = boss_name, time = setnum})
        else
            GLOBAL.ThePlayer.components.talker:Say("呼吸栏：设置错误,需要设置为纯数字")
        end
    end
end)

AddPrefabPostInit("world", function (inst)
    inst:DoTaskInTime(1, function (inst)
        if GLOBAL.TheWorld and GLOBAL.TheWorld.net and GLOBAL.TheWorld.net.components.shardstate then
            local seed = GLOBAL.TheWorld.net.components.shardstate:GetMasterSessionId()
            DataUtil.SetSeed(seed)
            -- 通过这种方式传递数据, 我也是奇葩
            DataUtil.SetAnn(GetModConfigData("sw_huxi_announce"))
            PushHuxi("ins", "ReadAndShow")
        end
    end)
end)

