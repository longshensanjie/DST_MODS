-- 合集中禁止覆盖环境
-- 放弃旧的思路：对每个新出现的表部署
-- 新的思路：箱子打开部署箱子里的，身上的单独部署，这样节约运算

local TheInput = GLOBAL.TheInput
local STRINGS = GLOBAL.STRINGS
local file_id = "REAT_"
local certi_id = "POS_"
local player_seed, world_seed
local owner_id = file_id.."OWNER"
local equip_id = file_id.."EQUIP"
local container_id = file_id.."CONT"
local altas_id = file_id.."ALTAS"
local position_id = file_id.."POS"
local gamer = "player"
local world = "world"
local INFO = {}
local funcTip = "旺达表命名"
local supportable = {"pocketwatch_recall", "pocketwatch_portal"}
local permission = true
local function prlog(...)
    print(funcTip, ...)
end


local function GetEntPosID(ent)
    local pos = ent:GetPosition()
    if pos.x and pos.y and pos.z then
        return string.format("%.2f%.2f%.2f", pos.x, pos.y, pos.z)
    end
end

local function GetItemPosTable(item)
    local items
    items = GLOBAL.ThePlayer.replica.inventory:GetItems() or {}
    for pos, theitem in pairs(items)do
        if theitem == item then
            return {type = owner_id, pos = certi_id..pos}
        end
    end
    items = GLOBAL.ThePlayer.replica.inventory:GetEquips() or {}
    for pos, theitem in pairs(items)do
        if theitem == item then
            return {type = equip_id, pos = certi_id..pos}
        end
    end
    local containers = GLOBAL.ThePlayer.replica.inventory:GetOpenContainers() or {}
    for container in pairs(containers) do
        if container and container.replica and container.replica.container then
            local items_container = container.replica.container:GetItems() or {}
            for pos, theitem in pairs(items_container)do
                if theitem == item then
                    return {type = container_id, pos = certi_id..pos, cont_pos = GetItemPosTable(container)}
                end
            end
        end
    end
end

local function ModifyItemDataAll()
    prlog("数据修改")
    local items
    if permission and GLOBAL.ThePlayer and GLOBAL.ThePlayer.replica.inventory then
        items = GLOBAL.ThePlayer.replica.inventory:GetItems() or {}
        for pos, theitem in pairs(items)do
            if table.contains(supportable, theitem.prefab) then
                SetTableMultiLevel(INFO, {gamer, owner_id, certi_id..pos}, theitem[altas_id])
            end
        end
        items = GLOBAL.ThePlayer.replica.inventory:GetEquips() or {}
        for pos, theitem in pairs(items)do
            if table.contains(supportable, theitem.prefab) then
                SetTableMultiLevel(INFO, {gamer, equip_id, certi_id..pos}, theitem[altas_id])
            end
        end
        local containers = GLOBAL.ThePlayer.replica.inventory:GetOpenContainers() or {}
        for container in pairs(containers) do
            if container.replica and container.replica.container and container.prefab then
                local items_container = container.replica.container:GetItems() or {}
                for pos, theitem in pairs(items_container)do
                    if table.contains(supportable, theitem.prefab) then
                        local cont_data = GetItemPosTable(container)
                        if cont_data and cont_data.type and cont_data.pos then
                            SetTableMultiLevel(INFO, {gamer, cont_data.type, cont_data.pos, certi_id..pos}, theitem[altas_id])
                        else
                            SetTableMultiLevel(INFO, {world, container.prefab, GetEntPosID(container), certi_id..pos}, theitem[altas_id])
                        end
                    end
                end
            end
        end
    end
end

local function ForEach(t, cb)
    for _,item in pairs(t)do
        cb(item)
    end
end


local function SayMyName(inst, name)
    prlog("设置名字",name)
    if not inst or not name then return end
    local standname = ""
    if inst.prefab then
        standname = STRINGS.NAMES[string.upper(inst.prefab)]
    end
    if type(name) == "string" and string.len(name)~=0 then
        inst.name = standname.."["..name.."]"
        inst[altas_id] = name
    end
end

