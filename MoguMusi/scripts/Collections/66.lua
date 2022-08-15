local _G = GLOBAL
local require = GLOBAL.require
local Text = require "widgets/text"

local STRING_TIME_DEFAULT = "--:--"

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

local function UpdateItemTile(inst)
    local timestr = STRING_TIME_DEFAULT
    local rechargetime = inst.rechargetime
    if inst.rechargepct < 0.9999 then
        local timeleft = math.floor(rechargetime - (rechargetime * inst.rechargepct))
        timeleft = timeleft <= 0 and 0 or timeleft
        timestr = GetTimeString(timeleft + 1)
    end
    if timestr == STRING_TIME_DEFAULT then
        inst.recharge_timer:Hide()
    else
        inst.recharge_timer:Show()
    end
    inst.recharge_timer:SetString(timestr)
end

AddClassPostConstruct("widgets/itemtile", function(self, invitem)
    if invitem:HasTag("rechargeable") then
        if not self.recharge_timer then
            self.recharge_timer = self:AddChild(Text(_G.NUMBERFONT, 42))
            self.recharge_timer:SetPosition(5, -17, 0)
        end
        self.recharge_timer:SetString(STRING_TIME_DEFAULT)
        self.recharge_timer:Hide()

        local original_SetChargePercent = self.SetChargePercent
        self.SetChargePercent = function(self, percent, ...)
            original_SetChargePercent(self, percent, ...)
            UpdateItemTile(self)
        end

        local original_SetChargeTime = self.SetChargeTime
        self.SetChargeTime = function(self, t, ...)
            original_SetChargeTime(self, t, ...)
            UpdateItemTile(self)
        end
    end
end)