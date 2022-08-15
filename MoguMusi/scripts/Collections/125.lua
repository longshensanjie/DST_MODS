local dyeing_containers = {}
local function ModifyContainerColor(container, reset)
    if container and container.AnimState then
        if reset then
            container.AnimState:SetAddColour(0, 0, 0, 0)
            -- container.AnimState:SetMultColour(1,1,1,1)
        else
            container.AnimState:SetAddColour(0, 255, 0, 0)
            -- container.AnimState:SetMultColour(0,1,0,1)
            table.insert(dyeing_containers, container)
        end
    end
end


local function ClearAllContainersColor()
    for _, dye_cont in pairs(dyeing_containers)do
        ModifyContainerColor(dye_cont, true)
    end
    dyeing_containers = {}
end

local function ShowMeetContainersWithPrefab(prefab)
    ClearAllContainersColor()
    local pos = GLOBAL.ThePlayer:GetPosition()
    if not pos then
        return
    end
    local all_ents = GLOBAL.TheSim:FindEntities(pos.x,0,pos.z, 40, nil, {'FX','DECOR','INLIMBO','NOCLICK'})
    for _,ent in pairs(all_ents)do
        if ent.prefab == prefab then
            ModifyContainerColor(ent, false)
        end
    end
end


AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(2.6, function()
        if inst == GLOBAL.ThePlayer then
            inst:ListenForEvent("refreshinventory", function()
                if GLOBAL.ThePlayer and GLOBAL.ThePlayer.replica.inventory then
                    local active_item = GLOBAL.ThePlayer.replica.inventory:GetActiveItem()
                    if active_item then
                        ShowMeetContainersWithPrefab(active_item.prefab)
                    else
                        ClearAllContainersColor()
                    end
                end
            end)
        end
    end)
end)



