--文件头部加载widget类
local Widget = require("widgets/widget")
local Text = require("widgets/text")

local text = "生物刷新时间\n"

local function addtext(txt)
    text = "\n"..text..txt
end

local cocktailText = Class(Widget, function ( self, owner )
    Widget._ctor(self, "cocktailText")
    self:AddChild(Text(BODYTEXTFONT, 30, text))
end)

return cocktailText