local TEMPLATES = require "widgets/redux/templates"

local hovertext_top = {
    offset_x = 2,
    offset_y = 45,
}

local function IsModOutOfDate( modname, workshop_version )
    return GLOBAL.IsWorkshopMod(modname) and workshop_version ~= "" and workshop_version ~= (GLOBAL.KnownModIndex:GetModInfo(modname) ~= nil and GLOBAL.KnownModIndex:GetModInfo(modname).version or "")
end

local last_index = 1
local function gonext_fn(self)

    local out_dated_mods = {}
    for _, v in ipairs(self.modnames_client) do
        if IsModOutOfDate( v.modname, v.version ) then
            table.insert(out_dated_mods, {name = v.modname, type = "client"})
        end
    end
    for _, v in ipairs(self.modnames_server) do
        if IsModOutOfDate( v.modname, v.version ) then
            table.insert(out_dated_mods, {name = v.modname, type = "server"})
        end
    end
    if #out_dated_mods == 0 then
        return
    end

    if #out_dated_mods < last_index then
        last_index = 1
    end
    local next = out_dated_mods[last_index]

    self.subscreener:OnMenuButtonSelected(next.type)

    local modnames_list = "optionwidgets_"..next.type
    local idx = #modnames_list > 0 and 1 or nil
    for i, v in metaipairs(self[modnames_list]) do
        if next.name == v.mod.modname then
            idx = i
        end
    end
    self:ShowModDetails(idx, self.optionwidgets_client == self[modnames_list])
    if idx then
        self.mods_scroll_list:ScrollToDataIndex(math.max(0, idx - 2))
    end

    last_index = last_index + 1

end

AddClassPostConstruct("widgets/redux/modstab", function(self)

    self.next_needs_update_mod_button = TEMPLATES.IconButton("images/ui.xml", "arrow2_right.tex", "更新下一个模组", false, false, function() gonext_fn(self) end, hovertext_top)
    self.allmodsmenu:AddCustomItem(self.next_needs_update_mod_button)
    if self.servercreationscreen.name == "ServerCreationScreen" then
        self.allmodsmenu:SetPosition(-600, -250)
    end

    local StartModsOrderUpdate = self.StartModsOrderUpdate
    self.StartModsOrderUpdate = function(self, ...)
        local rt = StartModsOrderUpdate(self, ...)
        if self.modsorderupdatetask then
            self.modsorderupdatetask.period = 1
        end
        -- self.modsorderupdatetask:Cancel()
        -- self.modsorderupdatetask = nil
        return rt
    end

    local StartWorkshopUpdate = self.StartWorkshopUpdate
    self.StartWorkshopUpdate = function(self, ...)
        local rt = StartWorkshopUpdate(self, ...)
        if self.workshopupdatetask then
            self.workshopupdatetask:Cancel()
            self.workshopupdatetask = nil
        end
        return rt
    end

    local UpdateModsOrder = self.UpdateModsOrder
    self.UpdateModsOrder = function(self, force_refresh, ...)
        local rt = UpdateModsOrder(self, force_refresh, ...)
        if self.downloading_mods_count > 0 then
            if self.workshopupdatetask == nil then
                self.workshopupdatetask = GLOBAL.scheduler:ExecutePeriodic(3, self.UpdateForWorkshop, nil, 0, "updateforworkshop", self)
            end
        elseif self.workshopupdatetask then
            self.workshopupdatetask:Cancel()
            self.workshopupdatetask = nil
        end
        return rt
    end

    local num_setstring = self.out_of_date_badge.count.SetString
    self.out_of_date_badge.count.SetString = function(s, str, ...)
        if tonumber(str) > 0 then
            self.next_needs_update_mod_button:Unselect()
        else
            self.next_needs_update_mod_button:Select()
        end
        return num_setstring(s, str, ...)
    end

    local OnRawKey = self.OnRawKey
    self.OnRawKey = function(self, key, down, ...)
        if down and key == GLOBAL.KEY_F5 then
            self:UpdateForWorkshop()
        end
        return OnRawKey(self, key, down, ...)
    end

    -- scheduler:ExecutePeriodic(FRAMES, function()
    --     for _, v in ipairs(KnownModIndex:GetClientModNamesTable()) do
    --         if IsWorkshopMod(v.modname) then
    --             TheSim:GetWorkshopVersion(v.modname)
    --         end
    --     end
    -- end, nil, 0, "somerandomtask", self)

    self.modfilterbar.search_box.textbox:SetPassControlToScreen(GLOBAL.CONTROL_SCROLLBACK, true)
    self.modfilterbar.search_box.textbox:SetPassControlToScreen(GLOBAL.CONTROL_SCROLLFWD, true)

end)
