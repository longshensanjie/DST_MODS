local function saveTheworld()
    local world_key = "MODS_INFO" -- 根据世界种子判断, 洞穴不提示就行了
    local data = LoadModData(world_key)
    SaveModData(world_key, {
        off_func = MUSHROOM_ban_list,
        con_mods = MUSHROOM_con_mod_list
    })
end

local content = ""
local PDS = GLOBAL.require "screens/redux/popupdialog"
local function showme()
    local data = LoadModData("MODS_INFO")
    if not data then
        TIP("功能冲突", "green", "没有冲突, 纵享丝滑")
        return
    end
    local ban_list = data.off_func
    local con_mod_list = data.con_mods
    if not ban_list or #ban_list == 0 or not con_mod_list or #con_mod_list == 0 then
        TIP("功能冲突", "green", "没有冲突, 纵享丝滑")
        return
    end
    local content = "这些功能已经帮你关闭：\n"

    if table.contains(AuthorizationMods, modname) then
        content = content .. table.concat(ban_list, "、")
        content = content .. "\n\n原因是服务器或本地启用了这些模组：\n"
        content = content .. table.concat(con_mod_list, "、")
    else
        content = "友情提醒：你订阅的是盗版蘑菇慕斯,请更新再试"
    end

    local title = modname == "shroomcake" and "蘑菇慕斯 󰀜 测试版" or "蘑菇慕斯 󰀜 智能模组"
    local pds = PDS(title, content, {{
        text = "我知道了",
        cb = function()
            GLOBAL.TheFrontEnd:PopScreen()
        end
    }, 
}, nil, "big", "dark_wide")
    print("*******************智能模组欢迎你********************")
    print(content)
    print("*******************智能模组结束********************")
    print("世界种子",GetWorldSeed())
    print("玩家种子",GetPlayerSeed())
    pds.dialog.body:EnableWordWrap(false)
    GLOBAL.TheFrontEnd:PushScreen(pds)
end


DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("quagmire_coin4.tex"), "quagmire_coin4.tex", "功能冲突", "查询自动关闭的功能", true, showme)


AddPrefabPostInit("world", function(inst)
    inst:DoTaskInTime(0.5, saveTheworld)
end)
