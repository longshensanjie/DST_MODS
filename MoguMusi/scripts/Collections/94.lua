local _G = GLOBAL
local require = _G.require
local enemies = require("enemies")
local TheSim = GLOBAL.TheSim
local TheInput = GLOBAL.TheInput
local show_widget = false
local colour_attack = true
local update_speed_task

local function InGame()
	return GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and not GLOBAL.ThePlayer.HUD:HasInputFocus()
end

local function GetPlayerSpeed()
	if not _G.ThePlayer then return nil end	
	local ThePlayer = _G.ThePlayer
	local run_speed = _G.TUNING.WILSON_RUN_SPEED
	local speed_multiplier = 1
	local externalspeedmultiplier = 1
	local fasteronroad = true

	--Rider, normal run speed
	local rider = ThePlayer.replica.rider
    local mount = rider ~= nil and rider:IsRiding() and rider:GetMount() or nil
    if mount ~= nil then
        run_speed = rider:GetMountRunSpeed()
		fasteronroad = rider:GetMountFasterOnRoad()
    end
	if ThePlayer.player_classified ~= nil then
		run_speed = ThePlayer.player_classified.runspeed:value()
		externalspeedmultiplier = ThePlayer.player_classified.externalspeedmultiplier:value()
	end
	
	local scale_x,scale_y,scale_z = ThePlayer.Transform:GetScale() --Scale increases/decreases speed for characters such as Wolfgang.
	local avg_scale = (scale_x+scale_y+scale_z)/3
	run_speed = run_speed * avg_scale

	--Inventory speed multipliers
    local inventory = ThePlayer.replica.inventory
    if inventory ~= nil then
        local rider = ThePlayer.replica.rider
        if rider ~= nil and rider:IsRiding() then
            local saddle = rider:GetSaddle()
            local inventoryitem = saddle ~= nil and saddle.replica.inventoryitem or nil
            if inventoryitem ~= nil then
                speed_multiplier = speed_multiplier * inventoryitem:GetWalkSpeedMult()
            end
        else
            for k, v in pairs(inventory:GetEquips()) do
                local inventoryitem = v.replica.inventoryitem
                if inventoryitem ~= nil then
                    speed_multiplier = speed_multiplier * inventoryitem:GetWalkSpeedMult()
                end
            end
        end
    end
	
	--Road, web, other speed multipliers
	local x, y, z = ThePlayer.Transform:GetWorldPosition()
    local oncreep = not ThePlayer:HasTag("spiderwhisperer") and _G.TheWorld.GroundCreep:OnCreep(x, y, z) --spiderwhisperer not a proper way to check, but there's no way to actually check without adding a locomotor, which will cause other issues.
	local groundspeedmultiplier = 1
	local wasoncreep
    if oncreep then
        if not wasoncreep then
            wasoncreep = true
        end
        groundspeedmultiplier = 0.6 --self.slowmultiplier from locomotor.lua
    else
        wasoncreep = false

        local current_ground_tile = _G.TheWorld.Map:GetTileAtPoint(x, 0, z)
		local is_fasterontile = (mount ~= nil and mount:HasTag("turfrunner_"..tostring(current_ground_tile))) or ThePlayer:HasTag("turfrunner_"..tostring(current_ground_tile))
        groundspeedmultiplier = (is_fasterontile or (fasteronroad and ((_G.RoadManager ~= nil and _G.RoadManager:IsOnRoad(x, 0, z)) or current_ground_tile == _G.GROUND.ROAD)))
									and 1.3 --self.fastmultiplier from locomotor.lua
									or 1
    end
	
	--Temporary ground speed multipliers: Bee Queen's Honey Trail(honey_trail.lua), Klaus's Ice Deer Spell(deer_fx.lua) are not accounted for.
	--But I don't think I'll count them, because they're temporary and they usually don't have any effect on the battle.
	--And they just mess up your time as they're temporary ground multipliers and when you run out, the danger color changes.
	
	return run_speed*speed_multiplier*groundspeedmultiplier*externalspeedmultiplier
	
end

local function StartDoingPeriodicSpeedTask()
	if not _G.ThePlayer then return nil end
	local ThePlayer = _G.ThePlayer
	update_speed_task = ThePlayer:DoPeriodicTask(1/10,function()
			ThePlayer._playerspeed = GetPlayerSpeed()
		end)
end

local function StopDoingPeriodicSpeedTask()
	if update_speed_task then
		update_speed_task:Cancel()
		update_speed_task = nil
	end
end



local function AddTimerToMobs()
	local pos = _G.ThePlayer:GetPosition()
	for _,ent in pairs(TheSim:FindEntities(pos.x,0,pos.z,80,{"_combat"},{"INLIMBO"})) do
		if ent and enemies[ent.prefab] and not ent["timer_isalreadymarked"] then
			_G.ThePlayer.HUD:AddChild(GLOBAL.require("widgets/timer")(ent))
			ent["timer_isalreadymarked"] = true
		end
	end
end

local function MarkMobsForRemoval()
	local pos = _G.ThePlayer:GetPosition()
	for _,ent in pairs(TheSim:FindEntities(pos.x,0,pos.z,80,{"_combat"},{"INLIMBO"})) do
		if ent and enemies[ent.prefab] then
			ent["timer_toremove"] = true
			ent["timer_isalreadymarked"] = nil
		end
	end
end

	for k,v in pairs(enemies) do
		AddPrefabPostInit(k,function(inst)
				if _G.ThePlayer and show_widget and not inst["timer_isalreadymarked"] then
					_G.ThePlayer.HUD:AddChild(GLOBAL.require("widgets/timer")(inst))
					inst["timer_isalreadymarked"] = true
				end
		end)
	end
	AddPlayerPostInit(function(inst)
				inst:DoTaskInTime(1,function ()
					if inst == _G.ThePlayer and show_widget then
						AddTimerToMobs()
					end
			end)
		end)
	
	AddPlayerPostInit(function(inst)
			inst:DoTaskInTime(0, function()
					if inst == _G.ThePlayer and colour_attack then --No reason to do the periodic task if we aren't gonna be using it for anything.
						StartDoingPeriodicSpeedTask()
					end
				end)
			end)
	
	
if GetModConfigData("attack_timer") then
	TheInput:AddKeyUpHandler(GetModConfigData("sw_jungler"),function()
		if not InGame() then return else
			if show_widget then
				show_widget = false
				MarkMobsForRemoval()
			else
				show_widget = true
				AddTimerToMobs()
			end
		end
	end)
end