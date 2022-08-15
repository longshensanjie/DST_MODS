local UpvalueUtil = require("lazy_controls/upvalueutil")
local getval = UpvalueUtil.GetUpvalue
local IsRightItem = morph_checker_IsRightItem

local allow_all_open_containers = true
local rmb_pickup_setting = "all"
local tilling_spacing_config = 1.33
-- 不再支持挨个发装备, 因为开启该功能无法连续投喂生物
-- local single_item_for_followers = false

local WALL_TAGS = {"wall"}
local CANARY_MUSTTAGS = {"canary"}
local CANARY_CANTTAGS = {"INLIMBO"}
local DIRTPILE_TAGS = {"dirtpile"}
local SOIL_MUSTTAGS = {"soil"}
local SOIL_CANTTAGS = {"NOCLICK", "NOBLOCK"}
local NUTRIENTS_OVERLAY_TAGS = {"DECOR", "NOCLICK"}
local DEPLOY_IGNORE_TAGS = {"NOBLOCK", "player", "FX", "INLIMBO", "DECOR", "WALKABLEPLATFORM"}
local TILLSOIL_IGNORE_TAGS = {"NOBLOCK", "player", "FX", "INLIMBO", "DECOR", "WALKABLEPLATFORM", "soil"}

local auto_collect_tag_blacklist = {"bundle", "fan", "irreplaceable", "singingshell"}
local auto_collect_blacklist = {
    "waxwelljournal", "firecrackers", "miniflare", "ash", "moonrockcrater",
    "purplemooneye", "bluemooneye", "yellowmooneye", "redmooneye", "orangemooneye", "greenmooneye",
    "pumpkin_lantern", "heatrock"
}

local endless_repeat_id = "actionqueue_endless_repeat_thread"

local is_gorge = GLOBAL.TheNet:GetServerGameMode() == "quagmire"
local farm_till_spacing = GLOBAL.GetFarmTillSpacing() + 0.01
local tilling_spacing = (is_gorge or tilling_spacing_config == "min") and farm_till_spacing or tilling_spacing_config

local till_shape = {
    {-1,  1},  {0,  1},  {1,  1},
    {-1,  0},  {0,  0},  {1,  0},
    {-1, -1},  {0, -1},  {1, -1},
}

local function is_eating(inst)
    return inst.AnimState:IsCurrentAnimation("eat_pre")
        or inst.AnimState:IsCurrentAnimation("eat")
        or inst.AnimState:IsCurrentAnimation("quick_eat_pre")
        or inst.AnimState:IsCurrentAnimation("quick_eat")
end
local function is_atk(inst)
    return inst.AnimState:IsCurrentAnimation("player_atk") -- When riding
        or inst.AnimState:IsCurrentAnimation("atk")
end
local function is_sleeping(inst)
    return inst.AnimState:IsCurrentAnimation("sleep_pre")
        or inst.AnimState:IsCurrentAnimation("sleep_loop")
end
local function is_onframe(inst, frame, allowed_bias)
    frame = frame * GLOBAL.FRAMES
    allowed_bias = allowed_bias or GLOBAL.FRAMES
    local ping = GLOBAL.TheNet:GetPing() / 1000
    local cur_time = inst.AnimState:GetCurrentAnimationTime()
    if not GLOBAL.TheWorld.ismastersim then
        frame = math.max(0, frame - math.max(GLOBAL.FRAMES, ping))
    end
    return cur_time >= frame and cur_time <= frame + allowed_bias
end

local function not_mastersim(target)
    return not GLOBAL.TheWorld.ismastersim
end

local function has_component(target, cmp)
    return target and target:HasActionComponent(cmp)
end

local function has_action(actions, action)
    for _, v in ipairs(actions) do
        if v.action == GLOBAL.ACTIONS[action] then
            return true
        end
    end
    return false
end

