local function MakeLocations()
    local useablepositions = {}
    for i = 1, 100 do
        local s = i / 32
        local a = math.sqrt(s * 512)
        local b = math.sqrt(s) * 11
        local pos = { x = math.sin(a) * b, y = 0, z = math.cos(a) * b }
        table.insert(useablepositions, pos)
    end
    return useablepositions 
end

local locations = MakeLocations()

local VALID_TILE_TYPES =
{
    [GLOBAL.GROUND.DIRT] = true, 
    [GLOBAL.GROUND.SAVANNA] = true, 
    [GLOBAL.GROUND.GRASS] = true, 
    [GLOBAL.GROUND.FOREST] = true, 
    [GLOBAL.GROUND.MARSH] = true, 

    -- CAVES
    [GLOBAL.GROUND.CAVE] = true, 
    [GLOBAL.GROUND.FUNGUS] = true, 
    [GLOBAL.GROUND.SINKHOLE] = true, 
    [GLOBAL.GROUND.MUD] = true, -- 
    [GLOBAL.GROUND.FUNGUSRED] = true, 
    [GLOBAL.GROUND.FUNGUSGREEN] = true, 

    --EXPANDED FLOOR TILES
    [GLOBAL.GROUND.DECIDUOUS] = true, 
}

local function CheckTileCompatibility(tile)
    return VALID_TILE_TYPES[tile]
end


local function createhelper(pos,inst)
    local helper = GLOBAL.CreateEntity()
    helper.entity:SetCanSleep(false)
    helper.persists = false

    helper.entity:AddTransform()
    helper.entity:AddAnimState()

    helper:AddTag("CLASSIFIED")
    helper:AddTag("NOCLICK")
    helper:AddTag("placer")

    helper.Transform:SetScale(1.24, 1.24, 1.24)

    helper.AnimState:SetBank("eyepos")
    helper.AnimState:SetBuild("eyepos")
    helper.AnimState:PlayAnimation("idle")
    helper.AnimState:SetLightOverride(1)
    helper.AnimState:SetOrientation(GLOBAL.ANIM_ORIENTATION.OnGround) 
    helper.AnimState:SetLayer(GLOBAL.LAYER_BACKGROUND) 
    helper.AnimState:SetSortOrder(1)
    helper.AnimState:SetAddColour(0, .2, .5, 0)

    helper.entity:SetParent(inst.entity)
    helper.Transform:SetPosition(pos.x, 0, pos.z)
	return helper
end

-- I'm not familiar with Vector3 yet, fix this soon.
local function cangrow(x, y, z, relative, world)
	local pos = nil
	if world then 
		pos = world
	else
		pos = { x = relative.x + x, y = relative.y + y, z = relative.z + z }
	end
	local ground = GLOBAL.TheWorld
	return ground.Map:IsAboveGroundAtPoint(pos.x ,0 ,pos.z ) and
	CheckTileCompatibility(ground.Map:GetTileAtPoint(pos.x, 0, pos.z )) and
	ground.Pathfinder:IsClear(x, 0, z, pos.x, 0, pos.z, { ignorewalls = true }) and
	#TheSim:FindEntities(pos.x, pos.y, pos.z, 2.5, {"eyeplant"} ) <= 0 and
	--added "FX" tag for compatibility with geometric placement.
	#TheSim:FindEntities(pos.x, pos.y, pos.z, 1, nil, {"FX"}) <= 0 and
	not ground.Map:IsPointNearHole(GLOBAL.Vector3(pos.x, pos.y, pos.z ))
end

local function OnEnableHelper(inst,enabled)
	if enabled then
		if inst.components.health ~= nil and inst.components.health:IsDead() or 
		   inst.replica.health ~= nil and inst.replica.health:IsDead() then
		return end
		inst.eyetask = inst:DoPeriodicTask(1, function(inst)
			if inst.helpers ~= nil then	
				for k, eye in pairs(inst.helpers) do 
					eye:Remove() 
				end
			end	
			inst.helpers = {}
			local x,y,z = inst.Transform:GetWorldPosition()
			local currentminions = nil
			if inst.components.minionspawner ~= nil then 
				if not inst.components.minionspawner:MaxedMinions() then
					currentminions = inst.components.minionspawner.numminions or 0 
				else return end
			elseif inst:HasTag("placer") then
				currentminions = 0
			else currentminions = #TheSim:FindEntities(x, y, z, 15, {"eyeplant"} ) 
			end
			for k,pos in ipairs(locations) do 
				if cangrow(x, y, z, pos) then
					table.insert(inst.helpers, createhelper(pos,inst))
					if #inst.helpers >= 32.4 - currentminions then
						break
					end
				end
			end
		end,0) 
    else 
		if inst.eyetask ~= nil then 
			inst.eyetask:Cancel()
			inst.eyetask = nil
		end
		if inst.helpers ~= nil then		 
			for k,v in pairs(inst.helpers) do
				v:Remove() 
			end
			inst.helpers = nil
		end
    end
end

AddPrefabPostInit("lureplant", function(inst)
    if not GLOBAL.TheNet:IsDedicated() then
        inst:AddComponent("deployhelper")
        inst.components.deployhelper.onenablehelper = OnEnableHelper
    end
end )

AddPrefabPostInit("lureplantbulb_placer", function(inst)
    if not GLOBAL.TheNet:IsDedicated() then
		inst:DoTaskInTime(0, OnEnableHelper, true)
    end
end )

