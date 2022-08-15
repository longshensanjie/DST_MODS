local ConfigFunctions = require "util/configfunctions"
local KeybindService = MOD_EQUIPMENT_CONTROL.KEYBINDSERVICE

local TELEPOOF_DOUBLECLICK = GetModConfigData("boas_DoubleClick", MOD_EQUIPMENT_CONTROL.MODNAME)
local TELEPOOF_CLICKS = 2

if TELEPOOF_DOUBLECLICK and type(TELEPOOF_DOUBLECLICK) ~= "number" then
    TELEPOOF_DOUBLECLICK = .5
end

local StoredMouseHovers =
{
    GENERIC = STRINGS.ACTIONS.BLINK.GENERIC,
}


local function SetBlinkText(delta)
    TELEPOOF_CLICKS = TELEPOOF_CLICKS + delta
    for ref, old in pairs(StoredMouseHovers) do
        STRINGS.ACTIONS.BLINK[ref] = string.format(
            old .. " (%s)",
            TELEPOOF_CLICKS
        )
    end
end

local function ToggleBlink(bool)
    if not bool then
        if TELEPOOF_DOUBLECLICK then
            SetBlinkText(0)
        else
            for ref, old in pairs(StoredMouseHovers) do
                STRINGS.ACTIONS.BLINK[ref] = old
            end
        end
    else
        for ref, old in pairs(StoredMouseHovers) do
            STRINGS.ACTIONS.BLINK[ref] = old .. " (Disabled)"
        end
    end
end

local ignorestr = {"SOUL", "FREESOUL"} 
local function ValidateAction(self)
    local act = self:GetRightMouseAction()

    return act
       and act.action == ACTIONS.BLINK
    --    and act.action.strfn(act) == "GENERIC"
       and not table.contains(ignorestr, act.action.strfn(act))
end

local function Init()
    local PlayerController = ThePlayer and ThePlayer.components.playercontroller

    if not PlayerController then
        return
    end
    
    ToggleBlink(false)

    local OldOnRightClick = PlayerController.OnRightClick
    function PlayerController:OnRightClick(down)
        if down and ValidateAction(self) then

            if TELEPOOF_DOUBLECLICK then
                if TELEPOOF_CLICKS > 0 then
                    SetBlinkText(-1)
                    self.inst:DoTaskInTime(TELEPOOF_DOUBLECLICK, function()
                        SetBlinkText(1)
                    end)
                end

                if TELEPOOF_CLICKS > 0 then
                    return
                end
            end
        end

        OldOnRightClick(self, down)
    end
end


return Init