AddComponentPostInit("actionqueuer", function(self)

    self.AddActionList("allclick", "HACK")

    self.AddActionList("leftclick", "MIOFUEL", "MURDER", "USEKLAUSSACKKEY", "READ",
    "BATHBOMB", "PLANTSOIL", "ADDCOMPOSTABLE", "INTERACT_WITH", "CARNIVALGAME_FEED", "BAIT",
    "ADVANCE_TREE_GROWTH", "HALLOWEENMOONMUTATE")

    self.AddActionList("rightclick", "LIGHT", "FILL", "POUR_WATER", "HIDEANSEEK_FIND")

    self.AddActionList("noworkdelay", "PICKUP", "PICK", "FEEDPLAYER", "UNWRAP", "RESETMINE", "DRAW",
    "TURNON", "TURNOFF", "LIGHT", "USEKLAUSSACKKEY", "READ", "FEED", "MURDER", "HACK", "BATHBOMB",
    "PLANTSOIL", "ADDCOMPOSTABLE", "INTERACT_WITH", "TILL", "TAKEITEM", "CARNIVALGAME_FEED", "BAIT",
    "ADVANCE_TREE_GROWTH", "POUR_WATER", "HIDEANSEEK_FIND")

    self.AddActionList("tools", "HACK")

    self.AddActionList("autocollect", "HACK")

    self.AddAction("noworkdelay", "POUR_WATER_GROUNDTILE", not_mastersim)

    self.AddAction("collect", "PICKUP", function(target)
        if target.replica.equippable ~= nil then return false end
        if table.contains(auto_collect_blacklist, target.prefab) then return false end
        for _, v in ipairs(auto_collect_tag_blacklist) do
            if target:HasTag(v) then
                return false
            end
        end
        if has_component(target, "book") then return false end
        return true
    end)
    self.AddAction("collect", "HARVEST", function(target)
        return target.prefab == "meatrack"
    end)
    self.RemoveAction("collect", "PICK")

    self.AddAction("leftclick", "SHAVE", function(target) -- Only exclude players and shaved beefalos
        return not target:HasTag("player")
            and not (target:HasTag("beefalo") and not target:HasTag("brushable"))
    end)

    self.AddAction("allclick", "MINE", function(target)  -- F, who wrote prefabs/moonstorm_glass.lua?
        return target.prefab ~= "moonstorm_glass_nub"
    end)

    local not_fuel_items = { "boatpatch", "featherpencil" }
    local function can_fuel(target)
        local active_item = self:GetActiveItem()
        return not table.contains(not_fuel_items, active_item and active_item.prefab)
    end
    self.AddAction("leftclick", "ADDFUEL", can_fuel)
    self.AddAction("leftclick", "ADDWETFUEL", can_fuel)

    local function is_target_only(target)
        local amount = 0
        for ent in pairs(self.selected_ents) do
            amount = amount + 1
            if ent ~= target or amount > 1 then
                return false
            end
        end
        return true
    end

    self.RemoveAction("leftclick", "EAT")
    self.RemoveAction("rightclick", "EAT")
    self.AddAction("allclick", "EAT", is_target_only)

    self.AddAction("leftclick", "FEED", is_target_only)
    self.AddAction("rightclick", "FEED", is_target_only)

    self.AddAction("leftclick", "GIVE", function(target)
        if target:HasTag("mushroom_farm") then
            local active_item = self:GetActiveItem()
            if active_item then
                if active_item.prefab == "livinglog" and not target.AnimState:IsCurrentAnimation("expired") then
                    return false
                elseif (active_item:HasTag("mushroom") or active_item:HasTag("spore")) and target.AnimState:IsCurrentAnimation("expired") then
                    return false
                end
            end
        end
        return not (target:HasTag("beefalo") and not is_target_only(target))
    end)
    -- if single_item_for_followers then
    --     local exclude_prefabs = { "mermking" }
    --     local followers = { "pig", "merm", "spider" }
    --     local function should_give_single(target)
    --         if table.contains(exclude_prefabs, target.prefab) then return end
    --         for _, tag in ipairs(followers) do
    --             if target:HasTag(tag) then
    --                 return true
    --             end
    --         end
    --     end
    --     self.AddAction("single", "GIVE", should_give_single)
    --     self.AddAction("noworkdelay", "GIVE", function(target)
    --         return target:HasTag("trader") and not should_give_single(target)
    --     end)
    -- end

    self.AddAction("leftclick", "ACTIVATE", function(target) -- Changed prefab test to tag test, mostly for compatible with Island Advantures
        return target:HasTag("dirtpile")
    end)

    self.AddAction("leftclick", "HARVEST", function(target)
        return target.prefab ~= "birdcage"
            and not (target.prefab == "fish_farm"
                and target.current_volume ~= nil
                and target.current_volume:value() == 1)
    end)
    self.AddAction("noworkdelay", "HARVEST", function(target)
        return not (target.prefab == "fish_farm"
            and target.current_volume ~= nil
            and target.current_volume:value() == 2)
    end)

    self.AddAction("single", "CASTSPELL", function(target)
        local hand_item = self:GetEquippedItemInHand()
        return not (hand_item and hand_item.prefab == "greenstaff")
    end)

    self.AddAction("rightclick", "COOK", function(target)
        return not (target:HasTag("cooker") and has_component(self:GetActiveItem(), "cookable"))
    end)

    self.AddAction("rightclick", "TAKEITEM", function(target)
        return target.prefab ~= "winch"
    end)

    self.AddAction("rightclick", "PICKUP", function(target)
        return target:HasTag("spider")
            or rmb_pickup_setting and target:HasTag("heavy") and is_target_only(target)
                and (rmb_pickup_setting == "all" or target.prefab:find("sculpture_"))
    end)

    self.AddAction("noworkdelay", "FILL", function(target)
        return self:GetActiveItem()
            or not has_component(self:GetEquippedItemInHand(), "wateryprotection")
    end)

    self.AddAction("leftclick", "REPAIR_LEAK", function(target)
        return not target.AnimState:IsCurrentAnimation("leak_small_pst")
    end)

    self.AddAction("leftclick", "CAST_POCKETWATCH", function(target)
        local active_item = self:GetActiveItem()
        return active_item and active_item.prefab == "pocketwatch_heal"
    end)

    local entity_morph, i = getval(self.CheckEntityMorph, "entity_morph")
    local extra_morph = { ancient_altar = "ancient_altar_broken" }
    shallowcopy(extra_morph, entity_morph)
    debug.setupvalue(self.CheckEntityMorph, i, entity_morph)

    local easy_stack, i = getval(self.OnUp, "easy_stack")
    local extra_stuff = { lureplantbulb = "lureplant" }
    shallowcopy(extra_stuff, easy_stack)
    debug.setupvalue(self.OnUp, i, easy_stack)

    local deploy_spacing, i = getval(self.SetToothTrapSpacing, "deploy_spacing")
    local extra_custom_spacing = { seed = 4/3 }
    -- shallowcopy(extra_custom_spacing, deploy_spacing) -- 棕榈树修复
    debug.setupvalue(self.SetToothTrapSpacing, i, deploy_spacing)

    local CheckAllowedActions = getval(self.Wait, "CheckAllowedActions")
    local IsValidEntity = getval(self.SelectionBox, "IsValidEntity")

    local function base_wait_cond()
        return self.inst:HasTag("idle") and not self.inst.components.playercontroller:IsDoingOrWorking()
            and not (self.inst.sg and self.inst.sg:HasStateTag("moving"))
            and not self.inst:HasTag("moving")
    end

    local function try_pickup_canary(pos)
        local x, y, z = pos:Get()
        local canarys = GLOBAL.TheSim:FindEntities(x, y, z, 4, CANARY_MUSTTAGS, CANARY_CANTTAGS)
        for _, canary in ipairs(canarys) do
            if canary.prefab == "canary_poisoned" and IsValidEntity(canary) then
                local act = self:GetAction(canary, false)
                if act then
                    self:SelectEntity(canary, false)
                    while IsValidEntity(canary) do
                        local act = self:GetAction(canary, false)
                        if not act or act.action ~= GLOBAL.ACTIONS.PICKUP then break end
                        self:SendActionAndWait(act, false, canary)
                    end
                    self:DeselectEntity(canary)
                    return true
                end
            end
        end
    end

    local Wait = self.Wait
    self.Wait = function(self, action, target)
        if action == GLOBAL.ACTIONS.PICKUP and CheckAllowedActions("noworkdelay", action, target) then
            local act = nil
            repeat
                Yield()
                act = IsValidEntity(target) and self:GetAction(target) or nil
            until is_eating(self.inst)
                or self.inst.AnimState:IsCurrentAnimation("staff") -- for using try_pickup_canary function
                or not (act and act.action == GLOBAL.ACTIONS.PICKUP)
                or base_wait_cond()
        elseif action == GLOBAL.ACTIONS.LOWER_SAIL_BOOST then
            local done_ho = false
            repeat
                Yield()
                if not done_ho and self.inst:HasTag("switchtoho") then
                    done_ho = true
                    self:SendAction(GLOBAL.BufferedAction(self.inst, target, action), false, target)
                end
            until base_wait_cond()
        elseif action == GLOBAL.ACTIONS.CASTSPELL then
            local hand_item = self:GetEquippedItemInHand()
            if not (hand_item and target) then
                Wait(self, action, target)
            elseif hand_item:HasTag("veryquickcast") then
                while IsValidEntity(target)
                    and self:GetAction(target, true, target:GetPosition())
                    and self:GetAction(target, true, target:GetPosition()).action ==GLOBAL.ACTIONS.CASTSPELL
                    and (self.inst:HasTag("idle") or is_atk(self.inst)) do

                    local act = GLOBAL.BufferedAction(self.inst, target, action, self:GetEquippedItemInHand())
                    self:SendAction(act, true, target)
                    GLOBAL.Sleep(self.action_delay)
                end

                repeat
                    Yield()
                until is_atk(self.inst) and is_onframe(self.inst, 5) or base_wait_cond()
            elseif self.auto_collect
                and hand_item.prefab == "greenstaff"
                and target.prefab == "sleepbomb" then

                local pos = target:GetPosition()
                GLOBAL.Sleep(self.work_delay)
                repeat
                    GLOBAL.Sleep(self.action_delay)
                    if self.inst.AnimState:IsCurrentAnimation("staff")
                        and is_onframe(self.inst, 45, self.action_delay + GLOBAL.FRAMES) then

                        TryCraft(self.inst)
                        GLOBAL.Sleep(GLOBAL.FRAMES * 6) -- sleep until 4 frames's busy done
                    end
                until try_pickup_canary(pos) or base_wait_cond()

            else
                Wait(self, action, target)
            end
        elseif action == GLOBAL.ACTIONS.FILL then
            Wait(self, action, target)
            if self:GetActiveItem() then return end
            local equip_item = self:GetEquippedItemInHand()
            local inventoryitem = equip_item and equip_item.replica.inventoryitem
            if inventoryitem and inventoryitem.classified and inventoryitem.classified.percentused:value() == 100 then
                local item = self:GetNewEquippedItemInHand(equip_item.prefab, function(_item)
                    return _item.replica.inventoryitem
                        and _item.replica.inventoryitem.classified
                        and _item.replica.inventoryitem.classified.percentused:value() < 100
                end)
                if not item then -- Just wanna break the loop, but idk how to do it without tons of override
                    self.inst:DoTaskInTime(0, function()
                        self:DeselectEntity(target)
                        self:ClearActionThread()
                        self:ApplyToSelection()
                    end)
                    GLOBAL.Sleep(GLOBAL.FRAMES * 2)
                end
            end
        elseif action == GLOBAL.ACTIONS.ACTIVATE and target:HasTag("dirtpile") then
            local x, y, z = target.Transform:GetWorldPosition()
            Wait(self, action, target)
            local ents = GLOBAL.TheSim:FindEntities(x, y, z, TUNING.HUNT_SPAWN_DIST + 1, DIRTPILE_TAGS)
            for _, ent in ipairs(ents) do
                if IsValidEntity(ent) and ent:GetTimeAlive() < 1 then
                    self:SelectEntity(ent, false)
                    break
                end
            end
        elseif action == GLOBAL.ACTIONS.GIVE
            and target.prefab == "birdcage"
            and is_sleeping(target) then

            local active_item = self:GetActiveItem()
            self.inst.replica.inventory:ReturnActiveItem()

            local act = GLOBAL.BufferedAction(self.inst, target, GLOBAL.ACTIONS.HARVEST)
            repeat
                self:SendActionAndWait(act, false, target)
            until not target:IsValid() or not target:HasTag("occupied")

            local bird, slot, container = GetItemFromContainers(nil, nil, nil, function(item) return item:HasTag("bird") end)
            if bird then
                if bird ~= self:GetActiveItem() then
                    container:TakeActiveItemFromAllOfSlot(slot)
                end
                local act = GLOBAL.BufferedAction(self.inst, target, GLOBAL.ACTIONS.STORE, bird)
                repeat
                    self:SendActionAndWait(act, false, target)
                until not target:IsValid() or target:HasTag("occupied")

                self:GetNewActiveItem(active_item.prefab)
            end
        else
            Wait(self, action, target)
        end
    end

    local SelectionBox = self.SelectionBox
    self.SelectionBox = function(self, rightclick, ...)
        SelectionBox(self, rightclick, ...)
        local update_selection = self.update_selection
        self.update_selection = function()
            local active_item = self:GetActiveItem()
            if active_item and active_item:HasTag("wallbuilder") then
                local unselectable_tags, i = getval(SelectionBox, "unselectable_tags")
                debug.setupvalue(SelectionBox, i, JoinArrays(unselectable_tags, WALL_TAGS))
                update_selection()
                debug.setupvalue(SelectionBox, i, unselectable_tags)
                return
            end
            update_selection()
        end
    end

    local function GetSnap(pos) -- Mostly from surg's Snaping Tills
        if self.inst.components.snaptiller then
            return self.inst.components.snaptiller:GetSnap(pos)
        elseif tilling_spacing ~= 1.33 then
            return pos
        end
        local x, _, z = GLOBAL.TheWorld.Map:GetTileCenterPoint(pos:Get())
        local pos_list = {}
        for _, coor in ipairs(till_shape) do
            table.insert(pos_list, GLOBAL.Vector3(x + coor[1] * 1.33, 0, z + coor[2] * 1.33))
        end
        local min_dist, final_pos
        for _, snap_pos in ipairs(pos_list) do
            local dist = distsq(pos.x, pos.z, snap_pos.x, snap_pos.z)
            if min_dist == nil or dist < min_dist then
                min_dist = dist
                final_pos = snap_pos
            end
        end
        return final_pos
    end

    self.HandleGroundItem = function(self, pos, range, ignore_tags)
        local ents = GLOBAL.TheSim:FindEntities(pos.x, 0, pos.z, range, nil, ignore_tags)
        local seeds = {}
        for _, ent in ipairs(ents) do
            if ent.prefab == "seeds" then
                table.insert(seeds, ent)
            else
                return -- Have other blockers, skip
            end
        end
        if #seeds == 0 then return end
        for _, seed in ipairs(seeds) do
            local act = IsValidEntity(seed)
                    and seed.replica.inventoryitem
                    and seed.replica.inventoryitem:CanBePickedUp()
                    and GLOBAL.BufferedAction(self.inst, seed, GLOBAL.ACTIONS.PICKUP)
            if act then
                self:SelectEntity(seed, false)
                while IsValidEntity(seed) do
                    if self:GetActiveItem() then
                        local playercontroller = self.inst.components.playercontroller
                        if playercontroller.ismastersim then
                            self.inst.components.combat:SetTarget(nil)
                            playercontroller:DoAction(act)
                        else
                            if seed:IsNear(self.inst, 6) then
                                GLOBAL.SendRPCToServer(GLOBAL.RPC.StopWalking)
                                local cb = function() GLOBAL.SendRPCToServer(GLOBAL.RPC.ActionButton, GLOBAL.ACTIONS.PICKUP.code, seed, true, true) end
                                if playercontroller:CanLocomote() then
                                    act.preview_cb = cb
                                    playercontroller.locomotor:PreviewAction(act, true)
                                else
                                    cb()
                                end
                            else
                                local pos = seed:GetPosition()
                                if playercontroller.locomotor then
                                    playercontroller.locomotor:RunInDirection(self.inst:GetAngleToPoint(pos))
                                end
                                GLOBAL.SendRPCToServer(GLOBAL.RPC.DragWalking, pos.x, pos.z)
                            end
                        end
                        self:Wait(act.action, seed)
                    else
                        self:SendActionAndWait(act, false, seed)
                    end
                end
                self:DeselectEntity(seed)
            end
        end
        return true
    end

    self.TillAtPoint = function(self, pos)
        self:WaitToolReEquip()
        local equip_item = self:GetEquippedItemInHand()
        if not equip_item then return false end
        pos = GetSnap(pos)
        if #GLOBAL.TheSim:FindEntities(pos.x, 0, pos.z, 0.05, SOIL_MUSTTAGS, SOIL_CANTTAGS) > 0 then
            return true -- Skip, if already have a good farm soil
        end
        local act = GLOBAL.BufferedAction(self.inst, nil, GLOBAL.ACTIONS.TILL, equip_item, pos)
        local target = GLOBAL.TheInput:GetWorldEntityUnderMouse()
        local actions
            actions = self.inst.components.playeractionpicker:GetPointActions(pos, equip_item, true, target)
        if has_action(actions, "TILL") then
            repeat
                self:SendActionAndWait(act, true)
                    actions = self.inst.components.playeractionpicker:GetPointActions(pos, equip_item, true, GLOBAL.TheInput:GetWorldEntityUnderMouse())
            until not has_action(actions, "TILL")
                or #(GLOBAL.TheSim:FindEntities(pos.x, 0, pos.z, 0.05, SOIL_MUSTTAGS, SOIL_CANTTAGS)) > 0
        elseif GLOBAL.TheWorld.Map:IsFarmableSoilAtPoint(pos.x, 0, pos.z) then
            if self:HandleGroundItem(pos, farm_till_spacing, TILLSOIL_IGNORE_TAGS) then
                self:TillAtPoint(pos) -- Try again
            end
        end
        return true
    end

    local GetDeploySpacing = getval(self.OnUp, "GetDeploySpacing")

    local DeployActiveItem = self.DeployActiveItem
    self.DeployActiveItem = function(self, pos, item, ...)
        local rt = DeployActiveItem(self, pos, item, ...)
        if rt then
            local active_item = self:GetActiveItem()
            local inventoryitem = active_item and active_item:IsValid() and not active_item:HasTag("groundtile") and active_item.replica.inventoryitem
            if inventoryitem
                and inventoryitem.classified ~= nil
                and not inventoryitem:CanDeploy(pos, nil, self.inst)
                and (
                    inventoryitem.classified.deploymode:value() ~= DEPLOYMODE.PLANT or
                    GLOBAL.TheWorld.Map:CanPlantAtPoint(pos:Get())
                ) then

                if self:HandleGroundItem(pos, GetDeploySpacing(active_item) - 0.01, DEPLOY_IGNORE_TAGS) then
                    return DeployActiveItem(self, pos, item, ...) -- Try again
                end
            end
        end
        return rt
    end

    local function needs_water(ent)
        local percent = ent and ent:IsValid() and tonumber(ent:GetDebugString():match("Frame: (.*)/"))
        if percent ~= nil then
            percent = percent / 30
        end
        return percent and percent < 0.9
    end

    local function has_water(item)
        local inventoryitem = item and item.replica.inventoryitem
        return inventoryitem.classified
            and inventoryitem.classified.percentused:value()
            and inventoryitem.classified.percentused:value() > 0
    end

    local TerraformAtPoint = self.TerraformAtPoint
    self.TerraformAtPoint = function(self, pos, item, ...)
        if has_component(item, "wateryprotection") then
            local equip_item = self:GetEquippedItemInHand()
            if not equip_item then return false end
            local nutrients_overlay
            local x, _, z = GLOBAL.TheWorld.Map:GetTileCenterPoint(pos:Get())
            if not x then return false end -- For endless deploy...
            for _, ent in ipairs(GLOBAL.TheSim:FindEntities(x, 0, z, 0.1, NUTRIENTS_OVERLAY_TAGS)) do
                if ent:IsValid() and ent.prefab == "nutrients_overlay" then
                    nutrients_overlay = ent
                    break
                end
            end
            if not needs_water(nutrients_overlay) then return true end
            repeat
                equip_item = self:GetEquippedItemInHand()
                local act = GLOBAL.BufferedAction(self.inst, nil, GLOBAL.ACTIONS.POUR_WATER_GROUNDTILE, equip_item, pos)
                local actions            
                    actions = self.inst.components.playeractionpicker:GetPointActions(pos, equip_item, true, GLOBAL.TheInput:GetWorldEntityUnderMouse())
                if has_action(actions, "POUR_WATER_GROUNDTILE") then
                    if not has_water(equip_item) then
                        local new_item = self:GetNewEquippedItemInHand(item.prefab, has_water)
                        if new_item then
                            act.invobject = new_item
                        else
                            return false
                        end
                    end
                    self:SendActionAndWait(act, true)
                else
                    return true
                end
            until not self.inst:IsValid() or not needs_water(nutrients_overlay)
            return true
        end
        return TerraformAtPoint(self, pos, item, ...)
    end

    local unselectable_tags = getval(self.CherryPick, "unselectable_tags")

    self.SelectEntities = function(self, data)
        local pos            = data.pos            or self.inst:GetPosition()
        local range          = data.range          or self.double_click_range
        local musttags       = data.musttags       or nil
        local canttags       = data.canttags       or unselectable_tags
        local mustoneoftags  = data.mustoneoftags  or nil
        local test_fn        = data.test_fn        or nil
        local action_test_fn = data.action_test_fn or nil
        local is_right_list  = data.is_right_list  or { false }
        local is_rightclick  = data.is_rightclick  or function(ent, is_right_list)
            for _, rightclick in ipairs(is_right_list) do
                local act, rightclick = self:GetAction(ent, rightclick, pos)
                if act and (action_test_fn == nil or action_test_fn(ent, act)) then
                    return rightclick
                end
            end
        end

        local selected = {}
        for _, ent in ipairs(GLOBAL.TheSim:FindEntities(pos.x, 0, pos.z, range, musttags, canttags, mustoneoftags)) do
            if IsValidEntity(ent) and not self:IsSelectedEntity(ent) and (test_fn == nil or test_fn(ent)) then
                local rightclick = is_rightclick(ent, is_right_list)
                if rightclick ~= nil then
                    self:SelectEntity(ent, rightclick)
                    table.insert(selected, { ent = ent, right = rightclick })
                end
            end
        end
        return selected
    end

    self.EndlessRepeat = function(self, select_data)

        if self.endless_repeat_thread then
            self:ClearEndlessRepeatThread(true)
        end

        select_data = select_data or {}

        if select_data.is_recipe then
            local builder = select_data.builder
            local recipe = select_data.recipe
            local skin = select_data.skin

            self.endless_repeat = true
            self.endless_repeat_thread = GLOBAL.StartThread(function()
                while self.inst:IsValid() do
                    if not self.action_thread and builder:CanBuild(recipe.name) then
                        self:RepeatRecipe(builder, recipe, skin)
                    end
                    GLOBAL.Sleep(self.action_delay)
                end
                self:ClearEndlessRepeatThread()
            end, endless_repeat_id)
            return
        end

        local check_list = {}

        local function already_in(prefab, rightclick, action)
            for _, v in ipairs(check_list) do
                if v.prefab == prefab and v.rightclick == rightclick and v.action == action then
                    return true
                end
            end
        end

        for ent, rightclick in pairs(self.selected_ents) do
            if IsValidEntity(ent) then
                local prefab = ent.prefab
                local act = self:GetAction(ent, rightclick)
                local action = act and act.action
                if action and not already_in(prefab, rightclick, action) then
                    table.insert(check_list, { prefab = prefab, rightclick = rightclick, action = action })
                end
            end
        end

        if #check_list == 0 then return end

        select_data.is_right_list = select_data.is_right_list or { false, true }
        select_data.test_fn = select_data.test_fn or nil
        select_data.is_rightclick = select_data.is_rightclick or function(ent)
            for _, v in ipairs(check_list) do
                if IsRightItem(ent, v.prefab) then
                    local act = self:GetAction(ent, v.rightclick)
                    if act and act.action == v.action then
                        return v.rightclick
                    end
                end
            end
        end

        self.endless_repeat = true
        self.endless_repeat_thread = GLOBAL.StartThread(function()
            while self.inst:IsValid() do
                self:SelectEntities(select_data)
                if GLOBAL.next(self.selected_ents) and not self.action_thread then
                    self:ApplyToSelection()
                end
                GLOBAL.Sleep(self.work_delay)
            end
            self:ClearEndlessRepeatThread()
        end, endless_repeat_id)

    end

    self.ShouldActivateEndlessRepeat = function(self, endless_repeat)
        return (endless_repeat or self.endless_repeat) and not self.endless_repeat_thread
    end

    -- self.SelectAllNearbyEnts = function(self, force_endless_repeat)
    --     local data = {
    --         range = self.double_click_range * (force_endless_repeat and 1 or 0.5),
    --         action_test_fn = function(ent, act)
    --             return not (
    --                 ent.prefab == "firesuppressor"
    --                 and (act.action == ACTIONS.TURNON or act.action == ACTIONS.TURNOFF)
    --             )
    --         end,
    --         is_right_list = { true, false },
    --     }
    --     self:SelectEntities(data)
    --     if self:ShouldActivateEndlessRepeat(force_endless_repeat) then
    --         self:EndlessRepeat(data)
    --     end
    --     if next(self.selected_ents) and not self.action_thread then
    --         self:ApplyToSelection()
    --     end
    -- end

    local RepeatRecipe = self.RepeatRecipe
    self.RepeatRecipe = function(self, builder, recipe, skin, ...)
        local rt = RepeatRecipe(self, builder, recipe, skin, ...)
        self.crafting_recipe_data = {is_recipe = true, builder = builder, recipe = recipe, skin = skin}
        if self:ShouldActivateEndlessRepeat() then
            self:EndlessRepeat(self.crafting_recipe_data)
        end
        return rt
    end

    local ApplyToSelection = self.ApplyToSelection
    self.ApplyToSelection = function(self, ...)
        if self:IsSelectedEntity(self.inst) then
            local active_item = self:GetActiveItem()
            if active_item then
                if active_item:HasTag("fish") then
                    self:StartFishKiller(active_item)
                    return
                elseif active_item.prefab == "pocketwatch_heal" then
                    self:RepeatCastWatch(active_item)
                    return
                end
            end
        end
        return ApplyToSelection(self, ...)
    end

    local action_thread_id = getval(ApplyToSelection, "action_thread_id") or "actionqueue_action_thread"

    self.StartActionThread = function(self, fn)
        self.action_thread = GLOBAL.StartThread(function()
            self.inst:ClearBufferedAction()
            fn()
            self:ClearActionThread()
            self:TryReusmeActionThread()
        end, action_thread_id)
    end

    local function not_stack_full(item)
        return not (item.replica.stackable ~= nil and item.replica.stackable:IsFull())
    end

    local function IsInventoryFull()
        local inv = self.inst.replica.inventory
        if not inv:IsFull() then
            return false
        end
        local overflow = inv:GetOverflowContainer()
        return not overflow or overflow:IsFull()
    end

    local function IsItemOwned(item)
        return item
            and item:IsValid()
            and item.replica.inventoryitem
            and item.replica.inventoryitem:IsHeldBy(self.inst)
    end

    self.StartFishKiller = function(self, start_item)
        self:StartActionThread(function()
            while self.inst:IsValid() do
                local final_item
                local active_item = self:GetActiveItem()
                if IsRightItem(active_item, start_item) then
                    final_item = active_item
                else
                    local item, inv, slot = self:GetItem(start_item.prefab)
                    if not item then break end
                    if active_item
                        and active_item:HasTag("fishmeat")
                        and IsInventoryFull()
                        and not self:GetItem(active_item.prefab, not_stack_full, true) then

                        -- inv:SwapActiveItemWithSlot(slot)
                        GLOBAL.SendRPCToServer(GLOBAL.RPC.SwapActiveItemWithSlot, slot)
                    end
                    final_item = item
                end
                repeat
                    UseItemOnSelf(final_item)
                    GLOBAL.Sleep(self.action_delay)
                until not IsItemOwned(final_item)
            end
            self:DeselectEntity(self.inst)
        end)
    end

    local function is_inactivate_watch(item)
        return item:HasTag("pocketwatch_inactive")
    end

    self.RepeatCastWatch = function(self, watch)
        self:StartActionThread(function()
            repeat
                UseItemOnSelf(watch)
                GLOBAL.Sleep(self.action_delay)
                if not (IsItemOwned(watch) and watch:HasTag("pocketwatch_inactive")) then
                    watch = self:GetItem(watch.prefab, is_inactivate_watch)
                end
            until not (watch and self.inst:IsValid())
            self:DeselectEntity(self.inst)
        end)
    end

    self.RepeatCastSpellAtPoint = function(self, pos)
        self:StartActionThread(function()
            local equip_item = self:GetEquippedItemInHand()
            local equip_prefab = equip_item.prefab
            local act = GLOBAL.BufferedAction(GLOBAL.ThePlayer, nil, GLOBAL.ACTIONS.CASTSPELL, equip_item, pos)
            repeat
                self:SendActionAndWait(act, true)
                equip_item = self:GetEquippedItemInHand() or self:GetNewEquippedItemInHand(equip_prefab)
                act.invobject = equip_item
            until not self.inst:IsValid() or not IsRightItem(equip_item, equip_prefab)
        end)
    end

    local OnUp = self.OnUp
    self.OnUp = function(self, rightclick, ...)
        if self.clicked
            and not self.action_thread
            and not self:IsWalkButtonDown() then

            if self:ShouldActivateEndlessRepeat() and GLOBAL.next(self.selected_ents) then
                self:EndlessRepeat()
            elseif rightclick and not GLOBAL.next(self.selected_ents) and not self:GetActiveItem() then
                local equip_item = self:GetEquippedItemInHand()
                if equip_item then
                    if has_component(equip_item, "farmtiller") or has_component(equip_item, "quagmire_tiller") then
                        self:ClearSelectionThread()
                        self.clicked = false
                        self:DeployToSelection(self.TillAtPoint, tilling_spacing)
                        return
                    elseif has_component(equip_item, "wateryprotection") then
                        self:ClearSelectionThread()
                        self.clicked = false
                        if not self.TL then
                            self:StartActionThread(function()
                                self:TerraformAtPoint(TheInput:GetWorldPosition(), equip_item)
                            end)
                        else
                            self:DeployToSelection(self.TerraformAtPoint, GLOBAL.TILE_SCALE, equip_item) -- Use TerraformAtPoint is bc wanna trigger DeployToSelection's GetAccessibleTilePosition function
                        end
                        return
                    elseif not self.TL and has_component(equip_item, "spellcaster") and equip_item:HasTag("castonpoint") then
                        local ent = not GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_CTRL) and GLOBAL.TheInput:GetWorldEntityUnderMouse()
                        local pos = ent and ent:GetPosition() or GLOBAL.TheInput:GetWorldPosition()
                        local actions
                            actions = self.inst.components.playeractionpicker:GetPointActions(pos, equip_item,true, ent)
                        if has_action(actions, "CASTSPELL") then
                            self:ClearSelectionThread()
                            self.clicked = false
                            self:RepeatCastSpellAtPoint(pos)
                            return
                        end
                    end
                end
            end

        end
        return OnUp(self, rightclick, ...)
    end

    if self.AddModCherryPickFn then
        self:AddModCherryPickFn(function(ent)
            return IsRightItem(ent.prefab, self.last_click.prefab)
        end)
    else
        local CherryPick = self.CherryPick
        self.CherryPick = function(self, rightclick, ...)
            local current_time = GLOBAL.GetTime()
            if current_time - self.last_click.time < self.double_click_speed and self.last_click.prefab then
                local x, _, z = self.last_click.pos:Get()
                for _, ent in pairs(GLOBAL.TheSim:FindEntities(x, 0, z, self.double_click_range, nil, unselectable_tags)) do
                    if IsRightItem(ent.prefab, self.last_click.prefab) and IsValidEntity(ent) and not self:IsSelectedEntity(ent) then -- Changed Part
                        local act, rightclick_ = self:GetAction(ent, rightclick)
                        if act and act.action == self.last_click.action then
                            self:SelectEntity(ent, rightclick_)
                        end
                    end
                end
                self.last_click.prefab = nil
                return
            end
            return CherryPick(self, rightclick, ...)
        end
    end

    self.GetItem = function(self, prefab, test_fn, no_open_containers)
        local containers = {}
        local inventory = self.inst.replica.inventory
        table.insert(containers, inventory)
        local backpack = inventory:GetOverflowContainer()
        if backpack then
            table.insert(containers, backpack)
        end
        if allow_all_open_containers and not no_open_containers then
            local open_containers = inventory:GetOpenContainers()
            if open_containers then
                for container in pairs(open_containers) do
                    local container_replica = container.replica.container
                    if container_replica and container_replica ~= backpack then
                        table.insert(containers, container_replica)
                    end
                end
            end
        end
        -- Make its order like: inventory -> backpack -> other opened containers
        for _, inv in ipairs(containers) do
            local items = inv:GetItems()
            for slot, item in orderedPairs(items) do
                if IsRightItem(item.prefab, prefab) and (test_fn == nil or test_fn(item, inv, slot)) then
                    items.__orderedIndex = nil
                    return item, inv, slot
                end
            end
        end
    end

    self.GetNewActiveItem = function(self, prefab, test_fn) -- Override
        local item, inv, slot = self:GetItem(prefab, test_fn)
        if item then
            inv:TakeActiveItemFromAllOfSlot(slot)
        end
        return item
    end

    self.GetNewEquippedItemInHand = function(self, prefab, test_fn) -- Override
        local item = self:GetItem(prefab, test_fn)
        if item then
            self.inst.replica.inventory:UseItemFromInvTile(item)
        end
        return item
    end

    local SendAction = self.SendAction
    self.SendAction = function(self, act, rightclick, target, ...)
        if act.action == GLOBAL.ACTIONS.DEPLOY and act.invobject and act.invobject:HasTag("tile_deploy") then
            act.action = GLOBAL.ACTIONS.DEPLOY_TILEARRIVE
        end
        return SendAction(self, act, rightclick, target, ...)
    end

    local function try_resume()
        if GLOBAL.next(self.selected_ents) then
            self:ApplyToSelection()
        end
    end

    self.TryReusmeActionThread = function(self)
        self.inst:DoTaskInTime(0, try_resume)
    end

    self.ClearEndlessRepeatThread = function(self, no_talking)
        if self.endless_repeat_thread then
            GLOBAL.KillThreadsWithID(self.endless_repeat_thread.id)
            self.endless_repeat_thread:SetList(nil)
            self.endless_repeat_thread = nil
        end
        if self.endless_repeat then
            self.endless_repeat = false
            if not no_talking then
                self.inst.components.talker:Say("Endless repeat: false")
            end
        end
    end

    local ClearActionThread = self.ClearActionThread
    self.ClearActionThread = function(self, ...)
        self.crafting_recipe_data = nil
        return ClearActionThread(self, ...)
    end

    local ClearAllThreads = self.ClearAllThreads
    self.ClearAllThreads = function(self, ...)
        self:ClearEndlessRepeatThread()
        return ClearAllThreads(self, ...)
    end

    GLOBAL.TheInput:AddKeyUpHandler(GetModConfigData("tony_endless_repeat_key"), function()
        if self.endless_repeat then
            self:ClearEndlessRepeatThread()
            TIP("无尽重复模式","white","关闭")
        else
            if self.action_thread then
                if self.crafting_recipe_data then
                    self:EndlessRepeat(self.crafting_recipe_data)
                elseif GLOBAL.next(self.selected_ents) then
                    self:EndlessRepeat()
                end
            end
            self.endless_repeat = true
            TIP("无尽重复模式","white","开启")
        end
    end)

    -- 移除,几乎不用的功能,代替框选
    -- GLOBAL.TheInput:AddKeyUpHandler(GetModConfigData("LC_select_nearby_ents_key"), function()
    --     self:SelectAllNearbyEnts(TheInput:IsKeyDown(KEY_LSHIFT))
    -- end)

    InterruptedByMobile(function()
        return self.endless_repeat_thread
    end, function ()
        self:ClearEndlessRepeatThread()
    end)

end)
