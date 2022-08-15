-- 几何工具 用来判断位置是否处于矩形中
local GeoUtil = require("utils/geoutil")
local Image = require("widgets/image")

-- 视角角度，判断部署建筑的角度
local headings = {[0] = true, [45] = false, [90] = false, [135] = true, [180] = true, [225] = false, [270] = false, [315] = true, [360] = true}

-- Shift右键粘贴 【蜘蛛巢已经不能种在蜘蛛巢上了，排队论过时啦】
local easy_stack = {minisign_item = "structure", minisign_drawn = "structure", spidereggsack = "spiderden"}
local entity_morph = {spiderhole = "spiderhole_rock"}
local moving_target = {tumbleweed = true}

-- 部署间隔
local deploy_spacing = {wall = 1, fence = 1, trap = 2, mine = 2, turf = 4, moonbutterfly = 4}
-- 陷阱的间隔另外计算，比如狗牙陷阱有些人不想那么密集，有些人喜欢密集
local drop_spacing = {trap = 2}

-- 类似特效、无法点击的、玩家等不能被选中
local unselectable_tags = {"DECOR", "FX", "INLIMBO", "NOCLICK", "player"}


-- ？？这两个线程分别是做什么的？
-- 框选的线程
local selection_thread_id = "actionqueue_selection_thread"
-- 排队论线程
local action_thread_id = "actionqueue_action_thread"

-- 允许的动作种类，适配模组动作需要对这个操作
local allowed_actions = {}
for _, category in pairs({"allclick", "leftclick", "rightclick", "single", "noworkdelay", "tools", "autocollect", "collect"}) do
    allowed_actions[category] = {}
end

-- 估计是刨地用的点位
local offsets = {}
for i, offset in pairs({{0,0},{0,1},{1,1},{1,0},{1,-1},{0,-1},{-1,-1},{-1,0},{-1,1}}) do
    offsets[i] = Point(offset[1] * 1.5, 0, offset[2] * 1.5)
end

-- 耕地队列的支持
local farm_grid = "3x3"
-- local farm_spacing = 1.333 -- 210116 null: 1.333 (4/3) = selection box spacing for Tilling, Wormwood planting, etc
-- 210202 null: selection box spacing / offset for Tilling, Wormwood planting, etc
local farm_spacing = 4/3 -- 210202 null: use 4/3 higher precision to prevent alignment issues at edge of maps
local farm3x3_offset = farm_spacing / 2 -- 210202 null: 3x3 grid offset, use 4/3/2 to prevent alignment issues at edge of maps

-- 蛇形种植
local double_snake = false -- 210127 null: support for snaking within snaking in DeployToSelection()

-- 210116 null: 4x4 grid offsets for each heading
local offsets_4x4 = { -- these are basically margin/offset multipliers, selection box often starts from adjacent tile
    [0] = {x = 3, z = 3}, -- heading of 0 and 360 are the same
    [45] = {x = 1, z = 3}, 
    [90] = {x = -1, z = 3}, 
    [135] = {x = -1, z = 1}, 
    [180] = {x = -1, z = -1}, 
    [225] = {x = 1, z = -1}, 
    [270] = {x = 3, z = -1}, 
    [315] = {x = 3, z = 1}, 
    [360] = {x = 3, z = 3}}

-- 210705 null: added support for other mods to add their own CherryPick conditions
local mod_cherrypick_fns = {} -- This will be a list of funtions from other mods

local DebugPrint = TUNING.ACTION_QUEUE_DEBUG_MODE and function(...)
    local msg = "[ActionQueue]"
    for i = 1, arg.n do
        msg = msg.." "..tostring(arg[i])
    end
    print(msg)
end or function() --[[disabled]] end

-- 排队论支持的动作有两个要素 种类、动作
local function AddAction(category, action, testfn)
    -- 检查动作种类是否存在
    if type(category) ~= "string" or not allowed_actions[category] then
        DebugPrint("Category doesn't exist:", category)
        return
    end
    -- 动作名应该在ACTIONS中或者是确认的动作ID
    local action_ = type(action) == "string" and ACTIONS[action] or action
    if type(action_) ~= "table" or not action_.id then
        DebugPrint("Action doesn't exist:", action)
        return
    end
    -- 测试函数要么别给，要么给哥函数，要么直接给true
    if testfn ~= nil and testfn ~= true and type(testfn) ~= "function" then
        DebugPrint("testfn should be true, a function that returns a boolean, or nil:", testfn, "type:", type(testfn))
        return
    end
    -- 动作可用时
    -- 测试函数存在         modifier = ”被修改“
    -- 测试函数不存在       modifier = "被移除"

    -- 动作不可用时
    -- 测试函数存在         modifier = 测试函数
    -- 测试函数不存在       modifier = “新增”
    local modifier = allowed_actions[category][action_] and (testfn and "modified" or "removed") or (testfn and "added")
    if not modifier then return end                 -- 只有可用的测试函数才能留下来

    -- 可用动作['动作种类']['动作ID'] = 测试函数
    allowed_actions[category][action_] = testfn
    DebugPrint("Successfully", modifier, action_.id, "action in", category, "category.")
end

-- 批量添加动作
-- 种类，动作ID1. 动作ID2.。。
local function AddActionList(category, ...)
    for _, action in pairs({...}) do
        AddAction(category, action, true)
    end
end

-- 也是批量添加，不知道为何要这么做
local function RemoveActionList(category, ...)
    for _, action in pairs({...}) do
        AddAction(category, action)
    end
end

--[[global console functions]]
AddActionQueuerAction = AddAction
RemoveActionQueuerAction = AddAction
AddActionQueuerActionList = AddActionList
RemoveActionQueuerActionList = RemoveActionList

--[[allclick]]
AddActionList("allclick", "CHOP", "MINE", "NET", "EAT")
-- 201222 null: Moved "EAT" from "rightclick" to "allclick" list

AddAction("allclick", "ATTACK", function(target)
    return target:HasTag("wall")
end)

-- 尝试兼容富贵
AddAction("allclick", "PLUCK", function(target)
    return target:HasTag("pluckable")
end)

-- 尝试兼容勋章
-- AddAction("allclick", "ROOTCHESTLEVELUP", function(target)
--     return target:HasTag("needfertilize")
-- end)
-- AddAction("allclick", "MAKECOOLDOWN", function(target)
--     return (target:HasTag("blueflame") and target:HasTag("fire")) or target.prefab=="staffcoldlight"
-- end)

-- 捕鱼器
AddAction("rightclick", "OCEAN_TRAWLER_RAISE", function(target)
    return target.prefab == "ocean_trawler"
end)
AddAction("rightclick", "OCEAN_TRAWLER_LOWER", function(target)
    return target.prefab == "ocean_trawler"
end)
AddAction("leftclick", "OCEAN_TRAWLER_FIX", function(target)
    return target.prefab == "ocean_trawler"
end)

--[[leftclick]]
AddActionList("leftclick", "ADDFUEL", "ADDWETFUEL", "CHECKTRAP", "COMBINESTACK", "COOK", "DECORATEVASE", "DIG", "DRAW", "DRY",
"EAT", "FERTILIZE", "FILL", "GIVE", "HAUNT", "LOWER_SAIL_BOOST", "PLANT", "RAISE_SAIL", "REPAIR_LEAK", "SEW", "TAKEITEM", "UPGRADE", 
"PLANTSOIL", "INTERACT_WITH", "ADDCOMPOSTABLE", -- null添加了植物交互和堆肥机的动作
"GIVETOPLAYER", "GIVEALLTOPLAYER")              -- 呼吸添加了给玩家塞东西的动作

AddAction("leftclick", "ACTIVATE", function(target)
    return target.prefab == "dirtpile"
end)
AddAction("leftclick", "HARVEST", function(target)
    return target.prefab ~= "birdcage"
end)
AddAction("leftclick", "HEAL", function(target)
    --ThePlayer can only heal themselves, not other players
    return target == ThePlayer or not target:HasTag("player")
end)
AddAction("leftclick", "PICK", function(target)
    return target.prefab ~= "flower_evil"
end)
AddAction("leftclick", "PICKUP", function(target)
    return target.prefab ~= "trap" and target.prefab ~= "birdtrap"
       and not target:HasTag("mineactive") and not target:HasTag("minesprung")
end)
AddAction("leftclick", "SHAVE", function(target)
    return target:HasTag("brushable")
end)

