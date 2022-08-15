require 'util'

-- xkill()
-- xday()
-- xreset()
-- xue()
-- xmaze()
-- xboons()
-- xtraps()
-- xpres()
-- xinterest()
-- xlayouts()
-- Save()
-- Load()

local layout_name = ""

local function GetKeyArrayFromDisc(dis)
    local res = {}
    if type(dis) ~= 'table' then return res end
    for k,v in pairs(dis) do
        table.insert(res, k)
    end
    return res
end

function xclear()
    xkill( 256 )
end

function xkill( range )
    range = range or 10
    local x,y,z = TheInput:GetWorldPosition():Get()
    -- local finished = false
    for i=1,16 do
        for k,v in pairs( TheSim:FindEntities( x,y,z, range) ) do
            if v ~= ThePlayer and not ( v.components.InventoryItem and v.components.InventoryItem:IsHeld() ) then
                if v.components.health then
                    v.components.health:Kill()
                elseif v.Remove then
                    v:Remove()
                end
                if v:HasTag('wall') then v:Remove() return end
            end
        end
    end
end

function xday()
    -- GetClock():Reset()
    TheWorld:PushEvent('ms_setclocksegs', {day=16})
    TheWorld:PushEvent('ms_setphase', 'day')
end

_g = {}

function xreset()
    _g = {}
end

function xue()
    loadfile('xue')()
end

function xmaze( )
    -- local maze_layouts = require 'map/maze_layouts'
    -- local name = GetRandomKey( maze_layouts.Layouts )
    local maze_layouts = require('map/maze_layouts')
    _g.xmaze = _g.xmaze or {}
    _g.xmaze.index = _g.xmaze.index and (_g.xmaze.index+1) or 1
    _g.xmaze.typeIndex = _g.xmaze.typeIndex or 1
    _g.xmaze.names = _g.xmaze.names or GetKeyArrayFromDisc( maze_layouts.Layouts )
    _g.xmaze.types = _g.xmaze.types or GetKeyArrayFromDisc( maze_layouts.AllLayouts )
    local name = _g.xmaze.names[_g.xmaze.index]
    local type = _g.xmaze.types[_g.xmaze.typeIndex]
    if not name then 
        _g.xmaze.index = 1 
        _g.xmaze.typeIndex = _g.xmaze.typeIndex+1
    end
    local name = _g.xmaze.names[_g.xmaze.index]
    local type = _g.xmaze.types[_g.xmaze.typeIndex]
    if not name or not type then return end
    -- SpawnLayoutAtPoint( _g.xmaze.names[_g.xmaze.index], nil, nil, 4.0,  )
    SpawnLayoutAtPoint( name, nil, nil, 4.0, {type} )

end

function xboons( )
    _g.boon = _g.boon or {}
    _g.boon.index = _g.boon.index and (_g.boon.index+1) or 1
    _g.boon.names = _g.boon.names or GetKeyArrayFromDisc( require('map/boons').Layouts )
    if not _g.boon.names[_g.boon.index] then return end
    SpawnLayoutAtPoint( _g.boon.names[_g.boon.index], nil, nil, 4.0 )
end

function xtraps( )
    _g.traps = _g.traps or {}
    _g.traps.index = _g.traps.index and (_g.traps.index+1) or 1
    _g.traps.names = _g.traps.names or GetKeyArrayFromDisc( require('map/traps').Layouts )
    if not _g.traps.names[_g.traps.index] then return end
    SpawnLayoutAtPoint( _g.traps.names[_g.traps.index], nil, nil, 4.0 )
end

function xpres()
    _g.xpres = _g.xpres or {}
    _g.xpres.index = _g.xpres.index and (_g.xpres.index+1) or 1
    _g.xpres.names = _g.xpres.names or GetKeyArrayFromDisc( require('map/protected_resources').Layouts )
    if not _g.xpres.names[_g.xpres.index] then return end
    SpawnLayoutAtPoint( _g.xpres.names[_g.xpres.index], nil, nil, 4.0 )
end

