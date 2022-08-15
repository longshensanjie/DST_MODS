-- 导入模组
local function iMod(modlist)
    if type(modlist) ~= "table" then
        modimport("scripts/Collections/" .. modlist .. ".lua")
    else
        for _, modname in pairs(modlist) do
            modimport("scripts/Collections/" .. modname .. ".lua")
        end
    end
end

-- 指定路径导入模组
local function iModPath(modlist)
    if modlist then
        if type(modlist) ~= "table" then
            modimport(modlist)
        else
            for _, pmod in pairs(modlist) do
                modimport(pmod)
            end
        end
    end
end

-- 必要的加载
iMod({"HX_preload",75,20,117,122})

-- 检查模组列表
local function isInlist(modlist)
    if type(modlist) ~= "table" then
        return HasModName(modlist)
    end
    for _, modname in pairs(modlist) do
        local conModName = HasModName(modname)
        if conModName then
            return conModName
        end
    end
    return false
end

-- 检查配置列表
local function isallConfig(tConfig)
    if type(tConfig) ~= "table" then
        return GetModConfigData(tConfig)
    end
    for _, cig in pairs(tConfig) do
        if not GetModConfigData(cig) then
            return false
        end
    end
    return true
end
-- 部署模组
local function setupMod(tConfig, banMod, iModlist, telse)
    -- 配置开关为关
    if not isallConfig(tConfig) then
        return
    end
    -- 冲突模组
    local conModName = isInlist(banMod)
    if conModName then
        -- 冲突的模组应该这么记录，注意：只有开启智能模组才能保存相关数据
        -- table.insert(ban_list, {banMod[1], conModName})          -- 我们不需要指出哪些mod关闭了哪些功能
        local banName = type(banMod) ~= "table" and banMod or banMod[1]
        if not table.contains(MUSHROOM_con_mod_list, conModName) then
            table.insert(MUSHROOM_con_mod_list, conModName)
        end
        if not table.contains(MUSHROOM_ban_list, banName) then
            table.insert(MUSHROOM_ban_list, banName)
        end
        return
    end
    -- 优先引入的模组
    iModPath(telse)
    -- 正常引入的模组
    iMod(iModlist)
end
local DebugerMod = GetModConfigData("sw_debugger")
if DebugerMod then
    -- 适配错误追踪
    bugtracker_config = {
        email = "hanhuxi@qq.com",
        upload_client_log = true,
        upload_server_log = true
    }
end

iModPath("modtable.lua")
-- 和这些模组冲突, 本模组会自动关闭
if isInlist(ShroomCakeBanMods) then
    return
end

local dearBtns = require "utilclass/dear_btns"
DEAR_BTNS = dearBtns()

for _, amodconfig in pairs(ShroomCakeModsTable) do
    setupMod(amodconfig[1], amodconfig[2], amodconfig[3], amodconfig[4])
end
