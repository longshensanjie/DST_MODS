local _G=GLOBAL
local showtip = true

local function IsValidEntity(ent)
    return ent and ent:IsValid()
end

local function GetEquippedItemInHand(inst)
    if not inst.replica.inventory then return nil end
    return inst.replica.inventory:GetEquippedItem(_G.EQUIPSLOTS.HANDS)
end


--SendAction was based on ActionQueue Reborn by eXiGe.
--ActionQueue Reborn: https://steamcommunity.com/sharedfiles/filedetails/?id=1608191708
--eXiGe: https://steamcommunity.com/profiles/76561198032277590
local function SendAction(inst, act, rightclick) -- From ActionQueue Reborn
    local playercontroller = inst.components.playercontroller
    if playercontroller == nil then return end
    local controlmods = act.controlmods or 10 --force stack and force attack
    if playercontroller.locomotor then
        local buffered_act = _G.BufferedAction(act.doer, act.target, act.action, act.invobject, act.pos)
        buffered_act.preview_cb = function()
            if rightclick then
                _G.SendRPCToServer(_G.RPC.RightClick, act.action.code, act.pos.x, act.pos.z, act.target, act.rotation, true, nil, nil, act.action.mod_name)
            else
                _G.SendRPCToServer(_G.RPC.LeftClick, act.action.code, act.pos.x, act.pos.z, act.target, true, controlmods, nil, act.action.mod_name)
            end
        end
        playercontroller:DoAction(buffered_act)
    else
        if rightclick then
            _G.SendRPCToServer(_G.RPC.RightClick, act.action.code, act.pos.x, act.pos.z, act.target, act.rotation, true, nil, act.action.canforce, act.action.mod_name)
        else
            _G.SendRPCToServer(_G.RPC.LeftClick, act.action.code, act.pos.x, act.pos.z, act.target, true, controlmods, act.action.canforce, act.action.mod_name)
        end
    end
end

local function GetInventories(inst)
    local inventories = {}
    local equipped_item = nil
    local inventory = inst.replica.inventory
    if inventory == nil then 
        return inventories 
    end
    table.insert(inventories, inventory)
    for _, SLOT in pairs(_G.EQUIPSLOTS) do
        equipped_item = inventory:GetEquippedItem(SLOT)
        if equipped_item and equipped_item.replica.container then
            table.insert(inventories, equipped_item.replica.container)
        end
    end
    return inventories
end

local function GetItemFromInventories(inst, search_fn)
    local inventories = GetInventories(inst)
    for _, inventory in pairs(inventories) do
        for slot, item in pairs(inventory:GetItems()) do
            if search_fn(item) then
                return item
            end
        end
    end
    return nil
