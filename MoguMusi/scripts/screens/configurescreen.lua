local TEMPLATES = require "widgets/redux/templates" 
local Widget = require "widgets/widget"
local Screen = require "widgets/screen" 
local Text = require "widgets/text"
local PopupDialogScreen = require "screens/redux/popupdialog"

local configurescreen = Class(Screen, function(self, mainscreen,index)
    Screen._ctor(self, "configurescreen")
    self.mainscreen = mainscreen
    self.index = index 

    -- 背景
    self.black = self:AddChild(TEMPLATES.BackgroundTint()) 

    -- 屏幕根基
    self.root = self:AddChild(TEMPLATES.ScreenRoot()) 
    self.root:SetHAnchor(0) 
    self.root:SetVAnchor(0) 
    self.root:SetPosition(0,0,0)

    -- 位置参数
    local label_width = 300
    local spinner_width = 225
    local item_width, item_height = label_width + spinner_width + 30, 40

    -- 按键设置
    local buttons = 
    {
        { text = STRINGS.MANAGER.back, cb = function() self:Cancel() end, },
        { text = STRINGS.MANAGER.ok, cb = function() self:Apply() end, },
    }
    
    local function Get_string() 
        if index then 
            return STRINGS.MANAGER.configure_hover
        else
            return STRINGS.MANAGER.new_connection
        end
    end

    -- 主界面
    self.dialog = self.root:AddChild(TEMPLATES.RectangleWindow(item_width, 380, Get_string(), buttons)) 

    -- 选项解释
    self.item_description = self.dialog:AddChild(Text(CHATFONT, 22))
    self.item_description:SetColour(UICOLOURS.GOLD)
    self.item_description:SetPosition(0,120)
    self.item_description:SetRegionSize(item_width+30, 25)

    local function ShowDescription(txt)
        self.item_description:SetString(txt or "")
    end 

    local function TextboxFocusFn(Textbox, txt)
        local old_OnGainFocus = Textbox.OnGainFocus
        Textbox.OnGainFocus = function(self)
            old_OnGainFocus(self)
            ShowDescription(txt)
        end

        local old_OnLoseFocus = Textbox.OnLoseFocus
        Textbox.OnLoseFocus = function(self)
            old_OnLoseFocus(self)
            ShowDescription("") 
        end
    end

    -- 备注填写框
    self.server_note = self.root:AddChild(TEMPLATES.LabelTextbox(STRINGS.MANAGER.server_note, (self.mainscreen.temp and self.mainscreen.temp.note) or "", 120, 315, 40, 5, NEWFONT, 25, -50)) 
    self.server_note.textbox:SetTextLengthLimit( 80 )
    self.server_note:SetPosition(0,70)
    self.server_note.textbox.OnTextInputted = function()
        self.mainscreen.temp.note = self.server_note.textbox:GetString() 
    end
    TextboxFocusFn(self.server_note, STRINGS.MANAGER.addnote)

    -- ip填写框
    self.server_ip = self.root:AddChild(TEMPLATES.LabelTextbox(STRINGS.MANAGER.server_ip, (self.mainscreen.temp and self.mainscreen.temp.ip) or "", 120, 315, 40, 5, NEWFONT, 25, -50)) 
    self.server_ip.textbox:SetTextLengthLimit( 80 )
    self.server_ip:SetPosition(0,10)
    self.server_ip.textbox.OnTextInputted = function() 
        self.mainscreen.temp.ip = self.server_ip.textbox:GetString() 
    end
    self.server_ip.old_ip = self.mainscreen.temp and self.mainscreen.temp.ip -- 临时保存原来的ip
    TextboxFocusFn(self.server_ip, STRINGS.MANAGER.setip)

    -- 端口填写框
    self.server_port = self.root:AddChild(TEMPLATES.LabelTextbox(STRINGS.MANAGER.server_port, ((self.mainscreen.temp and self.mainscreen.temp.port) and tostring(self.mainscreen.temp.port)) or STRINGS.MANAGER.default, 120, 315, 40, 5, NEWFONT, 25, -50)) 
    self.server_port.textbox:SetTextLengthLimit( 80 )
    self.server_port:SetPosition(0,-50)
    self.server_port.textbox.OnTextInputted = function()
        self.mainscreen.temp.port = tonumber(self.server_port.textbox:GetString()) 
    end
    TextboxFocusFn(self.server_port, STRINGS.MANAGER.set_port)

    -- 密码填写框
    self.server_password = self.root:AddChild(TEMPLATES.LabelTextbox(STRINGS.MANAGER.server_password, ((self.mainscreen.temp and self.mainscreen.temp.password) and tostring(self.mainscreen.temp.password)) or "", 120, 315, 40, 5, NEWFONT, 25, -50)) 
    self.server_password.textbox:SetTextLengthLimit( 80 )
    self.server_password:SetPosition(0,-110)
    self.server_password.textbox.OnTextInputted = function()
        self.mainscreen.temp.password = self.server_password.textbox:GetString()
    end
    TextboxFocusFn(self.server_password, STRINGS.MANAGER.set_password)

end)

