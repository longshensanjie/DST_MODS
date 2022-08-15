-- /scripts/components/weather.lua/SetGroundOverlay
AddPrefabPostInit("world", function(world)
    local surfaceT = GLOBAL.getmetatable(world.Map).__index
    local cover = surfaceT.SetOverlayLerp
    surfaceT.SetOverlayLerp = function(a, b, ...)
        return cover(a, 0, ...)
    end
end)