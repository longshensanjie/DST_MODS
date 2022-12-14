local InventoryFunctions = require "util/inventoryfunctions"
local CraftFunctions = require "util/craftfunctions"

-- local CRAFTING_ALLOWED = false
-- local AUTO_REPEAT_ACTIONS = false
local CRAFTING_ALLOWED = GetModConfigData("boas_AUTO_EQUIP_TOOL", MOD_EQUIPMENT_CONTROL.MODNAME) == 2
local AUTO_REPEAT_ACTIONS = GetModConfigData("boas_AUTO_REPEAT_ACTIONS", MOD_EQUIPMENT_CONTROL.MODNAME)

local CanOverrideAction =
{
    [ACTIONS.WALKTO] = true,
    [ACTIONS.LOOKAT] = true,
}

local CraftableTools =
{
    CHOP =
    {
        "goldenaxe",
        "axe",
    },
    MINE =
    {
        "goldenpickaxe",
        "pickaxe",
    },
}

local function GetToolAction(target)
    for toolAction in pairs(CraftableTools) do
        if target:HasTag(toolAction .. "_workable") then
            return toolAction
        end
    end

    return nil
end

local function GetTool(toolAction)
    for _, item in pairs(InventoryFunctions:GetPlayerInventory()) do
        if item:HasTag(toolAction .. "_tool") then
            return item
        end
    end

    if CRAFTING_ALLOWED then
        for i = 1, #CraftableTools[toolAction] do
            if CraftFunctions:KnowsRecipe(CraftableTools[toolAction][i]) and CraftFunctions:CanCraft(CraftableTools[toolAction][i]) then
                return CraftableTools[toolAction][i], true
            end
        end
    end

    return nil
end

local function DataValidation(data, prefab)
    return data
       and data.item
       and data.item.prefab == prefab
end

local function OnEquipToolEvent(inst, data, target, action, prefab)
    if DataValidation(data, prefab) then
        local act = BufferedAction(inst, target, action, data.item)
        local position = target:GetPosition()

        if inst.components.locomotor == nil then
            inst:DoTaskInTime(FRAMES * 4, function()
                SendRPCToServer(
                    RPC.LeftClick,
                    act.action.code,
                    position.x,
                    position.z,
                    act.target
                )
            end)
        else
            act.preview_cb = function()
                SendRPCToServer(
                    RPC.LeftClick,
                    act.action.code,
                    position.x,
                    position.z,
                    act.target
                )
            end
        end

        inst.components.playercontroller:DoAction(act)
    end

    inst.components.eventtracker:DetachEvent("OnGetToolEvent")
    inst.components.eventtracker:DetachEvent("OnEquipToolEvent")
end

local function OnGetToolEvent(inst, data, prefab)
    if DataValidation(data, prefab) then
        if TheWorld.ismastersim then
            inst:DoTaskInTime(0, function()
                InventoryFunctions:Equip(data.item)
            end)
        else
            InventoryFunctions:Equip(data.item)
        end
    end

    inst.components.eventtracker:DetachEvent("OnGetToolEvent")
end

local function IsInOneOfAnimation(inst, anims)
    for i = 1, #anims do
        if inst.AnimState:IsCurrentAnimation(anims[i]) then
            return true
        end
    end

    return false
end

local WorkAnimations =
{
    "woodie_chop_pre",
    "woodie_chop_loop",
    "chop_pre",
    "chop_loop",
    "pickaxe_pre",
    "pickaxe_loop",
}

local function IsWorking(inst)
    return AUTO_REPEAT_ACTIONS
       and inst.AnimState
       and (IsInOneOfAnimation(inst, WorkAnimations)
        or inst:HasTag("beaver")
       and not inst:HasTag("attack")
       and inst.AnimState:IsCurrentAnimation("atk"))
