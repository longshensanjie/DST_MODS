local _G = GLOBAL
if _G.TheNet:IsDedicated() or _G.TheNet:GetServerGameMode() == "lavaarena" then return end
TUNING.ACTION_QUEUE_DEBUG_MODE = false

-- 排队论的注释来自于littledro
-- 这是他的项目地址：https://gitee.com/romywumy/actionqueue

local SpawnPrefab = _G.SpawnPrefab
local TheInput = _G.TheInput
local unpack = _G.unpack
local CONTROL_ACTION = _G.CONTROL_ACTION
local CONTROL_FORCE_INSPECT = _G.CONTROL_FORCE_INSPECT
local CONTROL_FORCE_TRADE = _G.CONTROL_FORCE_TRADE
local PLAYERCOLOURS = _G.PLAYERCOLOURS
local STRINGS = _G.STRINGS
local ActionQueuer
local ThePlayer
local TheWorld

PLAYERCOLOURS.WHITE = {1, 1, 1, 1}

-- 这个数组用来控制什么操作可以打断排队论
local interrupt_controls = {}

-- 上下左右、攻击、检查、空格都会打断排队论
for control = _G.CONTROL_ATTACK, _G.CONTROL_MOVE_RIGHT do
    interrupt_controls[control] = true
end

-- 220225 null: support for littledro's QAAQ mod
local qaaq = true
if qaaq then
    -- QAAQ 的提灯砍树需要空格不能打断队列
	interrupt_controls[_G.CONTROL_ACTION] = false
end

-- 左键False右键true
local mouse_controls = {[_G.CONTROL_PRIMARY] = false, [_G.CONTROL_SECONDARY] = true}

local function GetKeyFromConfig(config)
    local key = GetModConfigData(config, true)
    if type(key) == "string" and _G:rawget(key) then
        key = _G[key]
    end
    return type(key) == "number" and key or -1
end


local turf_grid = {}
local turf_size = 4
local turf_grid_visible = false
local turf_grid_radius = 5
local turf_grid_color = PLAYERCOLOURS[GetModConfigData("Q_turf_grid_color")]

-- 网格显示
TheInput:AddKeyUpHandler(GetKeyFromConfig("Q_turf_grid_key"), function()
    if not InGame() then return end
    if turf_grid_visible then
        for _, grid in pairs(turf_grid) do
            grid:Hide()
        end
        turf_grid_visible = false
        TIP("网格显示","white",turf_grid_visible)
        return
    end
    local center_x, _, center_z = TheWorld.Map:GetTileCenterPoint(ThePlayer.Transform:GetWorldPosition())
    local radius = turf_grid_radius * turf_size
    local count = 1
    for x = center_x - radius, center_x + radius, turf_size do
        for z = center_z - radius, center_z + radius, turf_size do
            if not turf_grid[count] then
                turf_grid[count] = SpawnPrefab("gridplacer")
                turf_grid[count].AnimState:SetAddColour(unpack(turf_grid_color))
            end
            turf_grid[count].Transform:SetPosition(x, 0, z)
            turf_grid[count]:Show()
            count = count + 1
        end
    end
    turf_grid_visible = true
    TIP("网格显示","white",turf_grid_visible)
end)

-- 220225 null: support for littledro's QAAQ mod
local collect_mod = {turn_on = true, turn_off = false, chop_mod = "挖树根模式"} 

-- 自动收集
TheInput:AddKeyUpHandler(GetKeyFromConfig("Q_auto_collect_key"), function()
    if not InGame() then return end
    if qaaq then -- 220225 null: support for littledro's QAAQ mod
        ActionQueuer.auto_collect = collect_mod.turn_on
        collect_mod.turn_on = collect_mod.chop_mod
        collect_mod.chop_mod = collect_mod.turn_off
        collect_mod.turn_off = ActionQueuer.auto_collect
    else
        ActionQueuer.auto_collect = not ActionQueuer.auto_collect -- 220225 null: original autocollect toggle
    end
    TIP("自动采集","white",ActionQueuer.auto_collect)
end)

