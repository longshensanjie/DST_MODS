local G = GLOBAL

-- 阿比盖尔控制
local keybind = GetModConfigData("wendy_summonkey")
local keybind2 = GetModConfigData("wendy_commandkey")

local function GetAbigail()
    if not G.ThePlayer:HasTag("ghostfriend_summoned") then return end
    for k, v in pairs(G.Ents) do
        if v.prefab == "abigail" and v.replica.follower and
            v.replica.follower:GetLeader() == G.ThePlayer then return v end
    end
    return nil
end
if keybind then
    G.TheInput:AddKeyDownHandler(keybind, function()
        if not InGame() then return end
        -- 仅温蒂可用此快捷键
        if not G.ThePlayer or G.ThePlayer.prefab ~= "wendy"then return end
        local flower = GetItemFromAll("abigail_flower")
        if not flower then return end
        local abigail = GetAbigail()
        local rpc = nil
        local act = nil
        local target = nil
		-- 存在阿比盖尔
        if abigail then
            rpc = G.RPC.ControllerUseItemOnSceneFromInvTile
            act = G.ACTIONS.CASTUNSUMMON
            target = abigail
		-- 不存在艾比盖尔
        elseif G.ThePlayer:HasTag("ghostfriend_notsummoned") then
            rpc = G.RPC.ControllerUseItemOnSelfFromInvTile
            act = G.ACTIONS.CASTSUMMON
        else
            return
        end
		SendRPCAwithB(rpc, act, flower, target)
    end)
end
if keybind2 then
	G.TheInput:AddKeyDownHandler(keybind2, function()
		if not InGame() then return end
        -- 仅温蒂可用此快捷键
        if not G.ThePlayer or G.ThePlayer.prefab ~= "wendy"then return end
		local flower = GetItemFromAll("abigail_flower")
		local abigail = GetAbigail()
		if not flower or not G.ThePlayer:HasTag("ghostfriend_summoned") then
			return
		end
		if abigail then
			local act = G.ACTIONS.COMMUNEWITHSUMMONED
			SendRPCAwithB(G.RPC.ControllerUseItemOnSelfFromInvTile, act, flower)
		end
	end)
end

local PlayerHud = require "screens/playerhud"
local old_PlayerHud_OnControl = PlayerHud.OnControl
function PlayerHud:OnControl(control, down)
    local ret = old_PlayerHud_OnControl(self, control, down)
    if control >= G.CONTROL_INV_1 and control <= G.CONTROL_INV_10 then
        local inventory = G.ThePlayer.replica.inventory
        if inventory ~= nil then
            local hot_key_num = control - G.CONTROL_INV_1 + 1
            local item = inventory:GetItemInSlot(hot_key_num)
            local abigail_flower = GetItemFromAll("abigail_flower")
            if item ~= nil and abigail_flower and item:HasTag("ghostlyelixir") then
                inventory:ControllerUseItemOnItemFromInvTile(abigail_flower, item)
            end
        end
    end
    return ret
end

AddClassPostConstruct("widgets/invslot", function(self)
    local _UseItem = self.UseItem
    self.UseItem = function(...)
        if self.tile and self.tile.item  then
            local inventory = G.ThePlayer and G.ThePlayer.replica.inventory or nil
            local abigail_flower = GetItemFromAll("abigail_flower")
            if inventory and abigail_flower and self.tile.item:HasTag("ghostlyelixir") then
                inventory:ControllerUseItemOnItemFromInvTile(abigail_flower, self.tile.item)
            elseif inventory  then
                inventory:UseItemFromInvTile(self.tile.item)
            else
                _UseItem(...)
            end
        else
            _UseItem(...)
        end
    end
end)

AddComponentPostInit("playeractionpicker", function(self)
    local old_GetInventoryActions = self.GetInventoryActions
    self.GetInventoryActions = function(self, useitem, right)
        local sorted_acts = old_GetInventoryActions(self, useitem, right)
        local abigail_flower = GetItemFromAll("abigail_flower")
        if abigail_flower and useitem:HasTag("ghostlyelixir") then
            for i, act in ipairs(sorted_acts) do
                if act.action == G.ACTIONS.LOOKAT then
                    act.GetActionString = function()
                        return "使用"
                    end
                end
            end
        end
        return sorted_acts
    end
end)