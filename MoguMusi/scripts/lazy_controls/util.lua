-- 视为同类【该页配置强制加载, 不支持模组提示】
-- 我的配置
-- 鹿角、贝壳、小玩具、节日挂饰和彩灯、冬季盛宴零食、万圣节挂饰、石笋、万圣节糖果、孢子、科学家工具、蓝图广告等
-- 不包含：种子、各种蔬菜（有时候只会收一种菜）、各种巨大蔬菜、树
local morph_table = {}
local function generate_list(base_str, start_num, end_num)
    local t = {}
    if not end_num then
        end_num = start_num
        start_num = 1
    end
    for i = start_num, end_num do
        table.insert(t, base_str..tostring(i))
    end
    return t
end

local index = 0
local function add_to_morph_table(config, ...)
        if not GetModConfigData("tony_thesame") then return end
    -- if not config or GetModConfigData(config.."_are_one") then
        for _, list in ipairs({...}) do
            for _, v in ipairs(list) do
                morph_table[v] = index
            end
        end
        index = index + 1
    -- end
end

add_to_morph_table("trinkets", generate_list("trinket_", GLOBAL.NUM_TRINKETS), {"antliontrinket"}) -- Trinkets
morph_table["trinket_6"] = nil -- Exclude Frazzled Wires

add_to_morph_table("shells", generate_list("singingshell_octave", 3, 5)) -- Shells
add_to_morph_table("antlers", generate_list("deer_antler", 3)) -- Antlers
add_to_morph_table("winter_lights", generate_list("winter_ornament_light", 8)) -- Festive Lights
add_to_morph_table("halloween_ornaments", generate_list("halloween_ornament_", GLOBAL.NUM_HALLOWEEN_ORNAMENTS)) -- Halloween Ornaments
add_to_morph_table("halloween_candies", generate_list("halloweencandy_", GLOBAL.NUM_HALLOWEENCANDY)) -- Halloween Candies
add_to_morph_table("winter_foods", generate_list("winter_food", GLOBAL.NUM_WINTERFOOD)) -- Winter Feast Foods

GLOBAL.require("prefabs/winter_ornaments")
local ornaments = GLOBAL.GetAllWinterOrnamentPrefabs()
for i = #ornaments, 1, -1 do
    if ornaments[i]:find("winter_ornament_light") then
        table.remove(ornaments, i)
    end
end
add_to_morph_table("winter_ornaments", ornaments)

local SEEDLESS = {
    berries = true,
    cave_banana = true,
    cactus_meat = true,
    berries_juicy = true,
    kelp = true,
}

-- 如需启用蔬菜, 请取消注释下列内容
if GetModConfigData("tony_thesame") == "plant" then
    local seeds = { "seeds" }
    local farm_plants = { "farm_plant_randomseed" }
    local giant_veggies = {}
    GLOBAL.require("prefabs/veggies")
    for veggiename in pairs(GLOBAL.VEGGIES) do
        if not SEEDLESS[veggiename] then
            table.insert(seeds, veggiename.."_seeds")
            table.insert(farm_plants, "farm_plant_"..veggiename)
            table.insert(giant_veggies, veggiename.."_oversized")
        end
    end
    add_to_morph_table("seeds", seeds)                 -- Seeds
    add_to_morph_table("plants", farm_plants)          -- Planted Veggies
    add_to_morph_table("giant_veggies", giant_veggies) -- Giant Veggies
end


add_to_morph_table("weeds", table.getkeys(require("prefabs/weed_defs").WEED_DEFS)) -- Weeds

-- add_to_morph_table("trees", {"evergreen", "evergreen_sparse", "deciduoustree", "twiggytree"}) -- Trees
add_to_morph_table("spores", {"spore_tall", "spore_medium", "spore_small"}) -- Spores
add_to_morph_table("recipe_papers", {"blueprint", "sketch", "tacklesketch"}) -- Blueprints / Sketches / Adverts

add_to_morph_table("wagstaff_tools", generate_list("wagstaff_tool_", 5)) -- Wagstaff NPC / Grainy Transmission Tools

add_to_morph_table(nil, generate_list("chessjunk", 3)) -- Broken Clockworks
add_to_morph_table(nil, { -- Ancient Statues
    "ruins_statue_head", "ruins_statue_head_nogem", "ruins_statue_mage", "ruins_statue_mage_nogem"
})
add_to_morph_table(nil, { -- Suspicious Moonrocks
    "gargoyle_houndatk", "gargoyle_hounddeath",
    "gargoyle_werepigatk", "gargoyle_werepigdeath", "gargoyle_werepighowl"
})
add_to_morph_table("天体任务的两小鸟儿",{"bird_mutant","bird_mutant_spitter",})
add_to_morph_table("普通宝石",{"redgem", "bluegem", "purplegem",})
add_to_morph_table("珍惜宝石",{"orangegem", "yellowgem", "greengem","opalpreciousgem",})


local stalagmite_morphs = {"full", "med", "low"}
local function add_stalagmite(base_name)
    local t = {base_name}
    for _, v in ipairs(stalagmite_morphs) do
        table.insert(t, base_name .. "_" .. v)
    end
    add_to_morph_table(nil, t)
end

add_stalagmite("stalagmite") -- Stalagmites
add_stalagmite("stalagmite_tall") -- Stalagmites (Tall)


function morph_checker_IsRightItem(a, b)
    local prefab_a = type(a) == "table" and a.prefab or a
    local prefab_b = type(b) == "table" and b.prefab or b
    if prefab_a == prefab_b then
        return true
    end
    local group_id = morph_table[prefab_a]
    return group_id ~= nil and morph_table[prefab_b] == group_id
end

-- 获取容器
function GetDefaultCheckingContainers()
    return ThePlayer and {
        ThePlayer.replica.inventory:GetActiveItem(),
        ThePlayer.replica.inventory,
        ThePlayer.replica.inventory:GetOverflowContainer()
    } or {}
end
-- 获取一个物品从容器
function GetItemFromContainers(containers, item, get_all, test_fn)

    containers = containers or GetDefaultCheckingContainers()
    test_fn = test_fn or morph_checker_IsRightItem

    local final_items = {}

    for _, container in orderedPairs(containers) do
        if type(container) == "table" then
            if is_entity(container) and test_fn(container, item) then
                if get_all then
                    table.insert(final_items, {item = container})
                else
                    containers.__orderedIndex = nil
                    return container
                end
            elseif container.GetItems then
                local items = container:GetItems()
                for i, v in orderedPairs(items) do
                    if test_fn(v, item) then
                        if get_all then
                            table.insert(final_items, {slot = i, item = v, container = container.inst})
                        else
                            items.__orderedIndex = nil
                            containers.__orderedIndex = nil
                            return v, i, container
                        end
                    end
                end
            end
        end
    end
    if get_all and #final_items > 0 then
        return final_items
    end

end