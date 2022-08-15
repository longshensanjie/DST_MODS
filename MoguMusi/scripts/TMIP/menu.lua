local ImgBtn = require "widgets/imagebutton"
local b = require "screens/redux/popupdialog"
local c =
    'local player = %s if player == nil then ThePlayer.components.talker:Say("' ..
        STRINGS.TOO_MANY_ITEMS_UI.PLAYER_NOT_ON_SLAVE_TIP .. '") return end '
local function d()
    local e = 1;
    local f = TheInput:IsKeyDown(KEY_CTRL)
    if f then e = 0 end
    local g =
        'local h = player.components.hunger if player and not player:HasTag("playerghost") and h then h:SetPercent(' ..
            e .. ") end"
    SendCommand(string.format(c .. g, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_HUNGER)
end
local function h()
    local e = 1;
    local f = TheInput:IsKeyDown(KEY_CTRL)
    if f then e = 0 end
    local g =
        'local h = player.components.sanity if player and not player:HasTag("playerghost") and h then h:SetPercent(' ..
            e .. ") end"
    SendCommand(string.format(c .. g, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_SANITY)
end
local function i()
    local e = 1;
    local f = TheInput:IsKeyDown(KEY_CTRL)
    if f then e = 0.05 end
    local g =
        'local h = player.components.health if player and not player:HasTag("playerghost") and h then h:SetPercent(' ..
            e .. ") end"
    SendCommand(string.format(c .. g, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_HEALTH)
end
local function j()
    local k = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_HEALTHLOCK .. ":"
    local l = k .. STRINGS.UI.MODSSCREEN.STATUS.WORKING_NORMALLY;
    local m = k .. STRINGS.UI.MODSSCREEN.STATUS.DISABLED_MANUAL;
    local g =
        'local h = player.components.health local t = player.components.talker local hpper = h:GetPercent() local minhp = h.minhealth local hv if player and not player:HasTag("playerghost") and h then if minhp == 0 then hv = 1 t:Say("' ..
            l .. '") elseif minhp == 1 then hv = 0 t:Say("' .. m ..
            '") else hv = 0 t:Say("' .. m ..
            '") end h:SetMinHealth(hv) h:SetPercent(hpper) end'
    SendCommand(string.format(c .. g, GetCharacter()))
end
local function n()
    local e = 0;
    local f = TheInput:IsKeyDown(KEY_CTRL)
    if f then e = 1 end
    local g =
        'local h = player.components.moisture if player and not player:HasTag("playerghost") and h then h:SetPercent(' ..
            e .. ") end"
    SendCommand(string.format(c .. g, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_WET)
end
local function o()
    local e = 25;
    local f = TheInput:IsKeyDown(KEY_CTRL)
    if f and TheWorld and TheWorld.state.temperature then
        e = TheWorld.state.temperature
    end
    local g =
        'local h = player.components.temperature if player and not player:HasTag("playerghost") and h then h:SetTemperature(' ..
            e .. ") end"
    SendCommand(string.format(c .. g, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_TEMPERATURE)
end
local function p()
    local e = 1;
    local f = TheInput:IsKeyDown(KEY_CTRL)
    if f then e = 0 end
    local g =
        'local i = player.components.singinginspiration if player and not player:HasTag("playerghost") and i then i:SetPercent(' ..
            e .. ") end"
    SendCommand(string.format(c .. g, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_SUBMENU_INSPIRATION)
end
local function q()
    local r = STRINGS.TOO_MANY_ITEMS_UI.TMIP_CONSOLE;
    local s = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_GODMODE .. ":"
    local t = s .. STRINGS.UI.MODSSCREEN.STATUS.DISABLED_MANUAL;
    local u = s .. STRINGS.UI.MODSSCREEN.STATUS.WORKING_NORMALLY;
    local g =
        'local p = player local h = p.components.health local t = p.components.talker if p ~= nil then if p:HasTag("playerghost") then p:PushEvent("respawnfromghost") p.rezsource = "' ..
            r ..
            '" else if h ~= nil then local godmode = h.invincible t:Say(godmode and "' ..
            t .. '" or "' .. u .. '") h:SetInvincible(not godmode) end end end'
    SendCommand(string.format(c .. g, GetCharacter()))
end
local function v()
    local w = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_CREATIVEMODE .. ":"
    local x = w .. STRINGS.UI.MODSSCREEN.STATUS.DISABLED_MANUAL;
    local y = w .. STRINGS.UI.MODSSCREEN.STATUS.WORKING_NORMALLY;
    local g =
        'local p = player local b = p.components.builder local t = p.components.talker if p and b and t then t:Say(b.freebuildmode and "' ..
            x .. '" or "' .. y .. '") b:GiveAllRecipes() end'
    SendCommand(string.format(c .. g, GetCharacter()))
end
local function z()
    local A = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_ONEHITKILLMODE .. ":"
    local B = A .. STRINGS.UI.MODSSCREEN.STATUS.DISABLED_MANUAL;
    local C = A .. STRINGS.UI.MODSSCREEN.STATUS.WORKING_NORMALLY;
    local g =
        'local p = player local c = p.components.combat or nil local t = p.components.talker if p and c and t and c.CalcDamage then if c.OldCalcDamage then p.components.talker:Say("' ..
            B ..
            '") c.CalcDamage = c.OldCalcDamage c.OldCalcDamage = nil else p.components.talker:Say("' ..
            C ..
            '") c.OldCalcDamage = c.CalcDamage c.CalcDamage = function(...) return 9999999999*9 end end end'
    SendCommand(string.format(c .. g, GetCharacter()))
end
local function D()
    local e = 1;
    local f = TheInput:IsKeyDown(KEY_CTRL)
    if f then e = 0 end
    local g =
        'local i = player.components.mightiness if player and not player:HasTag("playerghost") and i then i:SetPercent(' ..
            e .. ") end"
    SendCommand(string.format(c .. g, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_SUBMENU_FITNESS)
end
local function H()
    if _G.TOOMANYITEMS.DATA.SHOW_CONFIRM_SCREEN then
        local I;
        I = b(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_EMPINVENTORY,
              STRINGS.TOO_MANY_ITEMS_UI.BUTTON_EMPINVENTORYTIP, {
            {
                text = STRINGS.UI.TRADESCREEN.ACCEPT,
                cb = function()
                    local f = TheInput:IsKeyDown(KEY_CTRL)
                    local J = 0;
                    if f then J = 1 end
                    local g =
                        "local inventory = player and player.components.inventory or nil local backpack = inventory and inventory:GetOverflowContainer() or nil local inventorySlotCount = inventory and inventory:GetNumSlots() or 0 local backpackSlotCount = backpack and backpack:GetNumSlots() or 0 local removeallinstr = " ..
                            J ..
                            " for i = 1, inventorySlotCount do local item = inventory:GetItemInSlot(i) or nil inventory:RemoveItem(item, true) if item ~= nil then item:Remove() end end if removeallinstr == 1 then for i = 1, backpackSlotCount do local item = backpack:GetItemInSlot(i) or nil inventory:RemoveItem(item, true) if item ~= nil then item:Remove() end end end"
                    SendCommand(string.format(c .. g, GetCharacter()))
                    TheFrontEnd:PopScreen(I)
                end
            }, {
                text = STRINGS.UI.TRADESCREEN.CANCEL,
                cb = function() TheFrontEnd:PopScreen(I) end
            }
        })
        TheFrontEnd:PushScreen(I)
    else
        local f = TheInput:IsKeyDown(KEY_CTRL)
        local J = 0;
        if f then J = 1 end
        local g =
            "local inventory = player and player.components.inventory or nil local backpack = inventory and inventory:GetOverflowContainer() or nil local inventorySlotCount = inventory and inventory:GetNumSlots() or 0 local backpackSlotCount = backpack and backpack:GetNumSlots() or 0 local removeallinstr = " ..
                J ..
                " for i = 1, inventorySlotCount do local item = inventory:GetItemInSlot(i) or nil inventory:RemoveItem(item, true) if item ~= nil then item:Remove() end end if removeallinstr == 1 then for i = 1, backpackSlotCount do local item = backpack:GetItemInSlot(i) or nil inventory:RemoveItem(item, true) if item ~= nil then item:Remove() end end end"
        SendCommand(string.format(c .. g, GetCharacter()))
    end
end
local function K()
    if _G.TOOMANYITEMS.DATA.SHOW_CONFIRM_SCREEN then
        local I;
        I = b(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_EMPTYBACKPACK,
              STRINGS.TOO_MANY_ITEMS_UI.BUTTON_EMPTYBACKPACKTIP, {
            {
                text = STRINGS.UI.TRADESCREEN.ACCEPT,
                cb = function()
                    local f = TheInput:IsKeyDown(KEY_CTRL)
                    local J = 0;
                    if f then J = 1 end
                    local g =
                        "local inventory = player and player.components.inventory or nil local backpack = inventory and inventory:GetOverflowContainer() or nil local inventorySlotCount = inventory and inventory:GetNumSlots() or 0 local backpackSlotCount = backpack and backpack:GetNumSlots() or 0 local removeallinstr = " ..
                            J ..
                            " for i = 1, backpackSlotCount do local item = backpack:GetItemInSlot(i) or nil inventory:RemoveItem(item, true) if item ~= nil then item:Remove() end end if removeallinstr == 1 then for i = 1, inventorySlotCount do local item = inventory:GetItemInSlot(i) or nil inventory:RemoveItem(item, true) if item ~= nil then item:Remove() end end end"
                    SendCommand(string.format(c .. g, GetCharacter()))
                    TheFrontEnd:PopScreen(I)
                end
            }, {
                text = STRINGS.UI.TRADESCREEN.CANCEL,
                cb = function() TheFrontEnd:PopScreen(I) end
            }
        })
        TheFrontEnd:PushScreen(I)
    else
        local f = TheInput:IsKeyDown(KEY_CTRL)
        local J = 0;
        if f then J = 1 end
        local g =
            "local inventory = player and player.components.inventory or nil local backpack = inventory and inventory:GetOverflowContainer() or nil local inventorySlotCount = inventory and inventory:GetNumSlots() or 0 local backpackSlotCount = backpack and backpack:GetNumSlots() or 0 local removeallinstr = " ..
                J ..
                " for i = 1, backpackSlotCount do local item = backpack:GetItemInSlot(i) or nil inventory:RemoveItem(item, true) if item ~= nil then item:Remove() end end if removeallinstr == 1 then for i = 1, inventorySlotCount do local item = inventory:GetItemInSlot(i) or nil inventory:RemoveItem(item, true) if item ~= nil then item:Remove() end end end"
        SendCommand(string.format(c .. g, GetCharacter()))
    end
end
local L = Class(function(self, M, N)
    self.owner = M;
    self.shield = self.owner.owner.shield;
    local O = -180;
    local P = -220;
    local function Q() self.owner.owner:Close() end
    local function R() self.owner.owner:ShowDebugMenu() end
    local function S() self.owner.owner:ShowWoodieMenu() end
    local function T() self.owner.owner:ShowAbigailMenu() end
    local function U() self.owner.owner:ShowWormwoodMenu() end
    self.menu = {
        ["inspirationmenu"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_SUBMENU_INSPIRATION,
            fn = p,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_inspiration.tex",
            pos = {N[1], O}
        },
        ["hunger"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_HUNGER,
            fn = d,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_hunger.tex",
            pos = {N[2], O}
        },
        ["sanity"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_SANITY,
            fn = h,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_sanity.tex",
            pos = {N[3], O}
        },
        ["health"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_HEALTH,
            fn = i,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_health.tex",
            pos = {N[4], O}
        },
        ["lockhealth"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_HEALTHLOCK ..
                STRINGS.TOO_MANY_ITEMS_UI.BUTTON_ONOROFF,
            fn = j,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_health_lock.tex",
            pos = {N[5], O}
        },
        ["moisture"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_WET,
            fn = n,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_wet.tex",
            pos = {N[6], O}
        },
        ["temperature"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_TEMPERATURE,
            fn = o,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_temperature.tex",
            pos = {N[7], O}
        },
        ["removebackpack"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_EMPTYBACKPACK,
            fn = K,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_empbackpack.tex",
            pos = {N[8], O}
        },
        ["prevbutton"] = {
            tip = STRINGS.UI.HELP.PREVPAGE,
            fn = function() self.owner.inventory:Scroll(-1) end,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_left.tex",
            pos = {N[9], O}
        },
        ["nextbutton"] = {
            tip = STRINGS.UI.HELP.NEXTPAGE,
            fn = function() self.owner.inventory:Scroll(1) end,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_right.tex",
            pos = {N[10], O}
        },
        ["cancel"] = {
            tip = STRINGS.UI.OPTIONS.CLOSE,
            fn = Q,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_close.tex",
            pos = {N[11], O}
        },
        ["fitness"] = {
            tip =  STRINGS.TOO_MANY_ITEMS_UI.BUTTON_SUBMENU_FITNESS,
            fn = D,
            atlas = "images/qwert.xml",
            image = "qwert.tex",
            pos = {N[1], P}
        },
        ["wormwoodmenu"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_SUBMENU_WORMWOOD,
            fn = U,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_wormwood.tex",
            pos = {N[2], P}
        },
        ["woodiemenu"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_SUBMENU_WOODIEMENU,
            fn = S,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_woodie.tex",
            pos = {N[3], P}
        },
        ["abigailmenu"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_SUBMENU_ABIGAIL,
            fn = T,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_abigail.tex",
            pos = {N[4], P}
        },
        ["creativemode"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_CREATIVEMODE ..
                STRINGS.TOO_MANY_ITEMS_UI.BUTTON_ONOROFF,
            fn = v,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_creativemode.tex",
            pos = {N[5], P}
        },
        ["godmode"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_GODMODE ..
                STRINGS.TOO_MANY_ITEMS_UI.BUTTON_ONOROFF,
            fn = q,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_godmode.tex",
            pos = {N[6], P}
        },
        ["onehitkillmode"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_ONEHITKILLMODE ..
                STRINGS.TOO_MANY_ITEMS_UI.BUTTON_ONOROFF,
            fn = z,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_onehitkillmode.tex",
            pos = {N[7], P}
        },
        ["removeinventory"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_EMPINVENTORY,
            fn = H,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_empinventory.tex",
            pos = {N[8], P}
        },
        ["debug"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_DEBUGMENU ..
                STRINGS.TOO_MANY_ITEMS_UI.BUTTON_ONOROFF,
            fn = R,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_debugmod.tex",
            pos = {N[9], P}
        }
    }
    self:MainButton()
end)
function L:MainButton()
    self.mainbuttons = {}

    
    local function V(W)
        local function X(Y, Z, _, a0, a1, N)
            if type(a1) == "string" then
                self.mainbuttons[Y] = self.shield:AddChild(ImgBtn(a0, a1, a1, a1))
            elseif type(a1) == "table" then
                self.mainbuttons[Y] = self.shield:AddChild(ImgBtn(a0, a1[1], a1[2],
                                                             a1[3]))
            else
                return
            end
            self.mainbuttons[Y]:SetTooltip(Z)
            self.mainbuttons[Y]:SetOnClick(_)
            self.mainbuttons[Y]:SetPosition(N[1], N[2], 0)
            local a2, a3 = self.mainbuttons[Y].image:GetSize()
            local a4 = math.min(35 / a2, 35 / a3)
            self.mainbuttons[Y]:SetNormalScale(a4)
            self.mainbuttons[Y]:SetFocusScale(a4 * 1.1)
        end
        for a5, a6 in pairs(W) do
            X(a5, a6.tip, a6.fn, a6.atlas, a6.image, a6.pos)
        end
    end


    if self.menu then
        V(self.menu)
        self.mainbuttons["removebackpack"]:SetImageNormalColour(1, 0.9, 0.9, 0.9)
        self.mainbuttons["removebackpack"]:SetImageFocusColour(1, 0.1, 0.1, 0.9)
        self.mainbuttons["removebackpack"]:SetImageSelectedColour(1, 0, 0, 0.9)
        self.mainbuttons["removeinventory"]:SetImageNormalColour(1, 0.9, 0.9,
                                                                 0.9)
        self.mainbuttons["removeinventory"]:SetImageFocusColour(1, 0.1, 0.1, 0.9)
        self.mainbuttons["removeinventory"]:SetImageSelectedColour(1, 0, 0, 0.9)
    end
end
return L
