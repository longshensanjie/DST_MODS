name = "冷切表"
version = "1.1.2"
description = "Version "..version.."\n\n旺达专属的冷切表来了".."\n\n效果：可给手中正在cd的一只不老表或二次表，传送表重置冷切时间".."\n\n注意：操作方式有两种，格子和背包中只存在一个正在cd的表的时候右键可直接帮你冷切，其他情况需要自己手动控制冷切哪一个，另外冷切表不可给冷切表重置冷切时间".."\n\n配置：可自行选择制作难度，默认正常难度"
author = "西风"

forumthread = ""

api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false

all_clients_require_mod = true

icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {
"item",
"utility",
"other",
"character",
}

configuration_options =
{
	{
		name = "CRAFT_COST",
		label = "Crafting Cost",
		options =
		{
			{description = "Easy",				data = 1},
			{description = "Normal (default)",	data = 2},
			{description = "Hard", 				data = 3},
		},
		default = 2,
	}
}