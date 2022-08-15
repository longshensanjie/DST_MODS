local a = require "widgets/screen"
local b = require "widgets/widget"
local c = require "widgets/textedit"
local d = require "widgets/menu"
local e = require "widgets/uianim"
local function f(g, target)
    if not g.isopen then return end
    local h = g:GetText()
    local i = h:match("^%s*(.-%S)%s*$") or ""
    if h ~= i or #h <= 0 then
        g.edit_text:SetString(i)
        g.edit_text:SetEditing(true)
        return
    end
    if g.config.acceptbtn.cb ~= nil then g.config.acceptbtn.cb(g, target) end
    g:Close()
end
local function j(g)
    if not g.isopen then return end
    g.config.middlebtn.cb(g)
    g.edit_text:SetEditing(true)
end
local function k(g)
    if not g.isopen then return end
    if g.config.cancelbtn.cb ~= nil then g.config.cancelbtn.cb(g) end
    g:Close()
end
local l = Class(a, function(self, m, target)
    a._ctor(self, "SomeWriter")
    self.isopen = false;
    self.config = m;
    self._scrnw, self._scrnh = TheSim:GetScreenSize()
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self:SetMaxPropUpscale(MAX_HUD_SCALE)
    self:SetPosition(0, 0, 0)
    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_MIDDLE)
    self.scalingroot = self:AddChild(b("writeablewidgetscalingroot"))
    self.scalingroot:SetScale(TheFrontEnd:GetHUDScale())
    self.root = self.scalingroot:AddChild(b("writeablewidgetroot"))
    self.root:SetScale(.6, .6, .6)
    self.black = self.root:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0, 0, 0, 0)
    -- self.black.OnMouseButton = function() k(self) end;
    self.bganim = self.root:AddChild(e())
    self.bganim:SetScale(1, 1, 1)
    self.bgimage = self.root:AddChild(Image())
    self.bganim:SetScale(1, 1, 1)
    self.edit_text = self.root:AddChild(c(BUTTONFONT, 50, ""))
    self.edit_text:SetColour(0, 0, 0, 1)
    self.edit_text:SetForceEdit(true)
    self.edit_text:SetPosition(0, 40, 0)
    self.edit_text:SetRegionSize(430, 160)
    self.edit_text:SetHAlign(ANCHOR_LEFT)
    self.edit_text:SetVAlign(ANCHOR_TOP)
    self.edit_text:SetTextLengthLimit(MAX_WRITEABLE_LENGTH)
    self.edit_text:EnableWordWrap(true)
    self.edit_text:EnableWhitespaceWrap(true)
    self.edit_text:EnableRegionSizeLimit(true)
    self.edit_text:EnableScrollEditWindow(false)
    self.buttons = {}
    table.insert(self.buttons, {
        text = m.cancelbtn.text,
        cb = function() k(self) end,
        control = m.cancelbtn.control
    })
    if m.middlebtn ~= nil then
        table.insert(self.buttons, {
            text = m.middlebtn.text,
            cb = function() j(self) end,
            control = m.middlebtn.control
        })
    end
    table.insert(self.buttons, {
        text = m.acceptbtn.text,
        cb = function() f(self, target) end,
        control = m.acceptbtn.control
    })
    for n, o in ipairs(self.buttons) do
        if o.control ~= nil then
            self.edit_text:SetPassControlToScreen(o.control, true)
        end
    end
    local p = m.menuoffset or Vector3(0, 0, 0)
    if TheInput:ControllerAttached() then
        local q = 150;
        self.menu = self.root:AddChild(d(self.buttons, q, true, "none"))
        self.menu:SetTextSize(40)
        local r = self.menu:AutoSpaceByText(15)
        self.menu:SetPosition(p.x - .5 * r, p.y, p.z)
    else
        local q = 110;
        self.menu = self.root:AddChild(d(self.buttons, q, true, "small"))
        self.menu:SetTextSize(35)
        self.menu:SetPosition(p.x - .5 * q * (#self.buttons - 1), p.y, p.z)
    end
    local s = ""
    if self.config.defaulttext ~= nil then
        if type(self.config.defaulttext) == "string" then
            s = self.config.defaulttext
        end
    end
    self:OverrideText(s)
    self.edit_text:OnControl(CONTROL_ACCEPT, false)
    self.edit_text.OnTextEntered = function()
        self:OnControl(CONTROL_ACCEPT, false)
    end;
    self.edit_text:SetHelpTextApply("")
    self.edit_text:SetHelpTextCancel("")
    self.edit_text:SetHelpTextEdit("")
    self.default_focus = self.edit_text;
    if m.bgatlas ~= nil and m.bgimage ~= nil then
        self.bgimage:SetTexture(m.bgatlas, m.bgimage)
    end
    if m.animbank ~= nil then self.bganim:GetAnimState():SetBank(m.animbank) end
    if m.animbuild ~= nil then
        self.bganim:GetAnimState():SetBuild(m.animbuild)
    end
    if m.pos ~= nil then
        self.root:SetPosition(m.pos)
    else
        self.root:SetPosition(0, 150, 0)
    end
    self.isopen = true;
    self:Show()
    if self.bgimage.texture then
        self.bgimage:Show()
    else
        self.bganim:GetAnimState():PlayAnimation("open")
    end
end)
function l:OnBecomeActive()
    self._base.OnBecomeActive(self)
    self.edit_text:SetFocus()
    self.edit_text:SetEditing(true)
end
function l:Close()
    if self.isopen then
        if self.bgimage.texture then
            self.bgimage:Hide()
        else
            self.bganim:GetAnimState():PlayAnimation("close")
        end
        self.black:Kill()
        self.edit_text:SetEditing(false)
        self.edit_text:Kill()
        self.menu:Kill()
        self.isopen = false;
        TheFrontEnd:PopScreen(self)
    end
end
function l:OverrideText(t)
    self.edit_text:SetString(t)
    self.edit_text:SetFocus()
end
function l:GetText() return self.edit_text:GetString() end
function l:SetValidChars(u) self.edit_text:SetCharacterFilter(u) end
function l:OnControl(v, w)
    if l._base.OnControl(self, v, w) then return true end
    if not w then
        for n, o in ipairs(self.buttons) do
            if v == o.control and o.cb ~= nil then
                o.cb()
                return true
            end
        end
        if v == CONTROL_OPEN_DEBUG_CONSOLE then return true end
    end
end
return l
