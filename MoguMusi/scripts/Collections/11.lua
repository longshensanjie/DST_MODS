local obc_languageCode = GLOBAL.TheNet:GetLanguageCode()
local obc_viewMode = GetModConfigData("OBC_INITIAL_VIEW_MODE")
local obc_recentTarget = {
	flag = 0,
	entity = nil,
	x = 0, y = 0, z = 0,
}

local function TextFilter(texts)
	return texts[1]
end

local function Say(texts)
	GLOBAL.ThePlayer.components.talker:Say(TextFilter(texts))
end

local function SetCamera(zoomstep, mindist, maxdist, mindistpitch, maxdistpitch, distance, distancetarget)
	if GLOBAL.TheCamera ~= nil then
		local camera = GLOBAL.TheCamera
		camera.zoomstep = zoomstep or camera.zoomstep
		camera.mindist = mindist or camera.mindist
		camera.maxdist = maxdist or camera.maxdist
		camera.mindistpitch = mindistpitch or camera.mindistpitch
		camera.maxdistpitch = maxdistpitch or camera.maxdistpitch
		camera.distance = distance or camera.distance
		camera.distancetarget = distancetarget or camera.distancetarget
	end
end

local function SetDefaultView()
	if GLOBAL.TheWorld ~= nil then
		if GLOBAL.TheWorld:HasTag("cave") then
			SetCamera(4, 15, 35, 25, 40, 25, 25)
		else
			SetCamera(4, 15, 50, 30, 60, 30, 30)
		end
	end
end

local function SetAerialView()
	if GLOBAL.TheWorld ~= nil then
		if GLOBAL.TheWorld:HasTag("cave") then
			SetCamera(10, 10, 180, 25, 40, 80, 80)
		else
			SetCamera(10, 10, 180, 30, 60, 80, 80)
		end
	end
end

local function SetVerticalView()
	if GLOBAL.TheWorld ~= nil then
		if GLOBAL.TheWorld:HasTag("cave") then
			SetCamera(10, 10, 180, 90, 90, 80, 80)
		else
			SetCamera(10, 10, 180, 90, 90, 80, 80)
		end
	end
end

local function ChangeViewMode()
	if InGame() then
		if obc_viewMode == 0 then
			SetAerialView()
			obc_viewMode = 1
			Say({"高空", "高空", "Aerial View"})
		elseif obc_viewMode == 1 then
			SetVerticalView()
			obc_viewMode = 2
			Say({"俯视", "俯視", "Vertical View"})
		elseif obc_viewMode == 2 then
			SetDefaultView()
			obc_viewMode = 0
			Say({"默认", "默認", "Default View"})
		end
	end
end

local function ShowOrHideHUD()
	if InGame() then
		if GLOBAL.ThePlayer.HUD:IsVisible() then
			GLOBAL.ThePlayer.HUD:Hide()
			TIP("OB视角","purple","HUD隐藏")
		else
			GLOBAL.ThePlayer.HUD:Show()
			TIP("OB视角","purple","HUD显示")
		end
	end
end

local function ShowOrHidePlayer()
	if InGame() then
		if GLOBAL.ThePlayer.entity:IsVisible() then
			GLOBAL.ThePlayer:Hide()
			GLOBAL.ThePlayer.DynamicShadow:Enable(false)
			TIP("OB视角","purple","隐藏建模","head")
		else
			GLOBAL.ThePlayer:Show()
			GLOBAL.ThePlayer.DynamicShadow:Enable(true)
			TIP("OB视角","purple","显示建模","head")
		end
	end
end

local function ChangeCameraTarget()
	if InGame() then
		local entity = GLOBAL.TheInput:GetWorldEntityUnderMouse()
		if entity ~= nil then
			local x, y, z = entity.Transform:GetWorldPosition()
			if x ~= nil and y ~= nil and z ~= nil then
				GLOBAL.TheCamera.target = entity
				GLOBAL.TheCamera.targetpos.x, GLOBAL.TheCamera.targetpos.y, GLOBAL.TheCamera.targetpos.z = x, y, z
				obc_recentTarget.flag = 1
				obc_recentTarget.entity = entity
				obc_recentTarget.x, obc_recentTarget.y, obc_recentTarget.z = x, y, z
				TIP("OB视角","purple","第二方视角","chat")
			else
				TIP("OB视角","red","目标超出范围","chat")
			end
		end
	end
