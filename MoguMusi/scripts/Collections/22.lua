
local _G = GLOBAL
if _G.TheNet:IsDedicated() or _G.TheNet:GetServerGameMode() == "lavaarena" then return end

local require = _G.require
local unpack = _G.unpack
local FindEntity = _G.FindEntity
local Vector3 = _G.Vector3

local PersistentMapIcons = require("widgets/persistentmapicons")
local WormHoleData = "WH"

local SHOW_NUMBERS = "num_"
local ICON_STYLE = "new"
local wormhole_path = "images/wormhole_"..SHOW_NUMBERS..ICON_STYLE
local tentapillar_path = "images/tentapillar_"..SHOW_NUMBERS..ICON_STYLE


AddMinimapAtlas(wormhole_path..".xml")
AddMinimapAtlas(tentapillar_path..".xml")

local WormholePositions = {}
local world_key
local function SaveWormholePositions()
    local s_list = {}
    for i, pos in ipairs(WormholePositions) do
        s_list[i] = {x = pos.x, y = pos.y, z = pos.z}
    end
    if world_key then
        SaveModData(WormHoleData..world_key, s_list)
    end
end

local function LoadWormholePositions()
    if not world_key then return end
    local s_list = LoadModData(WormHoleData..world_key)
    if s_list then
        for i, pos in ipairs(s_list) do
            WormholePositions[i] = Vector3(pos.x, pos.y, pos.z)
            print("[虫洞标记] Loaded icon at "..tostring(WormholePositions[i]))
        end
    end
end

local function WormholePositionExists(new_pos)
    for i, pos in ipairs(WormholePositions) do
        if pos:__eq(new_pos) then return i end
    end
    return false
end

local function AddWormholePosition(pos)
    table.insert(WormholePositions, pos)
    print("[虫洞标记] 添加了图标在世界位置： "..tostring(pos))
end

local texture, xml_path
AddSimPostInit(function()
    local TheWorld = _G.TheWorld
    local cave = TheWorld:HasTag("cave")
    world_key = GetWorldSeed()
    texture = cave and "tentapillar_" or "wormhole_"
    xml_path = cave and tentapillar_path or wormhole_path
    LoadWormholePositions()
    -- print("[虫洞标记] World Key: "..world_key)
end)

AddClassPostConstruct("widgets/mapwidget", function(self)
    self.wormholeicons = self:AddChild(PersistentMapIcons(self))
    for i, pos in ipairs(WormholePositions) do
        local key = math.ceil(i / 2)
        self.wormholeicons:AddMapIcon(xml_path..".xml", texture..key..".tex", pos)
    end
end)

local function RGB(r, g, b)
    return {r / 255, g / 255, b / 255, 1}
end

local colors = {
    RGB(255, 0, 32),    -- red
    RGB(0, 225, 255),   -- teal
    RGB(96, 64, 255),   -- purple
    RGB(0, 255, 75),    -- green
    RGB(255, 75, 0),    -- orange
    RGB(0, 128, 255),   -- blue
    RGB(96, 200, 32),   -- lime
    RGB(255, 32, 128),  -- pink
    RGB(182, 255, 0),   -- yellow
    RGB(64, 64, 64),    -- gray
}

local WORLD_COLORS = true
local WORLD_NUMBERS = true
local WORMHOLE_BORDER = true
local MINIMAP_ICONS = true
local function AddWormholeColor(inst, pos)
    if not inst or not inst:IsValid() or not pos or inst.color_done then return end
    local i = WormholePositionExists(pos)
    if not i then return end
    local key = math.ceil(i / 2)
    if key > 10 then return end
    if WORLD_COLORS then
        local add_color = 0.15
        inst.AnimState:SetAddColour(add_color, add_color, add_color, 0)
        inst.AnimState:OverrideMultColour(unpack(colors[key]))
    end
    if WORLD_NUMBERS then
        local label = inst.entity:AddLabel()
        label:SetFont(_G.CHATFONT_OUTLINE)
        label:SetFontSize(35)
        label:SetWorldOffset(0, 2, 0)
        local num = key == 10 and 0 or key
        label:SetText(" "..num.." ")
        label:SetColour(unpack(colors[key]))
        label:Enable(true)
    end
    if WORMHOLE_BORDER then
        if inst.prefab == "wormhole" then
            inst.AnimState:SetLayer(_G.LAYER_WORLD_BACKGROUND)
        end
        inst.border_circle = inst:SpawnChild("border_circle")
        inst.border_circle.AnimState:SetAddColour(unpack(colors[key]))
    end
    if MINIMAP_ICONS then
        inst.MiniMapEntity:SetIcon(texture..key..".tex")
    end
    inst.color_done = true
end

local wormhole_types = {tentacle_pillar_hole = true, tentacle_pillar = true, wormhole = true, ndpr_wormhole = true,
--  bermudatriangle = true  -- 电光三角并不是虫洞跳跃事件, 我认为这是岛屿冒险的问题
}
for prefab in pairs(wormhole_types) do
    AddPrefabPostInit(prefab, function(inst)
        inst:DoTaskInTime(0.2, function() AddWormholeColor(inst, inst:GetPosition()) end)
    end)
end

local function GetWormhole()
    local wormhole = FindEntity(_G.ThePlayer, 5, function(inst) return wormhole_types[inst.prefab] end, {"teleporter"})
    if wormhole then
        return {inst = wormhole, pos = wormhole:GetPosition()}
    end
    return false
end

local function SaveWormholePair(entrance, exit)
    if not entrance.pos:__eq(exit.pos) then
        AddWormholePosition(entrance.pos)
        AddWormholePosition(exit.pos)
        SaveWormholePositions()
        AddWormholeColor(entrance.inst, entrance.pos)
        AddWormholeColor(exit.inst, exit.pos)
    else
        print("[虫洞标记] Error saving wormhole pair")
    end
end

local function TryCraft(check)
    for recname, rec in pairs(GLOBAL.AllRecipes) do
        if GLOBAL.IsRecipeValid(recname) and rec.placer == nil and rec.sg_state ==
            nil and GLOBAL.ThePlayer.replica.builder:KnowsRecipe(recname) and
            GLOBAL.ThePlayer.replica.builder:CanBuild(recname) then
            if check then return true end
            GLOBAL.SendRPCToServer(GLOBAL.RPC.MakeRecipeFromMenu, rec.rpc_id)
            return rec
        end
    end
end

AddPrefabPostInit("player_classified", function(player_classified)
    player_classified:ListenForEvent("wormholetraveldirty", function()
        local entrance = GetWormhole()
        if entrance and not WormholePositionExists(entrance.pos) then
            local waitTime = 3
            local wormholecheck = LoadModData("WHForControl") or false
            if wormholecheck and TryCraft(true) then waitTime = 1 end
            _G.ThePlayer:DoTaskInTime(waitTime, function()
                local exit = GetWormhole()
                if exit and not WormholePositionExists(exit.pos) then
                    SaveWormholePair(entrance, exit)
                end
            end)
        end
    end)
end)