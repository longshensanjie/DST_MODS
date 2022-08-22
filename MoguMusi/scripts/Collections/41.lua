AddMinimapAtlas("images/mappin.xml")

local ICON_ENABLE = true

local INTERVAL_DBCLICK = 0.3
local MOVETASK_PERIOD = 2
local OFFSET_MUL = 2

local lastclick_time = 0
local keepmove_flag =false
local move_task = nil
local interrupt_controls = {}

for control = GLOBAL.CONTROL_ATTACK, GLOBAL.CONTROL_MOVE_RIGHT do
    interrupt_controls[control] = true	 
end



local function MakePin()
    local inst = GLOBAL.CreateEntity()
    inst.entity:AddTransform()
    -- inst.entity:AddAnimState()
    -- inst.entity:AddSoundEmitter()
    inst.entity:AddMiniMapEntity()
    inst.MiniMapEntity:SetIcon("mappin.tex")
    inst.MiniMapEntity:SetPriority(5)
    inst.MiniMapEntity:SetDrawOverFogOfWar(true)
    inst.MiniMapEntity:SetCanUseCache(false)
    inst.MiniMapEntity:SetEnabled(false)
    inst.entity:SetCanSleep(false)
    return inst
end

local mappin1 = MakePin()
local mappin2 = MakePin()
mappin1.MiniMapEntity:SetIsProxy(true)
mappin2.MiniMapEntity:SetIsProxy(false)

local function SetPin(x, y, z)
    mappin1.Transform:SetPosition(x, y, z)
    mappin2.Transform:SetPosition(x, y, z)
    mappin1.MiniMapEntity:SetEnabled(true)
    mappin2.MiniMapEntity:SetEnabled(true)
end

local function StopAutoMoving(forcestop)
	if keepmove_flag then
	----cancel the task----
		if move_task ~= nil then
			--print("cancel current task:",move_task)
			move_task:Cancel()
			move_task = nil
		end
	---stop the step ------	
		if forcestop then
			if GLOBAL.ThePlayer.components.locomotor ~= nil then
				GLOBAL.ThePlayer.components.locomotor:Stop()
				GLOBAL.ThePlayer.components.locomotor:Clear()
			else
				--GLOBAL.SendRPCToServer(GLOBAL.RPC.StopWalking)
				local angle = (GLOBAL.ThePlayer:GetRotation())*GLOBAL.DEGREES
				local offset_x = math.cos(angle)*OFFSET_MUL
				local offset_z = -math.sin(angle)*OFFSET_MUL
				local x,_,z =GLOBAL.ThePlayer:GetPosition():Get()
				GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, GLOBAL.ACTIONS.WALKTO.code, x+offset_x, z+offset_z) --it may cause go back a short distance
																												--because of the lag of communicate 
																												--between client and server
																												--so add a offset to make up
																												--EXCEPT arrive the destination
			end
		end
	---remove the pin------
		mappin1.MiniMapEntity:SetEnabled(false)
		mappin2.MiniMapEntity:SetEnabled(false)
	---reset the flag------
		keepmove_flag = false
	end

end


local function IsInGame()
	return GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD
end

local function IsInTyping()
	return  GLOBAL.ThePlayer.HUD:HasInputFocus()
end

local function IsInMap()
	return GLOBAL.ThePlayer.HUD:IsMapScreenOpen()

end

local function IsCursorOnHUD()
	local input = GLOBAL.TheInput
	return input.hoverinst and input.hoverinst.Transform == nil and input.hoverinst.entity:IsVisible() 
	--idk why function GetHUDEntityUnderMouse() sometime return false because of the hoverinst.entity:Isvalid()
	--so i remove it 
end

local function Go_PredictON(player, pos)
	if not keepmove_flag then return false end
	if player.components.locomotor == nil then StopAutoMoving() return false end 
	
	local target_pos = pos
	local act = GLOBAL.BufferedAction(GLOBAL.ThePlayer, nil, GLOBAL.ACTIONS.WALKTO, nil, target_pos)
	player.components.playercontroller:DoAction(act)

end


