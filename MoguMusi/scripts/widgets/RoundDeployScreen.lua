local Widget = require "widgets/widget"
local Screen = require "widgets/screen"
local Image = require("widgets/image")
local TextEdit = require("widgets/textedit")
local Text = require("widgets/text")
local TextButton = require("widgets/textbutton")
local TEMPLATES = require "widgets/redux/templates"
local scheme = require("cookpot")
-- local LANG = GetModConfigData("language")

local string = {}
if TUNING.LANG == "ch_s" then
    string = {
        setting = "设置",
        close = "关闭",
        shape = "形状",
        param = "参数",
        calc = "计算",
        ra = "半径/数量",
        ra_hover = "通过半径和间隔确定最大数量",
        ar = "数量/半径",
        ar_hover = "通过数量和间隔确定最小半径",
        custom = "自定义",
        custom_hover = "自定义半径和数量",
        circle = "圆形",
        circle_hover = "设置形状为圆形",
        cardioid = "心形线",
        cardioid_hover = "设置形状为心形",
        straight = "直线",
        straight_hover = "设置形状为直线",
        square = "正方形",
        square_hover = "设置形状为正方形",
        radius = "半径",
        deploynum = "数量",
        interval = "间隔",
        spin = "旋转角度",
        range = "部署角度",
        space = "额外间距:",
        space_honver = "种植多圈时，圈之间额外的距离.",
        clear = "清除",
        full_layers = "满层",
        single_layer = "单层",
        fl_hover = "种满整个圆",
        sl_hover = "只有最外圈"

    }
else
    string = {
        setting = "setting",
        close = "close",
        shape = "shape",
        param = "params",
        calc = "calc",
        ra = "radius/number",
        ra_hover = "Determine the maximum number by radius and interval",
        ar = "number/radius",
        ar_hover = "Determine the minimum radius by amount and interval",
        custom = "custom",
        custom_hover = "Custom radius and number",
        circle = "circle",
        circle_hover = "Set shape to circle",
        cardioid = "cardioid",
        cardioid_hover = "Set shape to cardioid",
        straight = "straight",
        straight_hover = "Set shape to straight",
        square = "square",
        square_hover = "Set shape to square",
        radius = "radius",
        deploynum = "amount",
        interval = "interval",
        spin = "spin",
        range = "range",
        space = "ex_space:",
        space_honver = "the extra distance between the circles.",
        clear = "clear",
        full_layers = "full",
        single_layer = "One",
        fl_hover = "Plant the whole circle",
        sl_hover = "Only the outermost circle"
    }
end
local function AddHoverText(widget, params, labelText)
    params = params or {}

    -- Widget class defaults these on its own in SetHoverText
    -- params.font = params.font or NEWFONT_OUTLINE
    -- params.size = params.size or 22

    params.offset_x = params.offset_x or 2
    -- add an extra 30 if it's got two lines of text
    params.offset_y = params.offset_y or 75
    local sign = params.offset_y < 0 and -1 or 1
    params.offset_y = params.offset_y + sign *
                          (labelText:match("\n") and 30 or 0)
    params.colour = params.colour or UICOLOURS.WHITE

    -- switcharoo with the text to make sure the hover parenting works correctly (bypassing a dev workaround for labels)
    local text = widget.text
    widget.text = nil
    widget:SetHoverText(labelText, params)
    widget.text = text
