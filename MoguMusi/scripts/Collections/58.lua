local drop_options_cfg = GetModConfigData("tony_repeat")
local double_click_scene_drop = true
local drop_on_grid = drop_options_cfg == "drop_on_grid"
local drop_on_grid_leftclick = drop_on_grid or drop_options_cfg == "drop_on_grid_leftclick"

local workingthread

local function StopThread()
    if workingthread then
        workingthread:SetList(nil)
    end
    workingthread = nil
end

local function DropActiveItemOnPoint(pos, active_item, single)
    local playercontroller = GLOBAL.ThePlayer.components.playercontroller

    local control_mod = single and 10 or 0
    local act = GLOBAL.BufferedAction(GLOBAL.ThePlayer, nil, GLOBAL.ACTIONS.DROP, active_item, pos)
    act.options.wholestack = not single

    if playercontroller.locomotor then
        --act.options.wholestack = not TheInput:IsControlPressed(CONTROL_FORCE_STACK)
        act.preview_cb = function()
            GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, GLOBAL.ACTIONS.DROP.code, pos.x, pos.z, nil, true, control_mod, nil, act.action.mod_name)
        end
        playercontroller:DoAction(act)
    else
        GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, GLOBAL.ACTIONS.DROP.code, pos.x, pos.z, nil, true, control_mod, act.action.canforce, act.action.mod_name)
    end
end

local function DropActiveItemOnGrid(pos, active_item, single)
    pos.x, pos.z = math.floor(pos.x) + 0.5, math.floor(pos.z) + 0.5
    DropActiveItemOnPoint(pos, active_item, single)
end

local function DropItemFromSlot(slot, item, single)
    local inventory = GLOBAL.ThePlayer.replica.inventory
    local inventoryitem = item.replica.inventoryitem
    if drop_on_grid
        and not inventory:GetActiveItem()
        and inventoryitem:CanGoInContainer()
        and not inventoryitem:CanOnlyGoInPocket() then

        if slot.equipslot then
            inventory:TakeActiveItemFromEquipSlot(slot.equipslot)
        elseif slot.num then
            slot.container:TakeActiveItemFromAllOfSlot(slot.num)
        end
        DropActiveItemOnGrid(GLOBAL.ThePlayer:GetPosition(), item, single)
    else
        inventory:DropItemFromInvTile(item, single)
        return true
    end
end

local function GetItem(src_container, item)
    local inv = GLOBAL.ThePlayer.replica.inventory
    local containers = { src_container }

    if src_container.inst == GLOBAL.ThePlayer then
        table.insert(containers, inv:GetOverflowContainer())
    elseif src_container.inst:HasTag("backpack") then
        table.insert(containers, inv)
    end
    table.insert(containers, inv:GetActiveItem())

    return GetItemFromContainers(containers, item)
end

local function fn(src_item, src_slot, src_container, single, grid_drop, override_pos)

    if not src_item or workingthread then return end

    local inv = GLOBAL.ThePlayer.replica.inventory

    workingthread = GLOBAL.ThePlayer:StartThread(function()
        while GLOBAL.ThePlayer:IsValid() do
            local item, slot, container
            if src_container:IsHolding(src_item) then
                item, slot, container = src_item, src_slot, src_container
            else
                item, slot, container = GetItem(src_container, src_item)
            end
            if not item then break end
            local inventoryitem = item.replica.inventoryitem

            if inventoryitem:CanGoInContainer()
                and (
                    override_pos
                    or grid_drop
                        and not inv:GetActiveItem()
                        and not inventoryitem:CanOnlyGoInPocket()
                ) then

                if type(slot) == "string" then
                    container:TakeActiveItemFromEquipSlot(slot)
                elseif type(slot) == "number" then
                    container:TakeActiveItemFromAllOfSlot(slot)
                end
                local pos = override_pos or GLOBAL.ThePlayer:GetPosition()
                local drop_fn = grid_drop and DropActiveItemOnGrid or DropActiveItemOnPoint
                repeat
                    drop_fn(pos, item, single)
                    GLOBAL.Sleep(3 * GLOBAL.FRAMES)
                until not inv:IsHolding(item)
            else
                inv:DropItemFromInvTile(item, single)
            end
            GLOBAL.Sleep(2 * GLOBAL.FRAMES)
        end
        StopThread()
    end)

