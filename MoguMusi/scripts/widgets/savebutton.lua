local TEMPLATES = require "widgets/redux/templates" 
local Widget = require "widgets/widget"
local Menu = require "widgets/menu"
local PopupDialogScreen = require "screens/redux/popupdialog"

local savebutton = Class(Widget, function(self, mainscreen)
    Widget._ctor(self, "savebutton") 
    self.root = self:AddChild(Widget("ROOT")) 
    self.mainscreen = mainscreen 

    -- 保存键的callback
    local function on_save_click(widget) 
        --print("savebutton")
        TheFrontEnd:PopScreen() -- 先关掉上层的screen

        if widget.data then 
            -- 检查是否重复
            local warning = false
            for k,v in pairs(widget.mainscreen.list) do 
                if widget.data[1].ip == v.ip then 
                    warning = true 
                    break 
                end
            end

            -- 如果重复
            if warning then 
                -- 弹窗提醒
                widget.last_focus_widget = TheFrontEnd:GetFocusWidget()
                TheFrontEnd:PushScreen(PopupDialogScreen(
                    STRINGS.MANAGER.server_existing,
                    STRINGS.MANAGER.no_reset,
                    {
                        { text=STRINGS.MANAGER.fine, cb = function() TheFrontEnd:PopScreen() end },
                    })
                )
            -- 如果没重复
            else
                local temp = {}
                temp.name = widget.data[1].name  
                temp.ip = widget.data[1].ip 
                temp.port = widget.data[1].port 
                table.insert(widget.mainscreen.list, temp) 
                widget.mainscreen:SaveList() 
                -- 弹窗提醒
                widget.last_focus_widget = TheFrontEnd:GetFocusWidget()
                TheFrontEnd:PushScreen(PopupDialogScreen(
                    nil,
                    STRINGS.MANAGER.save_success,
                    {
                        { text=STRINGS.MANAGER.ok, cb = function() TheFrontEnd:PopScreen() end },
                    })
                )
            end
        -- 当服务器信息不正确时
        else
            -- 弹窗提醒
            widget.last_focus_widget = TheFrontEnd:GetFocusWidget()
            TheFrontEnd:PushScreen(PopupDialogScreen(
                STRINGS.MANAGER.fail_get,
                nil,
                {
                    { text=STRINGS.MANAGER.fine, cb = function() TheFrontEnd:PopScreen() end },
                })
            )
        end 

    end

    self.savebutton = self.root:AddChild(TEMPLATES.IconButton("images/button_icons.xml", "save.tex", STRINGS.MANAGER.save_to, false, false,
        ------------------ callback --------------------------------
        function() 
            on_save_click(self) 
        end,
        ----------------------------------------------------------------------------
        {
            offset_x = 0,
            offset_y = 40,
        })
    )
    self.savebutton:SetPosition(-250, 198)
    self.savebutton:SetScale(.8)
    self.savebutton:SetHelpTextMessage(STRINGS.MANAGER.save_to) 

end) 

function savebutton:SetData(data)
    self.data = data 
end

return savebutton