local function LoadAllData()
    world_seed = GetWorldSeed()
    player_seed = GetPlayerSeed()
    if type(world_seed) == "string" and type(player_seed) == "string" then
        SetTableMultiLevel(INFO, {gamer}, LoadModData(file_id..player_seed))
        SetTableMultiLevel(INFO, {world}, LoadModData(file_id..world_seed))
    else
        prlog("种子丢失, 无法加载世界配置")
    end
end

local function SetBodyItemSingle(inst)
    local ihave = GetItemPosTable(inst)
    if ihave and ihave.pos then
        if ihave.type == owner_id or ihave.type == equip_id then    -- 在物品栏
            SayMyName(inst, GetTableMultiLevel(INFO, {gamer, ihave.type, ihave.pos}))
        elseif ihave.type == container_id then                      -- 在容器里
            if type(ihave.cont_pos) == "table" then                                  -- 在背包
                if ihave.cont_pos.cont_pos then
                    prlog("拒绝套娃！不要将表放到两层以上的容器里！")
                else
                    SayMyName(inst, GetTableMultiLevel(INFO, {gamer,ihave.cont_pos.type,ihave.cont_pos.pos,ihave.pos}))
                end
            else
                -- 箱子里的不必在此修改
                -- 原因：你懂个锤子
            end
        else
            prlog("发生了BUG, 物品处于未知位置")
        end
    else
        prlog("丢在地上不算哦")
    end
end

local function SetBodyItemInfo()
    ForEach(supportable, function(prefab)
        ForEach(GetItemsFromAll(prefab), SetBodyItemSingle)
    end)
end


-- 数据：加载（Load）、查询（Get）、部署（Set）、修改（Modify）、存储（Save）

-- 所有的数据将会在世界加载完成后加载
AddPrefabPostInit(world, function (inst)
    inst:DoTaskInTime(1.5, LoadAllData)
end)



local function Save_REAT_Data()
    -- 世界数据
    world_seed = GetWorldSeed()
    player_seed = GetPlayerSeed()
    if type(world_seed) == "string" and type(player_seed) == "string" then

        SaveModData(file_id..player_seed, GetTableMultiLevel(INFO, {gamer}))
        SaveModData(file_id..world_seed, GetTableMultiLevel(INFO, {world}))
    else
        prlog("未存储!",world_seed,player_seed)
    end
end

AddPlayerPostInit(function(inst)
    if inst == GLOBAL.ThePlayer then
        -- 玩家进入游戏后，将加载的数据全部部署
        inst:DoTaskInTime(2, SetBodyItemInfo)
        -- 稍有风吹草动再修改为新的数据
        inst:DoTaskInTime(2.5, function()
            inst:ListenForEvent("refreshinventory", ModifyItemDataAll)
        end)
        -- 天亮保存数据【防止崩溃丢数据】
        inst:WatchWorldState("startday", Save_REAT_Data)
    end

end)


-- 允许不同的容器放在一个点上
-- 开箱子后展示箱子里的东西
AddClassPostConstruct("components/container_replica", function (self, ent)
    local _Open = self.Open
    function self.Open(...)
        local container = ent.replica.container
        if not GetItemPosTable(ent) and container and container:GetNumSlots() and container:GetNumSlots() > 4 and ent.prefab then
            local items_container = container:GetItems() or {}
            for pos, theitem in pairs(items_container)do
                if table.contains(supportable, theitem.prefab) then
                    SayMyName(theitem, GetTableMultiLevel(INFO, {world, ent.prefab,  GetEntPosID(ent), certi_id..pos}))
                end
            end
        end
        _Open(...)
    end
end)

local function TemporaryOpen()
    permission = false
    GLOBAL.ThePlayer:DoTaskInTime(1, function()
        SetBodyItemInfo()
        permission = true
    end)
end

-- 拦截发送RPC
local oldSendRPCToServer = GLOBAL.SendRPCToServer
function GLOBAL.SendRPCToServer(rpc, actcode, target, ...)
    -- 插入宝石
    if GLOBAL.RPC and rpc == GLOBAL.RPC.UseItemFromInvTile 
    and GLOBAL.ACTIONS and GLOBAL.ACTIONS.GIVE and actcode == GLOBAL.ACTIONS.GIVE.code
    and type(target) == "table" and target.prefab == "pocketwatch_recall" then
        TemporaryOpen()
    end
    -- 激活裂缝表
    if GLOBAL.RPC and rpc == GLOBAL.RPC.UseItemFromInvTile 
    and GLOBAL.ACTIONS and GLOBAL.ACTIONS.CAST_POCKETWATCH and actcode == GLOBAL.ACTIONS.CAST_POCKETWATCH.code
    and type(target) == "table" and target.prefab == "pocketwatch_portal" then
        TemporaryOpen()
    end
    oldSendRPCToServer(rpc, actcode, target, ...)