end

InterruptedByMobile(function ()
    return workingthread
end, StopThread)

local last_rightclick_time = 0
local last_rightclick_inv
local last_rightclick_item
local last_time_no_grid_drop
local function InvSlotPostInit(self)
    local InvSlotOnControl = self.OnControl
    self.OnControl = function(self, control, down, ...)
        if down and GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_TRADE) and control == GLOBAL.CONTROL_SECONDARY then
            local current_time = GLOBAL.GetTime()
            local single = GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_STACK)
            --ThePlayer.replica.inventory:DropItemFromInvTile(self.tile.item, single)

            if InDoubleClickTime(current_time, last_rightclick_time) and last_rightclick_inv == self and last_rightclick_item then
                --DropItemFromSlot(self, last_rightclick_item, single)
                fn(
                    last_rightclick_item,
                    self.num or self.equipslot,
                    self.container or self.equipslot and GLOBAL.ThePlayer.replica.inventory,
                    single,
                    drop_on_grid and not last_time_no_grid_drop
                )
            end
            last_rightclick_time = current_time
            last_rightclick_inv = self
            last_rightclick_item = self.tile and self.tile.item

            if self.tile then
                last_time_no_grid_drop = DropItemFromSlot(self, self.tile.item, single)
            end
            return true
        end
        return InvSlotOnControl(self, control, down, ...)
    end
end

local function PlayerControllerPostInit(self, inst)
    if inst ~= GLOBAL.ThePlayer then return end
    local PlayerControllerOnLeftClick = self.OnLeftClick
    self.OnLeftClick = function(self, down, ...)
        if not down or GLOBAL.TheInput:GetHUDEntityUnderMouse() or self:IsAOETargeting() or self.placer_recipe then
            return PlayerControllerOnLeftClick(self, down, ...)
        end
        local act = self:GetLeftMouseAction()
        if act then
            if act.action == GLOBAL.ACTIONS.DROP then
                local active_item = GLOBAL.ThePlayer.replica.inventory:GetActiveItem()
                if active_item then
                    DropActiveItemOnGrid(GLOBAL.TheInput:GetWorldPosition(), active_item, not act.options.wholestack)
                    return
                end
            end
        end
        return PlayerControllerOnLeftClick(self, down, ...)
    end
end

-- Because I need to override Advanced Controls's this part
local function DelayPostInit(fn)
    return function(self, ...)
        self.inst:DoTaskInTime(0, function(inst, ...)
            fn(...)
        end, self, ...)
    end
end

AddClassPostConstruct("widgets/invslot", DelayPostInit(InvSlotPostInit))
AddClassPostConstruct("widgets/equipslot", DelayPostInit(InvSlotPostInit))
if drop_on_grid_leftclick then
    AddComponentPostInit("playercontroller", DelayPostInit(PlayerControllerPostInit))
end

if double_click_scene_drop then
    local last_scene_drop_time = 0
    GLOBAL.TheInput:AddControlHandler(GLOBAL.CONTROL_PRIMARY, function(down)
        if not down and not workingthread and InGame() and not GLOBAL.TheInput:GetHUDEntityUnderMouse() and GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_SHIFT) then
            local active_item = GLOBAL.ThePlayer.replica.inventory:GetActiveItem()
            if not active_item then return end
            local current_time = GLOBAL.GetTime()
            if InDoubleClickTime(current_time, last_scene_drop_time)
                and not (GLOBAL.ThePlayer.components.actionqueuer and GLOBAL.next(GLOBAL.ThePlayer.components.actionqueuer.selected_ents)) then

                fn(
                    active_item,
                    nil,
                    GLOBAL.ThePlayer.replica.inventory,
                    GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_STACK),
                    drop_on_grid_leftclick,
                    GLOBAL.TheInput:GetWorldPosition()
                )
            end
            last_scene_drop_time = current_time
        end
    end)
    -- Using control handler is basically because wanna compatible with ActionQueue Reborn
end
