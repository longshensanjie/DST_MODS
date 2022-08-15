local _G = GLOBAL
_G.MOD_KEEP_FOLLOWING_TEST = false
local require = _G.require

local Utils = require "keepfollowing/utils"
local ban_target = {"sleepbomb"}

--- Globals
-- @section globals

local ACTIONS = _G.ACTIONS
local BufferedAction = _G.BufferedAction
local CONTROL_ACTION = _G.CONTROL_ACTION
local CONTROL_MOVE_DOWN = _G.CONTROL_MOVE_DOWN
local CONTROL_MOVE_LEFT = _G.CONTROL_MOVE_LEFT
local CONTROL_MOVE_RIGHT = _G.CONTROL_MOVE_RIGHT
local CONTROL_MOVE_UP = _G.CONTROL_MOVE_UP
local CONTROL_PRIMARY = _G.CONTROL_PRIMARY
local CONTROL_SECONDARY = _G.CONTROL_SECONDARY
local TheInput = _G.TheInput
local TheSim = _G.TheSim

--- Debugging
-- @section debugging

local Debug

_G.ModKeepFollowingDebug = Debug

local function DebugString(...)
    return Debug and Debug:DebugString(...)
end

local function DebugInit(...)
    return Debug and Debug:DebugInit(...)
end

--- Helpers
-- @section helpers
local function IsDST()
    return TheSim:GetGameID() == "DST"
end

local function IsClient()
    return IsDST() and _G.TheNet:GetIsClient()
end

local function IsMoveButton(control)
    return control == CONTROL_MOVE_UP
        or control == CONTROL_MOVE_DOWN
        or control == CONTROL_MOVE_LEFT
        or control == CONTROL_MOVE_RIGHT
end

local function IsOurAction(action)
    return action == ACTIONS.MOD_KEEP_FOLLOWING_FOLLOW
        or action == ACTIONS.MOD_KEEP_FOLLOWING_PUSH
        or action == ACTIONS.MOD_KEEP_FOLLOWING_TENT_FOLLOW
        or action == ACTIONS.MOD_KEEP_FOLLOWING_TENT_PUSH
end

--- Configurations
-- @section configurations

local _COMPATIBILITY = "recommended"
local _KEY_ACTION = _G.KEY_LSHIFT
local _KEY_PUSH = _G.KEY_CTRL
local _PUSH_WITH_RMB = false

--- Actions
-- @section actions

local function ActionFollow(act)
    local keepfollowing = Utils.ChainGet(act, "doer", "components", "keepfollowing")
    if keepfollowing and act.doer and act.target then
        keepfollowing:Stop()
        keepfollowing:StartFollowing(act.target)
        return true
    end
    return false
end

local function ActionPush(act)
    local keepfollowing = Utils.ChainGet(act, "doer", "components", "keepfollowing")
    if keepfollowing and act.doer and act.target then
        keepfollowing:Stop()
        keepfollowing:StartPushing(act.target)
        return true
    end
    return false
end

local function ActionTentFollow(act)
    local keepfollowing = Utils.ChainGet(act, "doer", "components", "keepfollowing")
    if keepfollowing and act.doer and act.target then
        local leader = keepfollowing:GetTentSleeper(act.target)
        if leader then
            keepfollowing:Stop()
            keepfollowing:StartFollowing(leader)
            return true
        end
    end
    return false
end

local function ActionTentPush(act)
    local keepfollowing = Utils.ChainGet(act, "doer", "components", "keepfollowing")
    if keepfollowing and act.doer and act.target then
        local leader = keepfollowing:GetTentSleeper(act.target)
        if leader then
            keepfollowing:Stop()
            keepfollowing:StartPushing(leader)
            return true
        end
    end
    return false
end

AddAction("MOD_KEEP_FOLLOWING_FOLLOW", GLOBAL.STRINGS.RMB.."右键点击跟随", ActionFollow)
AddAction("MOD_KEEP_FOLLOWING_PUSH", GLOBAL.STRINGS.RMB.."右键点击推挤", ActionPush)
AddAction("MOD_KEEP_FOLLOWING_TENT_FOLLOW", "Follow player in", ActionTentFollow)
AddAction(
    "MOD_KEEP_FOLLOWING_TENT_PUSH",
    _PUSH_WITH_RMB and "Push player" or "Push player in",
    ActionTentPush
)

