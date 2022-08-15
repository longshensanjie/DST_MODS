require "util"
local Screen = require "widgets/screen"
local Widget = require "widgets/widget"
local Image = require "widgets/image"
local TEMPLATES = require "widgets/redux/templates"
local PopupDialogScreen = require "screens/redux/popupdialog"
local Pxl_42_ControlBar = require "widgets/pxl_42_controlbar"
local options = require "pxl_42_coloradjustment_options"

local SCREEN_OFFSET = 0.15 * RESOLUTION_X

local Pxl_42_Color_Adjustments = Class(Screen, function(self)
	Screen._ctor(self, "Pxl_42_Color_Adjustments")

    self.options = options

    self.right_root = self:AddChild(Widget("right_root"))
    self.right_root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.right_root:SetHAnchor(ANCHOR_RIGHT)
    self.right_root:SetVAnchor(ANCHOR_MIDDLE)
    --self.right_root:SetMaxPropUpscale(MAX_HUD_SCALE)

    local bg = self.right_root:AddChild(Image("images/bg_redux_wardrobe_bg.xml", "wardrobe_bg.tex"))
	bg:SetScale(0.8)
	bg:SetPosition(-70, 0)
	bg:SetTint(1, 1, 1, .76)

    local label_width = 120
    local controlbar_length = 245
    local item_width, item_height = label_width + controlbar_length + 30, 40

    local buttons = {
        {text = STRINGS.PXL_42_RADJUSTMENTS.APPLY, cb = function() self:Apply() end,},
        {text = STRINGS.PXL_42_RADJUSTMENTS.BACK, cb = function() self:Cancel() end,},
    }

    self.dialog = self.right_root:AddChild(TEMPLATES.RectangleWindow(item_width + 40, 580, nil, buttons))

    self.dialog:SetPosition(-280, 30)

    self.option_header = self.dialog:AddChild(Widget("option_header"))
    self.option_header:SetPosition(0, 270)

	self.dirty = false

    local function ScrollWidgetsCtor(context, idx)
        local widget = Widget("option"..idx)
        widget.bg = widget:AddChild(TEMPLATES.ListItemBackground(item_width, item_height))
        widget.opt = widget:AddChild(Pxl_42_ControlBar(label_width, controlbar_length, item_height))

        widget:SetOnGainFocus(function(_)
            self.options_scroll_list:OnWidgetFocus(widget)
        end)

        widget.real_index = idx
        widget.opt.spinner.OnChanged =
            function(_, data)
                local option = self.options[widget.real_index]
                option.temp = data
                PostProcessor:EnablePostProcessEffect(PostProcessorEffects[option.effect], data)
                if data ~= option.value then
                    self:MakeDirty()
                end
            end

        widget.opt.slider.OnChanged =
            function(_, data)
                local option = self.options[widget.real_index]
                option.temp = data
                if option.uniformvariable then
                    if option.uniformvariable.num then
                        if option.uniformvariable.num == 1 then
                            PostProcessor:SetUniformVariable(UniformVariables[option.uniformvariable.name], data)
                        elseif option.uniformvariable.num == 2 then
                            PostProcessor:SetUniformVariable(UniformVariables[option.uniformvariable.name], nil, data)
                        else
                            PostProcessor:SetUniformVariable(UniformVariables[option.uniformvariable.name], nil, nil, data)
                        end
                    end
                end
                self:MakeDirty()
            end

        return widget
	end

    local function ApplyDataToWidget(context, widget, data, idx)
        widget.opt.data = data
		if data then
            widget.real_index = idx
            local label = data.label
            widget.opt:Show()
            if data.is_header then
                widget.bg:Hide()
                widget.opt.control_root:Hide()
                widget.opt.label:Hide()
                widget.opt.header:Show()
                widget.opt.header:SetString(label)
            else
                widget.bg:Show()
                widget.opt.control_root:Show()
                widget.opt.label:Show()
                widget.opt.header:Hide()
                widget.opt.label:SetString(label..":")
                if data.spin_options then
                    widget.opt.spinner:Show()
                    widget.opt.slider:Hide()
                    widget.opt.spinner:SetOptions(data.spin_options)
                    if data.temp == nil then
                        data.temp = data.value
                    end
                    widget.opt.spinner:SetSelected(data.temp)
                else
                    widget.opt.spinner:Hide()
                    widget.opt.slider:Show()
                    widget.opt.slider:SetData(data)
                end
            end
        else
            widget.opt:Hide()
            widget.bg:Hide()
		end
	end

    self.optionspanel = self.dialog:InsertWidget(Widget("optionspanel"))

    self.options_scroll_list = self.optionspanel:AddChild(TEMPLATES.ScrollingGrid(
        self.options,
        {
            scroll_context = {
            },
            widget_width  = item_width,
            widget_height = item_height,
            num_visible_rows = 12,
            num_columns = 1,
            item_ctor_fn = ScrollWidgetsCtor,
            apply_fn = ApplyDataToWidget,
            scrollbar_offset = 20,
            scrollbar_height_offset = -60
        }
    ))

	if TheInput:ControllerAttached() then
        self.dialog.actions:Hide()
	end

	self.default_focus = self.options_scroll_list

    TheCamera:PushScreenHOffset(self, SCREEN_OFFSET)

    TheFrontEnd:LockFocus(false)
end)

