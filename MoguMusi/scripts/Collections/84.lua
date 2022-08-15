-- 自动加燃料/修装备
-- 修改自群友 7_Sloth, 原版是V键给旺达的表加燃料
local _G = GLOBAL
local JudgeValue = 80

---------------------------------------------
local sewtable = {"bernie_active","featherhat", "tophat", "walterhat", "goggleshat", "deserthat", "moonstorm_goggleshat", "catcoonhat",
                  "earmuffshat", "winterhat", "walrushat", "beefalohat", "rainhat", "eyebrellahat", "trunkvest_summer",
                  "raincoat", "sweatervest", "trunkvest_winter", "beargervest", "reflectivevest", "armorslurper",
                  "carnival_vest_a", "carnival_vest_b", "carnival_vest_c", "dragonheadhat", "dragonbodyhat",
                  "dragontailhat","heatrock","monkey_mediumhat", "monkey_smallhat",}

local feedtable = {"eyemaskhat", "shieldofterror"}

-- 模组适配
local REPAIR_BONE_table = {"bone_blade", "bone_whip", "bone_wand"}
local myth_repair_table = {"mk_battle_flag_item", "xzhat_mk", "cassock", "kam_lan_cassock"}
local musha_table1 = {"phoenixspear", "mushasword_frost", "mushasword4", "frosthammer", "bowm", "hat_mphoenix",
                      "armor_mushab", "broken_frosthammer", "hat_mbunnya", "hat_mwildcat","pirateback"}
local musha_table2 = {"musha_flute"}
local yuanzi_table = {"yuanzi_spear_lv1","yuanzi_spear_lv2","yuanzi_armor_lv1","yuanzi_armor_lv2"}
local no_rich_table = {"ndnr_armorvortexcloak"}
-------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

local function AddFuelAct(item, fuel)
    if item == nil or fuel == nil then
        return
    end
    -- 添加燃料
    local actions = fuel:GetIsWet() and _G.ACTIONS.ADDWETFUEL or _G.ACTIONS.ADDFUEL
    -- 喂养
    if table.contains(feedtable, item.prefab) then
        actions = _G.ACTIONS.FEED
    end
    -- 缝纫
    if table.contains(sewtable, item.prefab) then
        actions = _G.ACTIONS.SEW
    end
    if table.contains(myth_repair_table, item.prefab) then
        actions = _G.ACTIONS.SEW
    end
    -- 神话白骨
    if table.contains(REPAIR_BONE_table, item.prefab) then
        actions = _G.ACTIONS.REPAIR_BONE
    end
    -- 乃木圆子
    if table.contains(yuanzi_table, item.prefab) then
        actions = _G.ACTIONS.GIVE
    end

    SendRPCAtoB(_G.RPC.ControllerUseItemOnItemFromInvTile, actions, fuel, item)
end

local function getPerc(inst)
    if inst and inst.replica and inst.replica._ and inst.replica._.inventoryitem and
        inst.replica._.inventoryitem.classified then
        return inst.replica._.inventoryitem.classified.percentused:value()
    else
        return 100
    end
end

local mytable = { -- 放在前面的优先
-- 模组适配 - 精灵公主
{musha_table1,
 {"stinger","houndstooth","spidergland","rocks","flint","silk", "boneshard", "nitre", "goldnugget",
  "marble", "moonrocknugget","thulecite_pieces","thulecite",}}, {musha_table2, {"lightbulb","glowdust",}},
-- 模组适配 - 神话书说
{REPAIR_BONE_table, {"boneshard"}}, {{"nz_damask"}, {"myth_lotus_flower"}},
{myth_repair_table, {"sewing_tape", "sewing_kit"}},
-- 模组适配 - 富贵险中求
{no_rich_table, {"nightmarefuel"}},
 -- 本体
{{"pocketwatch_weapon"}, {"nightmarefuel"}}, {feedtable, {"monstermeat", "spoiled_food", "rock_avocado_fruit_ripe"}},
{{"lantern", "minerhat"}, {"lightbulb", "slurtleslime", "fireflies"}},
{{"armorskeleton", "yellowamulet", "thurible"}, {"nightmarefuel"}}, {sewtable, {"sewing_tape", "sewing_kit"}},
{{"molehat"}, {"wormlight", "wormlight_lesser"}},
-- 模组适配 - 乃木圆子
{yuanzi_table, {"yuanzi_flyknife"}}
}

local lasttime = -3

local function fn()
    if not InGame() then
        return
    end
    local flag = true
    for k_table, v_table in pairs(mytable) do
        for _, ea in pairs(v_table[1]) do
            local es = GetItemsFromAll(ea)
            for _, e in pairs(es) do
                if getPerc(e) < JudgeValue then
                    for _, theFuel in pairs(v_table[2]) do
                        local fs = GetItemsFromAll(theFuel)
                        if fs and fs[1] then
                            AddFuelAct(e, fs[1])
                            TIP(fs[1].name .. " 修复 " .. e.name, "pink", getPerc(e) .. "%", "head")
                            return
                        end
                    end
                end
            end
        end
    end

    if GLOBAL.GetTime() - lasttime > 3 then
        TIP("修复装备", "pink", "修复完成", "head")
        lasttime = GLOBAL.GetTime()
    end
end

_G.TheInput:AddKeyDownHandler(GetModConfigData("sw_manualAdd"), fn)