--- Player
-- @section player

local function OnPlayerActivated(player, world)
    player:AddComponent("keepfollowing")

    local keepfollowing = player.components.keepfollowing
    if keepfollowing then
        keepfollowing.is_client = IsClient()
        keepfollowing.is_dst = IsDST()
        keepfollowing.is_master_sim = world.ismastersim
        keepfollowing.world = world

        -- GetModConfigData
        local configs = {
            "follow_distance",
            "follow_distance_keeping",
            "follow_method",
            "push_lag_compensation",
            "push_mass_checking",
        }

        
        keepfollowing.config["follow_distance"] = 2.5
        keepfollowing.config["follow_distance_keeping"] = false
        keepfollowing.config["follow_method"] = "default"
        keepfollowing.config["push_lag_compensation"] = true
        keepfollowing.config["push_mass_checking"] = true
    end

    DebugString("Player", player:GetDisplayName(), "activated")
end

local function OnPlayerDeactivated(player)
    player:RemoveComponent("keepfollowing")
    DebugString("Player", player:GetDisplayName(), "deactivated")
end

local function AddPlayerPostInit(onActivatedFn, onDeactivatedFn)
    DebugString("Game ID -", TheSim:GetGameID())

    if IsDST() then
        env.AddPrefabPostInit("world", function(_world)
            _world:ListenForEvent("playeractivated", function(world, player)
                if player == _G.ThePlayer then
                    onActivatedFn(player, world)
                end
            end)

            _world:ListenForEvent("playerdeactivated", function(_, player)
                if player == _G.ThePlayer then
                    onDeactivatedFn(player)
                end
            end)
        end)
    else
        env.AddPlayerPostInit(function(player)
            onActivatedFn(player)
        end)
    end

    DebugInit("AddPlayerPostInit")
end

local function PlayerActionPickerPostInit(playeractionpicker, player)
    if player ~= _G.ThePlayer then
        return
    end

    --
    -- Overrides
    --

    local OldDoGetMouseActions = playeractionpicker.DoGetMouseActions
    playeractionpicker.DoGetMouseActions = function(self, position, _target)
        local lmb, rmb = OldDoGetMouseActions(self, position, _target)
        if TheInput:IsKeyDown(_KEY_ACTION) then
            local keepfollowing = player.components.keepfollowing
            local buffered = self.inst:GetBufferedAction()

            -- We could have used lmb.target. However, the PlayerActionPicker has leftclickoverride
            -- and rightclickoverride so we can't trust that. A good example is Woodie's Weregoose
            -- form which overrides mouse actions.
            local target = TheInput:GetWorldEntityUnderMouse()
            if (not target) or table.contains(ban_target, target.prefab) then
                return lmb, rmb
            end

            -- You are probably wondering why we need this check? Isn't it better to just show our
            -- actions without the buffered action check?
            --
            -- There are so many mods out there "in the wild" which also do different in-game
            -- actions and don't bother checking for interruptions in their scheduler tasks
            -- (threads). For example, ActionQueue Reborn will always try to force their action if
            -- entities have already been selected. We can adapt our mod for such cases to improve
            -- compatibility but this is the only bulletproof way to cover the most.
            if buffered
                and not IsOurAction(buffered.action)
                and buffered.action ~= ACTIONS.WALKTO
            then
                return lmb, rmb
            end

            if target:HasTag("tent") and target:HasTag("hassleeper") then
                if _PUSH_WITH_RMB then
                    lmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_TENT_FOLLOW)
                elseif TheInput:IsKeyDown(_KEY_PUSH) then
                    lmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_TENT_PUSH)
                elseif not TheInput:IsKeyDown(_KEY_PUSH) then
                    lmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_TENT_FOLLOW)
                end
            end

            if keepfollowing:CanBeLeader(target) then
                if _PUSH_WITH_RMB then
                    lmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_FOLLOW)
                elseif TheInput:IsKeyDown(_KEY_PUSH) and keepfollowing:CanBePushed(target) then
                    lmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_PUSH)
                elseif not TheInput:IsKeyDown(_KEY_PUSH) then
                    lmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_FOLLOW)
                end
            end

            if _PUSH_WITH_RMB then
                if target:HasTag("tent") and target:HasTag("hassleeper") then
                    rmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_TENT_PUSH)
                end

                if keepfollowing:CanBeLeader(target) and keepfollowing:CanBePushed(target) then
                    rmb = BufferedAction(player, target, ACTIONS.MOD_KEEP_FOLLOWING_PUSH)
                end
            end
        end
        return lmb, rmb
    end

    DebugInit("PlayerActionPickerPostInit")
