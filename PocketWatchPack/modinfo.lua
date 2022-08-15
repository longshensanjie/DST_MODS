name = "旺达的时间流逝怀表包"
description = "一个具有时间流逝功能的旺达怀表工具包".."\n\n配置：可自行选择制作难度，默认正常难度"
author = "西风"
version = "1.0.4"
forumthread = ""
api_version = 6
api_version_dst = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
all_clients_require_mod = true
icon_atlas = "images/modicon_pocketwatchpack.xml"
icon = "modicon_pocketwatchpack.tex"
priority = 0
server_filter_tags = {"item"}

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
