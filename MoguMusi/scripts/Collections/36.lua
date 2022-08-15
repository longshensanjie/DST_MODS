local _G = GLOBAL;
if _G.TheNet and
    (_G.TheNet:GetIsServer() and _G.TheNet:GetServerIsDedicated() or
        _G.TheNet:GetIsClient() and not _G.TheNet:GetIsServerAdmin()) then return end
        
_G.TOOMANYITEMS = {
    DATA_FILE = "mod_config_data/toomanyitemsplus_data_save",
    TELEPORT_DATA_FILE = "mod_config_data/",
    CHARACTER_USERID = "",
    TELEPORT_TEMP_TABLE = {},
    TELEPORT_TEMP_INDEX = 1,
    DATA = {},
    TELEPORT_DATA = {},
    LIST = {},
    MODSATLAS = {},
    UI_LANGUAGE = "en",
    G_TMIP_LANGUAGE = "chs",
    G_TMIP_TOGGLE_KEY = GetModConfigData("GOP_TMIP_TOGGLE_KEY") or 116,
    G_TMIP_L_CLICK_NUM = 1,
    G_TMIP_R_CLICK_NUM = 10,
    G_TMIP_DATA_SAVE = 1,
    G_TMIP_SEARCH_HISTORY_NUM = 10,
    G_TMIP_CATEGORY_FONT_SIZE = GetModConfigData("GOP_TMIP_CATEGORY_FONT_SIZE") or 24,
    G_TMIP_DEBUG_FONT_SIZE = GetModConfigData("GOP_TMIP_DEBUG_FONT_SIZE") or 24,
    G_TMIP_DEBUG_MENU_SIZE = GetModConfigData("GOP_TMIP_DEBUG_MENU_SIZE") or 550,
    G_TMIP_MOD_ROOT = MODROOT
}
if _G.TOOMANYITEMS.G_TMIP_DATA_SAVE == -1 then
    local a = _G.TOOMANYITEMS.DATA_FILE;
    _G.TheSim:GetPersistentString(a, function(b, c)
        if b then _G.ErasePersistentString(a, nil) end
    end)
elseif _G.TOOMANYITEMS.G_TMIP_DATA_SAVE == 1 then
    _G.TOOMANYITEMS.LoadData = function(a)
        local d = nil;
        _G.TheSim:GetPersistentString(a, function(b, c)
            if b == true then
                local e, f = _G.RunInSandboxSafe(c)
                if e and string.len(c) > 0 then
                    d = f
                else
                    print("[T键控制台] 无法加载 " .. a)
                end
            else
                -- print("[T键控制台] 未能找到 " .. a)
            end
        end)
        return d
    end;
    _G.TOOMANYITEMS.SaveData = function(a, d)
        if d and type(d) == "table" and a and type(a) == "string" then
            _G.SavePersistentString(a, _G.DataDumper(d, nil, true), false, nil)
        end
    end;
    _G.TOOMANYITEMS.SaveNormalData = function()
        _G.TOOMANYITEMS
            .SaveData(_G.TOOMANYITEMS.DATA_FILE, _G.TOOMANYITEMS.DATA)
    end
end
local STRINGS = _G.STRINGS;
STRINGS.TOO_MANY_ITEMS_UI = {}
local function h()
    _G.TOOMANYITEMS.UI_LANGUAGE = "cn"
    modimport("languages/TMIP_cn.lua")
