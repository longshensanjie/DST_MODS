local a = require "widgets/image"
local b = require "widgets/text"
local c = require "widgets/textbutton"
local d = require "widgets/widget"
local imgbtn = _G.require "widgets/imagebutton"
local f = require "widgets/TMIP_menubar"
local g = require "screens/redux/popupdialog"
local h = require "screens/TMIP_writeablewidget"
require "utils"
-- 伍迪、温蒂、植物人
local function i(j, k, id, tooltip, onclick, o, p, pos)
    k[id] = j:AddChild(imgbtn(o, p, p, p))
    k[id]:SetTooltip(tooltip)
    k[id]:SetOnClick(onclick)
    k[id]:SetPosition(pos[1], pos[2], 0)
    local sizeX, sizeY = k[id].image:GetSize()
    local t = math.min(35 / sizeX, 35 / sizeY)
    k[id]:SetNormalScale(t)
    k[id]:SetFocusScale(t * 1.1)
end
local function u(v)
    local w = v:GetText()
    local x = UserToClientID(w)
    local y;
    local z = TheNet:GetClientTable() or {}
    local A = tonumber(w)
    if A ~= nil and 0 < A and A <= #z then
        local B = z[A].name;
        if TheNet:GetServerIsClientHosted() then
            x = z[A].userid;
            y = z[A].prefab
        else
            x = z[A + 1].userid;
            y = z[A + 1].prefab
        end
    end
    if x then
        TOOMANYITEMS.CHARACTER_USERID = x
    else
        ThePlayer.components.talker:Say("Ivalid input!")
        TOOMANYITEMS.CHARACTER_USERID = ThePlayer.userid
    end
    if y then
        TOOMANYITEMS.CHARACTER_PREFAB = y
    else
        TOOMANYITEMS.CHARACTER_PREFAB = ThePlayer.prefab
    end
end
local function C(v)
    local w = tonumber(v:GetText())
    if w and w >= 3 and w <= 999 then
        _G.TOOMANYITEMS.DATA.deleteradius = w
    else
        ThePlayer.components.talker:Say("Invalid input!")
    end
end
local D = {
    animbank = "ui_board_5x3",
    animbuild = "ui_board_5x3",
    menuoffset = Vector3(6, -70, 0),
    cancelbtn = {
        text = STRINGS.UI.TRADESCREEN.CANCEL,
        cb = nil,
        control = CONTROL_CANCEL
    },
    acceptbtn = {
        text = STRINGS.UI.TRADESCREEN.ACCEPT,
        cb = u,
        control = CONTROL_ACCEPT
    }
}
local E = {
    animbank = "ui_board_5x3",
    animbuild = "ui_board_5x3",
    menuoffset = Vector3(6, -70, 0),
    cancelbtn = {
        text = STRINGS.UI.TRADESCREEN.CANCEL,
        cb = nil,
        control = CONTROL_CANCEL
    },
    acceptbtn = {
        text = STRINGS.UI.TRADESCREEN.ACCEPT,
        cb = C,
        control = CONTROL_ACCEPT
    }
}
local function F() return UserToName(TOOMANYITEMS.CHARACTER_USERID) end
local function G()
    local H;
    if TOOMANYITEMS.CHARACTER_PREFAB ~= "" and TOOMANYITEMS.CHARACTER_PREFAB ~=
        nil then
        H = STRINGS.NAMES[string.upper(TOOMANYITEMS.CHARACTER_PREFAB)]
    end
    if H then
        return H
    else
        return "nil"
    end
