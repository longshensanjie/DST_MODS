local Widget = require "widgets/widget"
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local PopupDialogScreen = require "screens/redux/popupdialog"

local button_width = 220
local button_height = 40
local button_x = 160

local PCKeyBindButton = Class(Widget, function(self, valid_keys, default, initial_value, can_no_toggle_key)
    Widget._ctor(self, "PCKeyBindButton")

    self:SetValidKeylist(valid_keys or {})

    self.default = default
    self.initial_value = initial_value
    self.can_no_toggle_key = can_no_toggle_key


    self.changed_image = self:AddChild(Image("images/global_redux.xml", "wardrobe_spinner_bg.tex"))
    self.changed_image:SetTint(1,1,1,0.3)
    self.changed_image:ScaleToSize(button_width, button_height)
    self.changed_image:SetPosition(button_x, 0)
    self.changed_image:Hide()

    self.binding_btn = self:AddChild(ImageButton("images/global_redux.xml", "blank.tex", "spinner_focus.tex"))
    self.binding_btn:ForceImageSize(button_width, button_height)
    self.binding_btn:SetTextColour(UICOLOURS.GOLD_CLICKABLE)
    self.binding_btn:SetTextFocusColour(UICOLOURS.GOLD_FOCUS)
    self.binding_btn:SetFont(CHATFONT)
    self.binding_btn:SetTextSize(25)
    self.binding_btn:SetPosition(button_x, 0)
    self.binding_btn:SetOnClick(function() self:MapControl() end)

    self.binding_btn:SetHelpTextMessage(STRINGS.UI.CONTROLSSCREEN.CHANGEBIND)
    self.binding_btn:SetDisabledFont(CHATFONT)

    self:SetVal(self.initial_value)

    self.focus_forward = self.binding_btn
end)

function PCKeyBindButton:TryConvertOption(val)
    -- return type(val) == "string" and rawget(_G, val) or val
    return val
end

function PCKeyBindButton:SetValidKeylist(keys)
    self.valid_keys = {}
    self.key_ref = {} -- Make a ref table for converting control id to string
    for _, v in ipairs(keys) do
        local num = self:TryConvertOption(v)
        table.insert(self.valid_keys, num)
        self.key_ref[num] = v
    end
end

function PCKeyBindButton:GetValDisplayName(val)
    val = self:TryConvertOption(val)
    if val == "no_toggle_key" then
        return STRINGS.UI.CONTROLSSCREEN.INPUTS[9][2]
    elseif type(val) == "string" then
        -- return val:len() > 0 and val or STRINGS.UI.CONTROLSSCREEN.INPUTS[9][2]
        return "功能面板"
    elseif type(val) == "number" then
        return STRINGS.UI.CONTROLSSCREEN.INPUTS[1][val] or STRINGS.UI.CONTROLSSCREEN.INPUTS[9][2]
    elseif val == false then
        return STRINGS.UI.MODSSCREEN.DISABLE
    end
    return ""
end

function PCKeyBindButton:SetBindingText(val, raw)
    self.binding_btn:SetText(raw and val or self:GetValDisplayName(val))
end

function PCKeyBindButton:SetOnSetValFn(fn)
	self.setvalfn = fn
end

function PCKeyBindButton:SetVal(val, raw)
    if val == nil then
        val = "no_toggle_key"
    end
    self.value = val
    self:SetBindingText(val, raw)
    if val == self.initial_value then
        self.changed_image:Hide()
    else
        self.changed_image:Show()
    end
    if self.setvalfn ~= nil then
        self.setvalfn(val)
    end
end

function PCKeyBindButton:SetOnChangeValFn(fn)
	self.changevalfn = fn
end

function PCKeyBindButton:ChangeVal(val)
    if self.changevalfn ~= nil then
        self.changevalfn(val, self.value)
    end
    self:SetVal(val)
end

function PCKeyBindButton:MapControl()
    local default_text = string.format(STRINGS.UI.CONTROLSSCREEN.DEFAULT_CONTROL_TEXT, self:GetValDisplayName(self.default))
    local body_text = STRINGS.UI.CONTROLSSCREEN.CONTROL_SELECT .. "\n\n" .. default_text

    local buttons = {
        {text = STRINGS.UI.CONTROLSSCREEN.CANCEL, cb = function() TheFrontEnd:PopScreen() end},
        {text = STRINGS.UI.MODSSCREEN.DISABLE, cb = function() self:ChangeVal(false) TheFrontEnd:PopScreen() end},
    }
    
    if self.on_mainboard then
        table.insert(buttons, 2, {text = "功能面板", cb = function() self:ChangeVal("biubiu") TheFrontEnd:PopScreen() end})
    end
   
    local popup = PopupDialogScreen(self.desc, body_text, buttons)

    popup.OnRawKey = function(_, key, down)
        if down then return end
        if table.contains(self.valid_keys, key) then
            self:ChangeVal(self.key_ref[key])
            TheFrontEnd:PopScreen()
            TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
            return true
        end
	end	
	TheFrontEnd:PushScreen(popup)
end

return PCKeyBindButton
