local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local TextEdit = require "widgets/textedit"

local Pxl_42_Slider = Class(Widget, function(self, width, height)
    Widget._ctor(self, "Pxl_42_Slider")

    self.width = width
    self.height = height

    self.root = self:AddChild(Widget("root"))

    self.sliderbar_width = self.width * 2 / 3
    self.current_pos = 0
    self.start_pos = 0
    self.end_pos = 0
	self.target_pos = self.current_pos

    self.reset_button = self.root:AddChild(ImageButton("images/avatars.xml", "loading_indicator.tex"))
    self.reset_button:SetPosition(self.width / 3 + 30, 0, 0)
    self.reset_button:SetScale(0.6)
    self.reset_button:SetOnClick(function()
        self:Reset()
    end)

    self.edit_root = self.root:AddChild(Widget("edit_root"))
    self.edit_root:SetPosition(self.width / 3 - 5, 0, 0)

    self.editbox_bg = self.edit_root:AddChild(Image("images/ui.xml", "in-window_button_tile_hl_noshadow.tex"))
    self.editbox_bg:ScaleToSize(38, 28)

    self.value_editbox = self.edit_root:AddChild(TextEdit(TALKINGFONT, 25, ""))
    self.value_editbox:SetColour(unpack(WHITE))
    self.value_editbox.edit_text_color = WHITE
    self.value_editbox.idle_text_color = WHITE
    self.value_editbox:SetEditCursorColour(unpack(WHITE))
    self.value_editbox:SetTextLengthLimit(5)
    self.value_editbox:EnableWordWrap(false)
    self.value_editbox:EnableScrollEditWindow(false)
    self.value_editbox:SetForceEdit(true)
    self.value_editbox:SetCharacterFilter("-.1234567890")
    self.value_editbox.controlbar = self
    self.value_editbox.OnStopForceEdit = function(self)
        local number = tonumber(self:GetString())
        if self.controlbar then
            if number then
                self.controlbar.current_pos = math.clamp(number, self.controlbar.min, self.controlbar.max) - self.controlbar.min
                self.controlbar.target_pos = self.controlbar.current_pos
            end
            self.controlbar:RefreshView()
        end
    end

    self.slider_bar_root = self.root:AddChild(Widget("slider_bar_root"))
    self.slider_bar_root:SetPosition((self.sliderbar_width - self.width) / 2, 0)

    self.slider_bar_line = self.slider_bar_root:AddChild(Image("images/ui.xml", "line_horizontal_1.tex"))
    self.slider_bar_line:ScaleToSize(self.sliderbar_width + 12, 3)
    self.slider_bar_line:SetPosition(0, 0)

    self.marker_root = self.slider_bar_root:AddChild(Widget("marker_root"))
    self.marker_root:SetPosition(-self.sliderbar_width / 2, 0)

    self.position_marker = self.marker_root:AddChild(ImageButton("images/global_redux.xml", "scrollbar_handle.tex"))
    self.position_marker.scale_on_focus = false
    self.position_marker.move_on_click = false
    self.position_marker.show_stuff = true
    self.position_marker:SetPosition(0, 0)
    self.position_marker:SetScale(0.2, 0.2, 1)
    self.position_marker:SetOnDown(function()
        TheFrontEnd:LockFocus(true)
        self.dragging = true
        self.saved_slider_pos = self.target_pos
    end)
    self.position_marker:SetWhileDown(function()
		self:DoDragSlider()
    end)
    self.position_marker.OnLoseFocus = function()
    end
    self.position_marker:SetOnClick(function()
        self.dragging = nil
        TheFrontEnd:LockFocus(false)
        self:RefreshView()
    end)
end)

function Pxl_42_Slider:SetData(data)
    self.modified = false
    self.data = data
    self.min = data.min
    self.max = data.max
    self.end_pos = data.max - data.min
    self.current_pos = data.temp ~= nil and data.temp - data.min or data.value - data.min
    self.target_pos = self.current_pos
    self:RefreshView()
end

function Pxl_42_Slider:DoDragSlider()
    self.modified = true
    local marker = self.position_marker:GetWorldPosition()
	local DRAG_SCROLL_Y_THRESHOLD = 150
    if math.abs(TheFrontEnd.lasty - marker.y) <= DRAG_SCROLL_Y_THRESHOLD then
		self.position_marker:SetPosition(self:GetSlideStart(), 0)
        marker = self.position_marker:GetWorldPosition()
        local start_x = marker.x
        self.position_marker:SetPosition(self:GetSlideRange(), 0)
        marker = self.position_marker:GetWorldPosition()
        local end_x = marker.x

        local slider_value = math.clamp((TheFrontEnd.lastx - end_x)/(start_x - end_x), 0, 1)
        self.current_pos = (1 - slider_value) * self.end_pos
        self.target_pos = self.current_pos
    else
        self.current_pos = self.saved_slider_pos
        self.target_pos = self.saved_slider_pos
    end

    self:RefreshView()
end

function Pxl_42_Slider:Reset()
    self.modified = true
    if self.data then
        self.current_pos = self.data.default - self.data.min
        self.target_pos = self.current_pos
    else
        self.current_pos = 0
        self.target_pos = 0
    end
    self:RefreshView()
end

function Pxl_42_Slider:GetPositionScale()
	return self.target_pos / self.end_pos
end

function Pxl_42_Slider:GetSlideStart()
	return 0
end

function Pxl_42_Slider:GetSlideRange()
	return self.sliderbar_width
end

function Pxl_42_Slider:RefreshView()
    if self.end_pos < 10 then
        self.target_pos = self.target_pos - self.target_pos % 0.01
    elseif self.end_pos < 100 then
        self.target_pos = self.target_pos - self.target_pos % 0.1
    elseif self.end_pos < 1000 then
        self.target_pos = self.target_pos - self.target_pos % 1
    end
	self.position_marker:SetPosition(self:GetPositionScale() * self:GetSlideRange(), 0)
    local value = self.target_pos + self.min
    self.value_editbox:SetString(tostring(value))
    if self.modified then
        self:OnChanged(value)
    end
end

function Pxl_42_Slider:OnChanged(target_pos)
end

function Pxl_42_Slider:OnControl(control, down)
	if Pxl_42_Slider._base.OnControl(self, control, down) then return true end
end

return Pxl_42_Slider