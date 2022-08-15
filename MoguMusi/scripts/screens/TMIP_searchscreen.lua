require "util"
local a = require "widgets/screen"
local b = require "widgets/widget"
local c = require "widgets/textedit"
local d = Class(a, function(self, e)
    a._ctor(self, "SearchScreen")
    self.config = e;
    self:DoInit()
end)
function d:OnBecomeActive()
    d._base.OnBecomeActive(self)
    if self.config.activefn ~= nil then
        self.config.activefn()
    end
    self.edit_text:SetFocus()
    TheFrontEnd:LockFocus(true)
end
function d:OnBecomeInactive()
    d._base.OnBecomeInactive(self)
end
function d:OnControl(f, g)
    if d._base.OnControl(self, f, g) then
        return true
    end
    if f == CONTROL_OPEN_DEBUG_CONSOLE then
        return true
    end
    if not g and f == CONTROL_CANCEL then
        self:Close()
        return true
    end
end
function d:OnRawKey(h, g)
    if d._base.OnRawKey(self, h, g) then
        return true
    end
    if g then
        return
    end
    if self.config.rawkeyfn ~= nil then
        self.config.rawkeyfn(h, self)
    end
    return true
end
function d:Run()
    if self.config.acceptfn ~= nil then
        self.config.acceptfn(self:GetText())
    end
end
function d:Close()
    if self.config.closefn ~= nil then
        self.config.closefn()
    end
    TheInput:EnableDebugToggle(true)
    TheFrontEnd:PopScreen(self)
end
function d:OnTextEntered()
    self:Run()
    self:Close()
end
function d:DoInit()
    TheInput:EnableDebugToggle(false)
    self.root = self:AddChild(b(""))
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root = self.root:AddChild(b(""))
    if _G.TOOMANYITEMS.UI_LANGUAGE == "cn" then
        self.root:SetPosition(8, -30, 0)
    else
        self.root:SetPosition(0, -30, 0)
    end
    self.edit_text = self.root:AddChild(c(NEWFONT, self.config.fontsize, ""))
    self.edit_text:SetPosition(self.config.pos)
    self.edit_text:SetRegionSize(self.config.size[1], self.config.size[2])
    self.edit_text.OnTextEntered = function()
        self:OnTextEntered()
    end;
    self.edit_text:SetPassControlToScreen(CONTROL_CANCEL, true)
    self.edit_text:SetPassControlToScreen(CONTROL_MENU_MISC_2, true)
    self.edit_text:SetEditing(self.config.isediting)
    self.edit_text:SetForceEdit(self.config.isediting)
end
function d:OverrideText(i)
    self.edit_text:SetString(i)
    self.edit_text:SetFocus()
end
function d:GetText()
    return self.edit_text:GetString()
end
return d
