GLOBAL.TUNING.LANG = "ch_s"
local showposition=GetModConfigData("sw_planting") == "pos"
local force_center_and_corners = true
local gridplacer, range, center_x, center_z
local ignore_key = false
local RoundDeployScreen = require("widgets/RoundDeployScreen")
local startdeploy=require("startdeploy")
if GLOBAL.TheNet:GetServerGameMode() == "lavaarena" then
    return
end

local function set_ignore()
    ignore_key = true
end
local function GetActiveScreenName()
    local screen = GLOBAL.TheFrontEnd:GetActiveScreen()
    return screen and screen.name or ""
end
local function IsDefaultScreen()
    return GetActiveScreenName():find("HUD") ~= nil
end


AddComponentPostInit("playercontroller", function(self,inst)
    if inst ~= GLOBAL.ThePlayer then return end
    GLOBAL.ThePlayer:AddComponent("deploydata")
end)
local function HighlightCenterFarm()
    local rd = GLOBAL.ThePlayer.components.deploydata
    local x, _, z = GLOBAL.TheInput:GetWorldPosition():Get()
    if force_center_and_corners  then
        center_x = math.floor(x / 2 + 0.5) * 2
        center_z = math.floor(z / 2 + 0.5) * 2
    else
        center_x = x
        center_z = z
    end
    rd.center_x = center_x
    rd.center_z = center_z
    if not range then
        range = GLOBAL.SpawnPrefab("deployrange")
    end
    local R =math.abs(rd.radius)
    local scale = math.sqrt(R * 0.16)
    range.Transform:SetPosition(center_x, 0, center_z)
    range.Transform:SetScale(scale, scale, scale)
    range:Show()
    if not gridplacer then
        if GLOBAL.PrefabExists("buildgridplacer") then
            gridplacer = GLOBAL.SpawnPrefab("buildgridplacer")
            gridplacer.AnimState:PlayAnimation("on", true)
            gridplacer.Transform:SetScale(1.7, 1.7, 1.7)
        else
            gridplacer = GLOBAL.SpawnPrefab("gridplacer")
        end
    end
    gridplacer:Show()
    gridplacer.Transform:SetPosition(center_x, 0, center_z)
end
local function PushOptionsScreen()
    local rd = GLOBAL.ThePlayer.components.deploydata
    local screen = RoundDeployScreen(GLOBAL.ThePlayer)
    local spacing
    if GLOBAL.ThePlayer.components.playercontroller.placer then
        local playercontroller = GLOBAL.ThePlayer.components.playercontroller
        local recipe = playercontroller.placer_recipe
        spacing = recipe.min_spacing
    end
local item=GLOBAL.ThePlayer.replica.inventory:GetActiveItem()
if not spacing and item then
    if item.replica.inventoryitem and item.replica.inventoryitem:DeploySpacingRadius() then
        spacing = item.replica.inventoryitem:DeploySpacingRadius()
    end
end

    --screen.owner = ThePlayer
    screen.inv = spacing
    for name, button in pairs(screen.mode_buttons) do
        if name == rd:getMode() then
            button:Select()
        else
            button:Unselect()
        end
    end
    for name, button in pairs(screen.shape_buttons) do
        if name == rd.shape then
            button:Select()
        else
            button:Unselect()
        end
    end
    screen:upvalue(rd)
    screen.refresh:SetSelected(rd.space)
    screen.toggle_key = GetModConfigData("plant_setting")
    screen.callback.ignore=set_ignore
    GLOBAL.TheFrontEnd:PushScreen(screen)
end
GLOBAL.TheInput:AddKeyUpHandler(GetModConfigData("plant_deploy"), function()
    if not InGame() then
        return
    end
    local sd=startdeploy(GLOBAL.ThePlayer)
    sd:ClearStationThread()
    if GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_TRADE) then
        if gridplacer then
            gridplacer:Hide()
        end
        if range then
            range:Hide()
        end
        center_x, center_z = nil, nil
    elseif GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_STACK) then
        HighlightCenterFarm()
    elseif center_x and center_z then
        sd:StartAutoDeploy()
    end
end)
GLOBAL.TheInput:AddKeyUpHandler(GetModConfigData("plant_setting"), function()
    if not InGame() then
        return
    end
    if IsDefaultScreen() then
        if ignore_key then
            ignore_key = false
        else
            PushOptionsScreen()
        end
    end
end)
GLOBAL.TheInput:AddKeyUpHandler(GetModConfigData("plant_placer"), function()
    if not InGame() then
        return
    end
    local sd=startdeploy(GLOBAL.ThePlayer)
    sd:Hide()
end)
GLOBAL.TheInput:AddKeyDownHandler(GetModConfigData("plant_placer"), function()
    if not InGame() then
        return
    end
    local sd=startdeploy(GLOBAL.ThePlayer)
    sd:Show()
end)

local function GetPositionStr()
    local x, _, z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
    return string.format("%.2f", x)..","..string.format("%.2f",z)
end


local function show_position(controls)
    controls.inst:DoTaskInTime(1, function()
        local DPWidget = require "widgets/displayposition"
        controls.dp = controls.top_root:AddChild(DPWidget(1))
        local hudscale = controls.top_root:GetScale()
        local screenw_full,_= GLOBAL.TheSim:GetScreenSize()
        local width = screenw_full / hudscale.x
        controls.dp.num:SetPosition(-width/2+100, -25)
        if showposition then
            local OnUpdate_base = controls.OnUpdate
            controls.OnUpdate = function(self, dt)
                OnUpdate_base(self, dt)
                local str = GetPositionStr()
                controls.dp.num:SetString(str)
            end
        end
    end)
end
if showposition then
    AddClassPostConstruct("widgets/controls", show_position)
end