-- 201223 null: left click for PLANTREGISTRY_RESEARCH while equipping plantregistryhat
AddAction("leftclick", "PLANTREGISTRY_RESEARCH", function(target)
    local equip_item = ThePlayer.components.playeravatardata.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    return equip_item and (equip_item.prefab == "plantregistryhat" or equip_item.prefab == "nutrientsgoggleshat") and
           target.prefab ~= "farm_plant_randomseed" -- 201223 null: disable research on random seeds to prevent infinite queue issue
end)

-- 210203 null: added support for leftclick FEED, when Walter feeds small Woby
AddAction("leftclick", "FEED", function(target)
    return target.prefab == "wobysmall"
end)

-- 210226 null: added support for left click Wickerbottom book on self for READ (for Wickerbottom / Maxwell)
AddAction("leftclick", "READ", function(target)
    local active_item = ThePlayer.components.playeravatardata.inst.replica.inventory:GetActiveItem()
    return active_item and active_item.AnimState and active_item.AnimState:GetBuild() == "books" and
           target == ThePlayer -- 210226 null: only queue READ if ThePlayer is using a book on themselves
end)

-- 210307 null: ATTACK for "leftclick" may or may not be enabled, depending on attack_queue config setting
-- ActionQueuer.SetAttackQueue() is called in modmain.lua

--[[rightclick]]
AddActionList("rightclick", "CASTSPELL", "COOK", "DIG", "DISMANTLE",-- "EAT", -- 201222 null: Removed "EAT" from "rightclick" list
"FEEDPLAYER", "HAMMER", "REPAIR", "RESETMINE", "TURNON", "TURNOFF", "UNWRAP", 
"TAKEITEM", "POUR_WATER", "DEPLOY_TILEARRIVE")
-- 201216 null: added support for TAKEITEM (lureplant) + POUR_WATER (extinguish)
-- 201223 null: added support for DEPLOY_TILEARRIVE (Fertilize Plot)

-- 201218 null: added support for right click PICK while equipping plantregistryhat
AddAction("rightclick", "PICK", function(target)
    local equip_item = ThePlayer.components.playeravatardata.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    return equip_item and (equip_item.prefab == "plantregistryhat" or equip_item.prefab == "nutrientsgoggleshat")
end)

-- 201218 null: added support for right click INTERACT_WITH while equipping plantregistryhat
AddAction("rightclick", "INTERACT_WITH", function(target)
    local equip_item = ThePlayer.components.playeravatardata.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HEAD)
    return equip_item and (equip_item.prefab == "plantregistryhat" or equip_item.prefab == "nutrientsgoggleshat")
end)

-- 210103 null: added support for right click INTERACT_WITH while Wormwood (plantkin)
AddAction("rightclick", "INTERACT_WITH", function(target)
    return ThePlayer:HasTag("plantkin")
end)

-- 210103 null: added support for right click PICK while Wormwood (plantkin)
AddAction("rightclick", "PICK", function(target)
    return ThePlayer:HasTag("plantkin")
end)

-- 210203 null: added support for rightclick FEED, when Walter feeds big Woby
AddAction("rightclick", "FEED", function(target)
    return target.prefab == "wobybig"
end)

--[[single]]
AddActionList("single", "CASTSPELL", "DECORATEVASE", "REPAIR_LEAK")
-- 210218 null: Added REPAIR_LEAK to "single" list so that it only attempts a single REPAIR_LEAK per boat_leak

--[[noworkdelay]]
AddActionList("noworkdelay", "ADDFUEL", "ADDWETFUEL", "ATTACK", "CHOP", "COOK", "DIG", "DRY", "EAT",
"FERTILIZE", "FILL", "HAMMER", "HARVEST", "HEAL", "MINE", "PLANT", "REPAIR", "TERRAFORM", "UPGRADE", 
"ADDCOMPOSTABLE", "DEPLOY_TILEARRIVE", "PICKUP")
-- 201223 null: added support for ADDCOMPOSTABLE (compostingbin) + DEPLOY_TILEARRIVE (Fertilize Plot)
-- 210307 null: added PICKUP to allow better support for PICKUP with higher latency connections

AddAction("noworkdelay", "GIVE", function(target)
    return target:HasTag("trader")
end)
AddAction("noworkdelay", "NET", function(target)
    return not ThePlayer.components.locomotor or not target:HasTag("butterfly")
end)
--[[tools]]
AddActionList("tools", "ATTACK", "CHOP", "DIG", "HAMMER", "MINE", "NET")
--[[autocollect]]
AddActionList("autocollect", "CHOP", "DIG", "HAMMER", "HARVEST", "MINE", "PICK", "PICKUP", "RESETMINE")
AddAction("autocollect", "GIVE", function(target)
    return target.prefab ~= "mushroom_farm" and target.prefab ~= "moonbase" and not target:HasTag("gemsocket")
end)

--[[collect]]
AddActionList("collect", "HARVEST")

AddAction("collect", "PICK", function(target)
    return not target:HasTag("flower")
end)

-- 210218 null: Moved PICKUP out of "collect" ActionList to allow for exceptions to PICKUP when auto-collect enabled
AddAction("collect", "PICKUP", function(target)
    return target.prefab ~= "lantern" -- 210218 null: Do not PICKUP lantern when auto-collect enabled
end)

local ActionQueuer = Class(function(self, inst)
    self.inst = inst
    self.selection_widget = Image("images/selection_square.xml", "selection_square.tex")
    self.selection_widget:Hide()
    self.clicked = false
    self.TL, self.TR, self.BL, self.BR = nil, nil, nil, nil
    TheInput:AddMoveHandler(function(x, y)
        self.screen_x, self.screen_y = x, y
        self.queued_movement = true
    end)
    --Maps ent to key and rightclick(true or false) to value
    self.selected_ents = {}
    self.selection_thread = nil
    self.action_thread = nil
    self.action_delay = FRAMES * 3
    self.work_delay = FRAMES * 6
    self.color = {x = 1, y = 1, z = 1}
    self.deploy_on_grid = false
    self.auto_collect = false
    self.endless_deploy = false
    self.last_click = {time = 0}
    self.double_click_speed = 0.4
    self.double_click_range = 15
    self.AddAction = AddAction
    self.RemoveAction = AddAction
    self.AddActionList = AddActionList
    self.RemoveActionList = RemoveActionList
end)

-- 有效实体
local function IsValidEntity(ent)
    return ent and ent.Transform and ent:IsValid() and not ent:HasTag("INLIMBO")
end

-- HUD
local function IsHUDEntity()
    local ent = TheInput:GetWorldEntityUnderMouse()
    return ent and ent:HasTag("INLIMBO") or TheInput:GetHUDEntityUnderMouse()
end

-- 检查动作的合法性,如果动作有fn,则以target做fn的参数对目标对应动作进行检测
local function CheckAllowedActions(category, action, target)
    local allowed_action = allowed_actions[category][action]
    return allowed_action and (allowed_action == true or allowed_action(target))
end

-- 将屏幕坐标转化为世界坐标
local function GetWorldPosition(screen_x, screen_y)
    return Point(TheSim:ProjectScreenPos(screen_x, screen_y))
end


-- 部署间隔
-- 不在部署间隔表中的由系统函数去获取,获取不到直接给1
local function GetDeploySpacing(item)
    for key, spacing in pairs(deploy_spacing) do
        if item.prefab:find(key) or item:HasTag(key) then return spacing end
    end
    local spacing = item.replica.inventoryitem:DeploySpacingRadius()
    return spacing ~= 0 and spacing or 1
end

-- 丢弃间隔:在丢弃间隔表中则直接获取丢弃间隔,否则给1
local function GetDropSpacing(item)
    for key, spacing in pairs(drop_spacing) do
        if item.prefab:find(key) or item:HasTag(key) then return spacing end
    end
    return 1
end

-- 比较实体的原版部署间隔与给定的间隔
local function CompareDeploySpacing(item, spacing)
    return item and item.replica.inventoryitem and item.replica.inventoryitem.classified
       and item.replica.inventoryitem.classified.deployspacing:value() == spacing
end

-- 获取固定的视角角度与对应的布尔值
local function GetHeadingDir()
    local dir = headings[TheCamera.heading]
    if dir ~= nil then return TheCamera.heading, dir end
    for heading, dir in pairs(headings) do --diagonal priority
        local check_angle = heading % 2 ~= 0 and 23 or 22.5
        if math.abs(TheCamera.heading - heading) < check_angle then
            return heading, dir
        end
    end
