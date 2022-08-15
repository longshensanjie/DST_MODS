local Text = require "widgets/text"
local Widget = require "widgets/widget"

local DPWidget = Class(Widget, function(self)
    Widget._ctor(self, "CoordinatesWidget")
    self.num = self:AddChild(Text(NUMBERFONT, 30))
    self.num:SetHAlign(ANCHOR_MIDDLE)
    self.num:SetString("hello")
    self.num:SetPosition(0, -25)
end)

return DPWidget
