local PCKeyBindButton = GLOBAL.require("widgets/pckeybindbutton")

AddClassPostConstruct("screens/redux/modconfigurationscreen", function(self)

    self.dirty = false
    self.dirty_sources = {}

    local make_dirty = self.MakeDirty
    self.MakeDirty = function(self, dirty, ...)
        if type(dirty) == "table" then
            self.dirty_sources[dirty.source] = dirty.value
        else
            return make_dirty(self, dirty, ...)
        end
    end

    self.IsDirty = function(self)
        for _, dirty in pairs(self.dirty_sources) do
            if dirty then
                return true
            end
        end
        return self.dirty
    end

    for _, widget in ipairs(self.options_scroll_list.widgets_to_update) do

        local spiner = widget.opt.spinner

        spiner.SetSelected = function(spiner, data) -- Revert to the old one
            for k, v in pairs(spiner.options) do
                if v.data == data then
                    spiner:SetSelectedIndex(k)
                    return
                end
            end
        end

        spiner.OnChanged = function(_, data)
            local opt_data = widget.opt.data
            local is_changed = data ~= opt_data.initial_value
            self.options[widget.real_index].value = data
            opt_data.selected_value = data
            widget.opt.spinner:SetHasModification(is_changed)
            widget:ApplyDescription()
            self:MakeDirty({source = opt_data.option.name, value = is_changed})
        end

        local keybind_btn = PCKeyBindButton()
        keybind_btn:SetOnChangeValFn(function(data)
            local opt_data = widget.opt.data
            local is_changed = data ~= opt_data.initial_value
            self.options[widget.real_index].value = data
            opt_data.selected_value = data
            widget:ApplyDescription()
            self:MakeDirty({source = opt_data.option.name, value = is_changed})
        end)
        widget.opt.keybind_btn = widget.opt:AddChild(keybind_btn)

        widget.opt.focus_forward = function()
            local opt = widget.opt
            return opt.keybind_btn.shown and opt.keybind_btn or opt.spinner
        end

    end

    local ApplyDataToWidget = self.options_scroll_list.update_fn
    self.options_scroll_list.update_fn = function(context, widget, data, idx, ...)

        local rt = ApplyDataToWidget(context, widget, data, idx, ...)

        local keybind_btn = widget.opt.keybind_btn
        if not keybind_btn then
            return rt
        end

        if data == nil or data.is_header then
            keybind_btn:Hide()
            return rt
        end

        local opt_data = data.option
        for _, v in ipairs(self.config) do
            if v.name == opt_data.name then
                if v.oklist then
                    local valid_keylist = {}
                    -- 表示禁用而不是未绑定
                    local can_no_toggle_key = false
                    -- 表示位于功能面板
                    local on_mainboard = false
                    for _, v in ipairs(opt_data.options) do
                        local tp = type(v.data)
                        if tp == "boolean" then
                            can_no_toggle_key = true
                        elseif tp == "number" then
                            table.insert(valid_keylist, v.data)
                        elseif tp == "string" then
                            on_mainboard = true
                        end
                    end

                    keybind_btn:Show()
                    keybind_btn:SetValidKeylist(valid_keylist)
                    keybind_btn.initial_value = data.initial_value
                    keybind_btn.default = v.default
                    keybind_btn.can_no_toggle_key = can_no_toggle_key
                    keybind_btn.on_mainboard = on_mainboard
                    keybind_btn:SetVal(data.selected_value)

                    widget.opt.spinner:Hide()
                else
                    keybind_btn:Hide()
                end
                return rt
            end
        end

    end

    self.options_scroll_list:RefreshView()

end)

-- if unbind_btn_setting then
--     local ImageButton = require("widgets/imagebutton")
--     ENV.AddClassPostConstruct("screens/redux/optionsscreen", function(self)
--         for _, group in ipairs(self.kb_controlwidgets) do
--             local unbind_btn = group:AddChild(ImageButton("images/global_redux.xml", "wardrobe_reset.tex"))
--             unbind_btn:SetPosition(-430, 0)
--             unbind_btn:SetOnClick(function()
--                 TheInputProxy:UnMapControl(0, group.controlId)
--                 self.is_mapping = true
--                 self:OnControlMapped(0, group.controlId, 0xFFFFFFFF, true)
--             end)
--             group.unbind_btn = unbind_btn
--         end
--     end)
-- end

-- UI, nightmare forever