end

-- 获取可用地皮焦点
local function GetAccessibleTilePosition(pos)
    local ent_blockers = TheSim:FindEntities(pos.x, 0, pos.z, 4, {"blocker"})
    for _, offset in pairs(offsets) do
        local offset_pos = offset + pos
        for _, ent in pairs(ent_blockers) do
            local ent_radius = ent:GetPhysicsRadius(0) + 0.6 --character size + 0.1
            if offset_pos:DistSq(ent:GetPosition()) < ent_radius * ent_radius then
                offset_pos = nil
                break
            end
        end
        if offset_pos then return offset_pos end
    end
    return nil
end


-- 蛇形种植
-- 210127 null: added support for changing between regular snaking or double snaking deployment
function ActionQueuer:SetDoubleSnake(bool)
    double_snake = bool
end

-- 耕地间隔
-- 201221 null: added support for changing Snapped farm Till grid
function ActionQueuer:SetFarmGrid(type)
    farm_grid = type
end

-- 攻击队列
-- 210307 null: enable or disable ATTACK with leftclick queuing
function ActionQueuer:SetAttackQueue(bool)
    if bool then
        self.AddAction("leftclick", "ATTACK", true) -- Add ATTACK to leftclick queue
    else
        self.AddAction("leftclick", "ATTACK") -- Remove ATTACK from leftclick queue
    end
end

-- 狗牙陷阱间距
function ActionQueuer:SetToothTrapSpacing(num)
    deploy_spacing.trap = num
end

-- 等待函数:不同的动作给不同的等待时间
function ActionQueuer:Wait(action, target)
    local current_time = GetTime()
    if action and CheckAllowedActions("noworkdelay", action, target) then
        -- 无workdelay
        repeat
            -- 无工作延迟，等待3帧
            Sleep(self.action_delay)
            -- 开始移动则停止
        until not (self.inst.sg and self.inst.sg:HasStateTag("moving")) and not self.inst:HasTag("moving")
    else
        Sleep(self.work_delay)
        repeat
            -- 3帧
            Sleep(self.action_delay)
            -- 移动打断，其他条件？？？
        until not (self.inst.sg and self.inst.sg:HasStateTag("moving")) and not self.inst:HasTag("moving")
              and self.inst:HasTag("idle") and not self.inst.components.playercontroller:IsDoingOrWorking()
    end
    DebugPrint("Time waited:", GetTime() - current_time)
end

-- 传入 目标,是否右键,位置 返回 合法的动作,是否右键
function ActionQueuer:GetAction(target, rightclick, pos)
    local pos = pos or target:GetPosition()     -- 如果没有传入位置,则用target的位置
    local playeractionpicker = self.inst.components.playeractionpicker
    if rightclick then
        for _, act in ipairs(playeractionpicker:GetRightClickActions(pos, target)) do
            if CheckAllowedActions("rightclick", act.action, target) then
                DebugPrint("Allowed rightclick action:", act)
                return act, true
            end
        end
    end
    for _, act in ipairs(playeractionpicker:GetLeftClickActions(pos, target)) do
        if not rightclick and CheckAllowedActions("leftclick", act.action, target)
          or CheckAllowedActions("allclick", act.action, target) then
            DebugPrint("Allowed leftclick action:", act)
            return act, false
        end
    end
    DebugPrint("No allowed action for:", target)
    return nil
end

-- 220410 null: alternative method to attempt Attack Queuing without excessive delays
function ActionQueuer:SendAttackLoop(act, pos, target)
    SendRPCToServer(RPC.LeftClick, act.action.code, pos.x, pos.z, target, false, 10, act.action.canforce, act.action.mod_name)
        -- Note that using this to attack causes subsequent client attack actions to always loop (even if not Attack Queuing)
    self:Wait(act.action, target) -- wait after attack to prevent freeze/crash
end

-- 排队论发送动作方法,统一为左右键的RPC
function ActionQueuer:SendAction(act, rightclick, target)
    DebugPrint("Sending action:", act)
    local playercontroller = self.inst.components.playercontroller
    -- 主机直接做动作
    if playercontroller.ismastersim then
        self.inst.components.combat:SetTarget(nil)
        playercontroller:DoAction(act)
        return
    end
    local pos = act:GetActionPoint() or self.inst:GetPosition()
    local controlmods = 10 --force stack and force attack
    -- 开延迟
    if playercontroller.locomotor then
        act.preview_cb = function()
            if rightclick then
                SendRPCToServer(RPC.RightClick, act.action.code, pos.x, pos.z, target, act.rotation, true, nil, nil, act.action.mod_name)
            else
                SendRPCToServer(RPC.LeftClick, act.action.code, pos.x, pos.z, target, true, controlmods, nil, act.action.mod_name)
            end
        end
        playercontroller:DoAction(act)
    else
    -- 关延迟
        if rightclick then
            SendRPCToServer(RPC.RightClick, act.action.code, pos.x, pos.z, target, act.rotation, true, nil, act.action.canforce, act.action.mod_name)
        else
            SendRPCToServer(RPC.LeftClick, act.action.code, pos.x, pos.z, target, true, controlmods, act.action.canforce, act.action.mod_name)
        end
    end
end


-- 发送动作然后等待
function ActionQueuer:SendActionAndWait(act, rightclick, target)
    self:SendAction(act, rightclick, target)
    self:Wait(act.action, target)
end

-- 设置选中实体的颜色和透明度
function ActionQueuer:SetSelectionColor(r, g, b, a)
    -- 原来 tint是 覆盖的色彩
    self.selection_widget:SetTint(r, g, b, a)
    self.color.x = r * 0.5
    self.color.y = g * 0.5
    self.color.z = b * 0.5
end


-- 框选器(是否右键)
function ActionQueuer:SelectionBox(rightclick)
    local previous_ents = {}                                                                        -- 先前的实体表
    local started_selection = false                                                                 -- 开始选择标志位
    local start_x, start_y = self.screen_x, self.screen_y                                           -- 开始选择的位置
    self.update_selection = function()
        if not started_selection then
            if math.abs(start_x - self.screen_x) + math.abs(start_y - self.screen_y) < 32 then
                return
            end
            started_selection = true
        end
        local xmin, xmax = start_x, self.screen_x
        if xmax < xmin then
            xmin, xmax = xmax, xmin
        end
        local ymin, ymax = start_y, self.screen_y
        if ymax < ymin then
            ymin, ymax = ymax, ymin
        end
        self.selection_widget:SetPosition((xmin + xmax) / 2, (ymin + ymax) / 2)                     -- 窗口在屏幕的位置
        self.selection_widget:SetSize(xmax - xmin + 2, ymax - ymin + 2)                             -- 窗口大小
        self.selection_widget:Show()
        self.TL, self.BL, self.TR, self.BR = GetWorldPosition(xmin, ymax), GetWorldPosition(xmin, ymin), GetWorldPosition(xmax, ymax), GetWorldPosition(xmax, ymin)
        --self.TL, self.BL, self.TR, self.BR = GetWorldPosition(xmin, ymin), GetWorldPosition(xmin, ymax), GetWorldPosition(xmax, ymin), GetWorldPosition(xmax, ymax)
        local center = GetWorldPosition((xmin + xmax) / 2, (ymin + ymax) / 2)                       -- 窗口实际在世界的位置
        local range = math.sqrt(math.max(center:DistSq(self.TL), center:DistSq(self.BL), center:DistSq(self.TR), center:DistSq(self.BR)))       -- 两点间的距离公式
        local IsBounded = GeoUtil.NewQuadrilateralTester(self.TL, self.TR, self.BR, self.BL)                                                    -- 是否在范围内
        local current_ents = {}
        for _, ent in pairs(TheSim:FindEntities(center.x, 0, center.z, range, nil, unselectable_tags)) do
            if IsValidEntity(ent) then
                local pos = ent:GetPosition()
                if IsBounded(pos) then                                                              -- 实体位置在框选范围内
                    if not self:IsSelectedEntity(ent) and not previous_ents[ent] then               -- 不是已选实体 且 不在之前的实体表中
                        local act, rightclick_ = self:GetAction(ent, rightclick, pos)
                        if act and act.action.id ~= "ATTACK" then -- 210315 null: don't select mobs / enemies with selection box
                            self:SelectEntity(ent, rightclick_)                                     -- 添加到选中记录，并高亮什么的
                        end
                    end
                    current_ents[ent] = true                                                        -- 记录当前实体进入当前实体表
                end
            end
        end
        -- ？？ 暂时无法理解之后的逻辑
        for ent in pairs(previous_ents) do                                                          -- 遍历之前的实体表
            if not current_ents[ent] then                                                           -- 如果之前的表中没有现在的量，则取消选中
                self:DeselectEntity(ent)
            end
        end
        previous_ents = current_ents
    end
    -- 框选线程
    self.selection_thread = StartThread(function()                                                  -- 该线程按帧刷新
        while self.inst:IsValid() do
            if self.queued_movement then
                self.update_selection()
                self.queued_movement = false
            end
            Sleep(FRAMES)
        end
        self:ClearSelectionThread()             -- 清除选择器线程                                  -- StartThread(执行函数，线程ID)
    end, selection_thread_id)