end
-- 伍迪三形态
local function I()
    local J = 1;
    local K = TheInput:IsKeyDown(KEY_CTRL)
    if K then J = 0 end
    local L =
        'local p = player.components.wereness if player and not player:HasTag("playerghost") and p then p:SetWereMode("beaver") p:SetPercent(' ..
            J .. ') end'
    SendCommand(string.format(IsPlayerExist .. L, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_BEAVER_WEREMETER)
end
local function M()
    local J = 1;
    local K = TheInput:IsKeyDown(KEY_CTRL)
    if K then J = 0 end
    local L =
        'local p = player.components.wereness if player and not player:HasTag("playerghost") and p then p:SetWereMode("goose") p:SetPercent(' ..
            J .. ') end'
    SendCommand(string.format(IsPlayerExist .. L, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_GOOSE_WEREMETER)
end
local function N()
    local J = 1;
    local K = TheInput:IsKeyDown(KEY_CTRL)
    if K then J = 0 end
    local L =
        'local p = player.components.wereness if player and not player:HasTag("playerghost") and p then p:SetWereMode("moose") p:SetPercent(' ..
            J .. ') end'
    SendCommand(string.format(IsPlayerExist .. L, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_MOOSE_WEREMETER)
end
-- 阿比盖尔升级
local function O()
    local L =
        'local v = player.components.ghostlybond if player and not player:HasTag("playerghost") and v then v:SetBondLevel(1) end'
    SendCommand(string.format(IsPlayerExist .. L, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_ABIGAIL_LV1)
end
local function P()
    local L =
        'local v = player.components.ghostlybond if player and not player:HasTag("playerghost") and v then v:SetBondLevel(2) end'
    SendCommand(string.format(IsPlayerExist .. L, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_ABIGAIL_LV2)
end
local function Q()
    local L =
        'local v = player.components.ghostlybond if player and not player:HasTag("playerghost") and v then v:SetBondLevel(3) end'
    SendCommand(string.format(IsPlayerExist .. L, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_ABIGAIL_LV3)
end
-- 植物人开花
local function R()
    local S = 1;
    local K = TheInput:IsKeyDown(KEY_CTRL)
    if K then S = 0 end
    local L =
        'local p = player.components.bloomness if player and not player:HasTag("playerghost") and p then p:SetLevel(' ..
            S .. ') end'
    SendCommand(string.format(IsPlayerExist .. L, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_WORMWOOD_LV1)
end
local function T()
    local S = 2;
    local K = TheInput:IsKeyDown(KEY_CTRL)
    if K then S = 0 end
    local L =
        'local p = player.components.bloomness if player and not player:HasTag("playerghost") and p then p:SetLevel(' ..
            S .. ') end'
    SendCommand(string.format(IsPlayerExist .. L, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_WORMWOOD_LV2)
end
local function U()
    local S = 3;
    local K = TheInput:IsKeyDown(KEY_CTRL)
    if K then S = 0 end
    local L =
        'local p = player.components.bloomness if player and not player:HasTag("playerghost") and p then p:SetLevel(' ..
            S .. ') end'
    SendCommand(string.format(IsPlayerExist .. L, GetCharacter()))
    OperateAnnnounce(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_WORMWOOD_LV3)
end
local V = Class(d, function(self)
    d._ctor(self, "TooManyItems")
    TOOMANYITEMS.CHARACTER_USERID = ThePlayer.userid;
    TOOMANYITEMS.CHARACTER_PREFAB = ThePlayer.prefab;
    self.root = self:AddChild(d("ROOT"))
    self.root:SetVAnchor(ANCHOR_MIDDLE)
    self.root:SetHAnchor(ANCHOR_MIDDLE)
    self.root:SetScaleMode(SCALEMODE_PROPORTIONAL)
    self.root:SetPosition(0, 0, 0)
    self.shieldpos_x = -340;
    self.shieldpos_y = 0;
    self.shieldsize_x = 420;
    self.shieldsize_y = 480;
    self.shield = self.root:AddChild(a("images/ui.xml", "black.tex"))
    self.shield:SetScale(1, 1, 1)
    self.shield:SetPosition(self.shieldpos_x, self.shieldpos_y, 0)
    self.shield:SetSize(self.shieldsize_x, self.shieldsize_y)
    self.shield:SetTint(1, 1, 1, 0.6)
    local W = TheWorld.meta.session_identifier or "world"
    local X = TOOMANYITEMS.TELEPORT_DATA_FILE ..
                  "toomanyitemsplus_teleport_save_" .. W;
    if TOOMANYITEMS.G_TMIP_DATA_SAVE == 1 then
        if TOOMANYITEMS.LoadData(X) then
            TOOMANYITEMS.TELEPORT_DATA = TOOMANYITEMS.LoadData(X)
        end
    elseif TOOMANYITEMS.G_TMIP_DATA_SAVE == -1 then
        _G.TheSim:GetPersistentString(X, function(Y, Z)
            if Y then _G.ErasePersistentString(X, nil) end
        end)
    end
    self:DebugMenu()
    self:SettingMenu()
    self:TipsMenu()
    self:WoodieMenu()
    self.woodieshield.flag = false;
    self.woodieshield:Hide()
    self:AbigailMenu()
    self.abigailshield.flag = false;
    self.abigailshield:Hide()
    self:WormwoodMenu()
    self.wormwoodshield.flag = false;
    self.wormwoodshield:Hide()
    if TOOMANYITEMS.DATA.IsDebugMenuShow then
        self.debugshield:Show()
    else
        self.debugshield:Hide()
    end
    if TOOMANYITEMS.DATA.IsTipsMenuShow then
        self.tipsshield:Show()
    else
        self.tipsshield:Hide()
    end
    if TOOMANYITEMS.DATA.IsSettingMenuShow then
        self.settingshield:Show()
    else
        self.settingshield:Hide()
    end
    self.menu = self.shield:AddChild(f(self))
end)
function V:Close()
    self:Hide()
    self.IsTooManyItemsMenuShow = false
end
function V:ShowWoodieMenu()
    self.abigailshield:Hide()
    self.wormwoodshield:Hide()
    self.abigailshield.flag = false;
    self.wormwoodshield.flag = false;
    if self.woodieshield.flag then
        self.woodieshield:Hide()
        self.woodieshield.flag = false
    else
        self.woodieshield:Show()
        self.woodieshield.flag = true
    end
end
function V:ShowAbigailMenu()
    self.woodieshield:Hide()
    self.wormwoodshield:Hide()
    self.woodieshield.flag = false;
    self.wormwoodshield.flag = false;
    if self.abigailshield.flag then
        self.abigailshield:Hide()
        self.abigailshield.flag = false
    else
        self.abigailshield:Show()
        self.abigailshield.flag = true
    end
end
function V:ShowWormwoodMenu()
    self.abigailshield:Hide()
    self.woodieshield:Hide()
    self.abigailshield.flag = false;
    self.woodieshield.flag = false;
    if self.wormwoodshield.flag then
        self.wormwoodshield:Hide()
        self.wormwoodshield.flag = false
    else
        self.wormwoodshield:Show()
        self.wormwoodshield.flag = true
    end
end
function V:ShowDebugMenu()
    if TOOMANYITEMS.DATA.IsDebugMenuShow then
        self.debugshield:Hide()
        TOOMANYITEMS.DATA.IsDebugMenuShow = false
    else
        self.debugshield:Show()
        TOOMANYITEMS.DATA.IsDebugMenuShow = true
    end
    if TOOMANYITEMS.G_TMIP_DATA_SAVE == 1 then TOOMANYITEMS.SaveNormalData() end
end
function V:ShowTipsMenu()
    if TOOMANYITEMS.DATA.IsTipsMenuShow then
        self.tipsshield:Hide()
        TOOMANYITEMS.DATA.IsTipsMenuShow = false
    else
        self.tipsshield:Show()
        TOOMANYITEMS.DATA.IsTipsMenuShow = true
    end
    if TOOMANYITEMS.G_TMIP_DATA_SAVE == 1 then TOOMANYITEMS.SaveNormalData() end
end
function V:ShowSettingMenu()
    if TOOMANYITEMS.DATA.IsSettingMenuShow then
        self.settingshield:Hide()
        TOOMANYITEMS.DATA.IsSettingMenuShow = false
    else
        self.settingshield:Show()
        TOOMANYITEMS.DATA.IsSettingMenuShow = true
    end
    if TOOMANYITEMS.G_TMIP_DATA_SAVE == 1 then TOOMANYITEMS.SaveNormalData() end
end
function V:FlushPlayer(_)
    if _ == "next" then
        local a0 = 1;
        local z = TheNet:GetClientTable() or {}
        for a1, a2 in pairs(z) do
            if a2.userid == TOOMANYITEMS.CHARACTER_USERID then
                local B = z[a1].name;
                if a1 == 1 and not TheNet:GetServerIsClientHosted() then
                    a0 = a1 + 1
                else
                    a0 = a1
                end
                break
            end
        end
        if a0 + 1 <= #z then
            a0 = a0 + 1
        else
            local B = z[1].name;
            if not TheNet:GetServerIsClientHosted() then
                a0 = 2
            else
                a0 = 1
            end
        end
        local a3 = z[a0].name;
        local a4 = z[a0].prefab;
        local x = UserToClientID(a3)
        if x then
            TOOMANYITEMS.CHARACTER_USERID = x
        else
            TOOMANYITEMS.CHARACTER_USERID = ThePlayer.userid
        end
        if a4 then
            TOOMANYITEMS.CHARACTER_PREFAB = a4
        else
            TOOMANYITEMS.CHARACTER_PREFAB = ThePlayer.prefab
        end
    else
        if self.writeablescreen then
            self.writeablescreen:KillAllChildren()
            self.writeablescreen:Kill()
            self.writeablescreen = nil
        end
        self.writeablescreen = h(D)
        ThePlayer.HUD:OpenScreenUnderPause(self.writeablescreen)
        if TheFrontEnd:GetActiveScreen() == self.writeablescreen then
            self.writeablescreen.edit_text:SetEditing(true)
        end
    end
    self:SetPointer()
end
function V:SetPointer()
    local a5 = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_POINTER;
    local a6 = ""
    if TOOMANYITEMS.CHARACTER_USERID == ThePlayer.userid then
        a6 = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_POINTER_SELF
    end
    self.pointer:SetText(string.format(a6 .. a5, F() or "", G() or "",
                                       TOOMANYITEMS.CHARACTER_USERID))
    self.pointersizex, self.pointersizey = self.pointer.text:GetRegionSize()
    self.pointer.image:SetSize(self.pointersizex * .85, self.pointersizey)
    self.pointer:SetPosition(self.left + self.pointersizex * .5,
                             self.shieldsize_y * .5 - self.pointersizey * .5, 0)
end
function V:FlushDeleteRadius()
    if self.writeablescreen1 then
        self.writeablescreen1:KillAllChildren()
        self.writeablescreen1:Kill()
        self.writeablescreen1 = nil
    end
    self.writeablescreen1 = h(E)
    ThePlayer.HUD:OpenScreenUnderPause(self.writeablescreen1)
    if TheFrontEnd:GetActiveScreen() == self.writeablescreen1 then
        self.writeablescreen1.edit_text:SetEditing(true)
    end
    self:SetDeleteRadiusPointer()
end
function V:SetDeleteRadiusPointer()
    self.deleteradiuspointer:SetText(_G.TOOMANYITEMS.DATA.deleteradius)
    self.deleteradiuspointersizex, self.deleteradiuspointersizey =
        self.deleteradiuspointer.text:GetRegionSize()
    self.deleteradiuspointer.image:SetSize(self.deleteradiuspointersizex * .85,
                                           self.deleteradiuspointersizey)
    self.deleteradiuspointer:SetPosition(
        self.settingleft + self.deleteradiusx + 20 + self.settinglinespace * 3 +
            self.decreasebutton5x + self.deleteradiuspointersizex * 0.5,
        self.shieldsize_y * .5 - self.screennamey - self.settinglinespace * 22.5,
        0)
end
function V:FlushConfirmScreen(n)
    if _G.TOOMANYITEMS.DATA.SHOW_CONFIRM_SCREEN then
        local a7;
        a7 = g(n[3], n[4], {
            {
                text = STRINGS.UI.TRADESCREEN.ACCEPT,
                cb = function()
                    SendCommand(string.format(n[2], GetCharacter()))
                    TheFrontEnd:PopScreen(a7)
                end
            }, {
                text = STRINGS.UI.TRADESCREEN.CANCEL,
                cb = function() TheFrontEnd:PopScreen(a7) end
            }
        })
        TheFrontEnd:PushScreen(a7)
    else
        SendCommand(string.format(n[2], GetCharacter()))
    end
end
function V:ChangeDeleteRadius(_)
    local a8 = 0;
    if _ == "add" then
        a8 = _G.TOOMANYITEMS.DATA.deleteradius + 5
    else
        a8 = _G.TOOMANYITEMS.DATA.deleteradius - 5
    end
    if a8 <= 3 then
        a8 = 3;
        self.decreasebutton5:SetClickable(false)
        self.decreasebutton5:SetColour(0.5, 0.5, 0.5, 0.5)
    else
        self.decreasebutton5:SetClickable(true)
        self.decreasebutton5:SetColour(0.9, 0.8, 0.6, 1)
    end
    if a8 > 999 then
        a8 = 999;
        self.addbutton5:SetClickable(false)
        self.addbutton5:SetColour(0.5, 0.5, 0.5, 0.5)
    else
        self.addbutton5:SetClickable(true)
        self.addbutton5:SetColour(0.9, 0.8, 0.6, 1)
    end
    _G.TOOMANYITEMS.DATA.deleteradius = a8;
    if _G.TOOMANYITEMS.DATA_SAVE == 1 then _G.TOOMANYITEMS.SaveNormalData() end
    self.deleteradiuspointer:SetText(_G.TOOMANYITEMS.DATA.deleteradius)
end
function V:ChangeFoodFreshness(_)
    local a8 = 0;
    if _ == "add" then
        a8 = _G.TOOMANYITEMS.DATA.xxd + 0.1
    else
        a8 = _G.TOOMANYITEMS.DATA.xxd - 0.1
    end
    if a8 <= 0.09 then
        a8 = 0.03;
        self.decreasebutton1:SetClickable(false)
        self.decreasebutton1:SetColour(0.5, 0.5, 0.5, 0.5)
    else
        self.decreasebutton1:SetClickable(true)
        self.decreasebutton1:SetColour(0.9, 0.8, 0.6, 1)
    end
    if a8 > 1 then
        a8 = 1;
        self.addbutton1:SetClickable(false)
        self.addbutton1:SetColour(0.5, 0.5, 0.5, 0.5)
    else
        self.addbutton1:SetClickable(true)
        self.addbutton1:SetColour(0.9, 0.8, 0.6, 1)
    end
    _G.TOOMANYITEMS.DATA.xxd = a8;
    if _G.TOOMANYITEMS.DATA_SAVE == 1 then _G.TOOMANYITEMS.SaveNormalData() end
    self.foodfreshnessvalue:SetString(_G.TOOMANYITEMS.DATA.xxd * 100 .. "%")
end
function V:ChangeToolFiniteuses(_)
    local a8 = 0;
    if _ == "add" then
        a8 = _G.TOOMANYITEMS.DATA.syd + 0.1
    else
        a8 = _G.TOOMANYITEMS.DATA.syd - 0.1
    end
    if a8 <= 0.09 then
        a8 = 0.03;
        self.decreasebutton2:SetClickable(false)
        self.decreasebutton2:SetColour(0.5, 0.5, 0.5, 0.5)
    else
        self.decreasebutton2:SetClickable(true)
        self.decreasebutton2:SetColour(0.9, 0.8, 0.6, 1)
    end
    if a8 > 1 then
        a8 = 1;
        self.addbutton2:SetClickable(false)
        self.addbutton2:SetColour(0.5, 0.5, 0.5, 0.5)
    else
        self.addbutton2:SetClickable(true)
        self.addbutton2:SetColour(0.9, 0.8, 0.6, 1)
    end
    _G.TOOMANYITEMS.DATA.syd = a8;
    if _G.TOOMANYITEMS.DATA_SAVE == 1 then _G.TOOMANYITEMS.SaveNormalData() end
    self.toolfiniteusesvalue:SetString(_G.TOOMANYITEMS.DATA.syd * 100 .. "%")
end
function V:ChangePrefabFuel(_)
    local a8 = 0;
    if _ == "add" then
        a8 = _G.TOOMANYITEMS.DATA.fuel + 0.1
    else
        a8 = _G.TOOMANYITEMS.DATA.fuel - 0.1
    end
    if a8 <= 0.09 then
        a8 = 0.03;
        self.decreasebutton3:SetClickable(false)
        self.decreasebutton3:SetColour(0.5, 0.5, 0.5, 0.5)
    else
        self.decreasebutton3:SetClickable(true)
        self.decreasebutton3:SetColour(0.9, 0.8, 0.6, 1)
    end
    if a8 > 1 then
        a8 = 1;
        self.addbutton3:SetClickable(false)
        self.addbutton3:SetColour(0.5, 0.5, 0.5, 0.5)
    else
        self.addbutton3:SetClickable(true)
        self.addbutton3:SetColour(0.9, 0.8, 0.6, 1)
    end
    _G.TOOMANYITEMS.DATA.fuel = a8;
    if _G.TOOMANYITEMS.DATA_SAVE == 1 then _G.TOOMANYITEMS.SaveNormalData() end
    self.prefabfuelvalue:SetString(_G.TOOMANYITEMS.DATA.fuel * 100 .. "%")
end
function V:ChangePrefabTemperature(_)
    local a8 = 0;
    if _ == "add" then
        a8 = _G.TOOMANYITEMS.DATA.temperature + 10
    else
        a8 = _G.TOOMANYITEMS.DATA.temperature - 10
    end
    if a8 <= 0 then
        a8 = 0;
        self.decreasebutton4:SetClickable(false)
        self.decreasebutton4:SetColour(0.5, 0.5, 0.5, 0.5)
    else
        self.decreasebutton4:SetClickable(true)
        self.decreasebutton4:SetColour(0.9, 0.8, 0.6, 1)
    end
    if a8 > 100 then
        a8 = 100;
        self.addbutton4:SetClickable(false)
        self.addbutton4:SetColour(0.5, 0.5, 0.5, 0.5)
    else
        self.addbutton4:SetClickable(true)
        self.addbutton4:SetColour(0.9, 0.8, 0.6, 1)
    end
    _G.TOOMANYITEMS.DATA.temperature = a8;
    if _G.TOOMANYITEMS.DATA_SAVE == 1 then _G.TOOMANYITEMS.SaveNormalData() end
    self.prefabtemperaturevalue:SetString(
        _G.TOOMANYITEMS.DATA.temperature .. "°C")
end
function V:WoodieMenu()
    self.woodieshield = self.root:AddChild(a("images/ui.xml", "black.tex"))
    self.woodieshield:SetScale(1, 1, 1)
    self.woodieshield:SetPosition(self.shieldpos_x - self.shieldsize_x * 0.5 -
                                      20,
                                  self.shieldpos_y - self.shieldsize_y * 0.5 +
                                      60, 0)
    self.woodieshield:SetSize(40, 120)
    self.woodieshield:SetTint(1, 1, 1, 0.6)
    self.woodiebuttons = {}
    self.woodiebuttonlist = {
        ["beaverness"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_BEAVER_WEREMETER,
            fn = I,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_woodiebeavermode.tex",
            pos = {0, -40}
        },
        ["gosseness"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_GOOSE_WEREMETER,
            fn = M,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_woodiegoosemode.tex",
            pos = {0, 0}
        },
        ["mooseness"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_MOOSE_WEREMETER,
            fn = N,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_woodiemoosemode.tex",
            pos = {0, 40}
        }
    }
    for a1, a2 in pairs(self.woodiebuttonlist) do
        i(self.woodieshield, self.woodiebuttons, a1, a2.tip, a2.fn, a2.atlas,
          a2.image, a2.pos)
    end
end
function V:AbigailMenu()
    self.abigailshield = self.root:AddChild(a("images/ui.xml", "black.tex"))
    self.abigailshield:SetScale(1, 1, 1)
    self.abigailshield:SetPosition(self.shieldpos_x - self.shieldsize_x * 0.5 -
                                       20,
                                   self.shieldpos_y - self.shieldsize_y * 0.5 +
                                       60, 0)
    self.abigailshield:SetSize(40, 120)
    self.abigailshield:SetTint(1, 1, 1, 0.6)
    self.abigailbuttons = {}
    self.abigailbuttonlist = {
        ["abigail1"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_ABIGAIL_LV1,
            fn = O,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_abigaillv1.tex",
            pos = {0, -40}
        },
        ["abigail2"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_ABIGAIL_LV2,
            fn = P,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_abigaillv2.tex",
            pos = {0, 0}
        },
        ["abigail3"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_ABIGAIL_LV3,
            fn = Q,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_abigaillv3.tex",
            pos = {0, 40}
        }
    }
    for a1, a2 in pairs(self.abigailbuttonlist) do
        i(self.abigailshield, self.abigailbuttons, a1, a2.tip, a2.fn, a2.atlas,
          a2.image, a2.pos)
    end
end
function V:WormwoodMenu()
    self.wormwoodshield = self.root:AddChild(a("images/ui.xml", "black.tex"))
    self.wormwoodshield:SetScale(1, 1, 1)
    self.wormwoodshield:SetPosition(
        self.shieldpos_x - self.shieldsize_x * 0.5 - 20,
        self.shieldpos_y - self.shieldsize_y * 0.5 + 60, 0)
    self.wormwoodshield:SetSize(40, 120)
    self.wormwoodshield:SetTint(1, 1, 1, 0.6)
    self.wormwoodbuttons = {}
    self.wormwoodbuttonlist = {
        ["wormwwodl1"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_WORMWOOD_LV1,
            fn = R,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_wormwoodlv1.tex",
            pos = {0, -40}
        },
        ["wormwwodl2"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_WORMWOOD_LV2,
            fn = T,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_wormwoodlv2.tex",
            pos = {0, 0}
        },
        ["wormwwodl3"] = {
            tip = STRINGS.TOO_MANY_ITEMS_UI.BUTTON_WORMWOOD_LV3,
            fn = U,
            atlas = "images/customicobyysh.xml",
            image = "tmipbutton_wormwoodlv3.tex",
            pos = {0, 40}
        }
    }
    for a1, a2 in pairs(self.wormwoodbuttonlist) do
        i(self.wormwoodshield, self.wormwoodbuttons, a1, a2.tip, a2.fn,
          a2.atlas, a2.image, a2.pos)
    end
end
-- 调试菜单
function V:DebugMenu()
    self.fontsize = _G.TOOMANYITEMS.G_TMIP_DEBUG_FONT_SIZE;
    self.debugwidth = _G.TOOMANYITEMS.G_TMIP_DEBUG_MENU_SIZE;
    self.font = BODYTEXTFONT;
    self.minwidth = 36;
    self.nextline = 24;
    self.spacing = 10;
    self.left = -self.debugwidth * 0.5;
    self.limit = -self.left;
    self.debugshield = self.root:AddChild(a("images/ui.xml", "black.tex"))
    self.debugshield:SetScale(1, 1, 1)
    self.debugshield:SetPosition(self.shieldpos_x + self.shieldsize_x * 0.5 +
                                     self.limit, self.shieldpos_y, 0)
    self.debugshield:SetSize(self.limit * 2, self.shieldsize_y)
    self.debugshield:SetTint(1, 1, 1, 0.6)
    -- 选择玩家
    self.pointer = self.debugshield:AddChild(c())
    self.pointer:SetFont(self.font)
    self.pointer:SetTooltip(STRINGS.TOO_MANY_ITEMS_UI.BUTTON_POINTERTIP)
    self.pointer:SetTextSize(self.fontsize)
    self.pointer:SetColour(0, 1, 1, 1)
    self.pointer:SetOverColour(0.4, 1, 1, 1)
    self.pointer:SetOnClick(function() self:FlushPlayer() end)
    self:SetPointer()

    self.settingbutton = self.debugshield:AddChild(c())
    self.settingbutton:SetFont(self.font)
    self.settingbutton:SetTextSize(self.fontsize)
    self.settingbutton:SetColour(0.9, 0.8, 0.6, 1)
    self.settingbutton:SetText(STRINGS.TOO_MANY_ITEMS_UI.SETTINGS_BUTTON)
    self.settingbutton:SetTooltip(STRINGS.TOO_MANY_ITEMS_UI.SETTINGS_BUTTON_TIP1)
    self.swidth, self.sheight = self.settingbutton.text:GetRegionSize()
    self.settingbutton:SetPosition(self.left + self.debugwidth - self.swidth *
                                       0.5 - self.spacing, self.shieldsize_y *
                                       0.5 - self.sheight * 0.5, 0)
    self.settingbutton:SetOnClick(function() self:ShowSettingMenu() end)
    self.helpbutton = self.debugshield:AddChild(c())
    self.helpbutton:SetFont(self.font)
    self.helpbutton:SetTextSize(self.fontsize)
    self.helpbutton:SetColour(0.9, 0.8, 0.6, 1)
    self.helpbutton:SetText(STRINGS.TOO_MANY_ITEMS_UI.TIPS_BUTTON)
    self.helpbutton:SetTooltip(STRINGS.TOO_MANY_ITEMS_UI.TIPS_BUTTON_TIP1)
    self.hwidth, self.hheight = self.helpbutton.text:GetRegionSize()
    self.helpbutton:SetPosition(self.left + self.debugwidth - self.swidth -
                                    self.spacing * 2 - self.hwidth * 0.5,
                                self.shieldsize_y * 0.5 - self.sheight * 0.5, 0)
    self.helpbutton:SetOnClick(function() self:ShowTipsMenu() end)
    self.swicthbutton = self.debugshield:AddChild(c())
    self.swicthbutton:SetFont(self.font)
    self.swicthbutton:SetTextSize(self.fontsize)
    self.swicthbutton:SetColour(0.9, 0.8, 0.6, 1)
    self.swicthbutton:SetText(STRINGS.TOO_MANY_ITEMS_UI.NEXT_PLAYER)
    self.swicthbutton:SetTooltip(STRINGS.TOO_MANY_ITEMS_UI.NEXT_PLAYER_TIP)
    self.swwidth, self.swheight = self.swicthbutton.text:GetRegionSize()
    self.swicthbutton:SetPosition(self.left + self.debugwidth - self.swidth -
                                      self.spacing * 3 - self.hwidth -
                                      self.swwidth * 0.5,
                                  self.shieldsize_y * 0.5 - self.sheight * 0.5,
                                  0)
    self.swicthbutton:SetOnClick(function() self:FlushPlayer("next") end)
    self.debugbuttonlist = require "TMIP/debug"
    self.top = self.shieldsize_y * .5 - self.pointersizey - self.spacing;
    local function a9(aa)
        if aa and BRANCH == "release" then return false end
        return true
    end
    local function ab(q)
        if q == "all" then
            return true
        elseif q == "cave" and TheWorld:HasTag("cave") then
            return true
        elseif q == "forest" and TheWorld:HasTag("forest") then
            return true
        end
        return false
    end
    local function ac(aa, ad)
        if a9(aa) and ab(ad) then return true end
        return false
    end
    local function ae(af, ag)
        local ah = ag;
        for ai = 1, #af do
            if ac(af[ai].beta, af[ai].pos) then
                local aj = self.debugshield:AddChild(c())
                aj:SetFont(self.font)
                aj.text:SetHorizontalSqueeze(.9)
                aj:SetText(af[ai].name)
                aj:SetTooltip(af[ai].tip)
                aj:SetTextSize(self.fontsize)
                aj:SetColour(0.9, 0.8, 0.6, 1)
                local n = af[ai].fn;
                if type(n) == "table" then
                    if n[1] == "confirm" then
                        aj:SetOnClick(function()
                            self:FlushConfirmScreen(n)
                        end)
                    else
                        aj:SetOnClick(function()
                            n.TeleportFn(n.TeleportNum)
                        end)
                    end
                elseif type(n) == "string" then
                    aj:SetOnClick(function()
                        SendCommand(string.format(n, GetCharacter()))
                    end)
                elseif type(n) == "function" then
                    aj:SetOnClick(n)
                end
                local ak, al = aj.text:GetRegionSize()
                if ak < self.minwidth then
                    ak = self.minwidth;
                    aj.text:SetRegionSize(ak, al)
                end
                aj.image:SetSize(ak * 0.8, al)
                if ah + ak > self.limit then
                    self.top = self.top - self.nextline;
                    aj:SetPosition(self.left + ak * .5, self.top, 0)
                    ah = self.left + ak + self.spacing / 2
                else
                    aj:SetPosition(ah + ak * .5, self.top, 0)
                    ah = ah + ak + self.spacing / 2
                end
            end
        end
    end
    local function am(af)
        for ai = 1, #af do
            local an = self.debugshield:AddChild(
                           b(self.font, self.fontsize, af[ai].tittle))
            an:SetHorizontalSqueeze(.85)
            local ak = an:GetRegionSize()
            an:SetPosition(self.left + ak * .5, self.top, 0)
            ae(af[ai].list, self.left + ak + self.spacing)
            self.top = self.top - self.nextline
        end
    end
    am(self.debugbuttonlist)
end
function V:ChangeDeleteFunction()
    local ao = _G.TOOMANYITEMS.DATA.ADVANCE_DELETE;
    if ao then
        self.onbutton3:SetClickable(true)
        self.onbutton3:SetColour(0.5, 0.5, 0.5, 0.5)
        self.offbutton3:SetClickable(false)
        self.offbutton3:SetColour(0.9, 0.8, 0.6, 1)
        _G.TOOMANYITEMS.DATA.ADVANCE_DELETE = false
    else
        self.onbutton3:SetClickable(false)
        self.onbutton3:SetColour(0.9, 0.8, 0.6, 1)
        self.offbutton3:SetClickable(true)
        self.offbutton3:SetColour(0.5, 0.5, 0.5, 0.5)
        _G.TOOMANYITEMS.DATA.ADVANCE_DELETE = true
    end
    if _G.TOOMANYITEMS.DATA_SAVE == 1 then _G.TOOMANYITEMS.SaveNormalData() end
end
function V:ChangeSpawnItemsTips()
    local ao = _G.TOOMANYITEMS.DATA.SPAWN_ITEMS_TIPS;
    if ao then
        self.onbutton1:SetClickable(true)
        self.onbutton1:SetColour(0.5, 0.5, 0.5, 0.5)
        self.offbutton1:SetClickable(false)
        self.offbutton1:SetColour(0.9, 0.8, 0.6, 1)
        _G.TOOMANYITEMS.DATA.SPAWN_ITEMS_TIPS = false
    else
        self.onbutton1:SetClickable(false)
        self.onbutton1:SetColour(0.9, 0.8, 0.6, 1)
        self.offbutton1:SetClickable(true)
        self.offbutton1:SetColour(0.5, 0.5, 0.5, 0.5)
        _G.TOOMANYITEMS.DATA.SPAWN_ITEMS_TIPS = true
    end
    if _G.TOOMANYITEMS.DATA_SAVE == 1 then _G.TOOMANYITEMS.SaveNormalData() end
end
function V:ChangeShowConfirmScreen()
    local ap = _G.TOOMANYITEMS.DATA.SHOW_CONFIRM_SCREEN;
    if ap then
        self.onbutton2:SetClickable(true)
        self.onbutton2:SetColour(0.5, 0.5, 0.5, 0.5)
        self.offbutton2:SetClickable(false)
        self.offbutton2:SetColour(0.9, 0.8, 0.6, 1)
        _G.TOOMANYITEMS.DATA.SHOW_CONFIRM_SCREEN = false
    else
        self.onbutton2:SetClickable(false)
        self.onbutton2:SetColour(0.9, 0.8, 0.6, 1)
        self.offbutton2:SetClickable(true)
        self.offbutton2:SetColour(0.5, 0.5, 0.5, 0.5)
        _G.TOOMANYITEMS.DATA.SHOW_CONFIRM_SCREEN = true
    end
    if _G.TOOMANYITEMS.DATA_SAVE == 1 then _G.TOOMANYITEMS.SaveNormalData() end
end

-- 帮助窗口
function V:TipsMenu()
    self.fontsize = 25;
    self.tipswidth = 500;
    self.font = BODYTEXTFONT;
    self.tipslinespace = 10;
    self.tipsleft = -self.tipswidth * 0.5;
    self.tipslimit = -self.tipsleft;
    self.tipsshield = self.root:AddChild(a("images/ui.xml", "black.tex"))
    self.tipsshield:SetScale(1, 1, 1)
    self.tipsshield:SetPosition(83, self.shieldpos_y, 0)
    self.tipsshield:SetSize(self.tipslimit * 2, self.shieldsize_y)
    self.tipsshield:SetTint(1, 1, 1, 1)
    self.screenname =
        self.tipsshield:AddChild(b(self.font, self.fontsize * 1.5))
    self.screenname:SetColour(0, 1, 1, 1)
    self.screenname:SetString(STRINGS.TOO_MANY_ITEMS_UI.TIPS_BUTTON_TIP)
    self.screennamex, self.screennamey = self.screenname:GetRegionSize()
    self.screenname:SetPosition(self.tipsleft + self.screennamex * .5 + 10,
                                self.shieldsize_y * .5 - self.screennamey * .5,
                                0)

    self.desimg = self.tipsshield:AddChild(
                      a("images/helpcnbyysh.xml", "helpcnbyysh.tex"))
    self.morebutton = self.tipsshield:AddChild(c())
    self.morebutton:SetFont(self.font)
    self.morebutton:SetText(STRINGS.TOO_MANY_ITEMS_UI.HELP_AND_INSTRUCTIONS)
    self.morebutton:SetTextSize(self.fontsize)
    self.morebutton:SetColour(0.9, 0.8, 0.6, 1)
    self.morebuttonx, self.morebuttony = self.closebutton.text:GetRegionSize()
    self.morebutton:SetPosition(self.tipsleft + self.tipswidth * 0.5,
                                self.shieldsize_y * .5 - self.morebuttony * .5 -
                                    5, 0)
    self.morebutton:SetOnClick(function()
        VisitURL("https://www.bilibili.com/video/BV1xN4y1M7qC/", false)
    end)

    self.desimg:SetPosition(0, self.shieldpos_y - 35, 0)
    self.desimg:SetScale(1, 1, 1)
    self.desimg:SetSize(self.tipslimit * 2, self.shieldsize_y)
    self.closebutton = self.tipsshield:AddChild(c())
    self.closebutton:SetFont(self.font)
    self.closebutton:SetText(STRINGS.UI.OPTIONS.CLOSE)
    self.closebutton:SetTextSize(self.fontsize)
    self.closebutton:SetColour(0.9, 0.8, 0.6, 1)
    self.closebuttonx, self.closebuttony = self.closebutton.text:GetRegionSize()
    self.closebutton:SetPosition(self.tipsleft + self.tipswidth -
                                     self.closebuttonx * .5 - 5,
                                 self.shieldsize_y * .5 - self.closebuttony * .5 -
                                     5, 0)
    self.closebutton:SetOnClick(function() self:ShowTipsMenu() end)
end

-- 设置窗口
function V:SettingMenu()
    self.fontsize = _G.TOOMANYITEMS.G_TMIP_DEBUG_FONT_SIZE;
    self.settingwidth = _G.TOOMANYITEMS.G_TMIP_DEBUG_MENU_SIZE / 3 * 2;
    self.font = BODYTEXTFONT;
    self.settinglinespace = 10;
    self.settingleft = -self.settingwidth * 0.5;
    self.settinglimit = -self.settingleft;
    self.settingshield = self.root:AddChild(a("images/ui.xml", "black.tex"))
    self.settingshield:SetScale(1, 1, 1)
    self.settingshield:SetPosition(15, self.shieldpos_y, 0)
    self.settingshield:SetSize(self.settinglimit * 2, self.shieldsize_y)
    self.settingshield:SetTint(1, 1, 1, 1)
    self.screenname = self.settingshield:AddChild(b(self.font,
                                                    self.fontsize * 1.5))
    self.screenname:SetColour(0, 1, 1, 1)
    self.screenname:SetString(STRINGS.TOO_MANY_ITEMS_UI.SETTINGS_BUTTON_TIP)
    self.screennamex, self.screennamey = self.screenname:GetRegionSize()
    self.screenname:SetPosition(self.settingleft + self.screennamex * .5 + 10,
                                self.shieldsize_y * .5 - self.screennamey * .5,
                                0)
    self.closebutton = self.settingshield:AddChild(c())
    self.closebutton:SetFont(self.font)
    self.closebutton:SetText(STRINGS.UI.OPTIONS.CLOSE)
    self.closebutton:SetTextSize(self.fontsize)
    self.closebutton:SetColour(0.9, 0.8, 0.6, 1)
    self.closebuttonx, self.closebuttony = self.closebutton.text:GetRegionSize()
    self.closebutton:SetPosition(self.settingleft + self.settingwidth -
                                     self.closebuttonx * .5 - 5,
                                 self.shieldsize_y * .5 - self.closebuttony * .5 -
                                     5, 0)
    self.closebutton:SetOnClick(function() self:ShowSettingMenu() end)
    self.spawnitemstips = self.settingshield:AddChild(
                              b(self.font, self.fontsize))
    self.spawnitemstips:SetColour(0.9, 0.8, 0.6, 1)
    self.spawnitemstips:SetString(STRINGS.TOO_MANY_ITEMS_UI
                                      .TMIP_SPAWN_ITEMS_TIPS)
    self.spawnitemstipsx, self.spawnitemstipsy =
        self.spawnitemstips:GetRegionSize()
    self.spawnitemstips:SetPosition(
        self.settingleft + self.spawnitemstipsx * .5 + 20, self.shieldsize_y *
            .5 - self.screennamey - self.settinglinespace * 7.5, 0)
    self.onbutton1 = self.settingshield:AddChild(c())
    self.onbutton1:SetFont(self.font)
    self.onbutton1:SetText(STRINGS.TOO_MANY_ITEMS_UI.TMIP_SPAWN_ITEMS_TIPS_ON)
    self.onbutton1:SetTextSize(self.fontsize)
    self.onbutton1:SetColour(0.9, 0.8, 0.6, 1)
    self.onbutton1x, self.onbutton1y = self.onbutton1.text:GetRegionSize()
    self.onbutton1:SetPosition(self.settingleft + self.spawnitemstipsx + 20 +
                                   self.settinglinespace + self.onbutton1x * .5,
                               self.shieldsize_y * .5 - self.screennamey -
                                   self.settinglinespace * 7.5, 0)
    self.onbutton1:SetOnClick(function() self:ChangeSpawnItemsTips() end)
    self.offbutton1 = self.settingshield:AddChild(c())
    self.offbutton1:SetFont(self.font)
    self.offbutton1:SetText(STRINGS.TOO_MANY_ITEMS_UI.TMIP_SPAWN_ITEMS_TIPS_OFF)
    self.offbutton1:SetTextSize(self.fontsize)
    self.offbutton1:SetColour(0.9, 0.8, 0.6, 1)
    self.offbutton1x, self.offbutton1y = self.offbutton1.text:GetRegionSize()
    self.offbutton1:SetPosition(self.settingleft + self.spawnitemstipsx + 20 +
                                    self.settinglinespace * 2 + self.onbutton1x +
                                    self.offbutton1x * 0.5, self.shieldsize_y *
                                    .5 - self.screennamey -
                                    self.settinglinespace * 7.5, 0)
    self.offbutton1:SetOnClick(function() self:ChangeSpawnItemsTips() end)
    local ao = _G.TOOMANYITEMS.DATA.SPAWN_ITEMS_TIPS;
    if ao then
        self.onbutton1:SetClickable(false)
        self.offbutton1:SetColour(0.5, 0.5, 0.5, 0.5)
    else
        self.onbutton1:SetColour(0.5, 0.5, 0.5, 0.5)
        self.offbutton1:SetClickable(false)
    end
    self.deletefunction = self.settingshield:AddChild(
                              b(self.font, self.fontsize))
    self.deletefunction:SetColour(0.9, 0.8, 0.6, 1)
    self.deletefunction:SetString(STRINGS.TOO_MANY_ITEMS_UI.ADVANCED_DELETE)
    self.deletefunctionx, self.deletefunctiony =
        self.deletefunction:GetRegionSize()
    self.deletefunction:SetPosition(
        self.settingleft + self.deletefunctionx * .5 + 20, self.shieldsize_y *
            .5 - self.screennamey - self.settinglinespace * 19.5, 0)
    self.onbutton3 = self.settingshield:AddChild(c())
    self.onbutton3:SetFont(self.font)
    self.onbutton3:SetText(STRINGS.TOO_MANY_ITEMS_UI.TMIP_ADVANCED_DELETE_ON)
    self.onbutton3:SetTooltip(STRINGS.TOO_MANY_ITEMS_UI.ADVANCED_DELETE_TIP)
    self.onbutton3:SetTextSize(self.fontsize)
    self.onbutton3:SetColour(0.9, 0.8, 0.6, 1)
    self.onbutton3x, self.onbutton3y = self.onbutton3.text:GetRegionSize()
    self.onbutton3:SetPosition(self.settingleft + self.deletefunctionx + 20 +
                                   self.settinglinespace + self.onbutton3x * .5,
                               self.shieldsize_y * .5 - self.screennamey -
                                   self.settinglinespace * 19.5, 0)
    self.onbutton3:SetOnClick(function() self:ChangeDeleteFunction() end)
    self.offbutton3 = self.settingshield:AddChild(c())
    self.offbutton3:SetFont(self.font)
    self.offbutton3:SetText(STRINGS.TOO_MANY_ITEMS_UI.TMIP_ADVANCED_DELETE_OFF)
    self.offbutton3:SetTooltip(STRINGS.TOO_MANY_ITEMS_UI.ADVANCED_DELETE_TIP)
    self.offbutton3:SetTextSize(self.fontsize)
    self.offbutton3:SetColour(0.9, 0.8, 0.6, 1)
    self.offbutton3x, self.offbutton3y = self.offbutton3.text:GetRegionSize()
    self.offbutton3:SetPosition(self.settingleft + self.deletefunctionx + 20 +
                                    self.settinglinespace * 2 + self.onbutton3x +
                                    self.offbutton3x * 0.5, self.shieldsize_y *
                                    .5 - self.screennamey -
                                    self.settinglinespace * 19.5, 0)
    self.offbutton3:SetOnClick(function() self:ChangeDeleteFunction() end)
    local ao = _G.TOOMANYITEMS.DATA.ADVANCE_DELETE;
    if ao then
        self.onbutton3:SetClickable(false)
        self.offbutton3:SetColour(0.5, 0.5, 0.5, 0.5)
    else
        self.onbutton3:SetColour(0.5, 0.5, 0.5, 0.5)
        self.offbutton3:SetClickable(false)
    end
    self.deleteradius = self.settingshield:AddChild(b(self.font, self.fontsize))
    self.deleteradius:SetColour(0.9, 0.8, 0.6, 1)
    self.deleteradius:SetString(STRINGS.TOO_MANY_ITEMS_UI.ADVANCED_DELETE_RADIUS)
    self.deleteradiusx, self.deleteradiusy = self.deleteradius:GetRegionSize()
    self.deleteradius:SetPosition(self.settingleft + self.deleteradiusx * .5 +
                                      20, self.shieldsize_y * .5 -
                                      self.screennamey - self.settinglinespace *
                                      22.5, 0)
    self.decreasebutton5 = self.settingshield:AddChild(c())
    self.decreasebutton5:SetFont(self.font)
    self.decreasebutton5:SetText("<")
    self.decreasebutton5:SetTextSize(self.fontsize * 2)
    self.decreasebutton5:SetColour(0.9, 0.8, 0.6, 1)
    self.decreasebutton5x, self.decreasebutton5y =
        self.decreasebutton5.text:GetRegionSize()
    self.decreasebutton5:SetPosition(
        self.settingleft + self.deleteradiusx + 20 + self.settinglinespace +
            self.decreasebutton5x * .5, self.shieldsize_y * .5 -
            self.screennamey - self.settinglinespace * 22.5, 0)
    self.decreasebutton5:SetOnClick(function()
        self:ChangeDeleteRadius("decrease")
    end)
    self.deleteradiuspointer = self.settingshield:AddChild(c())
    self.deleteradiuspointer:SetFont(self.font)
    self.deleteradiuspointer:SetTooltip("Click to edit: 3~999")
    self.deleteradiuspointer:SetTextSize(self.fontsize)
    self.deleteradiuspointer:SetColour(0, 1, 1, 1)
    self.deleteradiuspointer:SetOverColour(0.4, 1, 1, 1)
    self.deleteradiuspointer:SetOnClick(function() self:FlushDeleteRadius() end)
    self:SetDeleteRadiusPointer()
    self.addbutton5 = self.settingshield:AddChild(c())
    self.addbutton5:SetFont(self.font)
    self.addbutton5:SetText(">")
    self.addbutton5:SetTextSize(self.fontsize * 2)
    self.addbutton5:SetColour(0.9, 0.8, 0.6, 1)
    self.addbutton5x, self.addbutton5y = self.addbutton5.text:GetRegionSize()
    self.addbutton5:SetPosition(self.settingleft + self.deleteradiusx + 20 +
                                    self.settinglinespace * 5 +
                                    self.decreasebutton5x +
                                    self.deleteradiuspointersizex +
                                    self.addbutton5x * 0.5, self.shieldsize_y *
                                    .5 - self.screennamey -
                                    self.settinglinespace * 22.5, 0)
    self.addbutton5:SetOnClick(function() self:ChangeDeleteRadius("add") end)
    local a8 = _G.TOOMANYITEMS.DATA.deleteradius;
    if a8 <= 3 then
        self.decreasebutton5:SetClickable(false)
        self.decreasebutton5:SetColour(0.5, 0.5, 0.5, 0.5)
    end
    if a8 >= 999 then
        self.addbutton5:SetClickable(false)
        self.addbutton5:SetColour(0.5, 0.5, 0.5, 0.5)
    end
    self.showconfirmscreen = self.settingshield:AddChild(b(self.font,
                                                           self.fontsize))
    self.showconfirmscreen:SetColour(0.9, 0.8, 0.6, 1)
    self.showconfirmscreen:SetString(STRINGS.TOO_MANY_ITEMS_UI
                                         .SHOW_CONFIRM_SCREEN_TIPS)
    self.showconfirmscreenx, self.showconfirmscreeny =
        self.showconfirmscreen:GetRegionSize()
    self.showconfirmscreen:SetPosition(self.settingleft +
                                           self.showconfirmscreenx * .5 + 20,
                                       self.shieldsize_y * .5 - self.screennamey -
                                           self.settinglinespace * 16.5, 0)
    self.onbutton2 = self.settingshield:AddChild(c())
    self.onbutton2:SetFont(self.font)
    self.onbutton2:SetText(STRINGS.TOO_MANY_ITEMS_UI.TMIP_SHOW_CONFIRM_SCREEN_ON)
    self.onbutton2:SetTextSize(self.fontsize)
    self.onbutton2:SetColour(0.9, 0.8, 0.6, 1)
    self.onbutton2x, self.onbutton2y = self.onbutton2.text:GetRegionSize()
    self.onbutton2:SetPosition(
        self.settingleft + self.showconfirmscreenx + 20 + self.settinglinespace +
            self.onbutton2x * .5, self.shieldsize_y * .5 - self.screennamey -
            self.settinglinespace * 16.5, 0)
    self.onbutton2:SetOnClick(function() self:ChangeShowConfirmScreen() end)
    self.offbutton2 = self.settingshield:AddChild(c())
    self.offbutton2:SetFont(self.font)
    self.offbutton2:SetText(STRINGS.TOO_MANY_ITEMS_UI
                                .TMIP_SHOW_CONFIRM_SCREEN_OFF)
    self.offbutton2:SetTextSize(self.fontsize)
    self.offbutton2:SetColour(0.9, 0.8, 0.6, 1)
    self.offbutton2x, self.offbutton2y = self.offbutton2.text:GetRegionSize()
    self.offbutton2:SetPosition(
        self.settingleft + self.showconfirmscreenx + 20 + self.settinglinespace *
            2 + self.onbutton2x + self.offbutton2x * 0.5,
        self.shieldsize_y * .5 - self.screennamey - self.settinglinespace * 16.5,
        0)
    self.offbutton2:SetOnClick(function() self:ChangeShowConfirmScreen() end)
    local ao = _G.TOOMANYITEMS.DATA.SHOW_CONFIRM_SCREEN;
    if ao then
        self.onbutton2:SetClickable(false)
        self.offbutton2:SetColour(0.5, 0.5, 0.5, 0.5)
    else
        self.onbutton2:SetColour(0.5, 0.5, 0.5, 0.5)
        self.offbutton2:SetClickable(false)
    end
    self.foodfreshness =
        self.settingshield:AddChild(b(self.font, self.fontsize))
    self.foodfreshness:SetColour(0.9, 0.8, 0.6, 1)
    self.foodfreshness:SetString(STRINGS.TOO_MANY_ITEMS_UI.FOOD_FRESHNESS)
    self.foodfreshnessx, self.foodfreshnessy =
        self.foodfreshness:GetRegionSize()
    self.foodfreshness:SetPosition(
        self.settingleft + self.foodfreshnessx * .5 + 20,
        self.shieldsize_y * .5 - self.screennamey - self.settinglinespace * 1.5,
        0)
    self.decreasebutton1 = self.settingshield:AddChild(c())
    self.decreasebutton1:SetFont(self.font)
    self.decreasebutton1:SetText("<")
    self.decreasebutton1:SetTextSize(self.fontsize * 2)
    self.decreasebutton1:SetColour(0.9, 0.8, 0.6, 1)
    self.decreasebutton1x, self.decreasebutton1y =
        self.decreasebutton1.text:GetRegionSize()
    self.decreasebutton1:SetPosition(
        self.settingleft + self.foodfreshnessx + 20 + self.settinglinespace +
            self.decreasebutton1x * .5, self.shieldsize_y * .5 -
            self.screennamey - self.settinglinespace * 1.5, 0)
    self.decreasebutton1:SetOnClick(function()
        self:ChangeFoodFreshness("decrease")
    end)
    self.foodfreshnessvalue = self.settingshield:AddChild(b(self.font,
                                                            self.fontsize))
    self.foodfreshnessvalue:SetColour(1, 1, 1, 1)
    self.foodfreshnessvalue:SetString(_G.TOOMANYITEMS.DATA.xxd * 100 .. "%")
    self.foodfreshnessvaluex, self.foodfreshnessvaluey =
        self.foodfreshnessvalue:GetRegionSize()
    self.foodfreshnessvalue:SetPosition(
        self.settingleft + self.foodfreshnessx + 20 + self.settinglinespace * 3 +
            self.decreasebutton1x + self.foodfreshnessvaluex * 0.5,
        self.shieldsize_y * .5 - self.screennamey - self.settinglinespace * 1.5,
        0)
    self.addbutton1 = self.settingshield:AddChild(c())
    self.addbutton1:SetFont(self.font)
    self.addbutton1:SetText(">")
    self.addbutton1:SetTextSize(self.fontsize * 2)
    self.addbutton1:SetColour(0.9, 0.8, 0.6, 1)
    self.addbutton1x, self.addbutton1y = self.addbutton1.text:GetRegionSize()
    self.addbutton1:SetPosition(self.settingleft + self.foodfreshnessx + 20 +
                                    self.settinglinespace * 5 +
                                    self.decreasebutton1x +
                                    self.foodfreshnessvaluex + self.addbutton1x *
                                    0.5, self.shieldsize_y * .5 -
                                    self.screennamey - self.settinglinespace *
                                    1.5, 0)
    self.addbutton1:SetOnClick(function() self:ChangeFoodFreshness("add") end)
    local a8 = _G.TOOMANYITEMS.DATA.xxd;
    if a8 <= 0.09 then
        self.decreasebutton1:SetClickable(false)
        self.decreasebutton1:SetColour(0.5, 0.5, 0.5, 0.5)
    end
    if a8 >= 1 then
        self.addbutton1:SetClickable(false)
        self.addbutton1:SetColour(0.5, 0.5, 0.5, 0.5)
    end
    self.toolfiniteuses = self.settingshield:AddChild(
                              b(self.font, self.fontsize))
    self.toolfiniteuses:SetColour(0.9, 0.8, 0.6, 1)
    self.toolfiniteuses:SetString(STRINGS.TOO_MANY_ITEMS_UI.TOOL_FINITEUSES)
    self.toolfiniteusesx, self.toolfiniteusesy =
        self.toolfiniteuses:GetRegionSize()
    self.toolfiniteuses:SetPosition(
        self.settingleft + self.toolfiniteusesx * .5 + 20, self.shieldsize_y *
            .5 - self.screennamey - self.settinglinespace * 4.5, 0)
    self.decreasebutton2 = self.settingshield:AddChild(c())
    self.decreasebutton2:SetFont(self.font)
    self.decreasebutton2:SetText("<")
    self.decreasebutton2:SetTextSize(self.fontsize * 2)
    self.decreasebutton2:SetColour(0.9, 0.8, 0.6, 1)
    self.decreasebutton2x, self.decreasebutton2y =
        self.decreasebutton2.text:GetRegionSize()
    self.decreasebutton2:SetPosition(self.settingleft + self.toolfiniteusesx +
                                         20 + self.settinglinespace +
                                         self.decreasebutton2x * .5,
                                     self.shieldsize_y * .5 - self.screennamey -
                                         self.settinglinespace * 4.5, 0)
    self.decreasebutton2:SetOnClick(function()
        self:ChangeToolFiniteuses("decrease")
    end)
    self.toolfiniteusesvalue = self.settingshield:AddChild(b(self.font,
                                                             self.fontsize))
    self.toolfiniteusesvalue:SetColour(1, 1, 1, 1)
    self.toolfiniteusesvalue:SetString(_G.TOOMANYITEMS.DATA.syd * 100 .. "%")
    self.toolfiniteusesvaluex, self.toolfiniteusesvaluey =
        self.toolfiniteusesvalue:GetRegionSize()
    self.toolfiniteusesvalue:SetPosition(
        self.settingleft + self.toolfiniteusesx + 20 + self.settinglinespace * 3 +
            self.decreasebutton2x + self.toolfiniteusesvaluex * 0.5,
        self.shieldsize_y * .5 - self.screennamey - self.settinglinespace * 4.5,
        0)
    self.addbutton2 = self.settingshield:AddChild(c())
    self.addbutton2:SetFont(self.font)
    self.addbutton2:SetText(">")
    self.addbutton2:SetTextSize(self.fontsize * 2)
    self.addbutton2:SetColour(0.9, 0.8, 0.6, 1)
    self.addbutton2x, self.addbutton2y = self.addbutton2.text:GetRegionSize()
    self.addbutton2:SetPosition(self.settingleft + self.toolfiniteusesx + 20 +
                                    self.settinglinespace * 5 +
                                    self.decreasebutton2x +
                                    self.toolfiniteusesvaluex + self.addbutton2x *
                                    0.5, self.shieldsize_y * .5 -
                                    self.screennamey - self.settinglinespace *
                                    4.5, 0)
    self.addbutton2:SetOnClick(function() self:ChangeToolFiniteuses("add") end)
    local a8 = _G.TOOMANYITEMS.DATA.syd;
    if a8 <= 0.09 then
        self.decreasebutton2:SetClickable(false)
        self.decreasebutton2:SetColour(0.5, 0.5, 0.5, 0.5)
    end
    if a8 >= 1 then
        self.addbutton2:SetClickable(false)
        self.addbutton2:SetColour(0.5, 0.5, 0.5, 0.5)
    end
    self.prefabfuel = self.settingshield:AddChild(b(self.font, self.fontsize))
    self.prefabfuel:SetColour(0.9, 0.8, 0.6, 1)
    self.prefabfuel:SetString(STRINGS.TOO_MANY_ITEMS_UI.PREFAB_FUEL)
    self.prefabfuelx, self.prefabfuely = self.prefabfuel:GetRegionSize()
    self.prefabfuel:SetPosition(self.settingleft + self.prefabfuelx * .5 + 20,
                                self.shieldsize_y * .5 - self.screennamey -
                                    self.settinglinespace * 10.5, 0)
    self.decreasebutton3 = self.settingshield:AddChild(c())
    self.decreasebutton3:SetFont(self.font)
    self.decreasebutton3:SetText("<")
    self.decreasebutton3:SetTextSize(self.fontsize * 2)
    self.decreasebutton3:SetColour(0.9, 0.8, 0.6, 1)
    self.decreasebutton3x, self.decreasebutton3y =
        self.decreasebutton3.text:GetRegionSize()
    self.decreasebutton3:SetPosition(self.settingleft + self.prefabfuelx + 20 +
                                         self.settinglinespace +
                                         self.decreasebutton3x * .5,
                                     self.shieldsize_y * .5 - self.screennamey -
                                         self.settinglinespace * 10.5, 0)
    self.decreasebutton3:SetOnClick(function()
        self:ChangePrefabFuel("decrease")
    end)
    self.prefabfuelvalue = self.settingshield:AddChild(b(self.font,
                                                         self.fontsize))
    self.prefabfuelvalue:SetColour(1, 1, 1, 1)
    self.prefabfuelvalue:SetString(_G.TOOMANYITEMS.DATA.fuel * 100 .. "%")
    self.prefabfuelvaluex, self.prefabfuelvaluey =
        self.prefabfuelvalue:GetRegionSize()
    self.prefabfuelvalue:SetPosition(self.settingleft + self.prefabfuelx + 20 +
                                         self.settinglinespace * 3 +
                                         self.decreasebutton3x +
                                         self.prefabfuelvaluex * 0.5,
                                     self.shieldsize_y * .5 - self.screennamey -
                                         self.settinglinespace * 10.5, 0)
    self.addbutton3 = self.settingshield:AddChild(c())
    self.addbutton3:SetFont(self.font)
    self.addbutton3:SetText(">")
    self.addbutton3:SetTextSize(self.fontsize * 2)
    self.addbutton3:SetColour(0.9, 0.8, 0.6, 1)
    self.addbutton3x, self.addbutton3y = self.addbutton3.text:GetRegionSize()
    self.addbutton3:SetPosition(self.settingleft + self.prefabfuelx + 20 +
                                    self.settinglinespace * 5 +
                                    self.decreasebutton3x +
                                    self.prefabfuelvaluex + self.addbutton3x *
                                    0.5, self.shieldsize_y * .5 -
                                    self.screennamey - self.settinglinespace *
                                    10.5, 0)
    self.addbutton3:SetOnClick(function() self:ChangePrefabFuel("add") end)
    local a8 = _G.TOOMANYITEMS.DATA.fuel;
    if a8 <= 0.09 then
        self.decreasebutton3:SetClickable(false)
        self.decreasebutton3:SetColour(0.5, 0.5, 0.5, 0.5)
    end
    if a8 >= 1 then
        self.addbutton3:SetClickable(false)
        self.addbutton3:SetColour(0.5, 0.5, 0.5, 0.5)
    end
    self.prefabtemperature = self.settingshield:AddChild(b(self.font,
                                                           self.fontsize))
    self.prefabtemperature:SetColour(0.9, 0.8, 0.6, 1)
    self.prefabtemperature:SetString(STRINGS.TOO_MANY_ITEMS_UI
                                         .PREFAB_TEMPERATURE)
    self.prefabtemperaturex, self.prefabtemperaturey =
        self.prefabtemperature:GetRegionSize()
    self.prefabtemperature:SetPosition(self.settingleft +
                                           self.prefabtemperaturex * .5 + 20,
                                       self.shieldsize_y * .5 - self.screennamey -
                                           self.settinglinespace * 13.5, 0)
    self.decreasebutton4 = self.settingshield:AddChild(c())
    self.decreasebutton4:SetFont(self.font)
    self.decreasebutton4:SetText("<")
    self.decreasebutton4:SetTextSize(self.fontsize * 2)
    self.decreasebutton4:SetColour(0.9, 0.8, 0.6, 1)
    self.decreasebutton4x, self.decreasebutton4y =
        self.decreasebutton4.text:GetRegionSize()
    self.decreasebutton4:SetPosition(
        self.settingleft + self.prefabtemperaturex + 20 + self.settinglinespace +
            self.decreasebutton4x * .5, self.shieldsize_y * .5 -
            self.screennamey - self.settinglinespace * 13.5, 0)
    self.decreasebutton4:SetOnClick(function()
        self:ChangePrefabTemperature("decrease")
    end)
    self.prefabtemperaturevalue = self.settingshield:AddChild(b(self.font,
                                                                self.fontsize))
    self.prefabtemperaturevalue:SetColour(1, 1, 1, 1)
    self.prefabtemperaturevalue:SetString(
        _G.TOOMANYITEMS.DATA.temperature .. "°C")
    self.prefabtemperaturevaluex, self.prefabtemperaturevaluey =
        self.prefabtemperaturevalue:GetRegionSize()
    self.prefabtemperaturevalue:SetPosition(self.settingleft +
                                                self.prefabtemperaturex + 20 +
                                                self.settinglinespace * 3 +
                                                self.decreasebutton4x +
                                                self.prefabtemperaturevaluex *
                                                0.5, self.shieldsize_y * .5 -
                                                self.screennamey -
                                                self.settinglinespace * 13.5, 0)
    self.addbutton4 = self.settingshield:AddChild(c())
    self.addbutton4:SetFont(self.font)
    self.addbutton4:SetText(">")
    self.addbutton4:SetTextSize(self.fontsize * 2)
    self.addbutton4:SetColour(0.9, 0.8, 0.6, 1)
    self.addbutton4x, self.addbutton4y = self.addbutton4.text:GetRegionSize()
    self.addbutton4:SetPosition(
        self.settingleft + self.prefabtemperaturex + 20 + self.settinglinespace *
            5 + self.decreasebutton4x + self.prefabtemperaturevaluex +
            self.addbutton4x * 0.5, self.shieldsize_y * .5 - self.screennamey -
            self.settinglinespace * 13.5, 0)
    self.addbutton4:SetOnClick(
        function() self:ChangePrefabTemperature("add") end)
    local a8 = _G.TOOMANYITEMS.DATA.temperature;
    if a8 <= 0 then
        self.decreasebutton4:SetClickable(false)
        self.decreasebutton4:SetColour(0.5, 0.5, 0.5, 0.5)
    end
    if a8 >= 100 then
        self.addbutton4:SetClickable(false)
        self.addbutton4:SetColour(0.5, 0.5, 0.5, 0.5)
    end
end
function V:OnControl(aq, ar)
    if V._base.OnControl(self, aq, ar) then return true end
    if not ar then
        if aq == CONTROL_PAUSE or aq == CONTROL_CANCEL then self:Close() end
    end
    return true
end
function V:OnRawKey(as, ar)
    if V._base.OnRawKey(self, as, ar) then return true end
end
return V