end


local _DoRestart = GLOBAL.DoRestart
function GLOBAL.DoRestart(val)
	if val then
        Save_REAT_Data()
	end
	_DoRestart(val)
end
local _MigrateToServer = GLOBAL.MigrateToServer
function GLOBAL.MigrateToServer(ip,port,...)
	if ip and port then
        Save_REAT_Data()
	end
	_MigrateToServer(ip,port,...)
end


local sw_rename = false

local function AdaptTIP(sw)
    if sw then
        TIP(funcTip, "yellow", "已开启, 右键单击 溯源表或裂缝表 进行命名或重命名", "chat")
    else
        TIP(funcTip, "red", "已关闭", "chat")
    end
end



local writeablescreen
-- 合集的好处，凑一套代码
local WriteableWidget = require "screens/TMIP_writeablewidget"
local writeable_widget_args = {
    animbank = "ui_board_5x3",
    animbuild = "ui_board_5x3",
    menuoffset = GLOBAL.Vector3(6, -70, 0),
    cancelbtn = {
        text = STRINGS.UI.TRADESCREEN.CANCEL,
        cb = function()
            GLOBAL.ChatHistory:AddToHistory(GLOBAL.ChatTypes.Message, nil, nil, funcTip, "取消", COLORS.YELLOW)
        end,
        control = GLOBAL.CONTROL_CANCEL
    },
    acceptbtn = {
        text = STRINGS.UI.TRADESCREEN.ACCEPT,
        cb = function(w, target)
            SayMyName(target, w:GetText())
            ModifyItemDataAll()
        end,
        control = GLOBAL.CONTROL_ACCEPT
    }
}
local function OpenWriteScreen(target)
    if writeablescreen then
        writeablescreen:KillAllChildren()
        writeablescreen:Kill()
        writeablescreen = nil
    end
    writeablescreen = WriteableWidget(writeable_widget_args, target)
    GLOBAL.ThePlayer.HUD:OpenScreenUnderPause(writeablescreen)
    if GLOBAL.TheFrontEnd:GetActiveScreen() == writeablescreen then
        writeablescreen.edit_text:SetEditing(true)
    end
end

local function fn()
    sw_rename = not sw_rename
    AdaptTIP(sw_rename)
end
if GetModConfigData("wanda_rename") == "biubiu" then
DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("pocketwatch_recall.tex"), "pocketwatch_recall.tex", funcTip, "旺达为自己的表起名", true, fn)
end
AddBindBtn("wanda_rename", fn)

AddClassPostConstruct("widgets/invslot", function(self)
    local _OnControl = self.OnControl
    self.OnControl = function(self, control, down, ...)
        if down and control == GLOBAL.CONTROL_SECONDARY and not TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_TRADE) 
        and sw_rename 
        and self.tile and self.tile.item and table.contains(supportable, self.tile.item.prefab)
        then
            OpenWriteScreen(self.tile.item)
            sw_rename = false
            AdaptTIP(sw_rename)
        else
            return _OnControl(self, control, down, ...)
        end
    end
end)


-- 更改显示
AddComponentPostInit("playeractionpicker", function(self)
    local _GetInventoryActions = self.GetInventoryActions
    self.GetInventoryActions = function(self, item, ...)
        local inv_actions = _GetInventoryActions(self, item, ...)
        if sw_rename and table.contains(supportable, item.prefab) then
            for _, inv_action in pairs(inv_actions) do
                if inv_action.action == GLOBAL.ACTIONS.LOOKAT or inv_action.action == GLOBAL.ACTIONS.CAST_POCKETWATCH then
                    if item[altas_id] then
                        inv_action.GetActionString = function()
                            return "重命名"
                        end
                    else
                        inv_action.GetActionString = function()
                            return "命名"
                        end
                    end
                end
            end
        end
        return inv_actions
    end
end)


-- TODO 先不看
GLOBAL.WINFO = INFO