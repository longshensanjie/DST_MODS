if GLOBAL.TheNet:GetServerGameMode() == "lavaarena" then return end

local InventoryFunctions = require "util/inventoryfunctions"
local GeoUtil = require "utils/geoutil"
local CraftFunctions = require "util/craftfunctions"
local ActionQueuer
local CRAFTING_ALLOWED = GetModConfigData("QAAQ_crafting_allowed")
local tool_container = GetModConfigData("QAAQ_tool_container")
local collect_items = GetModConfigData("QAAQ_collect_items")
local EVERYTHING_CHOP = GetModConfigData("QAAQ_everything_chop")
local QuickActions = {"DIG","HAMMER","NET","MINE","PICK","CHOP","PICKUP"} 
local RightQuickActions = {"DIG","HAMMER","NET","CHOP","MINE"}
local LeftQuickActions = {"NET","CHOP","MINE"}
local ENV = env
GLOBAL.setfenv(1, GLOBAL)
local CanOverrideAction =
{
    [ACTIONS.WALKTO] = true,
    [ACTIONS.LOOKAT] = true,
    [ACTIONS.PICK] = false,
}

local CanOverrideActionRight =
{
    [ACTIONS.WALKTO] = true,
    [ACTIONS.LOOKAT] = true,
    [ACTIONS.PICK] = true,
    [ACTIONS.PICKUP] = true,
    [ACTIONS.TOSS] = true,
    [ACTIONS.LIGHT] = false,
    [ACTIONS.INTERACT_WITH] = false,
}
local function table_leng(t)
    local leng=0
    for k, v in pairs(t) do
        leng=leng+1
    end
    return leng;
end

local function CheckLeftActions(target, pos)
    local leftActionsTable = ThePlayer.components.playeractionpicker:GetLeftClickActions(pos, target)
    if table_leng(leftActionsTable) == 0 then
        return true
    end
    for _, act in ipairs(leftActionsTable) do
        if not CanOverrideAction[act.action] then
            return false
        end
    end
    return true
end
local function CheckRightActions(target, pos)
    local rightActionsTable = ThePlayer.components.playeractionpicker:GetRightClickActions(pos, target)
    if table_leng(rightActionsTable) == 0 then
        return true
    end
    for _, act in ipairs(rightActionsTable) do
        if not CanOverrideActionRight[act.action] then
            return false
        end
    end
    return true
end
local function GetQuickAction(target, rightclick)
    local pos = target:GetPosition()
    if rightclick then
        if CheckRightActions(target, pos) then
            for _, quickAction in pairs(RightQuickActions) do
                if target:HasTag(quickAction .. "_workable") then
                    return quickAction, true
                end
            end
        end
    else
        if CheckLeftActions(target, pos) then
            for _, quickAction in pairs(LeftQuickActions) do
                if target:HasTag(quickAction .. "_workable") then
                    return quickAction, false
                end
            end
        end
    end
    return nil
end

local CraftableTools =
{
    CHOP =
    {
        "goldenaxe",
        "axe",
    },
    MINE =
    {   
        "goldenpickaxe",
        "pickaxe",
    },
    DIG = 
    {
        "goldenshovel",
        "shovel",
    },
    HAMMER = 
    {
        "hammer",
    },
    NET = 
    {
        "bugnet",
    }
}

local function mergeTable(...)
    local mTable = {}
    for _, v in pairs({...}) do
        for _, k in pairs(v) do
            table.insert(mTable, k)
        end
    end
    return mTable
end

local function GetItemsFromOpenContainer()
    local items = {}
    if not ThePlayer or not ThePlayer.replica.inventory then
        return items
    end
    for container, v in pairs(ThePlayer.replica.inventory:GetOpenContainers()) do
        if container and container.replica and container.replica.container then
            local items_container = container.replica.container:GetItems()
            items = mergeTable(items, items_container)
        end
    end
    for _, item in pairs(ThePlayer.replica.inventory:GetItems()) do
        table.insert(items, item)
    end
    return items
end

local function GetPlayerInventory()
    if tool_container == 0 then
        return InventoryFunctions:GetInventoryItems()
    elseif tool_container == 1 then
        return InventoryFunctions:GetBackpackItems()
    else
        return GetItemsFromOpenContainer()
    end
end

