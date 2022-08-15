local bundle_first = GetModConfigData("tony_bundle_first") ~= 3
local stewer_first = GetModConfigData("tony_bundle_first") ~= 2



AddClassPostConstruct("widgets/invslot", function(self, inst)

    local FindBestContainer
    local i = 1
    repeat
        local name, val = GLOBAL.debug.getupvalue(self.TradeItem, i)
        if name then
            --print ("index", i, name, "=", val)
            if name == "FindBestContainer" then
                FindBestContainer = val
                break
            end
            i = i + 1
        end
    until not name
    if not FindBestContainer then return end

    self.TradeItem = function(self, stack_mod)
        local slot_number = self.num
        local character = GLOBAL.ThePlayer
        local inventory = character and character.replica.inventory or nil
        local container = self.container
        local container_item = container and container:GetItemInSlot(slot_number) or nil

        if character ~= nil and inventory ~= nil and container_item ~= nil then
            local opencontainers = inventory:GetOpenContainers()
            if GLOBAL.next(opencontainers) == nil then
                return
            end

            local overflow = inventory:GetOverflowContainer()
            local backpack = nil
            if overflow ~= nil and overflow:IsOpenedBy(character) then
                backpack = overflow.inst
                overflow = backpack.replica.container
                if overflow == nil then
                    backpack = nil
                end
            else
                overflow = nil
            end

            -- Changed Part
            local bundles = {}
            for k in pairs(opencontainers) do
                if k:HasTag("bundle") then
                    bundles[k] = true
                end
            end
            local stewers = {}
            for k in pairs(opencontainers) do
                if k:HasTag("stewer") then
                    stewers[k] = true
                end
            end
            -- Changed Part

            --find our destination container
            local dest_inst = nil
            if container == inventory then
                local playercontainers = backpack ~= nil and { [backpack] = true } or nil
                dest_inst = bundle_first and FindBestContainer(self, container_item, bundles) -- Changed Part
                    or stewer_first and FindBestContainer(self, container_item, stewers)      -- Changed Part
                    or FindBestContainer(self, container_item, opencontainers, playercontainers)
                    or FindBestContainer(self, container_item, playercontainers)
            elseif container == overflow then
                dest_inst = bundle_first and FindBestContainer(self, container_item, bundles) -- Changed Part
                    or stewer_first and FindBestContainer(self, container_item, stewers)      -- Changed Part
                    or FindBestContainer(self, container_item, opencontainers, { [backpack] = true })
                    or (inventory:IsOpenedBy(character)
                        and FindBestContainer(self, container_item, { [character] = true })
                        or nil)
            else
                local exclude_containers = { [container.inst] = true }
                if backpack ~= nil then
                    exclude_containers[backpack] = true
                end
                dest_inst = FindBestContainer(self, container_item, opencontainers, exclude_containers)
                if dest_inst == nil then
                    local playercontainers = {}
                    if inventory:IsOpenedBy(character) then
                        playercontainers[character] = true
                    end
                    if backpack ~= nil then
                        playercontainers[backpack] = true
                    end
                    dest_inst = FindBestContainer(self, container_item, playercontainers)
                end
            end

            --if a destination container/inv is found...
            if dest_inst ~= nil then
                if stack_mod and
                    container_item.replica.stackable ~= nil and
                    container_item.replica.stackable:IsStack() then
                    container:MoveItemFromHalfOfSlot(slot_number, dest_inst)
                else
                    container:MoveItemFromAllOfSlot(slot_number, dest_inst)
                end
                TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/click_object")
            else
                TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/click_negative")
            end
        end
    end

end)