end

 AddComponentPostInit("playercontroller", function(self)
    if(type(self.automation_tasks)~="table")then
        self.automation_tasks={}
    end

    self.automation_tasks.paddle={}
    local script = self.automation_tasks.paddle 

    script.inst = nil -- ThePlayer
    script.animation_fail_time = _G.FRAMES -- Not currently used. (4/30) -- Time from scripts\componentactions.lua Row(inst, doer, pos, actions) line: 35.
    script.relative_x, self.relative_z = 0, 0
    script.platform = nil
    script.oar = nil
    script.period = _G.FRAMES * 3

    script.oars = { -- Is there any way to tell what's an oar?
        oar = true,
        oar_driftwood = true,
        malbatross_beak = true,
        oar_monkey = true,
    }
    if HasModName("佩奇宝宝的神奇手杖") then
        script.oars = { -- Is there any way to tell what's an oar?
            oar = true,
            oar_driftwood = true,
            malbatross_beak = true,
            oar_monkey = true,
            cane = true,
            orangestaff = true,
        }
    end

    script.action_row = {
        action = _G.ACTIONS.ROW,
        invobject = nil,
        target = nil,
        doer = nil, -- ThePlayer
        pos = _G.Vector3(0, 0, 0),
    }

    ------------------------------------------------------------ Functions.

    script.Interrupt = function(self)
        if self.task then
            self.task:Cancel()
            self.task = nil
        end
    end

    script.AcceptControllerAction = function(self, control, down, LMBaction, RMBaction, inst)
        if control == _G.CONTROL_SECONDARY and RMBaction and (RMBaction.action == _G.ACTIONS.ROW or RMBaction.action == _G.ACTIONS.ROW_FAIL) then
            if down then
                self.inst = inst
                self.action_row.doer = inst
                local temp_act_pos = RMBaction:GetActionPoint()
                if not temp_act_pos then 
                    temp_act_pos = _G.TheInput:GetWorldPosition()
                end
                if temp_act_pos then
                    local inst_x, _, inst_z = self.inst.Transform:GetWorldPosition()
                    if inst_x and inst_z then
                        self.platform = _G.TheWorld.Map:GetPlatformAtPoint(inst_x, inst_z)
                        if self.IsValidPlatform(self.platform) then
                            local platform_x, platform_y, platform_z = self.platform.Transform:GetWorldPosition()
                            self.relative_x = temp_act_pos.x - platform_x -- Offset from boat to action.
                            self.relative_z = temp_act_pos.z - platform_z -- Offset from boat to action.
                            self:Start()
                            return true
                        end
                    end
                end
            else
                return true
            end
        end
        return false
    end

    script.Start = function(self)
        if self.task then return end
        if IsValidEntity(self.inst) then
            if showtip then
                showtip = false
                TIP("自动划船开始执行", "green", "移动可以打断该功能，无法划船请开关延迟补偿【本局游戏不再提示该消息】","chat")
            end
            self.task = self.inst:DoPeriodicTask(self.period, self.Run, 0, self)
        end
    end

    script.Run = function(_, self)
        if self.IsValidPlatform(self.platform) then
            local has_oar = false
            if self.IsValidOar(GetEquippedItemInHand(self.inst)) then
                local platform_x, platform_y, platform_z = self.platform.Transform:GetWorldPosition()
                self.action_row.pos.x = platform_x + self.relative_x
                self.action_row.pos.z = platform_z + self.relative_z
                SendAction(self.inst, self.action_row)
            else
                self.oar = GetItemFromInventories(self.inst, self.IsValidOar)
                if self.oar == nil then
                    self:Interrupt()
                end
                self.inst.replica.inventory:UseItemFromInvTile(self.oar)
            end
        else
            self:Interrupt()
        end
    end

    script.IsValidPlatform = function(ent)
        return IsValidEntity(ent) -- Platform health check?
    end

    script.IsValidOar = function(ent)
        return IsValidEntity(ent) and ent.prefab and script.oars[ent.prefab] ~= nil
    end






    if self.automation_components_setup then return else self.automation_components_setup = true end

    _G.assert(type(self.automation_tasks) == "table", "[BasicUtility] Automation enabled but unable to load scripts.\n"
            .."Try disabling automation in the mod settings.")
    self.mouse_controls = { [_G.CONTROL_PRIMARY] = true, [_G.CONTROL_SECONDARY] = true }
    self.interrupt_controls = {}
    for control = _G.CONTROL_ATTACK, _G.CONTROL_MOVE_RIGHT do
        self.interrupt_controls[control] = true
    end
    
    self.eat_control = false
    self.should_interrupt = false
    local playercontroller_OnControl = self.OnControl
    self.OnControl = function(self, control, down)
        -- self.do_automation = TheInput:IsControlPressed(automation_control)
        self.eat_control = false -- eat_control is only for eating the playercontroller action.
        self.should_interrupt = down                                                               -- Interrupt only down actions; up is meaningless.
                and (self.inst.HUD and not self.inst.HUD:HasInputFocus())                          -- Don't interrupt when the HUD has focus.
                and (self.interrupt_controls[control]                                              -- Interrupt any key press.
                    or (self.mouse_controls[control] and not _G.TheInput:GetHUDEntityUnderMouse()) -- Don't interrupt mouse presses when hovering over HUD.
                )
        for _, task in pairs(self.automation_tasks) do
            if task:AcceptControllerAction(control, down, self:GetLeftMouseAction(), self:GetRightMouseAction(), self.inst) then
                self.eat_control = true
            elseif self.should_interrupt then
                task:Interrupt()
            end
        end
        
        if not self.eat_control then
            playercontroller_OnControl(self, control, down)
        end
    end
end)