end
local function m()
    if _G.TOOMANYITEMS.G_TMIP_DATA_SAVE == 1 then
        _G.TOOMANYITEMS.DATA = _G.TOOMANYITEMS.LoadData(_G.TOOMANYITEMS
                                                            .DATA_FILE)
    end
    if _G.TOOMANYITEMS.DATA == nil then _G.TOOMANYITEMS.DATA = {} end
    if _G.TOOMANYITEMS.MODSATLAS == nil then _G.TOOMANYITEMS.MODSATLAS = {} end
    _G.TOOMANYITEMS.DATA.IsSettingMenuShow = false;
    _G.TOOMANYITEMS.DATA.IsTipsMenuShow = false;
    if _G.TOOMANYITEMS.DATA.IsDebugMenuShow == nil then
        _G.TOOMANYITEMS.DATA.IsDebugMenuShow = false
    end
    if _G.TOOMANYITEMS.DATA.listinuse == nil then
        _G.TOOMANYITEMS.DATA.listinuse = "all"
    end
    if _G.TOOMANYITEMS.DATA.search == nil then
        _G.TOOMANYITEMS.DATA.search = ""
    end
    if _G.TOOMANYITEMS.DATA.issearch == nil then
        _G.TOOMANYITEMS.DATA.issearch = false
    end
    if _G.TOOMANYITEMS.DATA.searchhistory == nil then
        _G.TOOMANYITEMS.DATA.searchhistory = {}
    else
        local n = #_G.TOOMANYITEMS.DATA.searchhistory;
        local o = n - _G.TOOMANYITEMS.G_TMIP_SEARCH_HISTORY_NUM;
        if o > 0 then
            local p = {}
            for q = o + 1, n do
                table.insert(p, _G.TOOMANYITEMS.DATA.searchhistory[q])
            end
            _G.TOOMANYITEMS.DATA.searchhistory = p
        end
    end
    if _G.TOOMANYITEMS.DATA.customitems == nil then
        _G.TOOMANYITEMS.DATA.customitems = {}
    end
    if _G.TOOMANYITEMS.DATA.currentpage == nil then
        _G.TOOMANYITEMS.DATA.currentpage = {}
    end
    _G.TOOMANYITEMS.LIST = _G.require "TMIP/prefablist"
    if _G.TOOMANYITEMS.DATA.xxd == nil or _G.TOOMANYITEMS.DATA.xxd <= 0 then
        _G.TOOMANYITEMS.DATA.xxd = 1
    end
    if _G.TOOMANYITEMS.DATA.syd == nil or _G.TOOMANYITEMS.DATA.syd <= 0 then
        _G.TOOMANYITEMS.DATA.syd = 1
    end
    if _G.TOOMANYITEMS.DATA.fuel == nil or _G.TOOMANYITEMS.DATA.fuel <= 0 then
        _G.TOOMANYITEMS.DATA.fuel = 1
    end
    if _G.TOOMANYITEMS.DATA.temperature == nil then
        _G.TOOMANYITEMS.DATA.temperature = 25
    end
    if _G.TOOMANYITEMS.DATA.SPAWN_ITEMS_TIPS == nil then
        _G.TOOMANYITEMS.DATA.SPAWN_ITEMS_TIPS = true
    end
    if _G.TOOMANYITEMS.DATA.SHOW_CONFIRM_SCREEN == nil then
        _G.TOOMANYITEMS.DATA.SHOW_CONFIRM_SCREEN = true
    end
    if _G.TOOMANYITEMS.DATA.ADVANCE_DELETE == nil then
        _G.TOOMANYITEMS.DATA.ADVANCE_DELETE = false
    end
    if _G.TOOMANYITEMS.DATA.deleteradius == nil then
        _G.TOOMANYITEMS.DATA.deleteradius = 10
    end
    if _G.TOOMANYITEMS.DATA.ThePlayerUserId == nil then
        _G.TOOMANYITEMS.DATA.ThePlayerUserId = _G.ThePlayer.userid
    end
end
local controls
local function t(self)
    controls = self;
    m()
    local u = _G.require "widgets/TooManyItemsPlus"
    if controls and controls.containerroot then
        controls.TMI = controls.containerroot:AddChild(u())
    else
        print("[T键控制台] AddClassPostConstruct errors!")
        return
    end
    controls.TMI.IsTooManyItemsMenuShow = false;
    controls.TMI:Hide()
end

local function A()
    if InGame() then
        if controls and controls.TMI then
            if controls.TMI.IsTooManyItemsMenuShow then
                controls.TMI:Hide()
                controls.TMI.IsTooManyItemsMenuShow = false
            else
                controls.TMI:Show()
                controls.TMI.IsTooManyItemsMenuShow = true
            end
        else
            print("[T键控制台] Menu can not show!")
            return
        end
    end
end
h()
AddClassPostConstruct("widgets/controls", t)
_G.TheInput:AddKeyUpHandler(_G.TOOMANYITEMS.G_TMIP_TOGGLE_KEY, A)

