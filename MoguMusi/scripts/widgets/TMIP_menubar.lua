local a = require "widgets/image"
local b = require "widgets/text"
local TextBtn = require "widgets/textbutton"
local d = require "widgets/widget"
local e = require "screens/TMIP_searchscreen"
local f = require "widgets/TMIP_inventorybar"
local g = require "TMIP/menu"
local function h(i) return string.lower(TrimString(i)) end
local j = Class(d, function(self, k)
    d._ctor(self, "TMIP_Menubar")
    self.owner = k;
    self:Init()
end)
function j:Init()
    self:InitSidebar()
    self:InitSearch()
    self:InitMenu()
    local function l(m, n)
        self.pagetext:SetString(m .. " / " .. n)
        if m <= 1 then
            self.TMIP_Menu.mainbuttons["prevbutton"]:Hide()
        else
            self.TMIP_Menu.mainbuttons["prevbutton"]:Show()
        end
        if m >= n then
            self.TMIP_Menu.mainbuttons["nextbutton"]:Hide()
        else
            self.TMIP_Menu.mainbuttons["nextbutton"]:Show()
        end
    end
    self.inventory = self:AddChild(f(l))
    self:LoadSearchData()
end
function j:InitMenu()
    local o = 36;
    if _G.TOOMANYITEMS.UI_LANGUAGE == "en" then o = o * 0.85 end
    local p = 37;
    local q = 20 - self.owner.shieldsize_x * .5;
    local r = self.owner.shieldsize_x * .5;
    local s = self.sidebar_width * .5;
    local t = {
        q, q + p, q + p * 2, q + p * 3, q + p * 4, q + p * 5, q + p * 6,
        q + p * 7, q + p * 8, q + p * 9, q + p * 10
    }
    self.TMIP_Menu = g(self, t)
    self.pagetext = self:AddChild(b(NEWFONT_OUTLINE, o))
    self.pagetext:SetString("1 / 2")
    self.pagetext:SetColour(1, 1, 1, 0.6)
    self.pagetext:SetPosition(s + 155, -220, 0)