end

local function ChangeCameraPosition()
	if InGame() then
		local x, y, z = GLOBAL.TheInput:GetWorldPosition():Get()
		GLOBAL.TheCamera.target = nil;
		GLOBAL.TheCamera.targetpos.x, GLOBAL.TheCamera.targetpos.y, GLOBAL.TheCamera.targetpos.z = x, y, z
		obc_recentTarget.flag = 2
		obc_recentTarget.entity = nil
		obc_recentTarget.x, obc_recentTarget.y, obc_recentTarget.z = x, y, z
		TIP("OB视角","purple","第三方视角","chat")
	end
end

local function ResetCameraTarget()
	if InGame() then
		if GLOBAL.TheCamera.target ~= GLOBAL.ThePlayer then
			GLOBAL.TheCamera:SetTarget(GLOBAL.ThePlayer)
			TIP("OB视角","purple","视角回切","chat")
		elseif obc_recentTarget.flag == 1 then
			if obc_recentTarget.entity ~= nil then
				local x, y, z = obc_recentTarget.entity.Transform:GetWorldPosition()
				if x ~= nil and y ~= nil and z ~= nil then
					GLOBAL.TheCamera.target = obc_recentTarget.entity
					GLOBAL.TheCamera.targetpos.x, GLOBAL.TheCamera.targetpos.y, GLOBAL.TheCamera.targetpos.z = x, y, z
					return
				end
			end
			TIP("OB视角","red","目标超出范围","chat")
		elseif obc_recentTarget.flag == 2 then
			GLOBAL.TheCamera.target = nil;
			GLOBAL.TheCamera.targetpos.x, GLOBAL.TheCamera.targetpos.y, GLOBAL.TheCamera.targetpos.z = obc_recentTarget.x, obc_recentTarget.y, obc_recentTarget.z
			TIP("OB视角","purple","视角回切","chat")
		end
	end
end

local function AddFOV(delta)
	if InGame() then
		local fov = GLOBAL.TheCamera.fov + delta
		if fov < 20 then
			fov = 20
		elseif fov > 179 then
			fov = 179
		end
		GLOBAL.TheCamera.fov = fov
		Say({"FOV " .. fov .. "（默认 35）", "FOV " .. fov .. "（默認 35）", "FOV " .. fov .. " (default 35)"})
	end
end

AddPlayerPostInit(
	function(inst) inst:DoTaskInTime(0, function(player)
		if GLOBAL.TheCamera ~= nil and GLOBAL.ThePlayer ~= nil and player == GLOBAL.ThePlayer then
			GLOBAL.TheCamera:SetTarget(GLOBAL.ThePlayer)
		end
	end)
end)

local function lerp(lower, upper, t)
    return t > 1 and upper
        or (t < 0 and lower
        or lower * (1 - t) + upper * t)
end

local function normalize(angle)
    while angle > 360 do
        angle = angle - 360
    end
    while angle < 0 do
        angle = angle + 360
    end
    return angle
end

