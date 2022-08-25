name = "背包熊"
description = "一个会偷吃东西的小熊背包"
author = "西风"
version = "1.0.1"

-- 这里的字符串是科雷官方论坛一个板块一个id
forumthread = ""

-- api_version = 6  这是单机版的api代码
-- dst_api_version = 10  这是联机版api代码，如果需要开启单机版的兼容必须添加上上一行单机兼容代码和这一行联机版兼容代码
dont_starve_compatible = true  -- 单机版
reign_of_giants_compatible = true  -- 巨人国
shipwrecked_compatible = true -- 海难
dst_compatible = true  -- 联机版
client_only_mod = false  -- 仅适用于联机版
server_only_mod = true   -- 仅适用于联机版
all_clients_require_mod = true  -- 仅适用于联机版


icon_atlas = "backcub.xml"  -- 模组图标配置文件
icon = "backcub.tex"    -- 模组图标文件

server_filter_tags = {}    -- 服务器标签 仅适用联机版
--[[ configuration_options = {
    {
        name = "采集倍数",
        label = "采集倍数",
        options = {
            {description = "默认", data = 1},
            {description = "2倍", data = 2},
            {description = "4倍", data = 4},
            {description = "8倍", data = 8},
            {description = "16倍", data = 16},
            {description = "32倍", data = 32}
        },
        default = 1,
    }
}   -- 模组变量配置
--]]
priority = 0            -- 模组优先级 0 - 10 加载的顺序 0最后载入覆盖前面(相同的功能代码)