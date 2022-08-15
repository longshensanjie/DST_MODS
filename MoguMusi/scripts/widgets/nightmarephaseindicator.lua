local Text = require "widgets/text"
local Widget = require "widgets/widget"
local UIAnim = require "widgets/uianim"

local STRING_TIME_DEFAULT = "--:--"
local SIZE_TEXT_TIMER     = 40
local SIZE_NAME_PHASE     = 36
local MARGIN_HORIZONTAL   = 35
local MARGIN_VERTICAL     = 32
local MARGIN_TIMER_CORRECT      = -3
local MARGIN_NAME_PHASE_CORRECT = 3

local PHASE_COLORS = 
{
    calm = {148/255, 121/255, 90/255, 1},
    warn = {200/255, 180/255, 84/255, 1},
    wild = {208/255, 61/255, 53/255, 1},
    dawn = {149/255, 105/255, 163/255, 1},
}

local function GetTimeString(intime)
    local result = STRING_TIME_DEFAULT
    local t = math.floor(intime)

    if t > 0 then
        local minute = 0
        local second = 0

        if t < 60 then
            second = t
        else
            minute = math.floor(t / 60)
            second = t - (minute * 60)
        end

        if minute < 10 then
            minute = "0"..minute
        end

        if second < 10 then
            second = "0"..second
        end

        result = minute..":"..second
    end
    return result
end

local function UpdateMedallion(self, newphase, oldphase, lock)
    if type(newphase) == "string" then
        if self.animon then
            if type(oldphase) == "string" then
                self.icon:GetAnimState():PlayAnimation(oldphase.."_pst")
                self.icon:GetAnimState():PushAnimation(newphase.."_pre")
            else
                self.icon:GetAnimState():PlayAnimation(newphase.."_pre")
            end

            if lock then
                self.icon:GetAnimState():PushAnimation(newphase.."_lock", true)
            else
                self.icon:GetAnimState():PushAnimation(newphase.."_loop", false)
            end
        else
            if lock then
                self.icon:GetAnimState():PushAnimation(newphase.."_staticlock", false)
            else
                self.icon:GetAnimState():PushAnimation(newphase.."_loop", false)
            end
        end

        self.timer:SetColour(unpack(PHASE_COLORS[newphase]))
        self.phasename:SetColour(unpack(PHASE_COLORS[newphase]))
    end
end

local function UpdateTextPostion(inst, pos, correct)
    local w, h = inst:GetRegionSize()

    if pos == "TOP" then
        inst:SetPosition(0, (h/2) + MARGIN_VERTICAL + correct)
    elseif pos == "RIGHT" then
        inst:SetPosition((w / 2) + MARGIN_HORIZONTAL, correct)
    elseif pos == "BOTTOM" then
        inst:SetPosition(0, -((h/2) + MARGIN_VERTICAL) + correct)
    elseif pos == "LEFT" then
        inst:SetPosition(-((w / 2) + MARGIN_HORIZONTAL), correct)
    else
        inst:SetPosition(0, correct) -- center
    end
end

local function Update(self, data)
    if data and data.phase ~= self.phase or
       (data.phase == self.phase and data.timeinphase == 1 and self.oldtimeinphase ~= 1) then
        local lock = false
        local oldphase = self.phase

        if data.timeinphase == 1 then lock = true end
        if oldphase ~= nil then self.correction = nil end

        self.phase = data.phase
        self.oldtimeinphase = nil

        self.timer:SetString(STRING_TIME_DEFAULT)

        if lock then
            self.phasename:SetString(STRINGS.NIGHMARE_PHASE_INDICATOR.PHASENAMES["lock"])
        else
            self.phasename:SetString(STRINGS.NIGHMARE_PHASE_INDICATOR.PHASENAMES[self.phase])
        end

        UpdateMedallion(self, self.phase, oldphase, lock)
        UpdateTextPostion(self.timer, self.timer_postype, MARGIN_TIMER_CORRECT)
        UpdateTextPostion(self.phasename, self.phasename_postype, MARGIN_NAME_PHASE_CORRECT)
    end

    if self.oldtimeinphase ~= nil and self.oldtimeinphase ~= 1 then
        local delta = ((data.timeinphase * 1000) - (self.oldtimeinphase * 1000)) * FRAMES
        if delta > 0 then
            local timeleft = ((1 - data.timeinphase) / delta) + (self.correction and self.correction or 0)
            self.timer:SetString(GetTimeString(timeleft))
            UpdateTextPostion(self.timer, self.timer_postype, MARGIN_TIMER_CORRECT)
        else
            self.timer:SetString(STRING_TIME_DEFAULT)
            UpdateTextPostion(self.timer, self.timer_postype, MARGIN_TIMER_CORRECT)
        end
    end
    
    self.oldtimeinphase = data and data.timeinphase or nil
end

local function CheckInventory(self)
    if self.owner and self.owner.replica and self.owner.replica.inventory then
        local found, amount = self.owner.replica.inventory:Has("nightmare_timepiece", 1)
        if found then
            self:Show()
        else
            self:Hide()
        end
    end
end

