AddPrefabPostInit("inventory_classified", function(inst)
    if not GLOBAL.TheWorld or (GLOBAL.TheWorld and GLOBAL.TheWorld.ismastersim) then
        return
    end

    local function Count(item)
        return item.replica.stackable ~= nil and item.replica.stackable:StackSize() or 1
    end

    local function GetOverflowContainer(inst)
        if inst.ignoreoverflow then
            return
        end
        local item = inst.GetEquippedItem(inst,GLOBAL.EQUIPSLOTS.BACK or GLOBAL.EQUIPSLOTS.BODY)
        return item ~= nil and item.replica.container or nil
    end
    inst.GetOverflowContainer = GetOverflowContainer

    inst.Has = function(inst, prefab, amount, checkallcontainers)
        local count =
            inst._activeitem ~= nil and
            inst._activeitem.prefab == prefab and
            Count(inst._activeitem) or 0

        if inst._itemspreview ~= nil then
            for i, v in ipairs(inst._items) do
                local item = inst._itemspreview[i]
                if item ~= nil and item.prefab == prefab then
                    count = count + Count(item)
                end
            end
        else
            for i, v in ipairs(inst._items) do
                local item = v:value()
                if item ~= nil and item ~= inst._activeitem and item.prefab == prefab then
                    count = count + Count(item)
                end
            end
        end

        local overflow = GetOverflowContainer(inst)
        if overflow ~= nil then
            local overflowhas, overflowcount = overflow:Has(prefab, amount)
            count = count + overflowcount
        end

        if checkallcontainers then
            local inventory_replica = inst and inst._parent and inst._parent.replica.inventory
            local containers = inventory_replica and inventory_replica:GetOpenContainers()

            if containers then
                for container_inst in pairs(containers) do
                    local container = container_inst.replica.container or container_inst.replica.inventory
                    if container and container ~= overflow and not container.excludefromcrafting then
                        local containerhas, containercount = container:Has(prefab, amount)
                        count = count + containercount
                    end
                end
            end
        end

        return count >= amount, count
    end
end)