local function GetTool(quickAction)
    local toolInHands = ActionQueuer:GetEquippedItemInHand()
    if toolInHands and toolInHands:HasTag("wateringcan") then
        return nil
    end
    if toolInHands and toolInHands:HasTag(quickAction .. "_tool") then
        return toolInHands
    end
    for _, item in pairs(GetPlayerInventory()) do
        if item:HasTag(quickAction .. "_tool") then
            return item
        end
    end
    return nil
end

local function GetMouseOverride(target, rightclick) 
    local quickAction, rightclick_ = GetQuickAction(target, rightclick)
    if quickAction then
        local item = GetTool(quickAction)
        if item then
            local buffAction = BufferedAction(ThePlayer, target, ACTIONS[quickAction], item)
            return buffAction, rightclick_
        end
    end
    return nil
end    

local function ShouldCane( hand )
    local ShouldNotPrefab = {"cane","orangestaff","wateringcan","premiumwateringcan"}
    local ShouldNotTag = {"fire","light","dumbbell"}
    for _, prefab in pairs(ShouldNotPrefab) do
        if hand.prefab == prefab then
            return false
        end
    end
    for _, tag in pairs(ShouldNotTag) do
        if hand:HasTag(tag) then
            return false
        end
    end
    return true
end

local function EquipCane()
    local hand = ActionQueuer:GetEquippedItemInHand()
    if hand and not ShouldCane(hand) then
        return false
    end
    for _, item in pairs(GetPlayerInventory()) do
        if item.prefab == "cane" or item.prefab == "orangestaff" then
            InventoryFunctions:Equip(item)
            return true
        end
    end
    return false
end

local function walkToTarget(target, bug)
    if not bug then
        local cane = EquipCane()
        if cane then
            Sleep(FRAMES)
        end 
    end
    local player_pos
    local target_pos
    local playercontroller = ThePlayer.components.playercontroller
    while true do
        player_pos = ThePlayer:GetPosition()
        target_pos = target:GetPosition()
        if not playercontroller.locomotor then
            SendRPCToServer(RPC.LeftClick, ACTIONS.WALKTO.code, target_pos.x, target_pos.z)
        else
            local act = BufferedAction(ThePlayer, target, ACTIONS.WALKTO)
            act.preview_cb = function()
                SendRPCToServer(RPC.LeftClick, act.action.code, target_pos.x, target_pos.z)
            end
            playercontroller:DoAction(act)
        end
        Sleep(FRAMES * 8)
        local nowPlayer_pos = ThePlayer:GetPosition()
        local nowwTarget_pos = target:GetPosition()
        local distSq = nowPlayer_pos:DistSq(nowwTarget_pos)
        if distSq and distSq < 16 then
            return true
        end
        if player_pos == nowPlayer_pos then
            return false
        end
    end
    return nil
end 

local function IsValidEntity(ent)
    return ent and ent.Transform and ent:IsValid() and not ent:HasTag("INLIMBO")
end

local function GetWorldPosition(screen_x, screen_y)
    return Point(TheSim:ProjectScreenPos(screen_x, screen_y))
end

local function CheckActions(act)
    for _, quickAction in pairs(QuickActions) do
        if act and act.action == ACTIONS[quickAction] then
            return true
        end
    end 
    return false
end

local tree_seeds = {"pinecone", "acorn", "twiggy_nut", "palmcone_seed"}

local function CheckCollectTarget(ent)
    if collect_items == 0 then
        return ent.prefab == "log" or ent:HasTag("stump") or table.contains(tree_seeds, ent.prefab)
    elseif collect_items == 1 then
        return ent.prefab == "log" or ent:HasTag("stump")
    elseif collect_items == 2 then
        return ent:HasTag("stump") or table.contains(tree_seeds, ent.prefab)
    elseif collect_items == 3 then
        return ent:HasTag("stump")
    elseif collect_items == 4 then
        return true
    end
    return false
end

local unselectable_tags = {"DECOR", "FX", "INLIMBO", "NOCLICK", "player"}

local function GetUpvalueHelper(entry_fn, entry_name)
    local i = 1
    while true do
        local name, value = debug.getupvalue(entry_fn, i)
        if name == entry_name then
            return value, i
        elseif name == nil then
            return
        end
        i = i + 1
    end
end

local function GetUpvalue(fn, path)
    local prv, i = nil, nil
    for var in path:gmatch("[^%.]+") do
        prv = fn
        fn, i = GetUpvalueHelper(fn, var)
        if not fn then break end
    end
    return fn, i, prv
end