local FollowCameraPostConstruct = function(self)
	local originalSetDefault = self.SetDefault
	self.SetDefault = function(self)
		originalSetDefault(self)
		if obc_viewMode == 0 then
			SetDefaultView()
		elseif obc_viewMode == 1 then
			SetAerialView()
		elseif obc_viewMode == 2 then
			SetVerticalView()
		end
	end
	self.Update = function(self, dt)
		if self.paused then
			return
		end
		local pangain = dt * self.pangain
		if self.cutscene then
			self.currentpos.x = lerp(self.currentpos.x, self.targetpos.x + self.targetoffset.x, pangain)
			self.currentpos.y = lerp(self.currentpos.y, self.targetpos.y + self.targetoffset.y, pangain)
			self.currentpos.z = lerp(self.currentpos.z, self.targetpos.z + self.targetoffset.z, pangain)
		else
			if self.time_since_zoom ~= nil and not self.cutscene then
				self.time_since_zoom = self.time_since_zoom + dt
				if self.should_push_down and self.time_since_zoom > .25 then
					self.distancetarget = self.distance - self.zoomstep
				end
			end
			if self.target ~= nil then
				local x, y, z = self.target.Transform:GetWorldPosition()
				if x == nil or y == nil or z == nil then
					if InGame() then
						self:SetTarget(GLOBAL.ThePlayer)
					end
					return
				end
				self.targetpos.x = x + self.targetoffset.x
				self.targetpos.y = y + self.targetoffset.y
				self.targetpos.z = z + self.targetoffset.z
			end
			self.currentpos.x = lerp(self.currentpos.x, self.targetpos.x, pangain)
			self.currentpos.y = lerp(self.currentpos.y, self.targetpos.y, pangain)
			self.currentpos.z = lerp(self.currentpos.z, self.targetpos.z, pangain)
		end
		local screenxoffset = 0
		while #self.screenoffsetstack > 0 do
			if self.screenoffsetstack[1].ref.inst:IsValid() then
				screenxoffset = self.screenoffsetstack[1].xoffset
				break
			end
			GLOBAL.table.remove(self.screenoffsetstack, 1)
		end
		if screenxoffset ~= 0 then
			self.currentscreenxoffset = lerp(self.currentscreenxoffset, screenxoffset, pangain)
		elseif self.currentscreenxoffset ~= 0 then
			self.currentscreenxoffset = lerp(self.currentscreenxoffset, 0, pangain)
			if GLOBAL.math.abs(self.currentscreenxoffset) < .01 then
				self.currentscreenxoffset = 0
			end
		end
		if self.shake ~= nil then
			local shakeOffset = self.shake:Update(dt)
			if shakeOffset ~= nil then
				local rightOffset = self:GetRightVec() * shakeOffset.x
				self.currentpos.x = self.currentpos.x + rightOffset.x
				self.currentpos.y = self.currentpos.y + rightOffset.y + shakeOffset.y
				self.currentpos.z = self.currentpos.z + rightOffset.z
			else
				self.shake = nil
			end
		end
		self.heading = normalize(self.heading)
		self.headingtarget = normalize(self.headingtarget)
		local diffheading = GLOBAL.math.abs(self.heading - self.headingtarget)
		self.heading =
			diffheading <= .01 and
			self.headingtarget or
			lerp(self.heading,
				diffheading <= 180 and
				self.headingtarget or
				self.headingtarget + (self.heading > self.headingtarget and 360 or -360),
				dt * self.headinggain)
		self.distance =
			GLOBAL.math.abs(self.distance - self.distancetarget) > .01 and
			lerp(self.distance, self.distancetarget, dt * self.distancegain) or
			self.distancetarget
		self.pitch = lerp(self.mindistpitch, self.maxdistpitch, (self.distance - self.mindist) / (self.maxdist - self.mindist))
		self:onupdatefn(dt)
		self:Apply()
		self:UpdateListeners(dt)
	end
end

if GetModConfigData("OBC_FUNCTION_KEY_1") then
	GLOBAL.TheInput:AddKeyUpHandler(GetModConfigData("OBC_FUNCTION_KEY_1"), ChangeViewMode)
end

if GetModConfigData("OBC_FUNCTION_KEY_2") then
	GLOBAL.TheInput:AddKeyUpHandler(GetModConfigData("OBC_FUNCTION_KEY_2"), ShowOrHideHUD)
end

if GetModConfigData("OBC_FUNCTION_KEY_3") then
	GLOBAL.TheInput:AddKeyUpHandler(GetModConfigData("OBC_FUNCTION_KEY_3"), ShowOrHidePlayer)
end

if GetModConfigData("OBC_SWITCH_KEY_1") then
	GLOBAL.TheInput:AddKeyUpHandler(GetModConfigData("OBC_SWITCH_KEY_1"), ChangeCameraTarget)
end

if GetModConfigData("OBC_SWITCH_KEY_2") then
	GLOBAL.TheInput:AddKeyUpHandler(GetModConfigData("OBC_SWITCH_KEY_2"), ChangeCameraPosition)
end

if GetModConfigData("OBC_RESET_KEY") then
	GLOBAL.TheInput:AddKeyUpHandler(GetModConfigData("OBC_RESET_KEY"), ResetCameraTarget)
end

GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_EQUALS, function() AddFOV(1) end)
GLOBAL.TheInput:AddKeyDownHandler(GLOBAL.KEY_MINUS, function() AddFOV(-1) end)

AddClassPostConstruct('cameras/followcamera', FollowCameraPostConstruct)
