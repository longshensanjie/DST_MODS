local instant_move = true
local autowrap = GetModConfigData("tony_doublego") == "autowrap"
local batch_move_stewer = GetModConfigData("tony_doublego") == "stewer"
local IsRightItem = morph_checker_IsRightItem

local AUTOWRAP_SLEEP_TIME = GLOBAL.FRAMES * 3

local workingthread

local last_leftclick_time = 0
local last_leftclick_item
local last_leftclick_inv
local go_to_container

local function try_auto_wrap(container)
    local container_inst = container.inst
    if container_inst:HasTag("bundle") and container:IsFull() then
        local button_fn = container.widget and container.widget.buttoninfo and container.widget.buttoninfo.fn
        if button_fn then
            local first_item
            for _, v in pairs(container:GetItems()) do
                if first_item == nil then
                    first_item = v
                elseif not IsRightItem(v, first_item) then
                    return
                end
                if (v.replica.stackable and not v.replica.stackable:IsFull())
                    or (
                        v.replica.inventoryitem.classified
                        and v.replica.inventoryitem.classified.percentused:value() ~= 100 -- Full durability
                        and v.replica.inventoryitem.classified.percentused:value() ~= 255 -- Default value
                    ) then

                    return
                end
            end
            if GLOBAL.TheWorld.ismastersim then GLOBAL.Sleep(AUTOWRAP_SLEEP_TIME) end -- If not, you won't even be able to see items go into the bundle
            repeat
                button_fn(container_inst, GLOBAL.ThePlayer)
                GLOBAL.Sleep(AUTOWRAP_SLEEP_TIME)
            until not (container_inst:IsValid() and container_inst.replica.container)
        end
    end
end

local function StopThread()
    if workingthread then
        workingthread:SetList(nil)
    end
    workingthread = nil
end

local function fn(item, from_container, to_container)

    if not item or workingthread then return end

    local function GetItem(extracontainers)
        if instant_move then
            return GetItemFromContainers(JoinArrays({from_container}, extracontainers), item, true)
        else
            local item, slot, container = GetItemFromContainers(JoinArrays({from_container}, extracontainers), item)
            return item and {item = item, slot = slot, container = container}
        end
    end

    if to_container == GLOBAL.ThePlayer then
        to_container = GLOBAL.ThePlayer.replica.inventory
    elseif to_container.replica then
        to_container = to_container.replica.container
    end

    workingthread = GLOBAL.ThePlayer:StartThread(function()

        while GLOBAL.ThePlayer:IsValid() do

            local item_info = nil -- For normal move
            local items = nil     -- For instant move

            local inventory = GLOBAL.ThePlayer.replica.inventory
            local backpack = inventory:GetOverflowContainer()

            local extracontainers = {}
            if to_container.inst:HasTag("bundle") then
                local containers = inventory:GetOpenContainers()
                table.insert(extracontainers, inventory)
                for k in pairs(containers) do
                    if not k:HasTag("bundle") and k.replica.container then
                        table.insert(extracontainers, k.replica.container)
                    end
                end
            elseif from_container == inventory and not to_container.inst:HasTag("backpack") then
                extracontainers = { backpack }
            elseif from_container.inst:HasTag("backpack") and to_container ~= inventory then
                extracontainers = { inventory }
            end

            if instant_move then
                items = GetItem(extracontainers)
            else
                item_info = GetItem(extracontainers)
            end

            if item_info and item_info.container then
                from_container = item_info.container
            end

            if item_info or items then

                local cur_items = instant_move and items or {item_info}
                if IsValidContainer(to_container, cur_items) then
                    if instant_move then
                        for _, data in ipairs(items) do
                            local slot = data.slot
                            local f_container = data.container
                            if f_container == GLOBAL.ThePlayer then
                                GLOBAL.SendRPCToServer(GLOBAL.RPC.MoveInvItemFromAllOfSlot, slot, to_container.inst)
                            else
                                GLOBAL.SendRPCToServer(GLOBAL.RPC.MoveItemFromAllOfSlot, slot, f_container, to_container.inst)
                            end
                        end
                    else
                        from_container:MoveItemFromAllOfSlot(item_info.slot, to_container.inst)
                    end
                elseif to_container == inventory and not from_container.inst:HasTag("backpack") then
                    if backpack and IsValidContainer(backpack, cur_items) then
                        to_container = backpack
                    else
                        break
                    end
                elseif to_container.inst:HasTag("backpack") and from_container ~= inventory then
                    if IsValidContainer(inventory, cur_items) then
                        to_container = inventory
                    else
                        break
                    end
                else
                    break
                end

            else

                if to_container.inst == GLOBAL.ThePlayer or to_container.inst:HasTag("backpack") then
                    break
                end
                local active_item = inventory:GetActiveItem()
                if active_item and IsRightItem(active_item, item) and IsValidContainer(to_container, {{item = active_item}}) then
                    for i = 1, to_container:GetNumSlots() do
                        local container_item = to_container:GetItemInSlot(i)
                        if container_item == nil then
                            to_container:PutAllOfActiveItemInSlot(i)
                        elseif to_container:AcceptsStacks()
                            and container_item.prefab == active_item.prefab
                            and container_item.AnimState:GetSkinBuild() == active_item.AnimState:GetSkinBuild()
                            and container_item.replica.stackable ~= nil and not container_item.replica.stackable:IsFull() then

                            to_container:AddAllOfActiveItemToSlot(i)
                        end
                    end
                else
                    break
                end

            end

            Yield()

        end

        if autowrap then try_auto_wrap(to_container) end

        StopThread()

    end)
    
end

InterruptedByMobile(function ()
    return workingthread
end, StopThread)

local function InvSlotPostInit(self)
    local InvSlotOnControl = self.OnControl
    self.OnControl = function(self, control, down, ...)
        if down and control == GLOBAL.CONTROL_ACCEPT and GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_TRADE) then
            local current_time = GLOBAL.GetTime()
            if go_to_container and go_to_container:IsValid()
                and (batch_move_stewer or not go_to_container:HasTag("stewer"))
                and InDoubleClickTime(current_time, last_leftclick_time)
                and last_leftclick_inv == self then

                fn(last_leftclick_item, self.container, go_to_container)
            end
            last_leftclick_time = current_time
            last_leftclick_inv = self
            last_leftclick_item = self.tile and self.tile.item
        end
        return InvSlotOnControl(self, control, down, ...)
    end
end

AddClassPostConstruct("widgets/invslot", InvSlotPostInit)

local function InvContainerPostInit(self)
    local MoveItemFromAllOfSlot = self.MoveItemFromAllOfSlot
    self.MoveItemFromAllOfSlot = function(self, slot, container, ...)
        go_to_container = container
        return MoveItemFromAllOfSlot(self, slot, container, ...)
    end
end

AddClassPostConstruct("components/inventory_replica", InvContainerPostInit)
AddClassPostConstruct("components/container_replica", InvContainerPostInit)

if autowrap then
    local function func()
        if not InGame() then return end
        local hud = GLOBAL.ThePlayer.HUD

        for container in pairs(hud.controls.containers) do
            if container:HasTag("bundle") then
                local widget = container.replica.container:GetWidget()
                if widget.buttoninfo
                    and widget.buttoninfo.fn
                    and (not widget.buttoninfo.validfn or widget.buttoninfo.validfn(container)) then

                    widget.buttoninfo.fn(container, GLOBAL.ThePlayer)
                end
                break
            end
        end
    end
    GLOBAL.TheInput:AddKeyUpHandler(32, func)
end