local function SetUpvalue(start_fn, path, new_fn)
    local fn, fn_i, scope_fn = GetUpvalue(start_fn, path)
    if not fn_i then print("Didn't find "..path.." from", start_fn) return end
    debug.setupvalue(scope_fn, fn_i, new_fn)
end

local function IsInOneOfAnimation(inst, anims)
    for i = 1, #anims do
        if inst.AnimState:IsCurrentAnimation(anims[i]) then
            return true
        end
    end

    return false
end
local WorkAnimations =
{
    "woodie_chop_pre",
    "woodie_chop_loop",
    "chop_pre",
    "chop_loop",
    "pickaxe_pre",
    "pickaxe_loop",
    "shovel_pre",
    "shovel_loop"
}
local function IsWorking(inst)
    if inst.AnimState
       and (IsInOneOfAnimation(inst, WorkAnimations)
        or inst:HasTag("beaver")
       and not inst:HasTag("attack")
       and inst.AnimState:IsCurrentAnimation("atk")) then
        return true
    end
    return false
end

local bugActions = {"CHOP","MINE","DIG","NET","HAMMER"}
local function CheckBugActions( act )
    for _, action_ in pairs(bugActions) do
        if act.action == ACTIONS[action_] then
            return true
        end
    end
    return false
end
--- 在这里添加想要手持砍树的东西- add your prefab at here
local bugItems = {"nightstick","lighter","torch","lantern","redlantern","umbrella","myth_redlantern"} -- ,"fishingrod","cane","grass_umbrella","orangestaff","malbatross_beak","oceanfishingrod"
local function CheckBugItem()
    local hand = ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
    for _, item in pairs(bugItems) do
        if hand and hand.prefab == item then
            return true
        end
    end
    return false
end

local function CheckLocomotor()
    local playercontroller = ThePlayer.components.playercontroller
    if playercontroller.locomotor then
        return true
    end
    return false
end

local function CheckBug(act)
    return not CheckLocomotor()
        and EVERYTHING_CHOP
        and CheckBugItem()
        and CheckBugActions(act)
end

local function CheckTarget(target, act)
    if act and act.action == ACTIONS["CHOP"] and target:HasTag("stump") then
        return false
    end
    if IsValidEntity(target) then
        return true
    end
    return false
end

local moving_target = {tumbleweed = true}

local function ToggleLagCompensation()
    local playercontroller = ThePlayer.components.playercontroller
    local movementprediction = not Profile:GetMovementPredictionEnabled()
    if playercontroller:CanLocomote() then
        playercontroller.locomotor:Stop()
    else
        playercontroller:RemoteStopWalking()
    end
    ThePlayer:EnableMovementPrediction(movementprediction)
    Profile:SetMovementPredictionEnabled(movementprediction)
end

local function GetNewToolAndAct(target, rightclick, pos, current_action) 
    local index
    local CraftTable = LeftQuickActions
    if target and target.prefab == "moonstorm_glass_nub" then return end
    if rightclick then CraftTable = RightQuickActions end
    for _, quickAction in pairs(CraftTable) do
        if target:HasTag(quickAction .. "_workable") then
            index = quickAction
            break
        end
    end
    if index and not(current_action and current_action.id ~= index) then
        for i = 1, #CraftableTools[index] do
            if CraftFunctions:KnowsRecipe(CraftableTools[index][i]) and CraftFunctions:CanCraft(CraftableTools[index][i]) then
                local locomotor_lag = false
                if CheckLocomotor() then
                    locomotor_lag = true
                    ToggleLagCompensation() 
                end
                CraftFunctions:Craft(CraftableTools[index][i])
                Sleep(FRAMES * 50)
                local act = ActionQueuer:GetAction(target, rightclick, pos)
                if locomotor_lag then
                    ToggleLagCompensation()
                end
                return act
            end 
        end 
    end
    return nil
end

local function GetItemSlotFromOpenContainerAndInventory(item)
    local slot, blankslot
    if item then
        for num, _item in pairs(ThePlayer.replica.inventory:GetItems()) do
            if _item == item then
                slot = num
                return ThePlayer.replica.inventory, slot
            end
        end
        for container, v in pairs(ThePlayer.replica.inventory:GetOpenContainers()) do
            if container and container.replica and container.replica.container then
                for num, _item in pairs(container.replica.container:GetItems()) do
                    if _item == item then
                        slot = num
                        return container.replica.container, slot
                    end
                end
            end
        end
    end
    for i = 1, ThePlayer.replica.inventory:GetNumSlots() do
        if not ThePlayer.replica.inventory:GetItemInSlot(i) or ThePlayer.replica.inventory:GetItemInSlot(i) == item then
            blankslot = i
            return ThePlayer.replica.inventory, blankslot
        end
    end
    for container, value in pairs(ThePlayer.replica.inventory:GetOpenContainers()) do
        if container and container.replica and container.replica.container then
            for i = 1, container.replica.container:GetNumSlots() do
                if not container.replica.container:GetItemInSlot(i) or container.replica.container:GetItemInSlot(i) == item then
                    blankslot = i
                    return container.replica.container, blankslot
                end
            end
        end
    end
    return nil