local NightmarePhaseIndicator = Class(Widget, function(self)
    Widget._ctor(self, "NightmarePhaseIndicator")
    self.owner = ThePlayer

    self.icon = self:AddChild(UIAnim())
    self.icon:GetAnimState():SetBank("nigthmarephaseindicator")
    self.icon:GetAnimState():SetBuild("nigthmarephaseindicator")
    self.icon:GetAnimState():PlayAnimation("calm_loop", false)
    self.icon:SetScale(.6, .6)
    self.icon:SetPosition(-3, 0)
    self.icon:SetClickable(false)

    self.phasename = self:AddChild(Text(UIFONT, SIZE_NAME_PHASE, ""))
    self.phasename:SetPosition(0, 0)

    self.timer = self:AddChild(Text(UIFONT, SIZE_TEXT_TIMER, STRING_TIME_DEFAULT))
    self.timer:SetPosition(0, 0)

    self.correction = -3 -- first correction value at spawn
    self.oldtimeinphase = nil
    self.phase = TheWorld.state.nightmarephase
    self.animon = false

    self.timer_postype = nil
    self.phasename_postype = nil

    UpdateMedallion(self, self.phase, nil, false)
    self.phasename:SetString(STRINGS.NIGHMARE_PHASE_INDICATOR.PHASENAMES[self.phase])
    UpdateTextPostion(self.phasename, self.phasename_postype, MARGIN_NAME_PHASE_CORRECT)

    self.inst:ListenForEvent("nightmareclocktick", function(world, data) Update(self, data) end, TheWorld)

    -- support StatusAnnouncer mod
    self.inst:DoTaskInTime(0, function()
        if ThePlayer.HUD._StatusAnnouncer then
            self.icon:SetClickable(true)
            self.icon.OnMouseButton = function(_, button, down)
                if button == 1000 and down and TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) and ThePlayer.HUD._StatusAnnouncer then
                    ThePlayer.HUD._StatusAnnouncer:Announce(self:GetAnnounce())
                end
            end
        end
    end)
end)

function NightmarePhaseIndicator:GetAnnounce()
    local phasename = self.phasename:GetString()

    if self.timer.shown then
        local timeleft = self.timer:GetString()
        if timeleft ~= "" and timeleft ~= STRING_TIME_DEFAULT then
            return subfmt(STRINGS.NIGHMARE_PHASE_INDICATOR.ANNOUNCE.FORMAT_STRING, {PHASENAME = phasename, TIMELEFT = timeleft})
        end
    end

    return subfmt(STRINGS.NIGHMARE_PHASE_INDICATOR.ANNOUNCE.NOTIME_FORMAT_STRING, {PHASENAME = phasename})
end

function NightmarePhaseIndicator:RunObserverInventory()
    -- hack, checking inventory on every frame for observing items
    -- not enough to use events: "newactiveitem", "gotnewitem", "dropitem", "itemget", "itemlose", "equip", "unequip",
    -- to fully control inventory on the client side
    self.inst:DoPeriodicTask(FRAMES, function(inst) CheckInventory(self) end)
    self:Hide()
end

function NightmarePhaseIndicator:AnimationOn()
    self.animon = true
end

function NightmarePhaseIndicator:AnimationOff()
    self.animon = false
end

function NightmarePhaseIndicator:ShowTimer()
    self.timer:Show()
end

function NightmarePhaseIndicator:HideTimer()
    self.timer:Hide()
end

function NightmarePhaseIndicator:ShowPhaseName()
    self.phasename:Show()
end

function NightmarePhaseIndicator:HidePhaseName()
    self.phasename:Hide()
end

function NightmarePhaseIndicator:SetPositionTimerCenter()
    self.timer_postype = nil
    UpdateTextPostion(self.timer, self.timer_postype, MARGIN_TIMER_CORRECT)
end

function NightmarePhaseIndicator:SetPositionTimerTop()
    self.timer_postype = "TOP"
    UpdateTextPostion(self.timer, self.timer_postype, MARGIN_TIMER_CORRECT)
end

function NightmarePhaseIndicator:SetPositionTimerRight()
    self.timer_postype = "RIGHT"
    UpdateTextPostion(self.timer, self.timer_postype, MARGIN_TIMER_CORRECT)
end

function NightmarePhaseIndicator:SetPositionTimerBottom()
    self.timer_postype = "BOTTOM"
    UpdateTextPostion(self.timer, self.timer_postype, MARGIN_TIMER_CORRECT)
end

function NightmarePhaseIndicator:SetPositionTimerLeft()
    self.timer_postype = "LEFT"
    UpdateTextPostion(self.timer, self.timer_postype, MARGIN_TIMER_CORRECT)
end

function NightmarePhaseIndicator:SetPositionPhaseNameCenter()
    self.phasename_postype = nil
    UpdateTextPostion(self.phasename, self.phasename_postype, MARGIN_NAME_PHASE_CORRECT)
end

function NightmarePhaseIndicator:SetPositionPhaseNameTop()
    self.phasename_postype = "TOP"
    UpdateTextPostion(self.phasename, self.phasename_postype, MARGIN_NAME_PHASE_CORRECT)
end

function NightmarePhaseIndicator:SetPositionPhaseNameRight()
    self.phasename_postype = "RIGHT"
    UpdateTextPostion(self.phasename, self.phasename_postype, MARGIN_NAME_PHASE_CORRECT)
end

function NightmarePhaseIndicator:SetPositionPhaseNameBottom()
    self.phasename_postype = "BOTTOM"
    UpdateTextPostion(self.phasename, self.phasename_postype, MARGIN_NAME_PHASE_CORRECT)
end

function NightmarePhaseIndicator:SetPositionPhaseNameLeft()
    self.phasename_postype = "LEFT"
    UpdateTextPostion(self.phasename, self.phasename_postype, MARGIN_NAME_PHASE_CORRECT)
end

return NightmarePhaseIndicator
