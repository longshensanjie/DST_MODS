local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local TextBtn = require "widgets/textbutton"
local Text = require "widgets/text"
local Quotations = require "QAQ/Quotations"
-------------------------------------------------------------------------------------------------------
local HuxiWindow = Class(Widget, function(self, dearbtns)
    Widget._ctor(self, "HuxiWindow")

    self.root = self:AddChild(Widget("root"))
    self.DearBtns = dearbtns or {}

    local screen_w, screen_h = TheSim:GetScreenSize()
    local height_frame = math.min(screen_w, screen_h) * 0.8
    local width_frame = height_frame * 0.8
    
    self.frame = self.root:AddChild(self:MakeFrame(width_frame, height_frame))
    self.root:SetHAnchor(ANCHOR_RIGHT)
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(-width_frame*0.6, screen_h*0.05)

    self:CloseIt()
end)

function HuxiWindow:GetQuotation() return GetRandomItem(Quotations) end

function HuxiWindow:MakeFrame(width, height)
    local w = Widget("huxi_menu_frame")

    local atlas = resolvefilepath(CRAFTING_ATLAS)

    -- 标题儿
    self.title_panel = w:AddChild(TextBtn())
    self.title_panel:SetFont(UIFONT)
    self.title_panel:SetText("蘑菇慕斯 · 蝶蛹󰀜")
    self.title_panel:SetTextSize(35)
    self.title_panel:SetColour(UICOLOURS.WHITE)
    self.title_panel:SetOnClick(function()
        -- self:CloseIt()
        self.title_panel:SetText(self.GetQuotation())
    end)
    self.title_panel:SetPosition(0, height / 2 - 13)

    -- 背景儿
    local fill = w:AddChild(Image(atlas, "backing.tex"))
    fill:ScaleToSize(width + 10, height + 18)
    fill:SetTint(1, 1, 1, 0.3)

    -- 上下左右四条边儿
    local left = w:AddChild(Image(atlas, "side.tex"))
    local right = w:AddChild(Image(atlas, "side.tex"))
    local top = w:AddChild(Image(atlas, "top.tex"))
    local bottom = w:AddChild(Image(atlas, "bottom.tex"))
    -- 分割条儿
    local itemlist_split = w:AddChild(Image(atlas, "horizontal_bar.tex"))

    left:SetPosition(-width / 2 - 8, 1)
    right:SetPosition(width / 2 + 8, 1)
    top:SetPosition(0, height / 2 + 10)
    bottom:SetPosition(0, -height / 2 - 8)

    left:ScaleToSize(-26, -(height - 20))
    right:ScaleToSize(26, height - 20)
    top:ScaleToSize(width+33, 38)
    bottom:ScaleToSize(width+33, 38)
    itemlist_split:SetPosition(0, height / 2 - 35)
    itemlist_split:ScaleToSize(width, 15)

    -- 功能儿
    self.funcs = w:AddChild(self:MakeButtons(width, 6))
    self.funcs:SetPosition(-width / 2, height / 2 - 30)

    -- fill:MoveToBack()
    self.title_panel:MoveToFront()
    return w
end

function HuxiWindow:MakeButtons(width, num_col)
    local margin_x = width / 60
    local margin_y = width / 15
    local spacing_y = width / 5.8
    local spacing_x = (width - 2 * margin_x) / num_col
    local x_init = margin_x + spacing_x / 2
    local y_init = -margin_y
    local w = Widget("huxi_menu_buttons")

    for order, dearbtn in pairs(self.DearBtns) do
        -- for order = 1, 33, 1 do
        dearbtn.length_img = width / 10
        local x_pos = x_init + ((order - 1) % num_col) * spacing_x
        local y_pos = y_init - math.floor((order - 1) / num_col) * spacing_y
        local cus_btn = w:AddChild(self:CustomButton(dearbtn))
        cus_btn:SetPosition(x_pos, y_pos)
    end

    return w
end

function HuxiWindow:CustomButton(dearbtn)
    local length_img = dearbtn.length_img
    local w = Widget("huxi_dear_btn")
    local img = w:AddChild(ImageButton(dearbtn.atlas, dearbtn.tex))
    local sizeX, sizeY = img:GetSize()
    local trans_scale = math.min(length_img / sizeX, length_img / sizeY)
    img:SetNormalScale(trans_scale)
    img:SetFocusScale(trans_scale * 1.2)
    img:SetOnClick(function()
        dearbtn.fn()
        if dearbtn.tclose then self:CloseIt() end
    end)
    local _OnGainFocus = img.OnGainFocus
    img.OnGainFocus = function(...)
        _OnGainFocus(img, ...)
        self.title_panel:SetText(dearbtn.tooltip)
    end

    local destxt = w:AddChild(Text(UIFONT, length_img / 2, dearbtn.destxt,
                                   UICOLOURS.WHITE))
    destxt:SetPosition(0, -length_img*0.85)
    return w
end

local function get_shadeds()
    return ThePlayer and ThePlayer.HUD and ThePlayer.HUD.controls and {
        ThePlayer.HUD.controls.minimap_small, ThePlayer.HUD.controls.clock,
        ThePlayer.HUD.controls.status, ThePlayer.HUD.controls.seasonclock,
        ThePlayer.HUD.controls.season
    }
end

function HuxiWindow:CloseIt()
    local shadeds = get_shadeds()
    if type(shadeds) == "table" then
        for _, shaded_ui in pairs(shadeds) do shaded_ui:Show() end
    end
    self:Hide()
    TheCamera:PushScreenHOffset(self, 0)
end

function HuxiWindow:ShowIt()
    local shadeds = get_shadeds()
    if type(shadeds) == "table" then
        for _, shaded_ui in pairs(shadeds) do shaded_ui:Hide() end
    end
    if ThePlayer and ThePlayer.HUD and ThePlayer.HUD.controls and
        ThePlayer.HUD.controls.minimap_small then
        ThePlayer.HUD.controls.minimap_small:Hide()
    end
    self:Show()
    TheCamera:PushScreenHOffset(self, 0.17 * RESOLUTION_X)

    -- 这里可以输出些有意思的信息
    -- 比如降雨预测等
    -- 这里怎么会有错！这bug离谱嗷
    if self.title_panel and self.title_panel.text and self.title_panel.text:GetRegionSize() then
        self.title_panel:SetText("蘑菇慕斯 · 蝶蛹󰀜")
    end
end
return HuxiWindow
