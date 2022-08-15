local Step = { 0, 1, 1.5, 2, 2.5, 3, 4, 4.5, 5, 6, 7.5, 8, 9, 10, 12, 15, 18, 20, 24, 30, 36, 40, 60, 180 }
local station_thread
local station_thread_id = "station_builder_thread"
local shape = require("shape")
local itemplacer = require("itemplacers")
local RoundDeploy = Class(function(self, inst)
    self.inst = inst
    self.Step = 8           --圆心角
    self.Radius = 15        --半径
    self.StartAngle = 0     --旋转角度
    self.Interval = 2       --间隔
    self.Center_x = 0
    self.Center_z = 0
    self.Shape = "circle"
    self.Mode = "radiusangle"
end)
function RoundDeploy:SetParam()
    if self.Mode == "radiusangle" then
        local a = self.Interval
        local b = self.Radius
        local OldStep = math.deg(math.acos((2 * b ^ 2 - a ^ 2) / (2 * b ^ 2)))
        for _, v in pairs(Step) do
            if OldStep <= v then
                self.Step = v
                break
            end
        end
    elseif self.Mode == "angleradius" then
        local a = self.Interval
        local A = self.Step
        local radius = a / (2 * math.cos(math.rad(90 - A / 2)))
        self.Radius = math.ceil(radius)

    end
end
function RoundDeploy:SetInterval(buildspacing)
    if buildspacing then
        self.Interval = buildspacing
        return
    end
    local item = self:GetActiveItem()
    if not item then
        return false
    end
    if item.replica.inventoryitem and item.replica.inventoryitem:DeploySpacingRadius() and item.replica.inventoryitem:DeploySpacingRadius() ~= 0 then
        self.Interval = item.replica.inventoryitem:DeploySpacingRadius()
    end
end
function RoundDeploy:GetParams()
    self:SetParam()
    return self.Radius, 360 / self.Step, self.StartAngle, self.Interval
end
function RoundDeploy:GetActiveItem()
    return self.inst.replica.inventory:GetActiveItem()
end
function RoundDeploy:GetNewActiveItem(prefab)
    local inventory = self.inst.replica.inventory
    local body_item = inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    local backpack = body_item and body_item.replica.container
    for _, inv in pairs(backpack and { inventory, backpack } or { inventory }) do
        for slot, item in pairs(inv:GetItems()) do
            if item and item.prefab == prefab then
                inv:TakeActiveItemFromAllOfSlot(slot)
                return item
            end
        end
    end
end
function RoundDeploy:GetPosition()
    if self.Shape == "cardioid" then
        return shape:GetCardioidPosition()
    elseif self.Shape == "straight" then
        return shape:GetStraightPosition()
    elseif self.Shape == "circle" then
        return shape:GetCirclePosition()
    elseif self.Shape == "square" then
        return shape:GetSquarePosition()
    end
end
function RoundDeploy:GetAction(pos, item, rightclick)
    local active_item = self:GetActiveItem() or self:GetNewActiveItem(item.prefab)
    if not active_item then
        return false
    end
    local inventoryitem = active_item.replica.inventoryitem
    if inventoryitem and inventoryitem:CanDeploy(pos, nil, self.inst) and rightclick then
        return BufferedAction(self.inst, nil, ACTIONS.DEPLOY, active_item, pos), true
    end
    if not rightclick then
        return BufferedAction(self.inst, nil, ACTIONS.DROP, active_item, pos)
    end
end
function RoundDeploy:SendRPC(act, rightclick)
    local playercontroller = self.inst.components.playercontroller
    if playercontroller.ismastersim then
        playercontroller:DoAction(act)
        return
    end
    local pos = act:GetActionPoint() or self.inst:GetPosition()
    local controlmods = 10
    if playercontroller.locomotor then
        act.preview_cb = function()
            if rightclick then
                SendRPCToServer(RPC.RightClick, act.action.code, pos.x, pos.z, nil, act.rotation, true, nil, nil, act.action.mod_name)
            else
                SendRPCToServer(RPC.LeftClick, act.action.code, pos.x, pos.z, nil, true, controlmods, nil, act.action.mod_name)
            end
        end
        playercontroller:DoAction(act)
    else
        if rightclick then
            SendRPCToServer(RPC.RightClick, act.action.code, pos.x, pos.z, nil, act.rotation, true, nil, act.action.canforce, act.action.mod_name)
        else
            SendRPCToServer(RPC.LeftClick, act.action.code, pos.x, pos.z, nil, true, controlmods, act.action.canforce, act.action.mod_name)
        end
    end
end
function RoundDeploy:ClearStationThread()
    if station_thread then
        KillThreadsWithID(station_thread.id)
        station_thread:SetList(nil)
        station_thread = nil
    end
end
function RoundDeploy:Wait(time)
    Sleep(FRAMES * time)
    repeat
        Sleep(FRAMES * time)
    until not (self.inst.sg and self.inst.sg:HasStateTag("moving")) and not self.inst:HasTag("moving")
            and self.inst:HasTag("idle") and not self.inst.components.playercontroller:IsDoingOrWorking()
    for control = _G.CONTROL_PRIMARY, _G.CONTROL_MOVE_RIGHT do
        TheInput:AddControlHandler(control, function(down)
            if down and station_thread then
                self:ClearStationThread()
            end
        end)
    end
end
function RoundDeploy:StartAutoDeploy()
    local position = self:GetPosition()
    if self.inst.components.playercontroller.placer then
        local playercontroller = self.inst.components.playercontroller
        local recipe = playercontroller.placer_recipe
        local skin = playercontroller.placer_recipe_skin
        local builder = self.inst.replica.builder
        station_thread = StartThread(function()
            for a, pos in pairs(position) do
                local rot = (a - 1) * self.Step
                if builder:CanBuildAtPoint(pos, recipe, 90 - rot) then
                    builder:MakeRecipeAtPoint(recipe, pos, 90 - rot, skin)
                    self:Wait(4)
                end
                if not builder:IsBuildBuffered(recipe.name) then
                    if not builder:CanBuild(recipe.name) then
                        return false
                    end
                    builder:BufferBuild(recipe.name)
                end
            end
            self:Wait(4)
            self:ClearStationThread()
        end, station_thread_id)
    elseif self:GetActiveItem() then
        local item = self:GetActiveItem()
        station_thread = StartThread(function()
            for _, pos in pairs(position) do
                local act = self:GetAction(pos, item, true)
                if act then
                    self:SendRPC(act, true)
                    self:Wait(4)
                end
            end
            self:Wait(4)
            self:ClearStationThread()
        end, station_thread_id)
    else
        local items = self.inst.replica.inventory:GetItems()
        if items and items[1] ~= nil then
            local item = items[1]
            station_thread = StartThread(function()
                for _, pos in pairs(position) do
                    local act = self:GetAction(pos, item, false)
                    if act then
                        self:SendRPC(act, false)
                        self:Wait(4)
                    end
                end
                self:Wait(4)
                self:ClearStationThread()
            end, station_thread_id)
        end
    end
end
function RoundDeploy:Show()
    itemplacer:ShowPlacer()
end
function RoundDeploy:Hide()
    itemplacer:HidePlacer()
end

return RoundDeploy