end

local function PlayerControllerPostInit(playercontroller, player)
    if player ~= _G.ThePlayer then
        return
    end

    --
    -- Helpers
    --

    local function KeepFollowingStop()
        local keepfollowing = player.components.keepfollowing
        if keepfollowing then
            keepfollowing:Stop()
        end
    end

    -- We ignore ActionQueue(DST) mod here intentionally. Our mod won't work with theirs if the same
    -- action key is used. So there is no point to mess with their functions anyway.
    --
    -- From an engineering perspective, the method which ActionQueue(DST) mod uses for overriding
    -- PlayerController:OnControl() should never be used. Technically, we can fix this issue by
    -- either using the same approach or using the global input handler when ActionQueue(DST) mod is
    -- enabled. However, I don't see any valid reason to do that.
    local function ClearActionQueueRebornEntities()
        local actionqueuer = player.components.actionqueuer
        if not actionqueuer
            or not actionqueuer.ClearActionThread
            or not actionqueuer.ClearSelectionThread
            or not actionqueuer.ClearSelectedEntities
        then
            return
        end

        actionqueuer:ClearActionThread()
        actionqueuer:ClearSelectionThread()
        actionqueuer:ClearSelectedEntities()
    end

    local function OurMouseAction(act)
        if not act then
            KeepFollowingStop()
            return false
        end

        local action = act.action
        if IsOurAction(action) then
            ClearActionQueueRebornEntities()
            if action.fn(act) then
                return true
            end
        else
            KeepFollowingStop()
        end

        return false
    end

    --
    -- Overrides
    --

    local OldOnControl = playercontroller.OnControl
    playercontroller.OnControl = function(self, control, down)
        if IsMoveButton(control) or control == CONTROL_ACTION then
            KeepFollowingStop()
        end

        if _COMPATIBILITY == "alternative" then
            if control == CONTROL_PRIMARY and not down then
                if TheInput:GetHUDEntityUnderMouse() or self:IsAOETargeting() then
                    return OldOnControl(self, control, down)
                end
                OurMouseAction(self:GetLeftMouseAction())
            elseif _PUSH_WITH_RMB and control == CONTROL_SECONDARY and not down then
                if TheInput:GetHUDEntityUnderMouse() or self:IsAOETargeting() then
                    return OldOnControl(self, control, down)
                end
                OurMouseAction(self:GetRightMouseAction())
            end
        end

        OldOnControl(self, control, down)
    end

    if _COMPATIBILITY == "recommended" then
        local OldOnLeftClick = playercontroller.OnRightClick
        playercontroller.OnRightClick = function(self, down)
            if not down
                and not self:IsAOETargeting()
                and not TheInput:GetHUDEntityUnderMouse()
                and OurMouseAction(self:GetLeftMouseAction())
            then
                return
            end
            OldOnLeftClick(self, down)
        end

        if _PUSH_WITH_RMB then
            local OldOnRightClick = playercontroller.OnRightClick
            playercontroller.OnRightClick = function(self, down)
                if not down
                    and not self:IsAOETargeting()
                    and not TheInput:GetHUDEntityUnderMouse()
                    and OurMouseAction(self:GetRightMouseAction())
                then
                    return
                end
                OldOnRightClick(self, down)
            end
        end
    end

    DebugInit("PlayerControllerPostInit")
end

AddPlayerPostInit(OnPlayerActivated, OnPlayerDeactivated)
AddComponentPostInit("playeractionpicker", PlayerActionPickerPostInit)
AddComponentPostInit("playercontroller", PlayerControllerPostInit)

--- KnownModIndex
-- @section knownmodindex

Utils.HideChangelog(modname, true)
