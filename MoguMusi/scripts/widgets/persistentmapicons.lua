
local Widget = require("widgets/widget")
local Image = require("widgets/image")
local Easing = require("easing")

local half_x, half_y = RESOLUTION_X / 2, RESOLUTION_Y / 2
local screen_width, screen_height = TheSim:GetScreenSize()
local function WorldPosToScreenPos(x, z)
    local map_x, map_y = TheWorld.minimap.MiniMap:WorldPosToMapPos(x, z, 0)
    local screen_x = ((map_x * half_x) + half_x) / RESOLUTION_X * screen_width
    local screen_y = ((map_y * half_y) + half_y) / RESOLUTION_Y * screen_height
    return screen_x, screen_y
end

local PersistentMapIcons = Class(Widget, function(self, mapwidget)
    Widget._ctor(self, "PersistentMapIcons")
    self.root = self:AddChild(Widget("root"))
    self.zoomed_scale = {}
    self.mapicons = {}

    -- 其实有更好的方法, 直接向地图加实体，懒得看代码，就这样吧

    -- for i = 1, 20 do
    --     self.zoomed_scale[i] = 0.85 - Easing.outExpo(i - 1, 0, 0.6, 8)
    -- end

    local MapWidgetOnUpdate = mapwidget.OnUpdate
    mapwidget.OnUpdate = function(mapwidget, ...)
        MapWidgetOnUpdate(mapwidget, ...)
        local zoom = TheWorld.minimap.MiniMap:GetZoom()
        local scale = 0.85 - Easing.outExpo(zoom - 1, 0, 0.6, 8)
        -- local scale = self.zoomed_scale[TheWorld.minimap.MiniMap:GetZoom()]
        for _, mapicon in ipairs(self.mapicons) do
            local x, y = WorldPosToScreenPos(mapicon.pos.x, mapicon.pos.z)
            mapicon.icon:SetPosition(x, y)
            -- 擦屁股
            mapicon.icon:SetScale(scale or mapicon.pos)
        end
    end
end)

function PersistentMapIcons:AddMapIcon(atlas, image, pos)
    local icon = self.root:AddChild(Image(atlas, image))
    table.insert(self.mapicons, {icon = icon, pos = pos})
end

return PersistentMapIcons
