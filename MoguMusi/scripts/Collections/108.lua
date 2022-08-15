-- local no_debug_console_toggle = GetModConfigData("no_debug_console_toggle")

-- local ENV = env
-- GLOBAL.setfenv(1, GLOBAL)

-- 禁用`关闭控制台
-- ENV.AddGlobalClassPostConstruct("frontend", "FrontEnd", function(self)
--     local on_control = self.OnControl
--     self.OnControl = function(self, control, down, ...)
--         local console_enabled = CONSOLE_ENABLED
--         CONSOLE_ENABLED = not (#self.screenstack > 0 and self.screenstack[#self.screenstack]:IsEditing())
--         local ret = on_control(self, control, down, ...)
--         CONSOLE_ENABLED = console_enabled
--         return ret
--     end
-- end)
-- ENV.AddClassPostConstruct("screens/consolescreen", function(self)

--     local CONSOLE_HISTORY = GetConsoleHistory()

--     local Run = self.Run
--     self.Run = function(self, ...) -- Don't record, if duplicate
--         local ret = Run(self, ...)
--         if #CONSOLE_HISTORY > 2 and CONSOLE_HISTORY[#CONSOLE_HISTORY] == CONSOLE_HISTORY[#CONSOLE_HISTORY - 1] then
--             table.remove(CONSOLE_HISTORY, #CONSOLE_HISTORY)
--         end
--         return ret
--     end

--     self.console_edit.validrawkeys[KEY_V] = true -- Fix ctrl_pasting not working
--     local on_control = self.console_edit.OnControl
--     self.console_edit.OnControl = function(self, control, down, ...) -- Don't pass to consolescreen when we're trying to type "~"
--         local ret = on_control(self, control, down, ...)
--         if not down
--             and control == CONTROL_OPEN_DEBUG_CONSOLE
--             and (no_debug_console_toggle or TheInput:IsKeyDown(KEY_SHIFT)) then

--             return true
--         end
--         return ret
--     end

-- end)

local CHATINPUT_HISTORY = {"来狗了, 快离开基地!", "BOSS要来了, 快走!", "跟着我, 带你去看好康的",
                            "蘑菇慕斯祝你新的一年开开心心,顺顺利利!",
                            "如果发现哪里有BUG,就在评论区说说吧!", "谢谢使用我的MOD!"}
CHATINPUT_HISTORY = table.reverse(CHATINPUT_HISTORY)

-- function GetChatInputHistory()
--     return CHATINPUT_HISTORY
-- end

-- function SetChatInputHistory(history)
--     if type(history) == "table" and type(history[1]) == "string" then
--         CHATINPUT_HISTORY = history
--     end
-- end

AddClassPostConstruct("screens/chatinputscreen", function(self)

    local Run = self.Run
    self.Run = function(self, ...)
        local chat_string = self.chat_edit:GetString()
        chat_string = chat_string ~= nil and chat_string:match("^%s*(.-%S)%s*$")
        if chat_string and (#CHATINPUT_HISTORY == 0 or chat_string ~= CHATINPUT_HISTORY[#CHATINPUT_HISTORY]) then
            table.insert(CHATINPUT_HISTORY, chat_string)
        end
        return Run(self, ...)
    end

    local OnRawKey = self.chat_edit.OnRawKey
    self.chat_edit.OnRawKey = function(s, key, down, ...)

        if OnRawKey(s, key, down, ...) then
            return true
        end

        if not down then return end

        local len = #CHATINPUT_HISTORY
        if len == 0 then return end

        if key == GLOBAL.KEY_UP then
            if self.history_idx ~= nil then
                self.history_idx = math.max( 1, self.history_idx - 1 )
            else
                self.history_idx = len
            end
            self.chat_edit:SetString( CHATINPUT_HISTORY[ self.history_idx ] )
        elseif key == GLOBAL.KEY_DOWN then
            if self.history_idx ~= nil then
                if self.history_idx == len then
                    self.chat_edit:SetString( "" )
                else
                    self.history_idx = math.min( len, self.history_idx + 1 )
                    self.chat_edit:SetString( CHATINPUT_HISTORY[ self.history_idx ] )
                end
            end
        end

        return true

    end

    self.chat_edit.validrawkeys[GLOBAL.KEY_UP] = true
    self.chat_edit.validrawkeys[GLOBAL.KEY_DOWN] = true

end)
