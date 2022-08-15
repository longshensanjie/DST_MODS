function SendCommand(a)
    local b, c, d = TheSim:ProjectScreenPos(TheSim:GetPosition())
    local e = TheNet:GetIsClient() and TheNet:GetIsServerAdmin()
    if e then
        TheNet:SendRemoteExecute(a, b, d)
    else
        ExecuteConsoleCommand(a)
    end
end
function GetCharacter()
    return "UserToPlayer('" .. _G.TOOMANYITEMS.CHARACTER_USERID .. "')"
end
function OperateAnnnounce(f)
    if _G.TOOMANYITEMS.DATA.SPAWN_ITEMS_TIPS then
        if ThePlayer then
            ThePlayer:DoTaskInTime(0.1, function()
                if ThePlayer.components.talker and f then
                    ThePlayer.components.talker:Say("[TMIP]" .. f)
                end
            end)
        end
    end
end

IsPlayerExist =
    'local player = %s if player == nil then ThePlayer.components.talker:Say("' ..
        STRINGS.TOO_MANY_ITEMS_UI.PLAYER_NOT_ON_SLAVE_TIP .. '") return end '
function gotoonly(i)
    i = i or ""
    return string.format(IsPlayerExist ..
                             'if player ~= nil then local function tmi_goto(prefab) if player.Physics ~= nil then player.Physics:Teleport(prefab.Transform:GetWorldPosition()) else player.Transform:SetPosition(prefab.Transform:GetWorldPosition()) end end local target = c_findnext("' ..
                             i ..
                             '") if target ~= nil then tmi_goto(target) end end',
                         GetCharacter())
end
