if not GLOBAL.IsSteam() then
    return
end

local ENV = env
GLOBAL.setfenv(1, GLOBAL)

local ImageButton = require("widgets/imagebutton")
local Button = require "widgets/button"
local Menu = require "widgets/menu"

local QC_STRINGS = {
    LAST_SERVER = "Last Server",
    REJOIN_SERVER = "Rejoin Server"
}

local CHINESE_CODES = {
    "chs",  -- Chinese Mod
    "zh",   -- Simplified Chinese
    "zhr",  -- Simplified Chinese (WeGame)
}
if table.contains(CHINESE_CODES, LanguageTranslator.defaultlang) then
    QC_STRINGS.LAST_SERVER = "快速重连"
    QC_STRINGS.REJOIN_SERVER = "快速重连"
end

local filepath = "mod_config_data/qc_lastserver_save"
local last_server_data = {}
local temp_last_server_data = {}
TheSim:GetPersistentString(filepath, function(load_success, str)
    if load_success then
        local success, savedata = RunInSandboxSafe(str)
        if success and string.len(str) > 0 then
            last_server_data = savedata
        end
    end
end)

local function SaveLastServerData()
    SavePersistentString(filepath, DataDumper(last_server_data, nil, true))
end

local function Connect(ip, port, password)
    if ip and port then
        local start_worked = TheNet:StartClient(ip, port, 0, password)
        if start_worked then
            DisableAllDLC()
        end
    end
end

local function MakeWidgetData(title, ip, port, password)
    return {
        title = title,
        fn = function()
            Connect(ip, port, password)
        end
    }
end

local QC_WIDGET_DATA = {}
local SERVER_DATA = require("qc_server_data")

for _, data in ipairs(SERVER_DATA) do
    table.insert(QC_WIDGET_DATA, MakeWidgetData(unpack(data)))
end

table.insert(QC_WIDGET_DATA, {
    title = QC_STRINGS.LAST_SERVER,
    fn = function()
        if last_server_data.name then
            Connect(last_server_data.ip, last_server_data.port, last_server_data.password)
            print("Connecting last joined server: "..last_server_data.name)
        else
            print("No previous server")
        end
    end
})

ENV.AddClassPostConstruct("screens/redux/mainscreen", function(self)
    for i, v in ipairs(QC_WIDGET_DATA) do
        local btn = self.fixed_root:AddChild(ImageButton("images/frontscreen.xml", "play_highlight.tex"))
        btn.bg = btn:AddChild(Image("images/frontscreen.xml", "play_highlight_hover.tex"))
        btn.bg:SetScale(.345, .265)
        btn.bg:MoveToBack()
        btn.bg:Hide()
        btn:SetPosition(-480, -35 * i - 20)

        btn:SetNormalScale(.325, .25)
        btn:SetFocusScale(.35, .275)

        btn:SetTextColour(WHITE)
        btn:SetTextFocusColour(WHITE)

        btn:SetFont(TITLEFONT)
        btn:SetDisabledFont(TITLEFONT)
        btn:SetTextSize(25)
        btn:SetText(v.title, true)

        local on_gain_focus = btn.OnGainFocus
        btn.OnGainFocus = function()
            on_gain_focus(btn)
            btn:SetTextSize(27)
            btn.image:SetTint(1, 1, 1, 1)
            btn.bg:Show()
        end
        local on_lose_focus = btn.OnLoseFocus
        btn.OnLoseFocus = function()
            on_lose_focus(btn)
            btn:SetTextSize(25)
            btn.image:SetTint(1, 1, 1, .6)
            btn.bg:Hide()
        end
        btn:SetOnClick(v.fn)

        btn:OnLoseFocus()
    end
end)

local function MakeConnectButton(text, onclick)
    local btn = Button()
    btn:SetFont(BUTTONFONT)
    btn:SetDisabledFont(BUTTONFONT)
    btn:SetTextColour(GOLD)
    btn:SetTextFocusColour(WHITE)
    btn:SetText(text, true)
    btn.text:SetRegionSize(180, 40)
    btn.text:SetHAlign(ANCHOR_LEFT)
    btn.text_shadow:SetRegionSize(180, 40)
    btn.text_shadow:SetHAlign(ANCHOR_LEFT)
    btn:SetTextSize(35)

    btn.bg = btn:AddChild(Image("images/ui.xml", "blank.tex"))
    local w, h = btn.text:GetRegionSize()
    btn.bg:ScaleToSize(180, h + 15)

    btn:SetOnClick(onclick)
    return btn
