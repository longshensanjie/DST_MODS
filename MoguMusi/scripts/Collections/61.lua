--取消施法限制
local point_actions = {
    [GLOBAL.ACTIONS.CASTSPELL] = true,
    [GLOBAL.ACTIONS.ROW] = false,
}

local PlayerController = require("components/playercontroller")

local GetRightMouseAction = PlayerController.GetRightMouseAction
function PlayerController:GetRightMouseAction(...)
    local act = GetRightMouseAction(self, ...)
    if not (GLOBAL.TheInput:GetHUDEntityUnderMouse() or self:IsAOETargeting() or self.placer_recipe)
        and (act == nil or act.action == GLOBAL.ACTIONS.LOOKAT) 
    then

        local pos = GLOBAL.TheInput:GetWorldPosition()
        local useitem = self.inst.replica.inventory and self.inst.replica.inventory:GetActiveItem()
        local equipitem = self.inst.replica.inventory and self.inst.replica.inventory:GetEquippedItem(GLOBAL.EQUIPSLOTS.HANDS)
        local target = GLOBAL.TheInput:GetWorldEntityUnderMouse()
        local temp_act

        if useitem and useitem:IsValid() then
                temp_act = self.inst.components.playeractionpicker:GetPointActions(pos, useitem, true, target)[1]

        elseif equipitem and equipitem:IsValid() then
                temp_act = self.inst.components.playeractionpicker:GetPointActions(pos, equipitem, true, target)[1]

        end
        -- if (temp_act == nil or temp_act == act) and TheInput:IsKeyDown(KEY_LCTRL) then
        --     temp_act = self.inst.components.playeractionpicker:GetPointSpecialActions(pos, useitem, true)[1]
        -- end

        if temp_act and point_actions[temp_act.action] ~= nil then
            act = temp_act
        end
    end
    self.RMBaction = act
    return self.RMBaction
end

local OnRightClick = PlayerController.OnRightClick
function PlayerController:OnRightClick(down, ...)
    if not down or GLOBAL.TheInput:GetHUDEntityUnderMouse() or self:IsAOETargeting() or self.placer_recipe then
        return OnRightClick(self, down, ...)
    end
    local act = self:GetRightMouseAction()
    if act and not act.target and point_actions[act.action] ~= nil then
        local ent = point_actions[act.action] and not GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_CTRL) and GLOBAL.TheInput:GetWorldEntityUnderMouse()
        local pos = ent and ent:GetPosition() or GLOBAL.TheInput:GetWorldPosition()
        act:SetActionPoint(pos)
        local platform, pos_x, pos_z = self:GetPlatformRelativePosition(pos.x, pos.z)
        if not self.ismastersim then
            if self.locomotor == nil then
                self.remote_controls[GLOBAL.CONTROL_SECONDARY] = 0
                GLOBAL.SendRPCToServer(GLOBAL.RPC.RightClick, act.action.code, pos_x, pos_z, nil, nil, nil, nil, nil, nil, platform, platform ~= nil)
            elseif self:CanLocomote() then
                act.preview_cb = function()
                    self.remote_controls[GLOBAL.CONTROL_SECONDARY] = 0
                    GLOBAL.SendRPCToServer(GLOBAL.RPC.RightClick, act.action.code, pos_x, pos_z, nil, nil, nil, nil, nil, nil, platform, platform ~= nil)
                end
            end
        end
        self:DoAction(act)
        return
    end
    return OnRightClick(self, down, ...)
end
