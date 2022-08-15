local TEMPLATES = require "widgets/redux/templates" 
local Widget = require "widgets/widget"
local Screen = require "widgets/screen" 
local Text = require "widgets/text"
local PopupDialogScreen = require "screens/redux/popupdialog"
local configurescreen = require "screens/configurescreen"

-- 位置参数（官方文件搬过来的）
local font_face = CHATFONT
local font_size = 28
local title_font_size = font_size*.8
local title_font_face = HEADERFONT

local units_per_row = 2
local header_height = 330
local num_rows = math.ceil(19 / units_per_row)
local text_content_y = -12 * (units_per_row - 1)
local text_align = ANCHOR_LEFT
if units_per_row == 1 then
    text_align = ANCHOR_MIDDLE
end
local dialog_size_x = 830
local dialog_width = dialog_size_x + (60*2) 
local row_height = 30 * units_per_row
local row_width = dialog_width*0.9
local dialog_size_y = row_height*(num_rows + 0.25)
------------------------------------------------------------------------------

local MainUi = Class(Screen, function(self)
    Screen._ctor(self, "MainUi") 

    -- 背景
    self.black = self:AddChild(TEMPLATES.BackgroundTint()) 

    -- 屏幕根基
    self.root = self:AddChild(TEMPLATES.ScreenRoot())

    -- 位置参数
    local label_width = 300
    local spinner_width = 225
    local item_width, item_height = label_width + spinner_width + 30, 40

    -- 按键设置
    local buttons = 
    {
        { text = STRINGS.MANAGER.back, cb = function() self:Cancel() end, },
    }
    
    -- 主界面
    self.dialog = self.root:AddChild(TEMPLATES.RectangleWindow(item_width + 200, 580, STRINGS.MANAGER.panel, buttons)) 

    -- 分割线
	self.horizontal_line = self.dialog:AddChild(Image("images/global_redux.xml", "item_divider.tex"))
    self.horizontal_line:SetPosition(0,150)
    self.horizontal_line:SetSize(item_width + 150, 5)  

    -- 加入直连面板
    local grid = nil 
    grid = self.dialog:InsertWidget( self:BuildConnectionsPanel() )
    grid:SetPosition(-10,-70)
    self.grid = grid

    self.focus_forward = grid
    self.default_focus = grid

    self.parent_default_focus = self 
    
    -- 新建连接的按钮
    self.add_btn = self.dialog:AddChild(TEMPLATES.StandardButton(
            function() TheFrontEnd:PushScreen(configurescreen(self)) self.temp = {} end,
            STRINGS.MANAGER.addnew,
            {90, 45}
        )
    )
    self.add_btn:SetPosition(-270, 170)
end) 

-- 返回按钮
function MainUi:Cancel()
    TheFrontEnd:PopScreen() 
end

-- 设置连接列表 
function MainUi:SetData(list, data)
    self.list = list or self.list
    self.data = data or self.data
end 

-- 更新连接列表
function MainUi:UpdateList(data)
    self.grid:SetItemsData(data or self.list) 
    self:SaveList(data)
end

-- 保存连接列表
function MainUi:SaveList(data)
    self.data.DATA = data or self.list
    self.data.SaveData() 
end