end

local CONNECT_MENU_X = 530
local CONNECT_MENU_Y = 100
ENV.AddClassPostConstruct("screens/redux/multiplayermainscreen", function(self)
    local ConnectMenuItems = {}
    for _, v in ipairs(QC_WIDGET_DATA) do
        table.insert(ConnectMenuItems, {widget = MakeConnectButton(v.title, v.fn)})
    end
    self.connect_menu = self.fixed_root:AddChild(Menu(ConnectMenuItems, 43))
    self.connect_menu:SetPosition(CONNECT_MENU_X, CONNECT_MENU_Y)
end)

local JoinServerResponse = NetworkProxy.JoinServerResponse
NetworkProxy.JoinServerResponse = function(self, bool, guid, password, ...) -- This "bool" should be some thing like wants_cancel
    local should_save = false
    if bool == false and temp_last_server_data.needs_update then
        last_server_data = temp_last_server_data
        last_server_data.password = password ~= "" and password or nil
        should_save = true
    end
    if should_save or last_server_data.needs_rejoin then
        last_server_data.needs_rejoin = nil
        SaveLastServerData()
    end
    return JoinServerResponse(self, bool, guid, password, ...)
end

local join_server = JoinServer
JoinServer = function(server_listing, optional_password_override, ...)
    temp_last_server_data.needs_update = false
    if server_listing.row ~= nil and server_listing.row ~= "" then -- Not sure what "row" actually does
        temp_last_server_data.name = server_listing.name
        temp_last_server_data.ip = server_listing.ip
        temp_last_server_data.port = server_listing.port
        temp_last_server_data.needs_update = true
    end
    return join_server(server_listing, optional_password_override, ...)
end

local should_warn_mods_enabled = Profile.ShouldWarnModsEnabled
Profile.ShouldWarnModsEnabled = function(self, ...) 
    return not last_server_data.needs_rejoin and should_warn_mods_enabled(self, ...)
end

local PopupDialogScreen = require("screens/redux/popupdialog")
local PauseScreen = require("screens/redux/pausescreen")

function PauseScreen:DoConfirmRejoin()
    self.active = false

    local function doquit()
        self.parent:Disable()
        self.menu:Disable()
        last_server_data.needs_rejoin = true
        SaveLastServerData()
        DoRestart(true)
    end

    local confirm = PopupDialogScreen(STRINGS.UI.PAUSEMENU.CLIENTQUITTITLE, STRINGS.UI.PAUSEMENU.CLIENTQUITBODY, {
        {text=STRINGS.UI.PAUSEMENU.YES, cb = doquit},
        {text=STRINGS.UI.PAUSEMENU.NO, cb = function() TheFrontEnd:PopScreen() end}
    })
    if JapaneseOnPS4() then
        confirm:SetTitleTextSize(40)
        confirm:SetButtonTextSize(30)
    end
    TheFrontEnd:PushScreen(confirm)
end

local function get_playerstatusscreen_button(menu)
    for _, btn in ipairs(menu.items) do
        if btn.text:GetString() == STRINGS.UI.PAUSEMENU.PLAYERSTATUSSCREEN then
            return btn
        end
    end
end

ENV.AddClassPostConstruct("screens/redux/pausescreen", function(self)
    if TheNet:GetIsHosting() then return end

    local btn = get_playerstatusscreen_button(self.menu)
    if not btn then return end

    btn:SetText(QC_STRINGS.REJOIN_SERVER)
    btn:SetOnClick(function() self:DoConfirmRejoin() end)
end)

ENV.AddGamePostInit(function()
    if last_server_data.needs_rejoin and not FirstStartupForNetworking then
        Connect(last_server_data.ip, last_server_data.port, last_server_data.password)
    end
end)
