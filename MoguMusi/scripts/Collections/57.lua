local mark_x, mark_y
local function find_winchtable(inst)
    return inst.prefab == "winch"
end
local SCULPTINGTABLE_CANTTAGS = { "INLIMBO", "burnt" }

local function fn()
    local ThePlayer = GLOBAL.ThePlayer
    if not ThePlayer then return end

    local x, _, z = ThePlayer.Transform:GetWorldPosition()
    local bases = returnBases()
    if #bases == 0 then
        TIP("寻找天体", "red", "定位标记不足, 请放置天体探测仪或寻宝装置[需要一个屏幕内有两个箭头标记]","chat")
        return
    end

    if #bases == 1 then
        TIP("寻找天体", "red", "定位标记不足, 请继续放置天体探测仪或寻宝装置[需要一个屏幕内有两个箭头标记]","chat")
        return
    end

    local base1 = bases[1]
    local base2 = bases[2]

    local x1, _, y1 = base1.Transform:GetWorldPosition()
    local x2, _, y2 = base2.Transform:GetWorldPosition()

    -- See prefabs\archive_resonator.lua, tooooo stupid
    local rad1 = math.rad(base1:GetRotation() - 90 + 180)
    local rad2 = math.rad(base2:GetRotation() - 90 + 180)

    -- Do "-", because DST's 90 degrees is z-axis negative direction(instead of positive)
    local m1 = - math.tan(rad1)
    local m2 = - math.tan(rad2)

    if m1 == m2 then
        TIP("金手指：寻找天体", "red", "定位标记检测...等等...怎么是平行线？再放一次吧","chat")
        return
    end

    local c1 = y1 - m1 * x1
    local c2 = y2 - m2 * x2

    local x = (c2 - c1) / (m1 - m2)
    local y = m1 * x + c1

    mark_x, mark_y = x, y

    GLOBAL.TheFocalPoint.SoundEmitter:PlaySound("dontstarve/HUD/Together_HUD/learn_map")
    ThePlayer.HUD.controls:ShowMap(Vector3(x, 0, y))

    TIP("金手指：寻找天体", "green", "定位成功, 地图上红×为目标位置, 如果小地图消失, 按两下 M 即可恢复","chat")
end

local Easing = require("easing")

-- From Wormhole Icons [Fixed]
local half_x, half_y = GLOBAL.RESOLUTION_X / 2, GLOBAL.RESOLUTION_Y / 2
local screen_width, screen_height = GLOBAL.TheSim:GetScreenSize()
local function WorldPosToScreenPos(x, z)
    local map_x, map_y = GLOBAL.TheWorld.minimap.MiniMap:WorldPosToMapPos(x, z, 0)
    local screen_x = ((map_x * half_x) + half_x) / GLOBAL.RESOLUTION_X * screen_width
    local screen_y = ((map_y * half_y) + half_y) / GLOBAL.RESOLUTION_Y * screen_height
    return screen_x, screen_y
end

AddClassPostConstruct("widgets/mapwidget", function(self)
    if not mark_x then return end

    self.alter_finder_mark = self:AddChild(Image("minimap/minimap_data.xml", "messagebottletreasure_marker.png"))

    local OnUpdate = self.OnUpdate
    self.OnUpdate = function(self, ...)
        OnUpdate(self, ...)
        local x,y = WorldPosToScreenPos(mark_x, mark_y)
        local pos = {x = x, y = y}
        self.alter_finder_mark:SetPosition(x, y)
        self.alter_finder_mark:SetScale(1 - Easing.outExpo(GLOBAL.TheWorld.minimap.MiniMap:GetZoom() - 1, 0, 0.75, 8) or pos)
    end
end)

local markers = {
    "moon_altar_astral_marker_1",
    "moon_altar_astral_marker_2",
    -- 能力勋章宝藏？或许，我暂时不玩这个游戏
    "moon_altar_astral_marker",
}

local function postinit(inst)
    inst:SpawnChild("reticule")
end

for _, prefab in ipairs(markers) do
    AddPrefabPostInit(prefab, postinit)
end

if GetModConfigData("sw_altarfinder") == "biubiu" then
DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("archive_resonator_item.tex"), "archive_resonator_item.tex", "寻找天体", "寻找天体祭坛, 也支持某MOD寻宝", false, fn)
end

AddBindBtn("sw_altarfinder", fn)