-- 垂直种植
TheInput:AddKeyUpHandler(GetKeyFromConfig("Q_endless_deploy_key"), function()
    if not InGame() then return end
    ActionQueuer.endless_deploy = not ActionQueuer.endless_deploy
    TIP("自动下一行","white",ActionQueuer.endless_deploy)
end)

-- 重复制作
local last_recipe, last_skin
TheInput:AddKeyUpHandler(GetKeyFromConfig("Q_last_recipe_key"), function()
    if not InGame() then return end
    if not last_recipe then
        ThePlayer.components.talker:Say("没有之前的配方")
        return
    end
    local last_recipe_name = STRINGS.NAMES[last_recipe.name:upper()] or "UNKNOWN"
    local builder = ThePlayer.replica.builder
    if not builder:CanBuild(last_recipe.name) and not builder:IsBuildBuffered(last_recipe.name) then
        ThePlayer.components.talker:Say("还不能制作这个:"..last_recipe_name)
        return
    end
    if last_recipe.placer then
        if not builder:IsBuildBuffered(last_recipe.name) then
            builder:BufferBuild(last_recipe.name)
        end
        ThePlayer.components.playercontroller:StartBuildPlacementMode(last_recipe, last_skin)
    else
        builder:MakeRecipeFromMenu(last_recipe, last_skin)
    end
    ThePlayer.components.talker:Say("制作刚刚的配方:"..last_recipe_name)
end)

local function ActionQueuerInit()
    ThePlayer:AddComponent("actionqueuer")
    ActionQueuer = ThePlayer.components.actionqueuer
    ActionQueuer.double_click_speed = 0.3
    ActionQueuer.double_click_range = GetModConfigData("Q_double_click_range")
    ActionQueuer.deploy_on_grid = false
    ActionQueuer.auto_collect = false
    ActionQueuer.endless_deploy = GetModConfigData("Q_endless_deploy")
    ActionQueuer:SetToothTrapSpacing(GetModConfigData("Q_tooth_trap_spacing"))
    ActionQueuer:SetFarmGrid(GetModConfigData("Q_farm_grid"))
    ActionQueuer:SetDoubleSnake(GetModConfigData("Q_snake")) -- 210127 null: added support for snaking within snaking
    ActionQueuer:SetAttackQueue(GetModConfigData("Q_attack_queue")) -- 210307 null: enable or disable ATTACK queuing
    local r, g, b = unpack(PLAYERCOLOURS[GetModConfigData("Q_selection_color")])
    ActionQueuer:SetSelectionColor(r, g, b, GetModConfigData("Q_selection_opacity"))
end