end
-- 边沿窗口
function j:InitSidebar()
    self.sidebar_width = 0;
    self.sidebarlists = {
        {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_CUSTOM,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPCUSTOM,
            fn = self:GetSideButtonFn("custom")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_FOOD,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPFOOD,
            fn = self:GetSideButtonFn("food")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_SEEDS,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPSEEDS,
            fn = self:GetSideButtonFn("seeds")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_EQUIP,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPEQUIP,
            fn = self:GetSideButtonFn("equip")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_PROPS,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPPROPS,
            fn = self:GetSideButtonFn("props")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_MAGIC,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPMAGIC,
            fn = self:GetSideButtonFn("magic")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_ANIMAL,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPANIMAL,
            fn = self:GetSideButtonFn("animal")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_BOSS,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPBOSS,
            fn = self:GetSideButtonFn("boss")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_FOLLOWER,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPFOLLOWER,
            fn = self:GetSideButtonFn("follower")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_MATERIAL,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPMATERIAL,
            fn = self:GetSideButtonFn("material")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_GIFT,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPGIFT,
            fn = self:GetSideButtonFn("gift")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_RUINS,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPRUINS,
            fn = self:GetSideButtonFn("ruins")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_FARMING,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPFARMING,
            fn = self:GetSideButtonFn("farming")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_EVENT,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPEVENT,
            fn = self:GetSideButtonFn("event")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_ALL,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPALL,
            fn = self:GetSideButtonFn("all")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_COOKING,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPCOOKING,
            fn = self:GetSideButtonFn("cooking")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TOOLS,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPTOOLS,
            fn = self:GetSideButtonFn("tool")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_CLOTHES,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPCLOTHES,
            fn = self:GetSideButtonFn("clothes")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_PUPPET,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPPUPPET,
            fn = self:GetSideButtonFn("puppet")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_BASE,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPBASE,
            fn = self:GetSideButtonFn("base")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_PLANT,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPPLANT,
            fn = self:GetSideButtonFn("plant")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_ORE,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPORE,
            fn = self:GetSideButtonFn("ore")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_DEN,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPDEN,
            fn = self:GetSideButtonFn("den")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_BUILDING,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPBUILDING,
            fn = self:GetSideButtonFn("building")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_SCULPTURE,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPSCULPTURE,
            fn = self:GetSideButtonFn("sculpture")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_NATURAL,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPNATURAL,
            fn = self:GetSideButtonFn("natural")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_YULIUB,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPYULIUB,
            fn = self:GetSideButtonFn("mods")
        }, {
            show = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_OTHER,
            tip = STRINGS.TOO_MANY_ITEMS_UI.SIDEBAR_TIPOTHER,
            fn = self:GetSideButtonFn("others")
        }
    }
    local function u(v)
        local o = _G.TOOMANYITEMS.G_TMIP_CATEGORY_FONT_SIZE;
        if _G.TOOMANYITEMS.UI_LANGUAGE == "en" then o = o * 0.8 end
        local q = -self.owner.shieldsize_x * .5;
        local p = 1;
        local w = self.owner.shieldsize_y * .5;
        local x = self.owner.shieldsize_y * .5;
        local y = 1;
        local z = 1;
        for A = 1, #v do
            local B = self:AddChild(TextBtn())
            B:SetFont(NEWFONT)
            B:SetText(v[A].show)
            B:SetTooltip(v[A].tip)
            B:SetTextSize(o)
            B:SetColour(0.9, 0.8, 0.6, 1)
            B:SetOnClick(v[A].fn)
            local C, D = B.text:GetRegionSize()
            B.image:SetSize(C * 0.9, D)
            if C > self.sidebar_width then self.sidebar_width = C end
            if A == 1 then
                y = C;
                z = D;
                p = (self.owner.shieldsize_y - 80 - 14 * z) / 14
            end
            local E = math.floor(#v / 2 + 0.5)
            if A <= E then
                B:SetPosition(q + y * .5, w - z * .5, 0)
                w = w - z - p
            else
                B:SetPosition(q + p + y * 1.5, x - z * .5, 0)
                x = x - z - p
            end
        end
    end
    u(self.sidebarlists)
end
function j:GetSideButtonFn(F)
    return function()
        TOOMANYITEMS.DATA.listinuse = F;
        TOOMANYITEMS.DATA.issearch = false;
        self:ShowNormal()
        self:SaveData()
    end
end
function j:ShowNormal() self.inventory:TryBuild() end
function j:ShowSearch()
    TOOMANYITEMS.DATA.issearch = true;
    self.inventory.currentpage = 1;
    self.inventory:TryBuild()
end
-- 搜索窗口
function j:InitSearch()
    self.searchbar_width = self.owner.shieldsize_x - 75;
    self.search_fontsize = 26;
    self.searchshield = self:AddChild(a("images/ui.xml", "black.tex"))
    self.searchshield:SetScale(1, 1, 1)
    self.searchshield:SetTint(1, 1, 1, 0.2)
    self.searchshield:SetSize(self.searchbar_width, self.search_fontsize)
    self.searchshield:SetPosition(self.sidebar_width + 5, self.owner
                                      .shieldsize_y * .5 - self.search_fontsize *
                                      .5, 0)
    self.searchbarbutton = self.searchshield:AddChild(TextBtn())
    self.searchbarbutton:SetFont(NEWFONT)
    self.searchbarbutton:SetTextSize(self.search_fontsize)
    self.searchbarbutton:SetColour(0.9, 0.8, 0.6, 1)
    self.searchbarbutton:SetText(STRINGS.TOO_MANY_ITEMS_UI.SEARCH_TEXT)
    self.searchbarbutton:SetTooltip(STRINGS.TOO_MANY_ITEMS_UI.SEARCH_TIP)
    self.searchbarbutton:SetOnClick(function()
        self:Search(TOOMANYITEMS.DATA.search)
    end)
    self.searchbarbutton_width = self.searchbarbutton.text:GetRegionSize()
    self.searchbarbutton.image:SetSize(self.searchbarbutton_width * .9,
                                       self.search_fontsize)
    self.searchbarbutton_posx = self.searchbar_width * .5 -
                                    self.searchbarbutton_width * .5;
    self.searchbarbutton:SetPosition(self.searchbarbutton_posx, 0, 0)
    self.searchtext_limitwidth = self.searchbar_width -
                                     self.searchbarbutton_width;
    self:InitSearchScreen()
    self.searchhelptip = self.searchshield:AddChild(TextBtn())
    self.searchhelptip:SetFont(NEWFONT)
    self.searchhelptip:SetTextSize(self.search_fontsize)
    self.searchhelptip:SetText(STRINGS.TOO_MANY_ITEMS_UI.SEARCHBAR_TEXT)
    self.searchhelptip:SetTooltip(STRINGS.TOO_MANY_ITEMS_UI.SEARCHBAR_TIP)
    self.searchhelptip:SetOnClick(function() self:SearchKeyWords() end)
    self.searchhelptip.text:SetRegionSize(self.searchtext_limitwidth,
                                          self.search_fontsize)
    self.searchhelptip.image:SetSize(self.searchtext_limitwidth * .9,
                                     self.search_fontsize)
    self.searchhelptip:SetPosition(self.searchtext_limitwidth * .5 -
                                       self.searchbar_width * .5, 0, 0)
    self.searchtext = self.searchshield:AddChild(
                          b(NEWFONT, self.search_fontsize))
    self.searchtext:SetColour(0.9, 0.8, 0.6, 1)
    self:SearchTipSet()
end
function j:SearchTipSet()
    if TOOMANYITEMS.DATA.search ~= "" then
        self.searchtext:SetString(TOOMANYITEMS.DATA.search)
        self.searchhelptip:SetColour(0.9, 0.8, 0.6, 0)
        self.searchhelptip:SetOverColour(0.9, 0.8, 0.6, 0)
        local G, H = self.searchtext:GetRegionSize()
        if G > self.searchtext_limitwidth then
            self.searchtext:SetRegionSize(self.searchtext_limitwidth, H)
            self.searchtext:SetPosition(self.searchtext_limitwidth * .5 -
                                            self.searchbar_width * .5, 0, 0)
        else
            self.searchtext:SetPosition(G * .5 - self.searchbar_width * .5, 0, 0)
        end
    else
        self.searchtext:SetString("")
        self.searchhelptip:SetColour(0.9, 0.8, 0.6, 1)
        self.searchhelptip:SetOverColour(0.9, 0.8, 0.6, 1)
    end
end
function j:Search(i)
    if i == TOOMANYITEMS.DATA.search then
        self:ShowSearch()
    else
        local I = h(i)
        if I ~= "" then
            local J = {}
            local K = #TOOMANYITEMS.DATA.searchhistory;
            for A = 1, K do
                local L = TOOMANYITEMS.DATA.searchhistory[A]
                if L ~= I then table.insert(J, L) end
            end
            table.insert(J, I)
            TOOMANYITEMS.DATA.searchhistory = J;
            TOOMANYITEMS.DATA.search = I;
            self:ShowSearch()
        else
            TOOMANYITEMS.DATA.issearch = false;
            TOOMANYITEMS.DATA.search = ""
            self:ShowNormal()
        end
        self:SearchTipSet()
    end
    self:SaveData()
end
function j:InitSearchScreen()
    local function M()
        self.searchhelptip:Hide()
        self.searchtext:Hide()
    end
    local function N(i) if i then self:Search(i) end end
    local function O()
        self.searchhelptip:Show()
        self.searchtext:Show()
    end
    local function P(Q, R)
        if Q == KEY_UP then
            local S = #TOOMANYITEMS.DATA.searchhistory;
            if S > 0 then
                if self.history_idx ~= nil then
                    self.history_idx = math.max(1, self.history_idx - 1)
                else
                    self.history_idx = S
                end
                R:OverrideText(TOOMANYITEMS.DATA.searchhistory[self.history_idx])
            end
        elseif Q == KEY_DOWN then
            local S = #TOOMANYITEMS.DATA.searchhistory;
            if S > 0 then
                if self.history_idx ~= nil then
                    if self.history_idx == S then
                        R:OverrideText("")
                    else
                        self.history_idx = math.min(S, self.history_idx + 1)
                        R:OverrideText(
                            TOOMANYITEMS.DATA.searchhistory[self.history_idx])
                    end
                else
                    self.history_idx = S;
                    R:OverrideText("")
                end
            end
        end
    end
    self.SearchScreenConfig = {
        fontsize = self.search_fontsize,
        size = {self.searchtext_limitwidth, self.search_fontsize},
        isediting = true,
        pos = Vector3(self.owner.shieldpos_x - self.owner.shieldsize_x * .5 +
                          self.searchtext_limitwidth * .5 + self.sidebar_width *
                          3 - 17, self.owner.shieldsize_y * .5 + 15, 0),
        acceptfn = N,
        closefn = O,
        activefn = M,
        rawkeyfn = P
    }
end
function j:SearchKeyWords()
    if self.searchbar then
        self.searchbar:KillAllChildren()
        self.searchbar:Kill()
        self.searchbar = nil
    end
    self.searchbar = e(self.SearchScreenConfig)
    ThePlayer.HUD:OpenScreenUnderPause(self.searchbar)
    if TheFrontEnd:GetActiveScreen() == self.searchbar then
        self.searchbar.edit_text:SetHAlign(ANCHOR_LEFT)
        self.searchbar.edit_text:SetIdleTextColour(0.9, 0.8, 0.6, 1)
        self.searchbar.edit_text:SetEditTextColour(1, 1, 1, 1)
        self.searchbar.edit_text:SetEditCursorColour(1, 1, 1, 1)
        self.searchbar.edit_text:SetTextLengthLimit(200)
        self.searchbar.edit_text:EnableWordWrap(false)
        self.searchbar.edit_text:EnableRegionSizeLimit(true)
        self.searchbar.edit_text:EnableScrollEditWindow(false)
        self.searchbar.edit_text:SetString(TOOMANYITEMS.DATA.search)
        self.searchbar.edit_text.validrawkeys[KEY_UP] = true;
        self.searchbar.edit_text.validrawkeys[KEY_DOWN] = true
    end
end
function j:LoadSearchData()
    if TOOMANYITEMS.DATA.issearch then
        self:Search(TOOMANYITEMS.DATA.search)
    else
        self:ShowNormal()
    end
end
function j:SaveData()
    if TOOMANYITEMS.G_TMIP_DATA_SAVE == 1 then TOOMANYITEMS.SaveNormalData() end
end
function j:OnControl(T, U)
    if j._base.OnControl(self, T, U) then return true end
    return true
end
function j:OnRawKey(Q, U) if j._base.OnRawKey(self, Q, U) then return true end end
return j
