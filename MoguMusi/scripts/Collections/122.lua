-- 强制加载的内容, 不知道写在哪里，就丢在这里了
AddPrefabPostInit("world", function()
    GLOBAL.STRINGS.NAMES["WORM_PLANT"] = GLOBAL.STRINGS.NAMES["WORM"]       -- 修改“神秘植物”为“洞穴蠕虫”
end)