-- 排队键，LSHIFT
local action_queue_key = GetKeyFromConfig("Q_action_queue_key")
--maybe i won't need this one day...
local use_control = TheInput:GetLocalizedControl(0, CONTROL_FORCE_TRADE) == STRINGS.UI.CONTROLSSCREEN.INPUTS[1][action_queue_key]
action_queue_key = use_control and CONTROL_FORCE_TRADE or action_queue_key
TheInput.IsAqModifierDown = use_control and TheInput.IsControlPressed or TheInput.IsKeyDown
local always_clear_queue = true
AddComponentPostInit("playercontroller", function(self, inst)
    if inst ~= _G.ThePlayer then return end
    ThePlayer = _G.ThePlayer
    TheWorld = _G.TheWorld
    ActionQueuerInit()

    local PlayerControllerOnControl = self.OnControl
    self.OnControl = function(self, control, down)
        -- 左键false，右键true
        local mouse_control = mouse_controls[control]
        if mouse_control ~= nil then        -- 左键右键才能响应
            if down then                    -- 按下鼠标
                if TheInput:IsAqModifierDown(action_queue_key) then                                     -- 按下Shift
                    local target = TheInput:GetWorldEntityUnderMouse()                                  -- 鼠标下的实体
                    if target and target:HasTag("fishable") and not inst.replica.rider:IsRiding()       -- 能钓鱼 且 未骑行
                      and inst.replica.inventory:EquipHasTag("fishingrod") then                         -- 装备鱼竿
                        ActionQueuer:StartAutoFisher(target)
                    elseif not ActionQueuer.auto_fishing then                                           -- 不能钓鱼，就该干啥干啥
                        ActionQueuer:OnDown(mouse_control)
                    end
                    return
                end
            else
                ActionQueuer:OnUp(mouse_control)                                                        -- 鼠标抬起该干啥干啥
            end
        end
        PlayerControllerOnControl(self, control, down)                                                  -- 该干啥干啥
        if down and ActionQueuer.action_thread and not ActionQueuer.selection_thread and InGame()       -- 鼠标按下时有动作且未在选择
          and (interrupt_controls[control] or mouse_control ~= nil and not TheInput:GetHUDEntityUnderMouse()) then  -- 按下打断键 或者 鼠标左右点击了非HUD
            ActionQueuer:ClearActionThread()                                                            -- 动作终止
            if always_clear_queue or control == CONTROL_ACTION then                                     -- 如果打开了always_clear_queue选项或者使用空格，则会清除选择线程
                ActionQueuer:ClearSelectedEntities()                                                    -- 这就说明捡东西时按下空格会打断进程
            end
        end
    end
    -- 控制器支持
    local PlayerControllerIsControlPressed = self.IsControlPressed
    self.IsControlPressed = function(self, control)
        if control == CONTROL_FORCE_INSPECT and ActionQueuer.action_thread then return false end        -- 按下检查键时如果有动作线程返回false
        
        if use_control and control == CONTROL_FORCE_TRADE and                                           -- 按下shift时鼠标有东西返回false
           ThePlayer.components.playeravatardata.inst.replica.inventory:GetActiveItem() ~= nil then return false end
        
        return PlayerControllerIsControlPressed(self, control)                                          -- 正常返回
    end
end)

-- 修改制作组件
AddClassPostConstruct("components/builder_replica", function(self)
    -- 制作物品
    local BuilderReplicaMakeRecipeFromMenu = self.MakeRecipeFromMenu
    self.MakeRecipeFromMenu = function(self, recipe, skin)
        -- 记录上次制作的物品和皮肤
        last_recipe, last_skin = recipe, skin
        --如果按下Shift则进入队列制作
        if not ActionQueuer.action_thread and TheInput:IsAqModifierDown(action_queue_key)
          and not recipe.placer and self:CanBuild(recipe.name) then
            ActionQueuer:RepeatRecipe(self, recipe, skin)
        else
            BuilderReplicaMakeRecipeFromMenu(self, recipe, skin)
        end
    end

    -- 制作建筑
    local BuilderReplicaMakeRecipeAtPoint = self.MakeRecipeAtPoint
    self.MakeRecipeAtPoint = function(self, recipe, pt, rot, skin)
        last_recipe, last_skin = recipe, skin
        BuilderReplicaMakeRecipeAtPoint(self, recipe, pt, rot, skin)
    end
end)

-- 修改高亮组件
AddComponentPostInit("highlight", function(self, inst)
    local HighlightHighlight = self.Highlight
    self.Highlight = function(self, ...)
        if ActionQueuer.selection_thread or ActionQueuer:IsSelectedEntity(inst) then return end
        HighlightHighlight(self, ...)
    end
    local HighlightUnHighlight = self.UnHighlight
    self.UnHighlight = function(self, ...)
        if ActionQueuer:IsSelectedEntity(inst) then return end
        HighlightUnHighlight(self, ...)
    end
end)
--for minimizing the memory leak in geo
--hides the geo grid during an action queue
-- 隐藏网格
AddComponentPostInit("placer", function(self, inst)
    local PlacerOnUpdate = self.OnUpdate
    self.OnUpdate = function(self, ...)
        self.disabled = ActionQueuer.action_thread ~= nil
        PlacerOnUpdate(self, ...)
    end
end)