end

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller
    local PlayerActionPicker = ThePlayer and ThePlayer.components.playeractionpicker
    local Actionqueuer = ThePlayer.components.actionqueuer
    -- ?????????????????????,??????????????????????????????????????????????????????
    if not PlayerController or not PlayerActionPicker then
        return
    end

    if TheWorld.ismastersim then
        local PlayerControllerIsAnyOfControlsPressed = PlayerController.IsAnyOfControlsPressed
        function PlayerController:IsAnyOfControlsPressed(...)
            -- Automagic control repeats
            if IsWorking(self.inst) and (not Actionqueuer or Actionqueuer and not Actionqueuer.action_thread) then
                for _, control in ipairs({...}) do
                    if control == CONTROL_ACTION then
                        return true
                    end
                end
            end
            PlayerControllerIsAnyOfControlsPressed(self, ...)
        end
    else
        local PlayerControllerOnUpdate = PlayerController.OnUpdate
        function PlayerController:OnUpdate(...)
            -- Automagic control repeats
            if IsWorking(self.inst) and (not Actionqueuer or Actionqueuer and not Actionqueuer.action_thread) then
                self:OnControl(CONTROL_ACTION, true)
            end

            PlayerControllerOnUpdate(self, ...)
        end
    end

    local PlayerControllerOnLeftClick = PlayerController.OnLeftClick
    function PlayerController:OnLeftClick(down)
        if down then
            local act = self:GetLeftMouseAction()
            if act then
                if act.AUTOEQUIP then
                    InventoryFunctions:Equip(act.invobject)

                    -- Avoid action interference
                    self.inst:DoTaskInTime(GetTickTime(), function()
                        PlayerControllerOnLeftClick(self, down)
                    end)
                    return
                elseif act.CRAFT and TheInput:IsKeyDown(KEY_CTRL) then
                    if ThePlayer.sg ~= nil then
                        ThePlayer:ClearBufferedAction()
                    end
                    CraftFunctions:Craft(act.CRAFT)

                    local function getToolCallback(inst, data)
                        OnGetToolEvent(inst, data, act.CRAFT)
                    end

                    local function equipToolCallback(inst, data)
                        OnEquipToolEvent(inst, data, act.target, act.DOACTION, act.CRAFT)
                    end

                    self.inst.components.eventtracker:AddEvent(
                        "gotnewitem",
                        "OnGetToolEvent",
                        getToolCallback
                    )

                    self.inst.components.eventtracker:AddEvent(
                        "equip",
                        "OnEquipToolEvent",
                        equipToolCallback
                    )
                    return
                end
            end
        end

        PlayerControllerOnLeftClick(self, down)
    end

    local function ValidateMouseAction(lmb)
        return not InventoryFunctions:GetActiveItem()
           and not InventoryFunctions:IsHeavyLifting()
           and (not lmb or CanOverrideAction[lmb.action])
    end

    local MockEntity = EntityScript(TheSim:CreateEntity())
    local ModCraftAction = Action()
    ModCraftAction.stroverridefn = function(act)
        return "?????? " .. STRINGS.NAMES[string.upper(act.CRAFT)]
    end

    local OldDoGetMouseActions = PlayerActionPicker.DoGetMouseActions
    function PlayerActionPicker:DoGetMouseActions(...)
        local lmb, rmb = OldDoGetMouseActions(self, ...)

        if ValidateMouseAction(lmb) then
            local target = TheInput:GetWorldEntityUnderMouse()
            if target and CanEntitySeeTarget(self.inst, target) then
                local toolAction = GetToolAction(target)
                if toolAction then
                    local tool, craft = GetTool(toolAction)
                    if tool then
                        local lmb_override = BufferedAction(
                                                self.inst,
                                                target,
                                                craft and ModCraftAction or ACTIONS[toolAction],
                                                craft and MockEntity or tool
                                             )

                        if craft then
                            lmb_override.DOACTION = ACTIONS[toolAction]
                            lmb_override.CRAFT = tool
                        else
                            lmb_override.AUTOEQUIP = tool
                        end

                        return lmb_override, rmb
                    end
                end
            end
        end

        return lmb, rmb
    end
end

return Init