function xinterest()
    _g.xinterest = _g.xinterest or {}
    _g.xinterest.index = _g.xinterest.index and (_g.xinterest.index+1) or 1
    _g.xinterest.names = _g.xinterest.names or GetKeyArrayFromDisc( require('map/pointsofinterest').Layouts )
    if not _g.xinterest.names[_g.xinterest.index] then return end
    SpawnLayoutAtPoint( _g.xinterest.names[_g.xinterest.index], nil, nil, 4.0 )
end

function xlayouts()
    _g.xlayouts = _g.xlayouts or {}
    _g.xlayouts.index = _g.xlayouts.index and (_g.xlayouts.index+1) or 1
    _g.xlayouts.names = _g.xlayouts.names or GetKeyArrayFromDisc( require('map/layouts').Layouts )
    if not _g.xlayouts.names[_g.xlayouts.index] then return end
    SpawnLayoutAtPoint( _g.xlayouts.names[_g.xlayouts.index], nil, nil, 4.0 )
    print( string.format( 'xlayouts() index: %s, name: %s', _g.xlayouts.index, _g.xlayouts.names[_g.xlayouts.index] ) )
end

local men_zlayouts = {
    list={},
    index=nil
}
function zlayouts()
    _g.men_zlayouts = _g.men_zlayouts or deepcopy(men_zlayouts)
    men_zlayouts.index = men_zlayouts.index and (men_zlayouts.index+1) or 1
    _g.xlayouts = _g.xlayouts or {}
    _g.xlayouts.index = men_zlayouts.list[men_zlayouts.index] and -1+men_zlayouts.list[men_zlayouts.index] or 999999999
    xlayouts()
end

function SpawnLayoutAtPoint( name, _x, _z, _scale, choices )
    layout_name = name

    print( 'try to build: ' .. layout_name )

    local instList = {}

    local obj_layout = require("map/object_layout")
    local entities = {}
    local map_width, map_height = TheWorld.Map:GetSize()
    local add_fn = {
        fn=function(prefab, points_x, points_y, current_pos_idx, entitiesOut, width, height, prefab_list, prefab_data, rand_offset)
        -- print("adding, ", prefab, points_x[current_pos_idx], points_y[current_pos_idx])
            local x = (points_x[current_pos_idx] - width/2.0)*TILE_SCALE
            local y = (points_y[current_pos_idx] - height/2.0)*TILE_SCALE
            x = math.floor(x*100)/100.0
            y = math.floor(y*100)/100.0
            local inst = SpawnPrefab(prefab)
            inst.Transform:SetPosition(x, 0, y)

            if prefab_data and prefab_data.scenario then
                if inst.components.scenariorunner == nil then
                    inst:AddComponent("scenariorunner")
                end
                if prefab_data.scenario then
                    inst.components.scenariorunner:SetScript(prefab_data.scenario)
                end
            end

            table.insert( instList, inst )
        end,
        args={entitiesOut=entities, width=map_width, height=map_height, rand_offset = false, debug_prefab_list=nil}
    }

    local x, y, z = ConsoleWorldPosition():Get()
    x, z = TheWorld.Map:GetTileCoordsAtPoint(x, y, z)
    -- offset = offset or 3
    obj_layout.Place({math.floor(x) - 3, math.floor(z) - 3}, name, add_fn, nil, TheWorld.Map)

    for _, ent in ipairs(instList) do
        if ent.components.scenariorunner then
            ent.components.scenariorunner:Run()
        end
    end

    print( 'finish build: ' .. layout_name )
end

function c_layout(name)
    name = name or layout_name
    SpawnLayoutAtPoint( name )
end

function c_enablecheats()
    require "debugcommands"
    require "debugkeys"
    CHEATS_ENABLED = true
end

c_enablecheats()

function Save()
    -- SaveGameIndex:SaveCurrent()
    TheWorld:PushEvent("ms_save")
end

function Load()
    c_reset()
    -- StartNextInstance({reset_action = RESET_ACTION.LOAD_SLOT, save_slot=SaveGameIndex:GetCurrentSaveSlot()})
end

AddGameDebugKey(KEY_K, function()
    if not TheInput:IsKeyDown(KEY_CTRL) then
        xclear()
    end
    return true
end)
