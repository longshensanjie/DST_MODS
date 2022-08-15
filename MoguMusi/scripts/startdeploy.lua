local itemplacer = require("itemplacers")
local station_thread
local station_thread_id = "station_builder_thread"
local RoundDeploy = Class(function(self, owner)
    self.owner = owner
end)
function RoundDeploy:GetPosition()
local deploydata=self.owner.components.deploydata
if deploydata.scheme ~="" then
    return deploydata:GetSpecialPosition()
end
    if deploydata.shape == "cardioid" then
        return deploydata:GetCardioidPosition()
    elseif deploydata.shape == "straight" then
        return deploydata:GetStraightPosition()
    elseif deploydata.shape == "circle" then
        return deploydata:GetCirclePosition()
    elseif deploydata.shape == "square" then
        return deploydata:GetSquarePosition()
    end
end

function RoundDeploy:GetActiveItem()
    return self.owner.replica.inventory:GetActiveItem()
end
function RoundDeploy:GetNewActiveItem(prefab)
    local inventory = self.owner.replica.inventory
    local body_item = inventory:GetEquippedItem(EQUIPSLOTS.BODY)
    local back_item = inventory:GetEquippedItem(EQUIPSLOTS.BACK)
    local backpack =(back_item and back_item.replica.container) or (body_item and body_item.replica.container)
    for _, inv in pairs(backpack and { inventory, backpack } or { inventory }) do
        for slot, item in pairs(inv:GetItems()) do
            if item and item.prefab == prefab then
                inv:TakeActiveItemFromAllOfSlot(slot)
                return item
            end
        end
    end
end
function RoundDeploy:GetAction(pos, item, rightclick)
    local active_item = self:GetActiveItem() or self:GetNewActiveItem(item.prefab)
    if not active_item then
        return false
    end
    local inventoryitem = active_item.replica.inventoryitem
    if inventoryitem and inventoryitem:CanDeploy(pos, nil, self.owner) and rightclick then
        return BufferedAction(self.owner, nil, ACTIONS.DEPLOY, active_item, pos), true
    end
    if not rightclick then
        return BufferedAction(self.owner, nil, ACTIONS.DROP, active_item, pos)
    end
end
function RoundDeploy:SendRPC(act, rightclick)
    local playercontroller = self.owner.components.playercontroller
    if playercontroller.ismastersim then
        playercontroller:DoAction(act)
        return
    end
    local pos = act:GetActionPoint() or self.owner:GetPosition()
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
    until not (self.owner.sg and self.owner.sg:HasStateTag("moving")) and not self.owner:HasTag("moving")
            and self.owner:HasTag("idle") and not self.owner.components.playercontroller:IsDoingOrWorking()
    for control = _G.CONTROL_PRIMARY, _G.CONTROL_MOVE_RIGHT do
        TheInput:AddControlHandler(control, function(down)
            if down and station_thread then
                self:ClearStationThread()
            end
        end)
    end
end
 function RoundDeploy:DoPlant(position)
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
    end, station_thread_id)
end
function RoundDeploy:DoDrop(position)
    local items = self.owner.replica.inventory:GetItems()
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
            end, station_thread_id)
        end
end

function RoundDeploy:DoBuilding(position)
    local playercontroller = self.owner.components.playercontroller
        local recipe = playercontroller.placer_recipe
        local skin = playercontroller.placer_recipe_skin
        local builder = self.owner.replica.builder
        station_thread = StartThread(function()
            for a, pos in pairs(position) do
                local rot = (a - 1) * self.owner.components.deploydata.step
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
        end, station_thread_id)
end
function RoundDeploy:DoSpecialBuilding(data)
    local builder = self.owner.replica.builder
    station_thread = StartThread(function()
        for a, i in pairs(data) do
            local rot = (a - 1) * self.owner.components.deploydata.step
            if builder:CanBuildAtPoint(Vector3(i.x,0,i.z), _G.AllRecipes[i.item], 90 - rot) and  builder:IsBuildBuffered(_G.AllRecipes[i.item].name)  then
                builder:MakeRecipeAtPoint(_G.AllRecipes[i.item], Vector3(i.x,0,i.z), 90 - rot, i.skin)
                self:Wait(12)
            end
            if not builder:IsBuildBuffered(_G.AllRecipes[i.item].name) then
                if  builder:CanBuild(_G.AllRecipes[i.item].name) then
                    builder:BufferBuild(_G.AllRecipes[i.item].name)
                end
            end
        end
        self:Wait(12)
    end, station_thread_id)
end

function RoundDeploy:StartAutoDeploy()
    local position = self:GetPosition()
    if not position then
        return
    end
    if self.owner.components.deploydata.scheme ~=""  then
        self:DoSpecialBuilding(position)
    elseif  self.owner.components.playercontroller.placer then
        self:DoBuilding(position)
    elseif self:GetActiveItem() then
       self:DoPlant(position)
    else
        self:DoDrop(position)
    end
end


function RoundDeploy:Show()
    itemplacer:ShowPlacer(self:GetPosition())
end
function RoundDeploy:Hide()
    itemplacer:HidePlacer()
end

return RoundDeploy