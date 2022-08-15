local G = GLOBAL


local keybind = GetModConfigData("watch_heal")
local keybind2 = GetModConfigData("watch_warp")
local keybind3 = GetModConfigData("watch_recall")

-------------------------------------------------------------------------------------------------------------------------
local function UsePocket(pocketname)
    if not InGame() then return end
    if not GLOBAL.ThePlayer or GLOBAL.ThePlayer.prefab ~= "wanda" then return end
    local pocketwatch = GetItemFromAll(pocketname, "pocketwatch_inactive")
    if pocketwatch == nil or not G.ThePlayer:HasTag("pocketwatchcaster") then
        return
    end
    SendRPCAwithB(G.RPC.ControllerUseItemOnSelfFromInvTile, G.ACTIONS.CAST_POCKETWATCH, pocketwatch)
end

if keybind then
    G.TheInput:AddKeyDownHandler(keybind,
                                 function() UsePocket("pocketwatch_heal") end)
end

if keybind2 then
    G.TheInput:AddKeyDownHandler(keybind2,
                                 function() UsePocket("pocketwatch_warp") end)
end
if keybind3 then
    G.TheInput:AddKeyDownHandler(keybind3,
                                 function() UsePocket("pocketwatch_recall") end)
end
