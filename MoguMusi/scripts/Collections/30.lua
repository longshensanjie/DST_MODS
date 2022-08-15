local lantern_list = {"lantern", "myth_redlantern", "pumpkin_lantern", "redlantern", "miniboatlantern", "bottlelantern"}
local fireSource_list = {"dragonflyfurnace", "stafflight", "staffcoldlight","moonbase"}
local heat_list = {"heatrock", "icire_rock"}
local fireSource_range = 3

local function Drop()
    -- if not _G.ThePlayer then return end
    if InGame() then
        local items = GetItemsFromAll()
        local drop_sth
        for _,item in pairs(items)do
            if item.prefab and table.contains(lantern_list, item.prefab) then
                drop_sth = item
                break
            end
        end
        local pos = GLOBAL.ThePlayer:GetPosition()
        if GLOBAL.FindEntity(GLOBAL.ThePlayer, fireSource_range, function(inst) return table.contains(fireSource_list, inst.prefab) end) -- 附近有指定热源
        or (pos and (not IsEmpty(GLOBAL.TheSim:FindEntities(pos.x, 0, pos.z, fireSource_range, {"plant", "fire"}, {"INLIMBO", "FX"}))    -- 附近有燃烧的植物（排除拿火把打生物）
        or not IsEmpty(GLOBAL.TheSim:FindEntities(pos.x, 0, pos.z, fireSource_range, {"campfire", "fire"}, {"INLIMBO", "FX"}))))         -- 附近有燃烧的营火
        then
            for _,item in pairs(items)do
                if item.prefab and table.contains(heat_list, item.prefab) then
                    drop_sth = item
                    break
                end
            end
        end
        if drop_sth then
            GLOBAL.ThePlayer.replica.inventory:DropItemFromInvTile(drop_sth)
        end
    end
end

GLOBAL.TheInput:AddKeyDownHandler(GetModConfigData("sw_lantern"), Drop)