end
local toggle_strings = {[false] = string.sl_hover, [true] = string.fl_hover}
local RoundDeployScreen = Class(Screen, function(self, owner)
    Screen._ctor(self, "RoundDeploy")
    self.callback = {}
    TheInput:ClearCachedController()
    local cal = owner.components.deploydata
    self.black = self:AddChild(Image("images/global.xml", "square.tex"))
    self.black:SetVRegPoint(ANCHOR_MIDDLE)
    self.black:SetHRegPoint(ANCHOR_MIDDLE)
    self.black:SetVAnchor(ANCHOR_MIDDLE)
    self.black:SetHAnchor(ANCHOR_MIDDLE)
    self.black:SetScaleMode(SCALEMODE_FILLSCREEN)
    self.black:SetTint(0, 0, 0, .5)

    self.root = self:AddChild(Widget("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetPosition(0, 0, 0)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)

    local close_button = {
        {text = string.close, cb = function() self:Close() end}
    }
    self.bg = self.root:AddChild(TEMPLATES.RectangleWindow(619, 359,
                                                           string.setting,
                                                           close_button))
    self.bg.title:SetPosition(0, -70)

    self.vertical_line1 = self.root:AddChild(
                              Image("images/global_redux.xml",
                                    "item_divider.tex"))
    self.vertical_line1:SetRotation(90)
    self.vertical_line1:SetScale(1, .32)
    self.vertical_line1:SetPosition(-170, -40)

    self.vertical_line2 = self.root:AddChild(
                              Image("images/global_redux.xml",
                                    "item_divider.tex"))
    self.vertical_line2:SetRotation(90)
    self.vertical_line2:SetScale(1, .32)
    self.vertical_line2:SetPosition(170, -40)

    self.horizontal_line = self.root:AddChild(
                               Image("images/global_redux.xml",
                                     "item_divider.tex"))
    self.horizontal_line:SetScale(.8, 1)
    self.horizontal_line:SetPosition(0, 60)

    self.subtitle_geometry = self.root:AddChild(Text(CHATFONT, 25))
    self.subtitle_geometry:SetPosition(-205, 80, 0)
    self.subtitle_geometry:SetString(string.shape)
    self.subtitle_geometry:SetColour(UICOLOURS.GOLD)

    self.subtitle_color = self.root:AddChild(Text(CHATFONT, 25))
    self.subtitle_color:SetPosition(0, 80, 0)
    self.subtitle_color:SetString(string.param)
    self.subtitle_color:SetColour(UICOLOURS.GOLD)

    self.subtitle_misc = self.root:AddChild(Text(CHATFONT, 25))
    self.subtitle_misc:SetPosition(205, 80, 0)
    self.subtitle_misc:SetString(string.calc)
    self.subtitle_misc:SetColour(UICOLOURS.GOLD)

    local toggle_state = cal.isFullLayers
    self.toggle_button = self.root:AddChild(
                             TEMPLATES.IconButton("images/frontend.xml",
                                                  "button_square_highlight.tex",
                                                  toggle_strings[true], false,
                                                  false, function()
            toggle_state = not toggle_state
            self.toggle_button.text:SetString(toggle_state and
                                                  string.full_layers or
                                                  string.single_layer)
            self.toggle_button.hovertext:SetString(toggle_strings[toggle_state])
            cal.isFullLayers = toggle_state
        end, {90}))
    self.toggle_button.icon:Hide()
    self.toggle_button:SetTextSize(36)
    self.toggle_button:SetText("")
    self.toggle_button.image:SetTint(.5, 1, .5, 1)
    self.toggle_button:SetPosition(255, 135)

    -- local y=-120
    -- for _,v in pairs({"radius","spin","interval","range","deploynum"}) do
    --     self[v]= self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
    --     self[v]:SetPosition(y, 25, 0)
    --     self[v]:SetTextColour(UICOLOURS.GOLD)
    --     self[v]:SetText(string[v])
    --     self[v]:SetOnClick(function()
    --         print(cal:getParm(v))
    --     end)
    --     y=y+60
    -- end
    local textsize = 25
    self.radius = self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
    self.radius:SetPosition(-120, 25, 0)
    self.radius:SetText(string.radius)
    self.radius:SetTextSize(textsize)
    self.radius:SetTextColour(UICOLOURS.GOLD)
    self.radius:SetOnClick(function()
        local fnstr = self.edit_text:GetString()
        if fnstr ~= "0" and type(tonumber(fnstr)) == "number" then
            if tonumber(fnstr) < 0 then
                cal.order = true
            else
                cal.order = false
            end
            if cal.mode == 0 then
                cal:setRadius(tonumber(fnstr))
            elseif cal.mode == 2 then
                cal.radius = tonumber(fnstr)
            end
        end
        self:upvalue(cal)
    end)

    self.spin = self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
    self.spin:SetPosition(-60, 25, 0)
    self.spin:SetText(string.spin)
    self.spin:SetTextSize(textsize)
    self.spin:SetTextColour(UICOLOURS.GOLD)
    self.spin:SetOnClick(function()
        local fnstr = self.edit_text:GetString()
        if type(tonumber(fnstr)) == "number" then
            fnstr = tonumber(fnstr) % 360
            if cal.mode ~= 2 then
                cal:setspin(fnstr)
            else
                cal.spin = fnstr
            end
        end
        self:upvalue(cal)
    end)

    self.interval = self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
    self.interval:SetPosition(0, 25, 0)
    self.interval:SetText(string.interval)
    self.interval:SetTextSize(textsize)
    self.interval:SetTextColour(UICOLOURS.GOLD)
    self.interval:SetOnClick(function()
        local fnstr = self.edit_text:GetString()
        if type(tonumber(fnstr)) == "number" then

            cal:setInterval(tonumber(fnstr))
        else
            cal:setInterval(self.inv)
        end
        self:upvalue(cal)
    end)

    self.range = self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
    self.range:SetPosition(60, 25, 0)
    self.range:SetText(string.range)
    self.range:SetTextSize(textsize)
    self.range:SetTextColour(UICOLOURS.GOLD)
    self.range:SetOnClick(function()
        local fnstr = self.edit_text:GetString()
        local num = tonumber(fnstr)
        if type(num) == "number" then
            if num > 0 then
                cal.direction = true
            else
                cal.direction = false
            end
            if num % 360 == 0 then
                num = 360
            else
                num = num % 360
            end
            if cal.mode ~= 2 then
                cal:setRange(num)
            else
                cal.range = num
            end
        end
        self:upvalue(cal)

    end)

    self.deploynum =
        self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
    self.deploynum:SetPosition(120, 25, 0)
    self.deploynum:SetText(string.deploynum)
    self.deploynum:SetTextSize(textsize)
    self.deploynum:SetTextColour(UICOLOURS.GOLD)
    self.deploynum:SetOnClick(function()
        local fnstr = self.edit_text:GetString()
        if fnstr ~= "0" and type(tonumber(fnstr)) == "number" then
            fnstr = math.abs(tonumber(fnstr))
            if cal.mode == 1 then cal:setStep(math.floor(fnstr)) end
            if cal.mode == 2 then
                cal.step = math.abs(cal.range) / math.floor(fnstr)
                cal.deploynum = math.floor(fnstr)
            end
        end
        self:upvalue(cal)
    end)

    self.radiusdata = self.root:AddChild(Text(CHATFONT, 25))
    self.radiusdata:SetPosition(-120, -50, 0)
    self.radiusdata:SetColour(UICOLOURS.GOLD)

    self.spindata = self.root:AddChild(Text(CHATFONT, 25))
    self.spindata:SetPosition(-60, -50, 0)
    self.spindata:SetColour(UICOLOURS.GOLD)

    self.intervaldata = self.root:AddChild(Text(CHATFONT, 25))
    self.intervaldata:SetPosition(0, -50, 0)
    self.intervaldata:SetColour(UICOLOURS.GOLD)

    self.rangedata = self.root:AddChild(Text(CHATFONT, 25))
    self.rangedata:SetPosition(60, -50, 0)
    self.rangedata:SetColour(UICOLOURS.GOLD)

    self.deploynumdata = self.root:AddChild(Text(CHATFONT, 25))
    self.deploynumdata:SetPosition(120, -50, 0)
    self.deploynumdata:SetColour(UICOLOURS.GOLD)

    self.mode_buttons = {
        radiusangle = {text = string.ra, hover = string.ar_hover},
        angleradius = {text = string.ar, hover = string.ra_hover},
        custom = {text = string.custom, hover = string.custom_hover}
    }
    local button_y = 10
    for _, mode_preset in pairs({"radiusangle", "angleradius", "custom"}) do
        local button_params = self.mode_buttons[mode_preset]
        local button = self.root:AddChild(
                           TEMPLATES.StandardButton(function()
                for mode_name, mode_button in pairs(self.mode_buttons) do
                    if mode_name == mode_preset then
                        mode_button:Select()
                        cal:setMode(mode_name)
                    else
                        mode_button:Unselect()
                    end
                end
            end, button_params.text, {160, 50}))
        button:SetPosition(260, button_y)
        button:SetScale(.7)
        button:SetTextSize(30)
        button:SetHoverText(button_params.hover)
        button_y = button_y - 50
        self.mode_buttons[mode_preset] = button
    end

    self.shape_buttons = {
        circle = {text = string.circle, hover = string.circle_hover},
        cardioid = {text = string.cardioid, hover = string.cardioid_hover},
        straight = {text = string.straight, hover = string.straight_hover},
        square = {text = string.square, hover = string.square_hover}
    }
    local shape_buttons_y = 10
    for _, mode_preset in pairs({"circle", "cardioid", "straight", "square"}) do
        local button_params = self.shape_buttons[mode_preset]
        local button = self.root:AddChild(
                           TEMPLATES.StandardButton(function()
                for mode_name, mode_button in pairs(self.shape_buttons) do
                    if mode_name == mode_preset then
                        mode_button:Select()
                        cal.shape = mode_name
                    else
                        mode_button:Unselect()
                    end
                end
            end, button_params.text, {160, 50}))
        button:SetPosition(-260, shape_buttons_y)
        button:SetScale(0.7)
        button:SetTextSize(30)
        button:SetHoverText(button_params.hover)
        shape_buttons_y = shape_buttons_y - 50
        self.shape_buttons[mode_preset] = button
    end

    self.edit_bg = self.root:AddChild(Image())
    self.edit_bg:SetTexture("images/textboxes.xml", "textbox_long.tex")
    self.edit_bg:SetPosition(-25, -125, 0)
    self.edit_bg:ScaleToSize(235, 40)

    self.edit_text = self.root:AddChild(TextEdit(DEFAULTFONT, 32, ""))
    self.edit_text:SetColour(0, 0, 0, 1)
    -- self.edit_text.edit_text_color = {166/255, 143/255, 97/255, 1}
    -- self.edit_text.idle_text_color = {166/255, 143/255, 97/255, 1}
    self.edit_text:SetForceEdit(true)
    self.edit_text:SetPosition(-25, -125, 0)
    self.edit_text:SetRegionSize(220, 32)
    self.edit_text:SetHAlign(ANCHOR_MIDDLE)
    self.edit_text:SetVAlign(ANCHOR_MIDDLE)
    self.edit_text:SetTextLengthLimit(10)
    self.edit_text:EnableWordWrap(true)
    self.edit_text:EnableWhitespaceWrap(true)
    self.edit_text:EnableRegionSizeLimit(true)
    self.edit_text:EnableScrollEditWindow(false)

    self.clear = self.root:AddChild(TextButton("images/ui.xml", "blank.tex"))
    self.clear:SetPosition(120, -125, 0)
    self.clear:SetText(string.clear)
    self.clear:SetTextColour(UICOLOURS.GOLD)
    self.clear:SetOnClick(function()
        local fnstr = self.edit_text:GetString()
        for k in pairs(scheme) do
            if k == fnstr then
                cal.scheme = fnstr
                break
            else
                cal.scheme = ""
            end
        end
        self.edit_text:SetString("")
        self.edit_text:SetFocus()
        self.edit_text:SetEditing(true)
    end)

    -- self.spance = self.root:AddChild(Text(CHATFONT, 30))
    -- self.spance:SetPosition(235, -140, 0)
    -- self.spance:SetColour(UICOLOURS.GOLD)
    -- self.spance:SetScale(0.7)
    -- self.spance:SetString("层间距")

    local percent_options = {}
    for i = 0, 11 do
        percent_options[i] = {text = (i - 1) / 10, data = (i - 1) / 10}
    end
    self.refresh = self.root:AddChild(TEMPLATES.LabelSpinner(string.space,
                                                             percent_options,
                                                             160, -- label width
                                                             100, -- spinner width
                                                             30, -- height
    0, -- spacing between label and spinner
    nil, 32, -- font and size
    0, -- horizontal offset
    function(selected) cal.space = selected end))
    self.refresh:SetPosition(230, -140)
    self.refresh:SetScale(0.7)
    self.subtitle_refresh = self.refresh.label -- also needed for gross fix
    self.refresh = self.refresh.spinner
    AddHoverText(self.refresh, {offset_x = -4, offset_y = 50},
                 string.space_honver)

end)

function RoundDeployScreen:upvalue(cal)
    cal.scheme = ""
    self.refresh:SetSelected(cal.space)
    self.toggle_button.text:SetString(cal.isFullLayers and string.full_layers or
                                          string.single_layer)
    self.toggle_button.hovertext:SetString(toggle_strings[cal.isFullLayers])
    self.radiusdata:SetString(cal.radius)
    self.spindata:SetString(cal.spin)
    self.intervaldata:SetString(cal.interval)
    local range = cal.direction and cal.range or -cal.range
    self.rangedata:SetString(range)
    self.deploynumdata:SetString(cal.deploynum)
end

function RoundDeployScreen:OnRawKey(key, down)
    if RoundDeployScreen._base.OnRawKey(self, key, down) then return true end
    if key == self.toggle_key and not down then
        self.callback.ignore()
        self:Close()
        return true
    end
end
function RoundDeployScreen:OnControl(control, down)
    if RoundDeployScreen._base.OnControl(self, control, down) then
        return true
    elseif not down and
        (control == CONTROL_PAUSE or control == CONTROL_CANCEL or control ==
            KEY_B) then
        self:Close()
        return true
    end
end
function RoundDeployScreen:OnBecomeActive()
    RoundDeployScreen._base.OnBecomeActive(self)
    -- Hide the topfade, it'll obscure the pause menu if paused during fade. Fade-out will re-enable it
    TheFrontEnd:HideTopFade()
end
function RoundDeployScreen:Close()
    TheFrontEnd:PopScreen()
    TheFrontEnd:GetSound():PlaySound("/dontstarve/HUD/click_move")
end
return RoundDeployScreen
