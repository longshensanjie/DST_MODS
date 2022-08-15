-- 传送标点
local function ValidateAction(self)
    local act = self:GetRightMouseAction()
    local equip = GetEquippedItemFrom("hands")

    return act
       and act.action == ACTIONS.CASTSPELL and equip and equip.prefab == "telestaff"
end
local function SetCol(inst,col)
	if col then
		inst.AnimState:SetMultColour(col[1],col[2],col[3],col[4])
	end
end
local function sf_start(x,z)
    local COL_YELLOW = {1,0.8,0,1}
    local COL_WHITE = {1,1,1,1}
	local jiantou = GLOBAL.SpawnPrefab("private_arrow_down")
	local yuan1 = GLOBAL.SpawnPrefab("private_circle")
	local yuan2 = GLOBAL.SpawnPrefab("private_circle")
	local centor = GLOBAL.SpawnPrefab("private_circle")
	TheWorld:DoTaskInTime(0,function()
		jiantou.Transform:SetPosition(x, 0, z)

		yuan1.Transform:SetPosition(x, 0, z)
		yuan1.Transform:SetRotation(8)
		yuan1:SetRadius(666)
		SetCol(yuan1, COL_YELLOW)

		yuan2.Transform:SetPosition(x, 0, z)
		yuan2.Transform:SetRotation(0)
		yuan2:SetRadius(666)
		SetCol(yuan2, COL_YELLOW)

		centor.Transform:SetPosition(x, 0, z)
		centor:SetRadius(777)
		SetCol(centor, COL_WHITE)
	end)
end

AddComponentPostInit("playercontroller", function(self, inst)
    if inst ~= ThePlayer then return end
    local OldOnRightClick = self.OnRightClick
    function self:OnRightClick(down)
        if down and ValidateAction(self) then
            local ent = TheInput:GetWorldEntityUnderMouse()
            if ent and ent.prefab and not ent:HasTag("player") then
                local x, _, z = ent.Transform:GetWorldPosition()
                sf_start(x,z)
                TIP("传送标点","purple","坐标：("..tostring(math.ceil(x)).."，"..tostring(math.ceil(z))..")","chat")
            end
        end

        OldOnRightClick(self, down)
    end
end)
