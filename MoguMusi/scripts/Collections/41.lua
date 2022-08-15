AddMinimapAtlas("images/mappin.xml")
local canTele = GetModConfigData("sw_justgo")
if canTele == "canTele" then canTele = true else canTele = false end

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
local function SendCommand(a)
    local b, c, d = GLOBAL.TheSim:ProjectScreenPos(GLOBAL.TheSim:GetPosition())
    local e = GLOBAL.TheNet:GetIsClient() and GLOBAL.TheNet:GetIsServerAdmin()
    if e then
        GLOBAL.TheNet:SendRemoteExecute(a, b, d)
    else
        GLOBAL.ExecuteConsoleCommand(a)
    end
end
AddClassPostConstruct("screens/mapscreen", function(self)
    local OnMouseButton_old = self.OnMouseButton
    self.OnMouseButton = function(self, button, down, x, y)
        if OnMouseButton_old then
            OnMouseButton_old(self, button, down, x, y)
        end
        local jd = GLOBAL.ThePlayer and GLOBAL.ThePlayer.prefab == "wortox"
        if down 
        and ((jd and button == GLOBAL.MOUSEBUTTON_MIDDLE)
            or (not jd and button == GLOBAL.MOUSEBUTTON_RIGHT)
        )
        then
            local topscreen = GLOBAL.TheFrontEnd:GetActiveScreen()
            if topscreen.minimap ~= nil then
                local mousepos = GLOBAL.TheInput:GetScreenPosition()
                local mousewidgetpos = topscreen:ScreenPosToWidgetPos(mousepos)
                local mousemappos = topscreen:WidgetPosToMapPos(mousewidgetpos)
                local x, y, z = topscreen.minimap:MapPosToWorldPos(mousemappos:Get())
                SetPin(x, 0, y)
                local target_pos = GLOBAL.Vector3(x, 0, y)
                if GLOBAL.ThePlayer.components.locomotor then
                    GLOBAL.ThePlayer.components.playercontroller:DoAction(
                        GLOBAL.BufferedAction(GLOBAL.ThePlayer, nil, GLOBAL.ACTIONS.WALKTO, nil, target_pos))
                else
                    if GLOBAL.ThePlayer.Transform then
                        local pos_x,pos_y,pos_z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
                        local numy = y - pos_z
                        local numx = x - pos_x
                        if numy ~=0 and numx ~= 0 then
                            local absx = math.abs(numx)
                            local absy = math.abs(numy)
                            if absx > absy then
                                numx = numx / absx
                                numy = numy / absx
                            else
                                numx = numx / absy
                                numy = numy / absy
                            end 
                            GLOBAL.SendRPCToServer(GLOBAL.RPC.DirectWalking, numx/2, numy/2)
                        end
                    end
                end
                -- 开启创造模式就直接飞过去
                if canTele and GLOBAL.ThePlayer.player_classified and GLOBAL.ThePlayer.player_classified.isfreebuildmode:value() then
                    local a, _, b = target_pos:Get()
					if not a or not b then return end
                    SendCommand("ThePlayer.Transform:SetPosition(" .. a .. "," .. "0," .. b .. ")")
                end
            end
        end
    end
end)