-- 返回按钮
function configurescreen:Cancel()
    -- 清除临时变量并更新
    self.mainscreen.temp = {} 
    self.index = nil 
    self.mainscreen:UpdateList()
    TheFrontEnd:PopScreen() 
end

-- 确定按钮
function configurescreen:Apply() 
    local warning = false
    if self.mainscreen.temp.name == nil or self.mainscreen.temp.name == "" then 
        self.mainscreen.temp.name = STRINGS.MANAGER.notitle
    end 
    if self.mainscreen.temp.ip == nil or self.mainscreen.temp.ip == "" then 
        self.mainscreen.temp.ip = "0.0.0.0/0"
    end 
    if self.mainscreen.temp.password == nil or self.mainscreen.temp.password == "" then 
        self.mainscreen.temp.password = nil
    end 

    -- 检查设置的ip是否重复
    for k,v in pairs(self.mainscreen.list) do 
        if (self.index == nil and self.mainscreen.temp.ip == v.ip) -- 新建连接时，输入的ip已存在
            or (self.index ~= nil and self.mainscreen.temp.ip ~= self.server_ip.old_ip and self.mainscreen.temp.ip == v.ip) -- 配置连接时，更改后的ip已存在
            then 
            warning = true 
        end
    end 

    -- 当ip重复
    if warning then 
        -- 弹窗提醒
        self.last_focus_widget = TheFrontEnd:GetFocusWidget()
        TheFrontEnd:PushScreen(PopupDialogScreen(
            STRINGS.MANAGER.ip_existing,
            STRINGS.MANAGER.no_reset,
            {
                { text=STRINGS.MANAGER.fine, cb = function() TheFrontEnd:PopScreen() end },
            })
        )

    -- 如果ip没有重复
    elseif not warning then 
        -- 配置一条连接时
        if self.index then 
            -- 获取索引
            local list_index = nil 
            for i = 1,#self.mainscreen.list do 
                if self.mainscreen.list[i].ip == self.server_ip.old_ip then 
                    self.server_ip.old_ip = nil -- 清零
                    list_index = i 
                    break 
                end
            end 
            if list_index then 
                self.mainscreen.list[list_index].note = self.mainscreen.temp.note  
                self.mainscreen.list[list_index].ip = self.mainscreen.temp.ip
                self.mainscreen.list[list_index].port = self.mainscreen.temp.port 
                self.mainscreen.list[list_index].password = self.mainscreen.temp.password 
            end
        -- 新建一条连接时
        else
            table.insert(self.mainscreen.list, self.mainscreen.temp) 
        end

        -- 临时变量清零及更新
        self.index = nil 
        self.mainscreen.temp = {}
        self.mainscreen:UpdateList()
        TheFrontEnd:PopScreen() 
    end
end

return configurescreen 