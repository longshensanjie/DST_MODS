local Widget = require "widgets/widget"
local TEMPLATES = require "widgets/redux/templates"
local Screen = require "widgets/screen"
local Text = require("widgets/text")
require("fonts")

local TextEntry = Class(Screen, function(self,owner,target)
    Screen._ctor(self, "TextEntry")
    self.target = target
    self.owner = owner or ThePlayer
    self._scrnw, self._scrnh = TheSim:GetScreenSize()
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_MIDDLE)

    self.root = self:AddChild(Widget("root"))
    self.tiptext = self:AddChild(Text(CHATFONT, 45, "设置刷新的天数(纯数字)：", UICOLOURS.WHITE))
    self.nametextedit=self.root:AddChild(TEMPLATES.StandardSingleLineTextEntry("",200,80,CHATFONT,45,"设置刷新天数(20)"))
    self.confirmbutton=self.root:AddChild(TEMPLATES.StandardButton(function()self:Confirm()end,"确认",{80, 80}))
    self.cancelbutton=self.root:AddChild(TEMPLATES.StandardButton(function()self:OnClose() end,"取消",{80, 80}))
    self.confirmbutton:SetPosition(200,0)
    self.cancelbutton:SetPosition(300,0)
    self.tiptext:SetPosition(-300,0)
end)

function TextEntry:Confirm()
    local str=self.nametextedit.textbox:GetString()
    if self.target then
        self.owner.HUD:hxSetBossDuration(self.target,str)
    end
    self:OnClose()
end

function TextEntry:OnClose()
    TheFrontEnd:PopScreen() 
    self:Kill()
end

-- function TextEntry:Close()
--     self:Kill()
-- end

return TextEntry