local _G = GLOBAL
if not _G.IsSteam() then
    return
end


local TEMPLATES = _G.require "widgets/redux/templates"
local mainscreen = _G.require "screens/mainuiscreen"
local savebutton = _G.require "widgets/savebutton"


local cm_strings = {}
cm_strings.connect = "直连"
cm_strings.back = "返回"
cm_strings.ok = "确定"
cm_strings.panel = "保存的服务器"
cm_strings.addnew = "新建"
cm_strings.delete_ask = "确定要删除此连接吗？"
cm_strings.delete = "删除" 
cm_strings.delete_no = "手滑了"
cm_strings.delete_hover = "删除该连接"
cm_strings.configure_hover = "配置该连接"
cm_strings.new_connection = "新建一个连接"
cm_strings.default = "默认"
cm_strings.ip_emtpy = "服务器的IP地址不能留空！"
cm_strings.fine = "好吧"
cm_strings.connect_to = "连接到该服务器"
cm_strings.server_name = "服务器名称："
cm_strings.server_ip = "IP地址："
cm_strings.setip = "设置该连接的IP地址"
cm_strings.server_note = "备注："
cm_strings.addnote = "为该连接添加备注"
cm_strings.server_port = "端口："
cm_strings.set_port = "设置该连接的端口，不填则使用默认端口"
cm_strings.server_password = "密码："
cm_strings.set_password = "设置该连接的端口，无密码则留空"
cm_strings.notitle = "无标题"
cm_strings.ip_existing = "该IP地址已存在！"
cm_strings.no_reset = "请勿重复设置"
cm_strings.server_existing = "该服务器已存在！"
cm_strings.save_success = "保存成功！"
cm_strings.fail_get = "无法获取服务器信息"
cm_strings.save_to = "保存该服务器到蘑菇慕斯直连管理器"

GLOBAL.STRINGS.MANAGER = cm_strings

_G.FASTCONNECT = {
    DATA_FILE = "mod_config_data/connections_list_save.lua",
    DATA = {},
    TEMP_FILE = "mod_config_data/connections_list_temp.lua",
    TEMP = {}
}

-- 载入数据fn（摘自霄征“基地扫描仪”）
_G.FASTCONNECT.LoadData = function(filepath)
    local data = nil
    _G.TheSim:GetPersistentString(filepath, function(load_success, str)
        if load_success == true then
            local success, savedata = _G.RunInSandboxSafe(str)
            if success and string.len(str) > 0 then
                data = savedata
            else
                print("[FC] Could not load " .. filepath)
            end
        else
            print("[FC] Can not find " .. filepath)
        end
    end)
    return data
end

-- 保存数据到外部文件
_G.FASTCONNECT.SaveData = function()
    _G.SavePersistentString(_G.FASTCONNECT.DATA_FILE,
                            _G.DataDumper(_G.FASTCONNECT.DATA, nil, true),
                            false, nil)
end

-- 保存临时数据到外部文件
_G.FASTCONNECT.SaveTemp = function()
    _G.SavePersistentString(_G.FASTCONNECT.TEMP_FILE,
                            _G.DataDumper(_G.FASTCONNECT.TEMP, nil, true),
                            false, nil)
end

-- 载入数据
local list = _G.FASTCONNECT.LoadData(_G.FASTCONNECT.DATA_FILE) or {}
mainscreen:SetData(list, _G.FASTCONNECT)

-- 载入临时数据
local temp = _G.FASTCONNECT.LoadData(_G.FASTCONNECT.TEMP_FILE) or {}
savebutton:SetData(temp)

-- 添加主按键	2020.9.15
local function addmainbutton(self)
    local main_button = TEMPLATES.IconButton("images/button_icons.xml",
                                             "join.tex",
                                             _G.STRINGS.MANAGER.connect, false,
                                             true, function()
        _G.TheFrontEnd:PushScreen(mainscreen())
    end, {font = _G.NEWFONT_OUTLINE})
    self.submenu:AddCustomItem(main_button)
    self.submenu:Nudge(_G.Vector3(-self.submenu.offset / 2, 0, 0))
end
AddClassPostConstruct("screens/redux/multiplayermainscreen", addmainbutton)

-- 添加游戏内的保存按键
local function addsavebutton(self)
    local old_DoInit = self.DoInit
    function self:DoInit(...)
        old_DoInit(self, ...)
        if not _G.TheInput:ControllerAttached() then
            self.savebutton = self.root:AddChild(savebutton(mainscreen))
            -- self.savebutton:SetHAnchor(0) -- 这会使widget固定到屏幕上特定的位置，不会随分辨率变化
            -- self.savebutton:SetVAnchor(0) 
            self.savebutton:SetPosition(0, 0, 0)
        end
    end
end
AddClassPostConstruct("screens/playerstatusscreen", addsavebutton)

-- 修改加入服务器时的函数
local old_JoinServer = _G.JoinServer
_G.JoinServer = function(server_listing, optional_password_override, ...)
    old_JoinServer(server_listing, optional_password_override, ...)

    -- 保存临时数据
	--[[print("[join Server]")
	for key, value in pairs(server_listing) do
		print("" .. key .. " ")
	end]]
    _G.FASTCONNECT.TEMP[1] = {}
    _G.FASTCONNECT.TEMP[1].name = server_listing.name
    _G.FASTCONNECT.TEMP[1].ip = server_listing.ip
    _G.FASTCONNECT.TEMP[1].port = server_listing.port
    _G.FASTCONNECT.TEMP[1].password = (server_listing.has_password and optional_password_override) or ""
    _G.FASTCONNECT.SaveTemp()

    -- 更新服务器信息
    for k, v in pairs(mainscreen.list) do
        if v.ip == server_listing.ip then
            v.name = server_listing.name
            v.port = server_listing.port
            mainscreen:SaveList()
            break
        end
    end
end
