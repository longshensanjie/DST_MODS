local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Pxl_42_Slider = require "widgets/pxl_42_slider"
local TEMPLATES = require "widgets/redux/templates"

local Pxl_42_ControlBar = Class(Widget, function(self, label_width, controlbar_width, height)
    Widget._ctor(self, "Pxl_42_ControlBar")

    self.label_width = label_width
    self.controlbar_width = controlbar_width
    self.spacing = 5
    self.total_width = label_width + controlbar_width + self.spacing
    self.height = height

    local font = CHATFONT
    local colour = UICOLOURS.GOLD

    self.label = self:AddChild(Text(font, 25, "", colour))
    self.label:SetPosition((self.label_width - self.total_width) / 2, 0)
    self.label:SetRegionSize(self.label_width, self.height)
    self.label:SetHAlign(ANCHOR_RIGHT)

    self.header = self:AddChild(Text(font, 30, "", colour))

    self.control_root = self:AddChild(Widget("control_root"))
    self.control_root:SetPosition((self.total_width - self.controlbar_width) / 2 + self.spacing, 0)

    self.spinner = self.control_root:AddChild(TEMPLATES.StandardSpinner({}, self.controlbar_width, height, font, 25, false, colour))

    self.slider = self.control_root:AddChild(Pxl_42_Slider(self.controlbar_width, height))
end)

return Pxl_42_ControlBar