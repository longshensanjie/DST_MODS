local food_recipes = require("cooking").recipes
local str_buff_table = require("QAQ/bt_buffs")
local str_boss_table = require("QAQ/bt_bosses")
local Mod_Huxi = "ModData_MushRoomCake"
local SAVE_STYLE = "HuxiStyle"
local SaveData = require("persistentdata")
local ModDataContainer = SaveData(Mod_Huxi)            -- 样式风格为永久保存
local Connect_Seed = ""
local Announce_Way = "boss_spawn"

local function SetConnectSeed(seed)
    Connect_Seed = seed
end


local function str_contains(str, item)
    local t = {}
    local l = {}
    local index = 0
    for i = 1, string.len(str) do
        table.insert(t, string.byte(string.sub(str, i, i)))
    end

    for i = 1, string.len(item) do
        table.insert(l, string.byte(string.sub(item, i, i)))
    end
    if #l > #t then
        return false
    end

    for k, v1 in pairs(t) do
        index = index + 1
        if v1 == l[1] then
            local iscontens = true
            for i = 1, #l do
                if t[index + i - 1] ~= l[i] then
                    iscontens = false
                end
            end
            if iscontens then
                return iscontens
            end
        end
    end
    return false
end

local function GetFoodBuffForPrefab(foodname)
    -- 一个食物可能含有多个buff
    -- buff数据需要从三方面获取
    -- 1、玩家字符串匹配（提供数据接口）
    -- 2、官方或者mod定义的buff
    -- 3、温度BUFF（虽然没什么用，但是可以提高存在感）【从官方获取】
    local BUFFS = {}
    -- 1、玩家字符串匹配（提供数据接口）
    for str_buff_id,str_buff in pairs(str_buff_table)do
        for _, buff_judge in pairs(str_buff.judge)do
            if str_contains(foodname, buff_judge) then
                BUFFS[str_buff_id]= str_buff_table[str_buff_id]
                -- BUFFS = {
                --      buff1_id = {
                        --     image = "cane", 
                        --     duration = total_day_time / 2,
                        --     judge = {"coffee"},
                        --     describe = "咖啡",
                        -- },
                -- }
            end
        end
    end
    -- 2、之后的数据会替代之前的数据, 因为自定义的没有从官方查代码的准
    local food_item
    for _,food_items in pairs(food_recipes) do
		if food_items[foodname] then
			food_item = food_items[foodname]
            -- food_item = {
            --     test = function(cooker, names, tags) return names.royal_jelly and not tags.inedible and not tags.monster end,
            --     priority = 12,
            --     foodtype = FOODTYPE.GOODIES,
            --     health = TUNING.JELLYBEAN_TICK_VALUE,
            --     hunger = 0,
            --     perishtime = nil, -- not perishable
            --     sanity = TUNING.SANITY_TINY,
            --     cooktime = 2.5,
            --     potlevel = "low",
            --     tags = {"honeyed"},
            --     stacksize = 3,
            --     prefabs = { "healthregenbuff" },
            --     oneat_desc = STRINGS.UI.COOKBOOK.FOOD_EFFECTS_HEALTH_REGEN,
            --     oneatenfn = function(inst, eater)
            --         eater:AddDebuff("healthregenbuff", "healthregenbuff")
            --     end,
            --     floater = {"small", nil, 0.85},
            -- },
			break
		end
	end

    if food_item then
        -- 2、官方BUFF
        if food_item.prefabs then
            for _,buff_name in pairs(food_item.prefabs) do
                BUFFS[buff_name] = str_buff_table[buff_name]
            end
        end

        -- 3、温度BUFF（虽然没什么用，但是可以提高存在感）【从官方获取】
        if type(food_item.temperature) == "number" and type(food_item.temperatureduration) == "number" then
            if food_item.temperature > 0 then
                BUFFS.buff_hot = str_buff_table.buff_hot
                BUFFS.buff_hot.duration = food_item.temperatureduration
            else
                BUFFS.buff_cold = str_buff_table.buff_cold
                BUFFS.buff_cold.duration = food_item.temperatureduration
            end
        end
    end

    -- 将BUFFS整理返回
    local buffs_for_food = {}
    for buffname, buff in pairs(BUFFS)do
        table.insert(buffs_for_food, {name = buffname, image = buff.image, duration = buff.duration, describe = buff.describe})
    end

    return buffs_for_food
    -- {
    --     {
    --         name = "buff_cold",
    --         image = "icehat",
    --         duration = 5,
    --         describe = "清凉",
    --     },{},...{},
    -- }
end



local function GetBuffAndBoss()
    ModDataContainer:Load()
    return ModDataContainer:GetValue(Connect_Seed)
end

local function GetBossData(boss_name)
    if not str_boss_table[boss_name] then 
        print("非法查询BOSS数据", boss_name)
        return
    end
    local data = GetBuffAndBoss()
    str_boss_table[boss_name].name = boss_name
    if data and data.boss then
        for boss_name, boss_data in pairs(data.boss)do
            if boss_data.duration then
                str_boss_table[boss_name].duration = boss_data.duration
            end
        end
    end
    return str_boss_table[boss_name]
end

local function GetBuffData(buff_name)
    if not str_buff_table[buff_name] then 
        print("非法查询BUFF数据", buff_name)
        return
    end
    str_buff_table[buff_name].name = buff_name
    return str_buff_table[buff_name]
end

local function GetBossAnim()
    local t = {}
    for boss_name,boss_data in pairs(str_boss_table)do
        table.insert(t, {name = boss_name, anims = boss_data.judge, alias = boss_data.alias or boss_name})
    end
    return t
end

local function GetHuxiStyle()
    ModDataContainer:Load()
    return ModDataContainer:GetValue(SAVE_STYLE) or "all"
end

local function SetHuxiStyle(style)
    ModDataContainer:SetValue(SAVE_STYLE, style)
    ModDataContainer:Save()
end

local function SaveBuffAndBoss(data)
    ModDataContainer:SetValue(Connect_Seed, data)
    ModDataContainer:Save()
end

local function GetAnnounceWay()
    return Announce_Way
end

local function SetAnnounceWay(ann_way)
    Announce_Way = ann_way
end

return {
    GetFoodBuffForPrefab = GetFoodBuffForPrefab,        -- 从食物中提取buff
    GetBossData = GetBossData,                          -- 获取BOSS对应数据
    GetBuffData = GetBuffData,                          -- 获取BUFF对应数据
    GetBossAnim = GetBossAnim,                           -- 只获取生物及其生物动画
    GetStyle = GetHuxiStyle,                             -- 获取样式
    SetStyle = SetHuxiStyle,                            -- 设置呼吸栏样式
    SetSeed = SetConnectSeed,                           -- 设置世界种子
    Save = SaveBuffAndBoss,                               -- 储存数据
    Load = GetBuffAndBoss,                                -- 读取数据
    GetAnn = GetAnnounceWay,                             -- 获取宣告
    SetAnn = SetAnnounceWay,                              -- 设置宣告方式
}