-- 构造直连面板信息
function MainUi:BuildConnectionsPanel() 

    -- 滚动表几何参数
    local row_w = 720
    local row_h = 60
    local icon_size = 0
    local reward_width = 80
    local icon_spacing = 0
    local row_spacing = 5
    local slide_factor = 245 

    -- 表格背景
    local function CreateListItemBackground()
        return TEMPLATES.ListItemBackground(row_width-180,row_height)
    end 

    -- 滚动表构造函数
    local function ScrollWidgetsCtor(context, index)
        --local w = Widget("connections-cell-".. index)
        local w = Widget("connections-cell")
         
        -- 设置关注效果
        w.hideable_root = w:AddChild(Widget("control-connection"))
        w.hideable_root:SetPosition(-row_width/2 + slide_factor,0)
        w.bg = w.hideable_root:AddChild(CreateListItemBackground())
        w.bg:SetOnGainFocus(
            function() 
                self.grid:OnWidgetFocus(w) 
            end
        )
        w.bg:SetPosition(row_width/2 - slide_factor,0)
        w.focus_forward = w.bg

        w.widgets = w.hideable_root:AddChild(Widget("connection-data_root"))
	    w.widgets:SetPosition(-row_width/2, 0)

        -- 服务器的名称
        w.widgets.name = w.hideable_root:AddChild(Text(HEADERFONT, 26, "")) 
        w.widgets.name:SetColour(UICOLOURS.GOLD)
        w.widgets.name:SetHAlign(ANCHOR_LEFT)
        w.widgets.name._position = {x = -140, y = 14, w = 600}

        -- 服务器的ip
        w.widgets.ip = w.hideable_root:AddChild(Text(CHATFONT, 22, ""))
        w.widgets.ip:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
        w.widgets.ip:SetHAlign(ANCHOR_LEFT)
        w.widgets.ip._position = {x = -140, y = -14, w = 570} 

        -- 服务器的备注
        w.widgets.note = w.hideable_root:AddChild(Text(CHATFONT, 22, ""))
        w.widgets.note:SetColour(UICOLOURS.GOLD_UNIMPORTANT)
        w.widgets.note:SetHAlign(ANCHOR_LEFT)
        w.widgets.note._position = {x = 80, y = -14, w = 570} 

        local button_x = row_width+65
        local list = context.screen.list 

        -- 删除键的callback
        local function on_click_delete(context,widget) 

            -- 确定键的callback
            local function delete_fn(context,widget)
                -- 获取索引
                local list_index = nil 
                for i = 1,#context.screen.list do 
                    if context.screen.list[i].ip == widget.ip then 
                        list_index = i 
                        break 
                    end
                end
                if list_index then 
                    table.remove(context.screen.list, list_index) 
                end
                context.screen:UpdateList()
                TheFrontEnd:PopScreen()
            end

            -- 弹窗询问
            context.screen.last_focus_widget = TheFrontEnd:GetFocusWidget()
            TheFrontEnd:PushScreen(PopupDialogScreen(
            STRINGS.MANAGER.delete_ask,
            nil,
            {
                { text=STRINGS.MANAGER.delete, cb = function() delete_fn(context,widget) end },
                { text=STRINGS.MANAGER.delete_no, cb = function() TheFrontEnd:PopScreen() end },
            }
            ))
        end

        ------------
        -- 删除键 --
        ------------
        w.widgets.delete_btn = w.widgets:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "delete.tex", STRINGS.MANAGER.delete_hover, false, false,
        ------------------ callback --------------------------------
        function() 
            on_click_delete(context,w) 
        end,
        ----------------------------------------------------------------------------
        {
            offset_x = 0,
            offset_y = 20,
		}))
        w.widgets.delete_btn:SetPosition(button_x, -14)
        w.widgets.delete_btn:SetScale(.5)
        w.widgets.delete_btn:SetHelpTextMessage(STRINGS.MANAGER.delete_hover) 

        -- 设置键的CallBack
        local function on_click_configure(context,widget,index) 
            -- 获取索引
            local list_index = nil 
            for i = 1,#context.screen.list do 
                if context.screen.list[i].ip == widget.ip then 
                    list_index = i 
                    break 
                end
            end 
            if list_index then 
                -- 传递临时数据
                context.screen.temp = {} 
                context.screen.temp.note = context.screen.list[list_index].note 
                context.screen.temp.ip = context.screen.list[list_index].ip
                context.screen.temp.port = context.screen.list[list_index].port
                context.screen.temp.password = context.screen.list[list_index].password
            end
            TheFrontEnd:PushScreen(configurescreen(context.screen, index)) 
        end

        ------------
        -- 设置键 --
        ------------
        w.widgets.configure_btn = w.widgets:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "configure_mod.tex", STRINGS.MANAGER.configure_hover, false, false,
        ----------------------------  callback ------------------------------------------------
        function()
            on_click_configure(context,w,index) 
        end,
        ------------------------------------------------------------------------------------
        {
            offset_x = 0,
            offset_y = 20,
		}))
        w.widgets.configure_btn:SetPosition(button_x-30, -14)
        w.widgets.configure_btn:SetScale(.5)
        w.widgets.configure_btn:SetHelpTextMessage(STRINGS.MANAGER.configure_hover) 
        
        -- 连接键的CallBack
        local function on_click_goto(context,widget) 
            if widget.ip then 
                --print("[c_connect] " .. widget.ip .. " " .. widget.password)
                c_connect(widget.ip, widget.port, widget.password)
                --[[if widget.port == nil or STRINGS.MANAGER.default then 
                    c_connect(widget.ip) 
                else
                    c_connect(widget.ip, widget.port)
                end]]
            else
                -- 弹窗提醒
                context.screen.last_focus_widget = TheFrontEnd:GetFocusWidget()
                TheFrontEnd:PushScreen(PopupDialogScreen(
                STRINGS.MANAGER.ip_emtpy,
                nil,
                {
                    { text=STRINGS.MANAGER.fine, cb = function() TheFrontEnd:PopScreen() end },
                }
                ))
            end
        end 

        ------------
        -- 连接键 --
        ------------
        w.widgets.goto_btn = w.widgets:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "goto_url.tex", STRINGS.MANAGER.connect_to, false, false,
        ------------------------------ callback ----------------------------------------------
        function()
            on_click_goto(context,w)
        end,
        ---------------------------------------------------------------------------------------
        {
            offset_x = 0,
            offset_y = 20,
		}))
        w.widgets.goto_btn:SetPosition(button_x-60, -14)
        w.widgets.goto_btn:SetScale(.5)
        w.widgets.goto_btn:SetHelpTextMessage(STRINGS.MANAGER.connect_to)

        return w 
    end 

    -- 字数截断
    local function SetTruncatedLeftJustifiedString(txt, str)
        txt:SetTruncatedString(str or "", txt._position.w, nil, true) -- 当与SetRegionSize一起使用时，会导致无限循环
        local width, height = txt:GetRegionSize()
        txt:SetPosition(txt._position.x + width/2, txt._position.y)
    end

    -- 滚动表更新函数
    local function ScrollWidgetApply(context, w, data, index) 
        if w == nil then
            return
        elseif data == nil then
            w.hideable_root:Hide()
            return
        else
            w.hideable_root:Show() 
            -- 保存数据到widget本身
            w.name = data.name
            w.note = data.note
            w.ip = data.ip
            w.port = data.port
            w.password = data.password
 
            SetTruncatedLeftJustifiedString(w.widgets.name, STRINGS.MANAGER.server_name..data.name)
            SetTruncatedLeftJustifiedString(w.widgets.ip, STRINGS.MANAGER.server_ip..data.ip)
            SetTruncatedLeftJustifiedString(w.widgets.note, STRINGS.MANAGER.server_note..(data.note or "")) 
        end 
    end 

    -- 创建滚动表
    local grid = TEMPLATES.ScrollingGrid(
        self.list,
        {
            scroll_context = {
                screen = self,
            },
            widget_width  = row_width-180,
            widget_height = row_height,
            num_visible_rows = 7,
            num_columns = 1,
            item_ctor_fn = ScrollWidgetsCtor,
            apply_fn = ScrollWidgetApply,
            scrollbar_offset = 20,
            scrollbar_height_offset = -60
        }
    )

    return grid 
end

return MainUi 