GLOBAL.Profile:SetBoatCameraEnabled(false)
local Jfilter = false

if GetModConfigData("sw_filter") or GetModConfigData("sw_color") or HasModName("色彩调节") or HasModName("滤镜") or HasModName("画质") or HasModName("美颜") then
	Jfilter = true
end

local obc_eagleMode = 0
-- 0 : 默认
-- 1 ：大视野
-- 2 ：鹰眼

local nightsightMode = false
local lastFov = 35
local CIRCLE_STATE = {}

local NSData = "NightSight"
local G = GLOBAL


local change_mode = GetModConfigData("option_fullmap")
-- 0 "默认~鹰眼"
-- 1 "大视野~鹰眼"
-- 2 "默认~大视野~鹰眼",
-- 3 "默认~大视野"

local function MakeCircle(inst, n, scale)
	local circle = G.CreateEntity()

	circle.entity:SetCanSleep(false)
	circle.persists = false

	circle.entity:AddTransform()
	circle.entity:AddAnimState()

	circle:AddTag("CLASSIFIED")
	circle:AddTag("NOCLICK")
	circle:AddTag("placer")

	circle.Transform:SetRotation(n)
	-- 大小
	circle.Transform:SetScale(scale, scale, scale)

	circle.AnimState:SetBank("firefighter_placement")
	circle.AnimState:SetBuild("firefighter_placement")
	circle.AnimState:PlayAnimation("idle")
	circle.AnimState:SetLightOverride(1)
	circle.AnimState:SetOrientation(G.ANIM_ORIENTATION.OnGround)
	circle.AnimState:SetLayer(G.LAYER_BACKGROUND)
	circle.AnimState:SetSortOrder(3.1)
	-- 颜色
	circle.AnimState:SetAddColour(0, 255, 0, 0)

	circle.entity:SetParent(inst.entity)
	return circle
end






local function RemoveCircle()
	for _,circle in pairs(CIRCLE_STATE) do circle:Remove() end
	CIRCLE_STATE = {}
end

local function SetCamera(zoomstep, mindist, maxdist, mindistpitch, maxdistpitch, distance, distancetarget)
	if G.TheCamera ~= nil then
		local camera = G.TheCamera
		camera.zoomstep = zoomstep or camera.zoomstep
		camera.mindist = mindist or camera.mindist
		camera.maxdist = maxdist or camera.maxdist
		camera.mindistpitch = mindistpitch or camera.mindistpitch
		camera.maxdistpitch = maxdistpitch or camera.maxdistpitch
		camera.distance = distance or camera.distance
		camera.distancetarget = distancetarget or camera.distancetarget
	end
end

function GLOBAL.SetCamera(...)
	SetCamera(...)
end

local function SetDefaultView()
	if G.TheWorld ~= nil then
		if G.TheWorld:HasTag("cave") then
			SetCamera(4, 15, 35, 25, 40, 25, 25)
		else
			SetCamera(4, 15, 50, 30, 60, 30, 30)
		end
	end
end

local function SetAerialView()
	if G.TheWorld ~= nil then
		if G.TheWorld:HasTag("cave") then
			SetCamera(10, 10, 180, 25, 40, 80, 80)
		else
			SetCamera(10, 10, 180, 30, 60, 80, 80)
		end
	end
end

local function SetVerticalView()
	if G.TheWorld ~= nil then
		SetCamera(10, 10, 180, 90, 90, 80, 80)
	end
end

-- 鹰眼
local function EagleView()
	obc_eagleMode = 2
	SetVerticalView()
	G.TheCamera.fov = 165
	table.insert(CIRCLE_STATE, MakeCircle(G.ThePlayer, 0, 2))
	table.insert(CIRCLE_STATE, MakeCircle(G.ThePlayer, 2, 2))
	TIP("视角", "red", "鹰眼")
end

-- 标准
local function StandardView()
	obc_eagleMode = 0
	SetDefaultView()
	RemoveCircle()
	G.TheCamera.fov = 35
	TIP("视角", "green", "标准")
end

-- 大视野
local function HighView()
	obc_eagleMode = 1
	SetAerialView()
	RemoveCircle()
	G.TheCamera.fov = 35
	TIP("视角", "blue", "大视野")
end




local sw = {[0]={0,2}, [1]={1,2}, [2]={0,1,2}, [3]={0,1}}
local sww = {[0] = StandardView, [1] = HighView, [2] = EagleView}

local function EagleViewMode()
	if InGame() then
		local sels = sw[change_mode]
		if not table.contains(sels, obc_eagleMode) then obc_eagleMode = sels[1] end
		local id = sels[1]
		for k,v in pairs(sels)do
			if v == obc_eagleMode then
				id = k
				break
			end
		end
		id = id + 1
		if id>#sels then id = sels[1] else id = sels[id] end
		sww[id]()
	end
end


-- 智能夜视


local function TurnOnNightVision(player)
	if not Jfilter then
		player.light = player.entity:AddLight()
		player.light:SetFalloff(0.5)
		player.light:SetIntensity(player.lightx)
		player.light:SetRadius(10^4)
		player.light:SetColour(255/255, 225/255, 255/255)
		player.light:Enable(true)
	else
    	GLOBAL.ThePlayer.components.playervision:ForceNightVision(true)
	end
	if nightsightMode then
		player:DoTaskInTime(1, function() TIP("提示", "blue", "夜晚到来, 请准备光源") end)
	end
end



local function TurnOffNightVision(player)
	if not Jfilter then
		player.light = player.entity:AddLight()
		player.light:SetFalloff(0.5)
		player.light:SetIntensity(0)
		player.light:SetRadius(0)
		player.light:SetColour(255/255, 225/255, 255/255)
		player.light:Enable(false)
	else
    	GLOBAL.ThePlayer.components.playervision:ForceNightVision(false)
	end
end


local function TurnOffDelay(player)
	player:DoTaskInTime(5, function() TurnOffNightVision(player) end)
end

local function NightSight()
    if InGame() then
        local player = G.ThePlayer
		nightsightMode = not nightsightMode
		if nightsightMode then
			player.lightx = player.lightx or 1
			player:WatchWorldState("startday",TurnOffDelay)
			player:WatchWorldState("startnight",TurnOnNightVision)
			if G.TheWorld.state.isday or G.TheWorld.state.isdusk then
				TIP("开启", "green", "智能夜视已开启, 夜晚将会自动启用")
			else
				TIP("开启", "green", "智能夜视已开启")
				TurnOnNightVision(player)
			end
		else
			if G.TheWorld.state.isnight then
				TurnOffNightVision(player)
			end
			player:WatchWorldState("startnight",TurnOffNightVision)
			TIP("关闭", "red", "智能夜视已关闭")
		end
		SaveModData(NSData, nightsightMode)
	end
end

local c_f = GetModConfigData("cheat_fullmap")
if c_f then	
	G.TheInput:AddKeyDownHandler(c_f, EagleViewMode)
end

local c_g = GetModConfigData("cheat_nightversion")

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(1.55, function()
        if c_g and inst == GLOBAL.ThePlayer then
            nightsightMode = not LoadModData(NSData)
			NightSight()
        end
    end)
end)

if c_g == "biubiu" then
	DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("wx78module_nightvision.tex"), "wx78module_nightvision.tex", "夜视", "现在夜视状态会保存了", false, NightSight)
end




AddBindBtn("cheat_nightversion", NightSight)