local function Go_PredictOFF(player, pos)
	if not keepmove_flag then return false end
	if player.components.locomotor ~= nil then StopAutoMoving() return false end
	
	local player_pos = player:GetPosition()
	local target_pos = pos
	local act
	if player_pos:DistSq(target_pos) >4096 then -------see function IsPointInRange in networkclientrpc.lua
												--out of range ,divide the path 
		target_pos = (target_pos-player_pos):GetNormalized()* (math.sqrt(4096)-GLOBAL.TILE_SCALE)+player_pos --considering Player_pos change in short times
																											 --may lead to out of range							
		act = GLOBAL.BufferedAction(player, nil, GLOBAL.ACTIONS.WALKTO, nil, target_pos)
		GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, act.action.code, target_pos.x, target_pos.z, nil, nil, nil, act.action.canforce, act.action.mod_name)
		
	elseif player_pos:DistSq(target_pos) > 4 then --PIN in the range ,go util near the dest 
		act = GLOBAL.BufferedAction(player, nil, GLOBAL.ACTIONS.WALKTO, nil, target_pos)
		GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, act.action.code, target_pos.x, target_pos.z, nil, nil, nil, act.action.canforce, act.action.mod_name)
	else --arrive the dest ,finish movetask
		StopAutoMoving(false)	--dont forcestop
		
	end
	
end



AddClassPostConstruct(
    "screens/mapscreen",
    function(self)
        local OnControl_old = self.OnControl
        self.OnControl = function(self, control, down)

            if control == GLOBAL.CONTROL_SECONDARY and down then
                --print("lastclick:",lastclick_time)
                if (GLOBAL.GetTime() - lastclick_time) < INTERVAL_DBCLICK then
                    if OnControl_old then
                        OnControl_old(self, control, down)
                        --print("old_rightclick")
                    end
                else


                    local topscreen = GLOBAL.TheFrontEnd:GetActiveScreen()
                    if topscreen.minimap ~= nil then
                        local mousepos = GLOBAL.TheInput:GetScreenPosition()
                        local mousewidgetpos = topscreen:ScreenPosToWidgetPos(mousepos)
                        local mousemappos = topscreen:WidgetPosToMapPos(mousewidgetpos)
                        local x, z = topscreen.minimap:MapPosToWorldPos(mousemappos:Get())
                        SetPin(x, 0, z)
                        local target_pos = GLOBAL.Vector3(x, 0, z)

                        keepmove_flag = true
                        --movment prediction enable
                        if GLOBAL.ThePlayer.components.playercontroller.locomotor ~= nil then
                            GLOBAL.ThePlayer:DoTaskInTime(0.1, Go_PredictON, target_pos)

                        else --movment prediction disable
                            if move_task ~= nil then
                                --print("cancel last task:",move_task)
                                move_task:Cancel()
                                move_task = nil
                            end

                            move_task = GLOBAL.ThePlayer:DoPeriodicTask(MOVETASK_PERIOD, Go_PredictOFF, 0.1, target_pos)
                            --print("add:",move_task)

                        end
                    end
                end
                lastclick_time = GLOBAL.GetTime()
            else --control except mouserightdown
                if OnControl_old then
                    OnControl_old(self, control, down)
                end
            end
        end


    end)

AddComponentPostInit("playercontroller", function(self)
    local OnControl_old = self.OnControl
    self.OnControl = function(self, control, down)

        OnControl_old(self, control, down)

        if keepmove_flag and IsInGame() then

            --print("InGame",IsInGame(),"InMap:",IsInMap(),"Intype:",IsInTyping())
            --when you open the map and type in command box it actually IsNotInMap

            --press Direction key in game screen
            if not IsInMap() and not IsInTyping() and interrupt_controls[control] then
                StopAutoMoving(true) --forcestop
                --press space key in map screen
            elseif IsInMap() and control == GLOBAL.CONTROL_ACTION then
                StopAutoMoving(true) --forcestop
                --press button key except your backpack,craftmenu and other HUD
            elseif not IsInMap() and not IsInTyping() and not IsCursorOnHUD() and
                (control == GLOBAL.CONTROL_PRIMARY or control == GLOBAL.CONTROL_SECONDARY) then
                StopAutoMoving(false) --dont forcestop when mouseclick in the world,it will interrupt the original action
                --print("hoverinst:",GLOBAL.TheInput.hoverinst,"valid:",GLOBAL.TheInput.hoverinst.entity:IsValid(),"visible:",GLOBAL.TheInput.hoverinst.entity:IsVisible())
            end
        end

    end


end)         