function Pxl_42_Color_Adjustments:Apply()
	if self:IsDirty() then
        local settings = nil
        for k, v in pairs(self.options) do
            if v.temp ~= nil then
                v.value = v.temp
                v.temp = nil
            end
            if not settings then settings = {} end
            if v.key then
                settings[v.key] = v.value
            end
        end
        local str = json.encode(settings)
        TheSim:SetPersistentString("pxl_42_coloradjustments", str)
        self:MakeDirty(false)
        TheFrontEnd:PopScreen()
	else
		self:MakeDirty(false)
	    TheFrontEnd:PopScreen()
	end
end

function Pxl_42_Color_Adjustments:ConfirmRevert()
	TheFrontEnd:PushScreen(
		PopupDialogScreen(STRINGS.PXL_42_RADJUSTMENTS.BACKTITLE, STRINGS.PXL_42_RADJUSTMENTS.BACKBODY,
		  {
		  	{
		  		text = STRINGS.PXL_42_RADJUSTMENTS.YES,
		  		cb = function()
                    self:MakeDirty(false)
                    TheFrontEnd:PopScreen()
                    for i,v in pairs(self.options) do
                        if v.temp ~= nil then
                            if v.uniformvariable ~= nil then
                                if v.uniformvariable.num == 1 then
                                    PostProcessor:SetUniformVariable(UniformVariables[v.uniformvariable.name], v.value)
                                elseif v.uniformvariable.num == 2 then
                                    PostProcessor:SetUniformVariable(UniformVariables[v.uniformvariable.name], nil, v.value)
                                else
                                    PostProcessor:SetUniformVariable(UniformVariables[v.uniformvariable.name], nil, nil, v.value)
                                end
                            elseif v.spin_options ~= nil then
                                PostProcessor:EnablePostProcessEffect(PostProcessorEffects[v.effect], v.value)
                            end
                            v.temp = nil
                        end
                    end
                    TheFrontEnd:PopScreen()
                end
			},
			{
				text = STRINGS.PXL_42_RADJUSTMENTS.NO,
				cb = function()
					TheFrontEnd:PopScreen()
				end
			}
		  }
		)
	)
end

function Pxl_42_Color_Adjustments:Cancel()
	if self:IsDirty() then
		self:ConfirmRevert()
	else
		self:MakeDirty(false)
	    TheFrontEnd:PopScreen()
	end
end

function Pxl_42_Color_Adjustments:MakeDirty(dirty)
	if dirty ~= nil then
		self.dirty = dirty
	else
		self.dirty = true
	end
end

function Pxl_42_Color_Adjustments:IsDefaultSettings()
	local alldefault = true
	for i,v in pairs(self.options) do
		if self.options[i].temp ~= nil and self.options[i].temp ~= self.options[i].default then
			alldefault = false
			break
		end
	end
	return alldefault
end

function Pxl_42_Color_Adjustments:IsDirty()
	return self.dirty
end

function Pxl_42_Color_Adjustments:OnControl(control, down)
    if Pxl_42_Color_Adjustments._base.OnControl(self, control, down) then return true end

    if not down then
	    if control == CONTROL_CANCEL then
			self:Cancel()
            return true
	    elseif control == CONTROL_PAUSE and TheInput:ControllerAttached() and not TheFrontEnd.tracking_mouse then
            self:Apply()
            return true
        end
	end
end

return Pxl_42_Color_Adjustments