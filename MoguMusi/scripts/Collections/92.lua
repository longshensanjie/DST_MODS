
-- 写点啥好呢
local function forEach(t, fn)
    for _, v in pairs(t) do
        if v then
            fn(v)
        end
    end
end

local Animals = { -- {                                                            -- 这是一个样例
--     prefabs = {"tallbird","teenbird"},
--     details = 
--         {
--             {
--                 fn = IsValid,                                        
--                 rotary = {
--                     {"red", TUNING.TALLBIRD_ATTACK_RANGE}, 
--                 },
--             },
--         },
-- },
{ -- 邪恶红
    prefabs = {"ghost", "beeguard", "ink", "bat"},
    details = {{
        rotary = {{"red", 1.5}}
    }}
}, { -- 墨汁黑
    prefabs = {"ink", "spider_water"},
    details = {{
        rotary = {{"black", 2}}
    }}
}, { -- 邪恶红
    prefabs = {"slurtle"},
    details = {{
        rotary = {{"red", 2.5}}
    }}
}, { -- 邪恶红
    prefabs = {"tallbird", "teenbird", "lightninggoat", "tentacle_pillar_arm", "monkey", "slurtle", "worm", "krampus",
               "crawlingnightmare", "nightmarebeak", "deer_blue", "deer_red", "lavae", "birchnutdrake", "crabking_claw",
               "moonpig", "houndcorpse", "hound", "icehound", "firehound", "matutehound", "clayhound", "spider_healer",
               "spider_moon", "spider_dropper", "spider", "spider_warrior", "spider_hider", "spider_spitter",
               "archive_centipede", "pigguard", "mermguard","leif","leif_sparse"},
    details = {{
        rotary = {{"red", 3}}
    }}
}, { -- 中立蓝
    prefabs = {"koalefant_summer", "koalefant_winter", "grassgator", "beefalo", "pigman"},
    details = {{
        rotary = {{"blue", 3}}
    }}
}, { -- 月岛棕
    prefabs = {"fruitdragon", "gnarwail"},
    details = {{
        rotary = {{"brown", 3}}
    }}
}, { -- 青蛙白
    prefabs = {"frog", "bunnyman", "merm"},
    details = {{
        rotary = {{"white", 3}}
    }}
}, { -- 触手绿
    prefabs = {"tentacle", "rocky", "eyeofterror_mini", "catcoon"},
    details = {{
        rotary = {{"green", 4}}
    }}
}, { -- 邪恶红
    prefabs = {"slurper"},
    details = {{
        rotary = {{"red", 8}}
    }}
}, { -- 海象双
    prefabs = {"walrus"},
    details = {{
        rotary = {{"red", 15}, {"blue", 10}}
    }}
}, {
    prefabs = {"bishop", "bishop_nightmare"},
    details = {{
        rotary = {{"blue", 10}, {"red", 12}}
    }}
}, {
    prefabs = {"rook", "rook_nightmare"},
    details = {{
        rotary = {{"blue", 10}, {"red", 3}},
    }}
}, {
    prefabs = {"knight", "knight_nightmare"},
    details = {{
        rotary = {{"blue", 8.5}, {"red", 3}},
    }}
}}

local function fn(animal, prefab)
    AddPrefabPostInit(prefab, function(inst)
        forEach(animal.details, function(detail)
            if not detail.fn or (detail.fn)() then
                forEach(detail.rotary, function(item)
                    local a = GLOBAL.SpawnPrefab("hrange")
                    a.entity:SetParent(inst.entity)
                    a:SetColour(item[1])
                    a:SetRadius(item[2])
                end)
            end
        end)
    end)
end

forEach(Animals, function(Animal)
    if type(Animal.prefabs) == "table" then
        forEach(Animal.prefabs, function(prefab)
            fn(Animal, prefab)
        end)
    else
        fn(Animal, Animal.prefabs)
    end
end)
