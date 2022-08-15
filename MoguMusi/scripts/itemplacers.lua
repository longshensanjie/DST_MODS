local itemplacer = Class(function(self)
    self.placer = nil
    self.item = nil
    self.pos = {  }
end)
function itemplacer:GetItem(item)
    if item ~=nil then
        local recipe=_G.AllRecipes[item]
        local placerName = recipe.placer
        return placerName
    end
    local placerItem = ThePlayer.replica.inventory:GetActiveItem()
    if placerItem ~= nil and placerItem.replica.inventoryitem ~= nil and placerItem.components
    then
        local seedInvitem = placerItem.replica.inventoryitem
        local placerName = seedInvitem:GetDeployPlacerName()
        if PrefabExists(placerName) then
            return placerName
        end
    end
    if ThePlayer.components.playercontroller.placer then
        local playercontroller = ThePlayer.components.playercontroller
        local recipe = playercontroller.placer_recipe
        local placerName = recipe.placer
        return placerName
    end

end
function itemplacer:ShowPlacer(pos)
    if not pos then
        return
    end
    local placerName= self:GetItem()
    local np={}
local special=ThePlayer.components.deploydata.scheme
if special == "" then
    for k, v in pairs(pos) do
        table.insert(np,{itemplacer=placerName,x=v.x,z=v.z})
    end
    else
        for k, v in pairs(pos) do
            placerName  = self:GetItem(v.item)
            table.insert(np,{itemplacer=placerName,x=v.x,z=v.z})
        end
end


    --local placerName = self:GetItem()
    if not placerName then
        return
    end
    if self.placer ~= nil then
        return
    end
    self.pos=np
    self.placer = {}
    for _,v in pairs(self.pos) do
        self:SpawnDeployPlacer(v.itemplacer)
    end
    self:OnUpdate()
end
function itemplacer:SpawnDeployPlacer(placerName)
    local deployPlacer = SpawnPrefab(placerName)
    if not deployPlacer then
        return
    end
    table.insert(self.placer, deployPlacer)
    return deployPlacer
end
function itemplacer:OnUpdate()
    if self.placer then
        for k, v in pairs(self.placer) do
            local rot = (k - 1) * ThePlayer.components.deploydata.step
            v.Transform:SetPosition(self.pos[k].x, 0, self.pos[k].z)
            v.Transform:SetRotation(90 - rot)
            v.AnimState:SetAddColour(.25, .75, .25, 0)
        end
        if self.placer[1] then
            self.placer[1].AnimState:SetAddColour(.25, .25, .75, 0)
        end
    end
end
function itemplacer:HidePlacer()
    if self.placer == nil then
        return
    end
    for _, iv in pairs(self.placer) do
        iv:Remove()
    end
    self.placer = nil
end
return itemplacer