local _G = GLOBAL
local require = _G.require

local visible_animation      = true
local timer                  = "BOTTOM"
local phase_name             = "CENTER"
local horizontal_alignment   = "CENTER"
local vertical_alignment     = "TOP"
local horizontal_margin      = 0
local vertical_margin        = 50
local scale                  = GetModConfigData("phase_SCALE")
local visibly_have_medallion = GetModConfigData("phase_VISIBLY_HAVE_MEDALLION")

modimport("languages/NMphase_cn.lua")

local Widget = require "widgets/widget"
local NightmarePhaseIndicator = require "widgets/nightmarephaseindicator"

local function AddNightmarePhaseIndicator(self)
    if _G.TheWorld.net and _G.TheWorld.net.components.nightmareclock ~= nil then
        local original_CreateOverlays = self.CreateOverlays
        local original_OnMouseButton = self.OnMouseButton

        -- normalize position in logic coords game, default center screen
        local position = {x = 0, y = 0, hanchor = _G.ANCHOR_MIDDLE, vanchor = _G.ANCHOR_MIDDLE}

        if horizontal_alignment == "LEFT" then
            position.hanchor = _G.ANCHOR_LEFT
            position.x = horizontal_margin
        elseif horizontal_alignment == "RIGHT" then
            position.hanchor = _G.ANCHOR_RIGHT
            position.x = -horizontal_margin
        end

        if vertical_alignment == "TOP" then
            position.vanchor = _G.ANCHOR_TOP
            position.y = -vertical_margin
        elseif vertical_alignment == "BOTTOM" then
            position.vanchor = _G.ANCHOR_BOTTOM
            position.y = vertical_margin
        end

        self.CreateOverlays = function(owner)
            original_CreateOverlays(self, self.owner)

            self.nightmarephaseindicator = self.under_root:AddChild(Widget("nightmarephaseindicator_root"))
            self.nightmarephaseindicator:SetScaleMode(_G.SCALEMODE_PROPORTIONAL)
            self.nightmarephaseindicator:SetHAnchor(position.hanchor)
            self.nightmarephaseindicator:SetVAnchor(position.vanchor)
            self.nightmarephaseindicator:SetPosition(position.x, position.y)
            self.nightmarephaseindicator = self.nightmarephaseindicator:AddChild(NightmarePhaseIndicator())

            if visible_animation then
                self.nightmarephaseindicator:AnimationOn()
            else
                self.nightmarephaseindicator:AnimationOff()
            end

            if timer == "TOP" then
                self.nightmarephaseindicator:SetPositionTimerTop()
            elseif timer == "RIGHT" then
                self.nightmarephaseindicator:SetPositionTimerRight()
            elseif timer == "BOTTOM" then
                self.nightmarephaseindicator:SetPositionTimerBottom()
            elseif timer == "LEFT" then
                self.nightmarephaseindicator:SetPositionTimerLeft()
            elseif timer == "CENTER" then
                self.nightmarephaseindicator:SetPositionTimerCenter()
            else
                self.nightmarephaseindicator:HideTimer()
            end

            if phase_name == "TOP" then
                self.nightmarephaseindicator:SetPositionPhaseNameTop()
            elseif phase_name == "RIGHT" then
                self.nightmarephaseindicator:SetPositionPhaseNameRight()
            elseif phase_name == "BOTTOM" then
                self.nightmarephaseindicator:SetPositionPhaseNameBottom()
            elseif phase_name == "LEFT" then
                self.nightmarephaseindicator:SetPositionPhaseNameLeft()
            elseif phase_name == "CENTER" then
                self.nightmarephaseindicator:SetPositionPhaseNameCenter()
            else
                self.nightmarephaseindicator:HidePhaseName()
            end

            self.nightmarephaseindicator:SetScale(scale)

            if visibly_have_medallion then
                self.nightmarephaseindicator:RunObserverInventory()
            end

            -- try move layer announce to front
            for _, widget in pairs(self.under_root.children) do
                if widget and widget.name == "eventannouncer_root" then
                    widget:MoveToFront()
                    break
                end
            end
        end
    end
end

AddClassPostConstruct("screens/playerhud", AddNightmarePhaseIndicator)