end

-- 210705 null: added support for other mods to add their own CherryPick conditions
-- Requested by Tony for compatibility with Lazy Controls mod (https://steamcommunity.com/sharedfiles/filedetails/?id=2111412487)
function ActionQueuer:AddModCherryPickFn(fn) -- Allows other mods to add their own CherryPick functions to check custom conditions
    table.insert(mod_cherrypick_fns, fn)
end

function ActionQueuer:CanModCherryPick(ent) -- Check other mods' CherryPick conditions, if mod can CherryPick the ent, return true
    if next(mod_cherrypick_fns) == nil then return false end
    for _, v in ipairs(mod_cherrypick_fns) do
        if type(v) == "function" and v(ent) then
            return true
        end
    end
    return false
end

function ActionQueuer:CherryPick(rightclick)
    local current_time = GetTime()
    if current_time - self.last_click.time < self.double_click_speed and self.last_click.prefab then                -- 确认双击
        local x, y, z = self.last_click.pos:Get()

        -- 210213 null: support for differentiating Stone Fruit Bushes in Pick (idle3) vs Crumble (idle4) state (blizstorm)
        if self.last_click.prefab == "rock_avocado_bush" and self.last_click.action == ACTIONS.PICK then
			local AnimstatePick = self.last_click.AnimState:IsCurrentAnimation("idle3") and "idle3" or "idle4"
			for _, ent in pairs(TheSim:FindEntities(x, 0, z, self.double_click_range, nil, unselectable_tags)) do
                -- 对不同状态的石果进行区分
				if ent.prefab == "rock_avocado_bush" and ent.AnimState:IsCurrentAnimation(AnimstatePick) then
					self:SelectEntity(ent, false)
				end
            end
        
        -- 210315 null: support for isolating chopping of lvl 3 trees (blizstorm / Tranoze)
        elseif (self.last_click.prefab == "evergreen" or -- 210315 null: lvl 3 evergreen (blizstorm / Tranoze)
                self.last_click.prefab == "deciduoustree" or -- 210315 null: lvl 3 deciduous (blizstorm)
                self.last_click.prefab == "moon_tree" or -- 210322 null: lvl 3 lune trees
                self.last_click.prefab == "twiggytree" or -- 210322 null: lvl 3 twiggy trees
                self.last_click.prefab == "palmconetree") and   -- 棕榈树只砍大树
                self.last_click.action == ACTIONS.CHOP and 
               (self.last_click.AnimState:IsCurrentAnimation("sway1_loop_tall") or -- Only check for lvl3/tall trees
                self.last_click.AnimState:IsCurrentAnimation("sway2_loop_tall")) then 
                -- Only check for lvl3/tall trees. Otherwise default to original CherryPick code.
                -- Double Click on Tall trees only CHOPs the Tall trees. 
                -- Double Click on any other size tree CHOPs trees of all sizes (including Tall trees).
            for _, ent in pairs(TheSim:FindEntities(x, 0, z, self.double_click_range, nil, unselectable_tags)) do
                if ent.prefab == self.last_click.prefab and 
                -- 对不同状态的树区分
                  (ent.AnimState:IsCurrentAnimation("sway1_loop_tall") or 
                   ent.AnimState:IsCurrentAnimation("sway2_loop_tall")) then
                    self:SelectEntity(ent, false)
                end
            end
        
        -- 210322 null: support for isolating mining of lvl 3 marble trees
        elseif self.last_click.prefab == "marbleshrub" and 
               self.last_click.action == ACTIONS.MINE and 
               self.last_click.AnimState:IsCurrentAnimation("idle_tall") then -- Only check for lvl3/tall marble trees
            for _, ent in pairs(TheSim:FindEntities(x, 0, z, self.double_click_range, nil, unselectable_tags)) do
                -- 对不同状态的大理石树区分
                if ent.prefab == self.last_click.prefab and ent.AnimState:IsCurrentAnimation("idle_tall") then
                    self:SelectEntity(ent, false)
                end
            end

        else
            -- 210705 null: added support for other mods to add their own CherryPick conditions
            for _, ent in pairs(TheSim:FindEntities(x, 0, z, self.double_click_range, nil, unselectable_tags)) do
                if (ent.prefab == self.last_click.prefab -- Original CherryPick condition
                -- 对不同模组实体区分
                    or self:CanModCherryPick(ent)) -- 210705 null: Other mods' CherryPick conditions (if true, select the ent)
                    and IsValidEntity(ent) and not self:IsSelectedEntity(ent) then
                    local act, rightclick_ = self:GetAction(ent, rightclick)
                    if act and act.action == self.last_click.action then        -- 两次动作相同
                        self:SelectEntity(ent, rightclick_)
                    end
                end
            end

        end

        self.last_click.prefab = nil
        return
    end
    for _, ent in ipairs(TheInput:GetAllEntitiesUnderMouse()) do                    -- 单击流程,注意,任何时候都是先走单击再走双击的,虽然双击写在上面
        if IsValidEntity(ent) then
            local act, rightclick_ = self:GetAction(ent, rightclick)            -- 但是Cherrypick是多次执行,第一次执行会给给这次点击赋值一个表,存入相关信息,第二次时间差满足才进入双击流程
            if act then                                                           -- 鼠标下的实体如果有合法的动作
                self:ToggleEntitySelection(ent, rightclick_)                    -- 切换实体选择状态

                -- -- Original CherryPick code
                -- self.last_click = {prefab = ent.prefab, pos = ent:GetPosition(), action = act.action, time = current_time}

                -- 210213 null: save AnimState to support Stone Fruit Bush Pick (idle3) vs Crumble (idle4) state (blizstorm)
                self.last_click = {prefab = ent.prefab, pos = ent:GetPosition(), action = act.action, 
                                   time = current_time, AnimState = ent.AnimState}

                break
            end
        end
    end
end

function ActionQueuer:OnDown(rightclick)        -- 按下
    self:ClearSelectionThread()                 -- 重置选择线程
    if self.inst:IsValid() and not IsHUDEntity() then
        self.clicked = true
        self:SelectionBox(rightclick)
        self:CherryPick(rightclick)
    end
end

function ActionQueuer:OnUp(rightclick)          -- 抬起

    -- 210702 null: fix for Klei's mouse queue bug, clear Klei's own action queue
    ThePlayer.components.playercontroller:ClearActionHold()
    
    self:ClearSelectionThread()                 -- 按下和抬起都会清除线程？
    if self.clicked then                        -- 确认是按下后才能
        self.clicked = false
        if self.action_thread then return end
        if self:IsWalkButtonDown() then         -- 按下移动键打断
            self:ClearSelectedEntities()
        elseif next(self.selected_ents) then    -- 有选择的实体
            self:ApplyToSelection()             -- 选择器执行
        elseif rightclick then                                      -- 未选择实体实体时进入部署流程
            local active_item = self:GetActiveItem()
            if active_item then
                if easy_stack[active_item.prefab] then              -- 种植小木牌的
                    local ent = TheInput:GetWorldEntityUnderMouse()
                    if ent and ent:HasTag(easy_stack[active_item.prefab]) then
                        local act = BufferedAction(self.inst, nil, ACTIONS.DEPLOY, active_item, ent:GetPosition())
                        self:SendAction(act, true)                  -- 为了粘贴小木牌
                        return
                    end
                end

                -- 201224 null: added basic support for Fertilizing of farming tiles
                if active_item:HasTag("fertilizer") then            -- 施肥
                    -- local pos = GetWorldPositionUnderMouse() -- Tiles aren't entities, so try getting pos under mouse cursor
                    local pos = TheInput:GetWorldPosition() -- 210127 null: 地皮不是实体，所以直接获取鼠标下的位置
                    if pos and TheWorld.Map:IsFarmableSoilAtPoint(pos.x, 0, pos.z) then -- 这样做不是最好的方式，哪有直接从世界地图判断地皮的
                        self:FertilizeTile(pos, active_item) -- Fertilize a single tile multiple times
                    else
                        self:DeployToSelection(self.FertilizeAtPoint, 4, active_item) -- Fertilize multiple tiles
                    end
                    return
                end

                -- 210103 null: added basic support for Wormwood planting
                if ThePlayer:HasTag("plantkin") and active_item:HasTag("deployedfarmplant") then
                    if not self.TL then return end
                    local cx, cz = (self.TL.x + self.BR.x) / 2, (self.TR.z + self.BL.z) / 2 -- Get SelectionBox() center coords
                    if (cx and cz) and TheWorld.Map:IsFarmableSoilAtPoint(cx, 0, cz) then -- if center = soil tile
                        self:DeployToSelection(self.WormwoodPlantAtPoint, farm_spacing, active_item) -- Snap to farm grid
                    else
                        self:DeployToSelection(self.DeployActiveItem, farm_spacing, active_item) -- Plant normally
                    end
                    return
                end

                if active_item.replica.inventoryitem:IsDeployable(self.inst) then       -- 如果鼠标上是允许放置的则放置
                    self:DeployToSelection(self.DeployActiveItem, GetDeploySpacing(active_item), active_item)
                else                                                                     -- 否则丢弃
                    self:DeployToSelection(self.DropActiveItem, GetDropSpacing(active_item), active_item)
                end
                return
            end
            local equip_item = self:GetEquippedItemInHand()

            -- 手里是草叉则铲地皮
            if equip_item and equip_item.prefab == "pitchfork" then
                self:DeployToSelection(self.TerraformAtPoint, 4, equip_item)
            
            -- 210107 null: added support for Watering of farming tiles (single tile until full or multiple tiles once each)
            -- 支持浇水
            elseif equip_item and (equip_item.prefab == "wateringcan" or equip_item.prefab == "premiumwateringcan") then

                -- 210202 null: first check if selection box is being used
                if not self.TL or (math.abs(self.TL.x - self.BR.x) + math.abs(self.TR.z - self.BL.z) < 1) then -- if single click
                    local pos = TheInput:GetWorldPosition() -- 210127 null: Tiles aren't entities, so get pos under mouse cursor
                    if pos and TheWorld.Map:IsFarmableSoilAtPoint(pos.x, 0, pos.z) then
                        self:WaterTile(pos, equip_item) -- 210107 null: Water a single tile until full moisture
                    end
                else -- if selection box
                    self:DeployToSelection(self.WaterAtPoint, 4, equip_item) -- 201217 null: Water multiple tiles
                end
            
            -- 201217 null: added support for Tilling of farming tiles
            -- 支持刨坑
            elseif equip_item and (equip_item.prefab == "farm_hoe" or equip_item.prefab == "golden_farm_hoe") then
                self:DeployToSelection(self.TillAtPoint, farm_spacing, equip_item)
            
            end
        elseif self.inst.components.playercontroller.placer then
            -- 批量部署
            local playercontroller = self.inst.components.playercontroller
            local recipe = playercontroller.placer_recipe
            local rotation = playercontroller.placer:GetRotation()
            local skin = playercontroller.placer_recipe_skin
            local builder = self.inst.replica.builder
            local spacing = recipe.min_spacing > 2 and 4 or 2
            self:DeployToSelection(function(self, pos, item)
                if not builder:IsBuildBuffered(recipe.name) then
                    if not builder:CanBuild(recipe.name) then return false end
                    builder:BufferBuild(recipe.name)
                end
                if builder:CanBuildAtPoint(pos, recipe, rotation) then
                    builder:MakeRecipeAtPoint(recipe, pos, rotation, skin)
                    self:Wait()
                end
                return true
            end, spacing)
        end
    end
end

function ActionQueuer:IsWalkButtonDown()
    return self.inst.components.playercontroller:IsAnyOfControlsPressed(CONTROL_MOVE_UP, CONTROL_MOVE_DOWN, CONTROL_MOVE_LEFT, CONTROL_MOVE_RIGHT)
end

-- 获取鼠标上实体
function ActionQueuer:GetActiveItem()
    return self.inst.replica.inventory:GetActiveItem()
end

-- 获取手里的装备
function ActionQueuer:GetEquippedItemInHand()
    return self.inst.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
end

-- 从玩家身上拿取物品到鼠标
-- 并不适配5格装备栏, 但是LazyControls修复了它
function ActionQueuer:GetNewActiveItem(prefab)
    local inventory = self.inst.replica.inventory
    local body_item = inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    local backpack = body_item and body_item.replica.container
    for _, inv in pairs(backpack and {inventory, backpack} or {inventory}) do
        for slot, item in pairs(inv:GetItems()) do
            if item and item.prefab == prefab then
                inv:TakeActiveItemFromAllOfSlot(slot)
                return item
            end
        end
    end
end

-- 从身上装备物品
function ActionQueuer:GetNewEquippedItemInHand(prefab)
    local inventory = self.inst.replica.inventory
    local body_item = inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    local backpack = body_item and body_item.replica.container
    for _, inv in pairs(backpack and {inventory, backpack} or {inventory}) do
        for slot, item in pairs(inv:GetItems()) do
            if item and item.prefab == prefab then
                inventory:UseItemFromInvTile(item)
                return item
            end
        end
    end
end

-- 部署
function ActionQueuer:DeployActiveItem(pos, item)
    local active_item = self:GetActiveItem() or self:GetNewActiveItem(item.prefab)
    if not active_item then return false end
    local inventoryitem = active_item.replica.inventoryitem
    if inventoryitem and inventoryitem:CanDeploy(pos, nil, self.inst) then
        local act = BufferedAction(self.inst, nil, ACTIONS.DEPLOY, active_item, pos)
        local playercontroller = self.inst.components.playercontroller
        if playercontroller.deployplacer then
            act.rotation = playercontroller.deployplacer.Transform:GetRotation()
        end
        self:SendActionAndWait(act, true)
        if not playercontroller.ismastersim and not CompareDeploySpacing(active_item, DEPLOYSPACING.NONE) then
            while inventoryitem and inventoryitem:CanDeploy(pos, nil, self.inst) do
                Sleep(self.action_delay)
                if self.inst:HasTag("idle") then
                    self:SendActionAndWait(act, true)
                end
            end
        end
    end
    return true
end

-- 丢弃
function ActionQueuer:DropActiveItem(pos, item)
    local active_item = self:GetActiveItem() or self:GetNewActiveItem(item.prefab)
    if not active_item then return false end
    if #TheSim:FindEntities(pos.x, 0, pos.z, 0.1, nil, unselectable_tags) == 0 then
        local act = BufferedAction(self.inst, nil, ACTIONS.DROP, active_item, pos)
        act.options.wholestack = false
        self:SendActionAndWait(act, false)
    end
    return true
end

-- 201217 null: added support for Watering of farming tiles
-- 浇水
function ActionQueuer:WaterAtPoint(pos, item)
    local x, y, z = pos:Get()
    if not self:GetEquippedItemInHand() then return false end
    if TheWorld.Map:IsFarmableSoilAtPoint(x, y, z) then
        local act = BufferedAction(self.inst, nil, ACTIONS.POUR_WATER_GROUNDTILE, item, pos)
        self:SendActionAndWait(act, true)
    end
    return true
end

-- 201217 null: added support for Tilling of farming tiles
-- 开垦
function ActionQueuer:TillAtPoint(pos, item)
    local x, y, z = pos:Get()
    if not self:GetEquippedItemInHand() then return false end
    if TheWorld.Map:CanTillSoilAtPoint(x, y, z) then -- 201221 null: Fix for when objects block Tilling
        local act = BufferedAction(self.inst, nil, ACTIONS.TILL, item, pos)
        self:SendActionAndWait(act, false) -- false = RPC.LeftClick, avoids Geometric Placement mod's RPC.RightClick snap overrides
    end
    return true
end

-- 支持农场地皮施肥
function ActionQueuer:FertilizeAtPoint(pos, item, fast)
    local x, y, z = pos:Get()
    if not self:GetActiveItem() then return false end
    if TheWorld.Map:IsFarmableSoilAtPoint(x, y, z) then
        -- 这是一个很好的动作示例
        local act = BufferedAction(self.inst, nil, ACTIONS.DEPLOY_TILEARRIVE, item, pos)
        self:SendActionAndWait(act, true)

        -- extra delay needed when Fertilizing through SelectionBox()
        if not fast then while not self.inst:HasTag("idle") do Sleep(self.action_delay) end end
    end
    return true
end

-- 210103 null: added support for Wormwood planting inside farm soil grids
-- 种植
function ActionQueuer:WormwoodPlantAtPoint(pos, item)
    local x, y, z = pos:Get()
    if not self:GetActiveItem() then return false end
    if TheWorld.Map:CanTillSoilAtPoint(x, y, z) then -- Do not plant outside the farm soil tile in this scenario
        local act = BufferedAction(self.inst, nil, ACTIONS.DEPLOY, item, pos)
        self:SendActionAndWait(act, false) -- 210127 null: false avoids Geometric Placement mod's RPC.RightClick snap overrides
    end
    return true
end

-- 铲地皮
function ActionQueuer:TerraformAtPoint(pos, item)
    local x, y, z = pos:Get()
    if not self:GetEquippedItemInHand() then return false end
    if TheWorld.Map:CanTerraformAtPoint(x, y, z) then
        local act = BufferedAction(self.inst, nil, ACTIONS.TERRAFORM, item, pos)
        self:SendActionAndWait(act, true)
        while TheWorld.Map:CanTerraformAtPoint(x, y, z) do
            Sleep(self.action_delay)
            if self.inst:HasTag("idle") then
                self:SendActionAndWait(act, true)
            end
        end
        if self.auto_collect then
            self:AutoCollect(pos, true)
        end
    end
    return true
end

-- 获取最近的实体
function ActionQueuer:GetClosestTarget()        
    local mindistsq, target
    local player_pos = self.inst:GetPosition()

    for ent in pairs(self.selected_ents) do                             -- 遍历已选实体
        if IsValidEntity(ent) then
            local curdistsq = player_pos:DistSq(ent:GetPosition())      -- 点距
            if not mindistsq or curdistsq < mindistsq then              -- 哪个点距小记录哪个
                mindistsq = curdistsq
                target = ent
            end
        else
            self:DeselectEntity(ent)                                    -- 该实体废了，不要了
        end
    end
    return target
end


-- 究竟能否在3帧内完成装备
function ActionQueuer:WaitToolReEquip()
    if not self:GetEquippedItemInHand() and not self.inst:HasTag("wereplayer") then
        self:Wait()
        return true
    end
end

-- 继续选中
function ActionQueuer:CheckEntityMorph(prefab, pos, rightclick)
    if not entity_morph[prefab] then return end
    for _, ent in pairs(TheSim:FindEntities(pos.x, 0, pos.z, 1, nil, unselectable_tags)) do
        if ent.prefab == entity_morph[prefab] then
            self:SelectEntity(ent, rightclick)
        end
    end
end

-- 自动收集模式
function ActionQueuer:AutoCollect(pos, collect_now)
    for _, ent in pairs(TheSim:FindEntities(pos.x, 0, pos.z, 4, nil, unselectable_tags)) do     -- 遍历位置内一个地皮的实体
        if IsValidEntity(ent) and not self:IsSelectedEntity(ent) then
            local act = self:GetAction(ent, false)
            if act and CheckAllowedActions("collect", act.action, ent) then
                self:SelectEntity(ent, false)
                if collect_now then
                    self:SendActionAndWait(act, false, ent)
                    self:DeselectEntity(ent)
                end
            end
        end
    end
end

-- 排队论精髓：动作线程
function ActionQueuer:ApplyToSelection()
    self.action_thread = StartThread(function()
        self.inst:ClearBufferedAction()                     -- 清除缓存动作？不知道有何实际作用
        local active_item = self:GetActiveItem()            -- 获取鼠标上实体
        while self.inst:IsValid() do
            local target = self:GetClosestTarget()          -- 获取最近的目标实体
            if not target then break end                    -- 没有最近的实体则中断任务
            local rightclick = self.selected_ents[target]   -- 获取目标对应的鼠标操作，左键还是右键
            local pos = target:GetPosition()
            local act = self:GetAction(target, rightclick, pos)     -- 获取目标动作
            if act and act:IsValid() then
                local tool_action = allowed_actions.tools[act.action]                           -- 这个动作属于tools的动作
                local auto_collect = CheckAllowedActions("autocollect", act.action, target)     -- 这个动作属于autocollect的动作
                self:SendActionAndWait(act, rightclick, target)                                 -- 当前动作无需检查，执行一次
                if not CheckAllowedActions("single", act.action, target) then                   -- single的动作只执行一次，所以直接跳过
                    local noworkdelay = CheckAllowedActions("noworkdelay", act.action, target)  -- 这个动作属于noworkdelay
                    local current_action = act.action
                    -- 220410 null: Attack Queue vars
                    local started = false -- used for checking if first attack vs specific target
                    local equip_start = self:GetEquippedItemInHand() -- get starting weapon (IE, blowdarts)
                    while IsValidEntity(target) do
                        local act = self:GetAction(target, rightclick, pos)
                        if not act then
                            if active_item then
                                if noworkdelay then Sleep(self.action_delay) end --queue can exit without this delay
                                -- 如果现在鼠标上没东西而且可以从身上得到
                                if not self:GetActiveItem() and self:GetNewActiveItem(active_item.prefab) then
                                    act = self:GetAction(target, rightclick, pos)
                                end
                            elseif tool_action and self:WaitToolReEquip() then                  -- 工具的动作，等待工具装备
                                act = self:GetAction(target, rightclick, pos)                   -- 获取装备后的动作
                            end
                            if not act then break end                                            -- 如果还是没有动作就跳出循环
                        end
                        if act.action ~= current_action then break end              -- 如果获取到的动作和刚开始的不一致也推出循环
                        if act.action.id == "ATTACK" then -- if attack queuing
                            local equip_current = self:GetEquippedItemInHand() -- get current weapon (can be empty / nil)
                            if not started -- if not started yet (this check reduces delay on multi-mob attack queuing)
                               or (not self.inst:HasTag("attack") -- if not attacking (otherwise re-equips won't continue attacking)
                               and ((equip_start == equip_current)
                                    -- current weapon = starting weapon (can be empty handed, nil/nil)
                               or (equip_start and equip_current -- make sure they're not nil
                               and equip_start.prefab == equip_current.prefab))) then
                                    -- current prefab = starting prefab (can be newly equipped weapon of same prefab)
                                self:SendAttackLoop(act, pos, target) -- start attacking
                                started = true
                            elseif equip_start and not equip_current then
                                    -- if start equip was not empty, and current equip is empty
                                if self:GetNewEquippedItemInHand(equip_start.prefab) then -- re-equip new weapon if possible
                                    self:Wait() -- wait for the re-equip to prevent freeze/crash
                                else break end -- if can't re-equip new weapon, cancel current target's queue
                                    -- this prevents running into boss with unarmed attacks after blow darts are fully consumed
                            else
                                Sleep(self.action_delay)
                            end
                        else
                            -- 220410 null: original code
                            self:SendActionAndWait(act, rightclick, target)
                        end                        
                        -- self:SendActionAndWait(act, rightclick, target)                         -- 发送act并等待
                    end
                end
                self:DeselectEntity(target)             -- 针对目标的工作完成后,取消选中实体
                self:CheckEntityMorph(target.prefab, pos, rightclick)       -- 对于预制名会变的实体，采用继续选中操作的办法
                if active_item and not self:GetActiveItem() then            -- 如果鼠标上本来有东西 但现在 鼠标上没东西
                    self:GetNewActiveItem(active_item.prefab)               -- 拿东西
                elseif tool_action then                                     -- 如果是工具的动作
                    self:WaitToolReEquip()                                  -- 等待工具装备
                end
                if self.auto_collect and auto_collect then                  -- 如果开了自动采集
                    Sleep(FRAMES)
                    pos = moving_target[target.prefab] and self.inst:GetPosition() or pos
                    self:AutoCollect(pos, false)
                end
            else
                DebugPrint("No act or invalid")
                self:DeselectEntity(target)
            end
        end
        self:ClearActionThread()
    end, action_thread_id)
end


-- 部署器:部署函数,间距,物体
-- 这代码是我能看的？
function ActionQueuer:DeployToSelection(deploy_fn, spacing, item)
    if not self.TL then return end

    -- 210116 null: cases for snapping positions to farm grid (Tilling, Wormwood planting on soil tiles, etc)
    local snap_farm = false
    if deploy_fn == self.TillAtPoint or deploy_fn == self.WormwoodPlantAtPoint then snap_farm = true end
    if snap_farm then
        if farm_grid == "4x4" then spacing = 1.26 -- 210116 null: different spacing for 4x4 grid
        elseif farm_grid == "2x2" then spacing = 2 -- 210609 null: different spacing for 2x2 grid
        end
    end 

    local heading, dir = GetHeadingDir()
    local diagonal = heading % 2 ~= 0
    DebugPrint("Heading:", heading, "Diagonal:", diagonal, "Spacing:", spacing)
    DebugPrint("TL:", self.TL, "TR:", self.TR, "BL:", self.BL, "BR:", self.BR)
    local X, Z = "x", "z"
    if dir then X, Z = Z, X end
    local spacing_x = self.TL[X] > self.TR[X] and -spacing or spacing
    local spacing_z = self.TL[Z] > self.BL[Z] and -spacing or spacing
    local adjusted_spacing_x = diagonal and spacing * 1.4 or spacing
    local adjusted_spacing_z = diagonal and spacing * 0.7 or spacing
    local width = math.floor(self.TL:Dist(self.TR) / adjusted_spacing_x)
    local height = self.endless_deploy and 100 or math.floor(self.TL:Dist(self.BL) / (width < 1 and adjusted_spacing_x or adjusted_spacing_z))
    DebugPrint("Width:", width + 1, "Height:", height + 1) --since counting from 0
    local start_x, _, start_z = self.TL:Get()
    local terraforming = false

    if deploy_fn == self.WaterAtPoint or -- 201217 null: added support for Watering of farming tiles
       deploy_fn == self.FertilizeAtPoint or -- 201223 null: added support for Fertilizing of farming tiles
       deploy_fn == self.TerraformAtPoint or 
       item and item:HasTag("groundtile") then
        start_x, _, start_z = TheWorld.Map:GetTileCenterPoint(start_x, 0, start_z)
        terraforming = true

    elseif deploy_fn == self.DropActiveItem or item and (item:HasTag("wallbuilder") or item:HasTag("fencebuilder")) then
        start_x, start_z = math.floor(start_x) + 0.5, math.floor(start_z) + 0.5

    -- 210116 null: adjust farm grid start position + offsets (thanks to blizstorm for help)
    elseif snap_farm then

        -- 210709 null: fix for 3x3 alignment on medium/huge servers (different tile offsets)
        local tilecenter = _G.Point(_G.TheWorld.Map:GetTileCenterPoint(start_x, 0, start_z)) -- center of tile
        local tilepos = _G.Point(tilecenter.x - 2, 0, tilecenter.z - 2) -- corner of tile
        if tilecenter.x % 4 == 0 then -- if center of tile is divisible by 4, then it's a medium/huge server
            farm3x3_offset = farm_spacing -- adjust offset for medium/huge servers for 3x3 grid
        end

        if farm_grid == "4x4" then -- 4x4 grid
            -- 4x4 grid: spacing = 1.26, offset/margins = 0.11
            start_x, start_z = tilepos.x + math.floor((start_x - tilepos.x)/1.26 + 0.5) * 1.26 + 0.11 * offsets_4x4[heading].x, 
                               tilepos.z + math.floor((start_z - tilepos.z)/1.26 + 0.5) * 1.26 + 0.11 * offsets_4x4[heading].z 

        elseif farm_grid == "2x2" then -- 210609 null: 2x2 grid: spacing = 2 (4/2), offset = 1 (4/2/2)
            start_x, start_z = math.floor(start_x / 2) * 2 + 1, 
                               math.floor(start_z / 2) * 2 + 1

        else -- 3x3 grid: spacing = 1.333 (4/3), offset = 0.665 (4/3/2)
            -- start_x, start_z = math.floor(start_x * 0.75 + 0.5) * 1.333 + 0.665, 
            --                    math.floor(start_z * 0.75 + 0.5) * 1.333 + 0.665

            -- 210201 null: /0.75 (3/4) instead of *1.333 (4/3) to better support edge of large -1600 to 1600 maps (blizstorm)
            -- start_x, start_z = math.floor(start_x * 0.75 + 0.5) / 0.75 + 0.665, 
            --                    math.floor(start_z * 0.75 + 0.5) / 0.75 + 0.665
            start_x, start_z = math.floor(start_x / farm_spacing) * farm_spacing + farm3x3_offset, 
                               math.floor(start_z / farm_spacing) * farm_spacing + farm3x3_offset
                               -- 210202 null: remove +0.5 floored rounding for more consistent wormwood placements (blizstorm)
                               -- 210202 null: use more precise 3x3 grid offset for better alignment at edge of maps
        end

    elseif self.deploy_on_grid then -- 210201 null: deploy_on_grid = last to avoid conflict with farm grids (blizstorm)
        start_x, start_z = math.floor(start_x * 2 + 0.5) * 0.5, math.floor(start_z * 2 + 0.5) * 0.5

    end

    local cur_pos = Point()
    local count = {x = 0, y = 0, z = 0}
    local row_swap = 1
    
    -- 210127 null: added support for snaking within snaking for faster deployment (thanks to blizstorm)
    local step = 1
    local countz2 = 0
    local countStep = {{0,1},{1,0},{0,-1},{1,0}}
    if height < 1 then countStep = {{1,0},{1,0},{1,0},{1,0}} end -- 210130 null: bliz fix (210127)

    self.action_thread = StartThread(function()
        self.inst:ClearBufferedAction()
        while self.inst:IsValid() do
            cur_pos.x = start_x + spacing_x * count.x
            cur_pos.z = start_z + spacing_z * count.z
            if diagonal then
                if width < 1 then
                    if count[Z] > height then break end
                    count[X] = count[X] - 1
                    count[Z] = count[Z] + 1
                else
                    local row = math.floor(count.y / 2)
                    if count[X] + row > width or count[X] + row < 0 then
                        count.y = count.y + 1
                        if count.y > height then break end
                        row_swap = -row_swap
                        count[X] = count[X] + row_swap - 1
                        count[Z] = count[Z] + row_swap
                        cur_pos.x = start_x + spacing_x * count.x
                        cur_pos.z = start_z + spacing_z * count.z
                    end
                    count.x = count.x + row_swap
                    count.z = count.z + row_swap
                end
            else
                if double_snake then -- 210127 null: snake within snake deployment (thanks to blizstorm)
                    if count[X] > width or count[X] < 0 then
                        countz2 = countz2 + 2 -- assume first that next major row can be progressed since this is the case most of the time (blizstorm)

                        -- if countz2 > height then -- old bliz code (210115)
                        if countz2 + 1 > height then -- 210130 null: bliz fix (210127)

                            -- if countz2 - 1 > height then -- old bliz code (210115)
                            -- if countz2 - 1 <= height then -- old bliz code (210122)
                            if countz2 <= height then -- 210130 null: bliz fix (210127)

                                -- countz2 = countz2 - 1 -- old bliz code (210115)
                                countStep={{1,0},{1,0},{1,0},{1,0}}

                            else break end
                        end

                        step = 1
                        row_swap = -row_swap
                        count[X] = count[X] + row_swap
                        count[Z] = countz2
                        cur_pos.x = start_x + spacing_x * count.x
                        cur_pos.z = start_z + spacing_z * count.z
                    end
                    count[X] = count[X] + countStep[step][1]*row_swap
                    count[Z] = count[Z] + countStep[step][2]
                    step = step % 4 + 1

                else -- Regular snaking deployment
                    if count[X] > width or count[X] < 0 then
                        count[Z] = count[Z] + 1
                        if count[Z] > height then break end
                        row_swap = -row_swap
                        count[X] = count[X] + row_swap
                        cur_pos.x = start_x + spacing_x * count.x
                        cur_pos.z = start_z + spacing_z * count.z
                    end
                    count[X] = count[X] + row_swap
                end
            end

            local accessible_pos = cur_pos
            if terraforming then
                accessible_pos = GetAccessibleTilePosition(cur_pos)

            -- 210116 null: not needed anymore
            -- elseif snap_farm then -- 210116 null: (Tilling, Wormwood planting on soil tile)
            --     accessible_pos = GetSnapTillPosition(cur_pos) -- Snap pos to farm grid

            elseif deploy_fn == self.TillAtPoint then -- 210117 null: check if pos already Tilled
                for _,ent in pairs(TheSim:FindEntities(cur_pos.x, 0, cur_pos.z, 0.005, {"soil"})) do
                    if not ent:HasTag("NOCLICK") then accessible_pos = false break end -- Skip Tilling this position
                end
            end

            DebugPrint("Current Position:", accessible_pos or "skipped")
            if accessible_pos then
                if not deploy_fn(self, accessible_pos, item) then break end
            end
        end
        self:ClearActionThread()
        self.inst:DoTaskInTime(0, function() if next(self.selected_ents) then self:ApplyToSelection() end end)
    end, action_thread_id)
end

-- 支持农场施肥
function ActionQueuer:FertilizeTile(pos, item)
    -- 确保位置存在而且是农场地皮
    if not pos or not item or not TheWorld.Map:IsFarmableSoilAtPoint(pos.x, 0, pos.z) then return end
    -- 施肥还开个线程
    self.action_thread = StartThread(function()
        self.inst:ClearBufferedAction()                                 -- 清除缓存动作，每次执行动作线程都要这个？
        while self.inst:IsValid() and self:GetActiveItem() do           -- 玩家存在且手上有东西
            if not self:FertilizeAtPoint(pos, item, true) then break end
        end
        self:ClearActionThread()
    end, action_thread_id)
end

-- 210107 null: added support for Watering of farming tile until moisture is full
-- 浇水
function ActionQueuer:WaterTile(pos, item)
    if not pos or not item or not self:GetEquippedItemInHand() then return end

    local moisture


    -- TheWorld.Map:GetEntitiesOnTileAtPoint(pos) 获取地皮上的实体
    for _,ent in pairs(_G.TheWorld.Map:GetEntitiesOnTileAtPoint(pos.x, pos.y, pos.z)) do
        if ent.prefab == "nutrients_overlay" then -- Look for tile's nutrients_overlay entity, that contains moisture data
            moisture = ent
            break
        end
    end
    if not moisture or type(moisture) ~= "table" or not moisture.AnimState then return end
    
    self.action_thread = StartThread(function()
        self.inst:ClearBufferedAction()

        -- while self.inst:IsValid() and moisture.AnimState:GetCurrentAnimationTime() < 0.99 do -- Water tile until full

        -- 210202 null: water tile until 90% full instead of 99% (blizstorm)
        -- Moisture constantly drains, so it doesn't stay at 100% for long, hence 99% limit was previously used.
        -- However, there are some cases where you end up watering 5 times. Each = 25%, so 5th time = only watering 1%
        -- So blizstorm suggested using a 90% limit instead.
        while self.inst:IsValid() and moisture.AnimState:GetCurrentAnimationTime() < 0.9 do -- Water tile until 90% full
            if not self:WaterAtPoint(pos, item) then break end
        end
        self:ClearActionThread()
    end, action_thread_id)
end

function ActionQueuer:RepeatRecipe(builder, recipe, skin)
    self.action_thread = StartThread(function()
        self.inst:ClearBufferedAction()
        while self.inst:IsValid() and builder:CanBuild(recipe.name) do
            builder:MakeRecipeFromMenu(recipe, skin)
            Sleep(self.action_delay)
        end
        self:ClearActionThread()
    end, action_thread_id)
end

function ActionQueuer:StartAutoFisher(target)
    self:ToggleEntitySelection(target, false)
    if self.action_thread then return end
    if self.inst.locomotor then
        self.inst.components.talker:Say("Auto fisher will not work with lag compensation enabled")
        self:DeselectEntity(target)
        return
    end
    self.action_thread = StartThread(function()
        self.inst:ClearBufferedAction()
        self.auto_fishing = true
        while self.auto_fishing and self.inst:IsValid() and next(self.selected_ents) do
            for pond in pairs(self.selected_ents) do
                local fishingrod = self:GetEquippedItemInHand() or self:GetNewEquippedItemInHand("fishingrod")
                if not fishingrod or self:GetActiveItem() then self.auto_fishing = false break end
                local pos = pond:GetPosition()
                local fish_act = BufferedAction(self.inst, pond, ACTIONS.FISH, fishingrod, pos)
                while not self.inst:HasTag("nibble") do
                    if not self.inst:HasTag("fishing") and self.inst:HasTag("idle") then
                        self:SendAction(fish_act, false, pond)
                    end
                    Sleep(self.action_delay)
                end
                local catch_act = BufferedAction(self.inst, pond, ACTIONS.REEL, fishingrod, pos)
                self:SendAction(catch_act, false, pond)
                Sleep(self.action_delay)
                self:SendActionAndWait(catch_act, false, pond)

                -- 210130 null: only pick up fish if auto_collect is enabled
                if self.auto_collect then
                    local fish = FindEntity(self.inst, 2, nil, {"fish"})
                    if fish then
                        local pickup_act = BufferedAction(self.inst, fish, ACTIONS.PICKUP, nil, fish:GetPosition())
                        self:SendActionAndWait(pickup_act, false, fish)
                    end
                end
            end
        end
        self:ClearActionThread()
        self:ClearSelectedEntities()
    end, action_thread_id)
end

function ActionQueuer:IsSelectedEntity(ent)
    --nil check because boolean value
    return self.selected_ents[ent] ~= nil
end

-- 选中实体
function ActionQueuer:SelectEntity(ent, rightclick)
    if self:IsSelectedEntity(ent) then return end
    -- ？？？
    self.selected_ents[ent] = rightclick

    -- 添加高亮组件
    if not ent.components.highlight then
        ent:AddComponent("highlight")
    end
    local highlight = ent.components.highlight
    -- 取消预设的rgb再单独添加颜色
    highlight.highlight_add_colour_red = nil
    highlight.highlight_add_colour_green = nil
    highlight.highlight_add_colour_blue = nil
    highlight:SetAddColour(self.color)
    highlight.highlit = true
end

-- 清楚选择的实体
function ActionQueuer:DeselectEntity(ent)
    if self:IsSelectedEntity(ent) then
        -- 移除记录
        self.selected_ents[ent] = nil
        -- 移除高亮
        if ent:IsValid() and ent.components.highlight then
            ent.components.highlight:UnHighlight()
        end
    end
end

-- 反转实体选中状态
function ActionQueuer:ToggleEntitySelection(ent, rightclick)
    if self:IsSelectedEntity(ent) then
        self:DeselectEntity(ent)
    else
        self:SelectEntity(ent, rightclick)
    end
end

-- 清除全部选择的实体
function ActionQueuer:ClearSelectedEntities()
    for ent in pairs(self.selected_ents) do
        self:DeselectEntity(ent)
    end
end

-- 清除选中线程
function ActionQueuer:ClearSelectionThread()
    if self.selection_thread then
        DebugPrint("Thread cleared:", self.selection_thread.id)
        KillThreadsWithID(self.selection_thread.id)
        self.selection_thread:SetList(nil)
        self.selection_thread = nil
        self.selection_widget:Hide()
    end
end

function ActionQueuer:ClearActionThread()
    if self.action_thread then
        DebugPrint("Thread cleared:", self.action_thread.id)
        KillThreadsWithID(self.action_thread.id)
        self.action_thread:SetList(nil)
        self.action_thread = nil
        self.auto_fishing = false
        self.TL, self.TR, self.BL, self.BR = nil, nil, nil, nil
    end
end

function ActionQueuer:ClearAllThreads()
    self:ClearActionThread()
    self:ClearSelectionThread()
    self:ClearSelectedEntities()
    self.selection_widget:Kill()
end

ActionQueuer.OnRemoveEntity = ActionQueuer.ClearAllThreads
ActionQueuer.OnRemoveFromEntity = ActionQueuer.ClearAllThreads

return ActionQueuer