end

ENV.AddComponentPostInit("actionqueuer", function(self)
    ActionQueuer = ThePlayer.components.actionqueuer
    if ActionQueuer then
        local CheckAllowedActions = GetUpvalue(self.Wait, "CheckAllowedActions")
        local action_thread_id = "actionqueue_action_thread"
        local allowed_actions = 
        {
            tools = {"ATTACK", "CHOP", "DIG", "HAMMER", "MINE", "NET"}
        }

        self.ApplyToSelection = function(self)
            self.action_thread = StartThread(function()
                self.inst:ClearBufferedAction()
                local active_item = self:GetActiveItem()
                while self.inst:IsValid() do
                    local target = self:GetClosestTarget()
                    if not target then break end
                    local rightclick = self.selected_ents[target]
                    local pos = target:GetPosition()
                    local act = self:GetAction(target, rightclick, pos)
                    if not act and not self:GetActiveItem() and CRAFTING_ALLOWED then    
                        act = GetNewToolAndAct(target, rightclick, pos)
                        if not act then 
                            self:ClearSelectedEntities()
                            break 
                        end
                    end
                    if act and act:IsValid() and CheckBug(act) then
                        if walkToTarget(target, true) or walkToTarget(target, true) then
                            local container, slot = GetItemSlotFromOpenContainerAndInventory(act.invobject)
                            if container then
                                container:TakeActiveItemFromAllOfSlot(slot)
                                SendRPCToServer(RPC.TakeActiveItemFromAllOfSlot, slot, container)
                            end
                            Sleep(FRAMES)
                            if act.action == ACTIONS["HAMMER"]then
                                while CheckTarget(target, act) and self:GetActiveItem() do 
                                    SendRPCToServer(RPC.SwapEquipWithActiveItem)
                                    Sleep(FRAMES)
                                    SendRPCToServer(RPC.ActionButton, act.action.code, target, true, true)
                                    SendRPCToServer(RPC.SwapEquipWithActiveItem)
                                    if CheckLocomotor() then
                                        Sleep(FRAMES*3)
                                    end
                                    Sleep(FRAMES*18)
                                end
                            else
                                SendRPCToServer(RPC.SwapEquipWithActiveItem)
                                Sleep(FRAMES)
                                SendRPCToServer(RPC.ActionButton, act.action.code, target, true, true)
                                SendRPCToServer(RPC.SwapEquipWithActiveItem)
                            end
                            local PlayerController = ThePlayer and ThePlayer.components.playercontroller
                            local PlayerControllerOnUpdate = PlayerController.OnUpdate
                            function PlayerController:OnUpdate(...)
                                if IsWorking(self.inst) then
                                    self:OnControl(CONTROL_ACTION, true)
                                end
                                PlayerControllerOnUpdate(self, ...)
                            end  
                            while CheckTarget(target, act) and self:GetActiveItem() do
                                Sleep(FRAMES*5)
                            end
                            local _container, blankslot = GetItemSlotFromOpenContainerAndInventory()
                            local now_active_item = self:GetActiveItem()
                            if now_active_item and blankslot then
                                _container:PutAllOfActiveItemInSlot(blankslot)
                                SendRPCToServer(RPC.PutAllOfActiveItemInSlot, blankslot, _container)
                            elseif now_active_item then
                                local pos = ThePlayer:GetPosition()
                                Sleep(FRAMES)
                                SendRPCToServer(RPC.LeftClick, ACTIONS.DROP.code, pos.x, pos.z, nil, true)
                                Sleep(FRAMES*30)
                            end
                            self:DeselectEntity(target)
                            local auto_collect = CheckAllowedActions("autocollect", act.action, target)
                            if self.auto_collect and auto_collect then
                                Sleep(FRAMES)
                                pos = moving_target[target.prefab] and self.inst:GetPosition() or pos
                                self:AutoCollect(pos, false)
                            end
                        end
                    elseif act and act:IsValid() then
                        local tool_action = allowed_actions.tools[act.action]
                        local auto_collect = CheckAllowedActions("autocollect", act.action, target)
                        self:SendActionAndWait(act, rightclick, target)
                        if not CheckAllowedActions("single", act.action, target) then
                            local noworkdelay = CheckAllowedActions("noworkdelay", act.action, target)
                            local current_action = act.action
                            local started = false -- 同步qaaq的更新
                            local equip_start = self:GetEquippedItemInHand() 
                            local compostingbin_full = false
                            while IsValidEntity(target) do
                                local act = self:GetAction(target, rightclick, pos)
                                if not act and not self:GetActiveItem() and CRAFTING_ALLOWED then
                                    act = GetNewToolAndAct(target, rightclick, pos, current_action)
                                end
                                if not act then
                                    if active_item then
                                        if noworkdelay then Sleep(self.action_delay) end --queue can exit without this delay
                                        if not self:GetActiveItem() and self:GetNewActiveItem(active_item.prefab) then
                                            act = self:GetAction(target, rightclick, pos)
                                        end
                                    elseif tool_action and self:WaitToolReEquip() then
                                        act = self:GetAction(target, rightclick, pos)
                                    end
                                    if not act then break end
                                end
                                if act.action ~= current_action then break end
                                if act.action.id == "ATTACK" then
                                    local equip_current = self:GetEquippedItemInHand() 
                                    if not started
                                       or (not self.inst:HasTag("attack")
                                       and ((equip_start == equip_current)
                                       or (equip_start and equip_current
                                       and equip_start.prefab == equip_current.prefab))) then
                                        self:SendAttackLoop(act, pos, target)
                                        started = true
                                    elseif equip_start and not equip_current then
                                        if self:GetNewEquippedItemInHand(equip_start.prefab) then
                                            self:Wait()
                                        else break end 
                                    else
                                        Sleep(self.action_delay)
                                    end
                                else
                                    if target.prefab == "compostingbin" then
                                        local say = ThePlayer.components.talker and ThePlayer.components.talker.Say
                                        if say then 
                                            ThePlayer.components.talker.Say = function(self, script, ...)
                                                print(script,type(script))
                                                if script == "我做不到。" then
                                                    compostingbin_full = true
                                                end
                                                say(self, script, ...)
                                            end
                                        end
                                        print(compostingbin_full)
                                        if compostingbin_full then break end
                                    end
                                    self:SendActionAndWait(act, rightclick, target)
                                end
                                -- self:SendActionAndWait(act, rightclick, target)
                            end
                        end
                        self:DeselectEntity(target)
                        self:CheckEntityMorph(target.prefab, pos, rightclick)
                        if active_item and not self:GetActiveItem() then
                            self:GetNewActiveItem(active_item.prefab)
                        elseif tool_action then
                            self:WaitToolReEquip()
                        end
                        if self.auto_collect and auto_collect then
                            Sleep(FRAMES)
                            pos = moving_target[target.prefab] and self.inst:GetPosition() or pos
                            self:AutoCollect(pos, false)
                        end
                    else
                        self:DeselectEntity(target)
                    end
                end
                self:ClearActionThread()
            end, action_thread_id)
        end

        local AutoCollect = self.AutoCollect
        self.AutoCollect = function(self, pos, collect_now)
            local collect_mod = self.auto_collect
            if collect_mod == "挖树根模式" then
                for _, ent in pairs(TheSim:FindEntities(pos.x, 0, pos.z, 4, nil, unselectable_tags)) do
                    if IsValidEntity(ent) and not self:IsSelectedEntity(ent) then
                        local rightclick = false
                        if ent:HasTag("stump") and not (ThePlayer.prefab == "woodie" and ThePlayer.weremode:value() ~= 0) then
                            rightclick = true
                        end
                        local act = self:GetAction(ent, rightclick)
                        if act and act.action == ACTIONS["LIGHT"] then  -- 火把砍树的时候开自动收集砍树模式对树桩得到的动作是点燃
                            act = nil   -- 而卡这个bug的流程在ApplyToSelection里面,所以这里先进行排除
                        end
                        if act and CheckCollectTarget(ent) then
                            self:SelectEntity(ent, rightclick)
                            if collect_now then -- 这里是铲地皮时候的自动收集,不走应用器
                                self:SendActionAndWait(act, rightclick, ent)
                                self:DeselectEntity(ent)
                            end
                        end
                    end
                end
            else
                return AutoCollect(self, pos, collect_now)
            end
        end

        self.SelectionBox = function(self, rightclick)
            local previous_ents = {}
            local started_selection = false
            local start_x, start_y = self.screen_x, self.screen_y
            local NET_ents = {}
            local notNET_ents ={}
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
                self.selection_widget:SetPosition((xmin + xmax) / 2, (ymin + ymax) / 2)
                self.selection_widget:SetSize(xmax - xmin + 2, ymax - ymin + 2)
                self.selection_widget:Show()
                self.TL, self.BL, self.TR, self.BR = GetWorldPosition(xmin, ymax), GetWorldPosition(xmin, ymin), GetWorldPosition(xmax, ymax), GetWorldPosition(xmax, ymin)
                local center = GetWorldPosition((xmin + xmax) / 2, (ymin + ymax) / 2)
                local range = math.sqrt(math.max(center:DistSq(self.TL), center:DistSq(self.BL), center:DistSq(self.TR), center:DistSq(self.BR)))
                local IsBounded = GeoUtil.NewQuadrilateralTester(self.TL, self.TR, self.BR, self.BL)
                local current_ents = {}
                for _, ent in pairs(TheSim:FindEntities(center.x, 0, center.z, range, nil, unselectable_tags)) do
                    if IsValidEntity(ent) then
                        local pos = ent:GetPosition()
                        if IsBounded(pos) then
                            if not self:IsSelectedEntity(ent) and not previous_ents[ent] then
                                local act, rightclick_ = self:GetAction(ent, rightclick, pos)
                                if act and act.invobject and act.invobject.prefab == "bugnet" then
                                    NET_ents[ent] = rightclick_    
                                    self:SelectEntity(ent, rightclick_)
                                elseif act then
                                    notNET_ents[ent] = rightclick_
                                    self:SelectEntity(ent, rightclick_)
                                end
                            end
                            current_ents[ent] = true
                        end
                    end
                end
                for ent in pairs(previous_ents) do
                    if not current_ents[ent] then
                        self:DeselectEntity(ent)
                    end
                end
                previous_ents = current_ents
                local deselect_table = {}
                local hand = ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS)
                local NET_ents_flag = false
                if table_leng(NET_ents) ~= 0 then NET_ents_flag = true end
                if hand and hand.prefab == "bugnet" and NET_ents_flag then
                    deselect_table = notNET_ents
                end
                if table_leng(deselect_table) ~= 0 then
                    for ent, rightclick_ in pairs(deselect_table) do
                        self:DeselectEntity(ent)
                    end
                end
            end
            self.selection_thread = StartThread(function()
                while self.inst:IsValid() do
                    if self.queued_movement then
                        self.update_selection()
                        self.queued_movement = false
                    end
                    Sleep(FRAMES)
                end
                self:ClearSelectionThread()
            end, "actionqueue_selection_thread")
        end
        
        local SendAction = self.SendAction
        self.SendAction = function(self, act, rightclick, target)
            if act.action == ACTIONS["CHOP"] or act.action == ACTIONS["NET"] or act.action == ACTIONS["MINE"] then
                rightclick = false
            end
            return SendAction(self, act, rightclick, target)
        end

        local GetAction = self.GetAction
        self.GetAction = function(self, target, rightclick, pos)
            local IsRiding = ThePlayer.replica.rider:IsRiding()
            local active_item = ThePlayer.replica.inventory:GetActiveItem()
            if active_item or IsRiding then
                return GetAction(self, target, rightclick, pos)
            end
            local act, rightclick_ = GetMouseOverride(target, rightclick)
            if act then
                return act, rightclick_
            end
            return GetAction(self, target, rightclick, pos)
        end

        self.SendActionAndWait = function(self, act, rightclick, target)
            if CheckActions(act) then
                local player_pos = ThePlayer:GetPosition()
                local target_pos = target:GetPosition()
                local distSq = player_pos:DistSq(target_pos)
                if distSq and distSq > 16 then
                    walkToTarget(target)
                end 
                if ThePlayer.replica.inventory:GetEquippedItem(EQUIPSLOTS.HANDS) ~= act.invobject and target.prefab ~= "farm_soil" then
                    InventoryFunctions:Equip(act.invobject)
                end
            end
            self:SendAction(act, rightclick, target)
            self:Wait(act.action, target)
        end
    end
end)