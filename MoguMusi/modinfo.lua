name = "蘑菇慕斯 · 蝶蛹󰀜"
version = "dev1.191"


description = 
"	󰀃当前版本："..version.. "󰀃\n\n"..
[[






	󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚󰀚

	󰀒：好友位已满，遇到问题请Steam评论或留言
	󰀗：闪退请订阅【错误追踪】模组发送崩溃日志
	󰀐：立秋辣【QQ群已解散, 有问题就在B站直播吧啊哈哈】
																					󰀍
]]

-- 󰀐：别的问题可添加QQ群 973700749 交流

author = "呼吸[原作者]冰汽[搬运修改]"
forumthread = ""
api_version = 10
icon_atlas = "modicon.xml"
icon = "modicon.tex"
all_clients_require_mod = false
client_only_mod = true
dst_compatible = true
priority = -9998					-- insight优先级-10000, 勋章优先级-9999 越大越先加载，需要比勋章优先加载
-----------------------------------------------------------------------------------
-- 希望少一点BUG
-----------------------------------------------------------------------------------
-- 按键
local function AddOpt(desc,data,hover)
	if hover then
		return {description = desc, data = data, hover = hover}
	else
		return {description = desc, data = data}
	end
 end

local theKeys = {
	AddOpt("关闭",false),
	AddOpt("B",98),
	AddOpt("C",99),
	AddOpt("G",103),
	AddOpt("H",104),
	AddOpt("I",105,"该项是饥荒检查自身皮肤的默认按键, 不怕冲突可以选"),
	AddOpt("J",106),
	AddOpt("K",107),
	AddOpt("L",108),
	AddOpt("N",110),
	AddOpt("O",111),
	AddOpt("P",112),
	AddOpt("R",114),
	AddOpt("T",116),
	AddOpt("V",118),
	AddOpt("X",120),
	AddOpt("Z",122),
	AddOpt("减号-",45,"该项是OB视角的默认键位, 使用此快捷键请关闭OB视角"),
	AddOpt("加号+",61,"该项是OB视角的默认键位, 使用此快捷键请关闭OB视角"),
	AddOpt("关闭",false," ↑↑↑ 上面不是有关闭按钮嘛 ↑↑↑ ,干嘛要在这里关"),
	AddOpt("<",44,"小于号或者逗号"),
	AddOpt(">",46,"大于号或者小数点"),
	AddOpt(":",59,"冒号或者分号"),
	AddOpt("'",39,"单引号或者双引号"),
	AddOpt("[",91,"左括号"),
	AddOpt("]",93,"右括号"),
	AddOpt("\\",92,"右斜杠"),
	AddOpt("F1",282),
	AddOpt("F2",283),
	AddOpt("F3",284),
	AddOpt("F4",285),
	AddOpt("F5",286),
	AddOpt("F6",287),
	AddOpt("F7",288),
	AddOpt("F8",289),
	AddOpt("F9",290),
	AddOpt("F10",291),
	AddOpt("F11",292),
	AddOpt("方向键(↑)",273),
	AddOpt("方向键(↓)",274),
	AddOpt("方向键(←)",276),
	AddOpt("方向键(→)",275),
	AddOpt("关闭",false," ↑↑↑ 上面不是有关闭按钮嘛 ↑↑↑ ,干嘛要在这里关"),
	AddOpt("PageUp",280,"PageUp"),
	AddOpt("PageDown",281,"PageDown"),
	AddOpt("Home",278,"Home"),
	AddOpt("Insert",277,"Insert"),
	AddOpt("Delete",127,"Delete"),
	AddOpt("End",279,"End"),
	AddOpt("Pause",19,"Pause"),
	AddOpt("Scroll Lock",145,"Scroll Lock"),
	AddOpt("CAPSLOCK大写锁定",301,"CAPSLOCK大写锁定"),
	AddOpt("左ALT",308,"游戏默认的检查键, 请确保不冲突再使用此按键"),
	AddOpt("右ALT",307,"游戏默认的检查键, 请确保不冲突再使用此按键"),
	AddOpt("左CTRL",306,"左CTRL"),
	AddOpt("右CTRL",305,"右CTRL"),
	AddOpt("右Shift",303,"右Shift"),
	AddOpt("小键盘0",256,"小键盘0"),
	AddOpt("小键盘1",257,"小键盘1"),
	AddOpt("小键盘2",258,"小键盘2"),
	AddOpt("小键盘3",259,"小键盘3"),
	AddOpt("小键盘4",260,"小键盘4"),
	AddOpt("小键盘5",261,"小键盘5"),
	AddOpt("小键盘6",262,"小键盘6"),
	AddOpt("小键盘7",263,"小键盘7"),
	AddOpt("小键盘8",264,"小键盘8"),
	AddOpt("小键盘9",265,"小键盘9"),
	AddOpt("小键盘 .",266,"小键盘 ."),
	AddOpt("小键盘 /",267,"小键盘 /"),
	AddOpt("小键盘 *",268,"小键盘 *"),
	AddOpt("小键盘 -",269,"小键盘 -"),
	AddOpt("小键盘 +",270,"小键盘 +"),
	AddOpt("关闭",false," ↑↑↑ 上面不是有关闭按钮嘛 ↑↑↑ ,干嘛要在这里关"),
} 
-------------------------------------------------------------------------------------
local theBoardKeys = {}

for i=1,#theKeys,1 do
	theBoardKeys[i] = theKeys[i]
end
theBoardKeys[#theBoardKeys+1] = AddOpt("功能面板", "biubiu", "将该功能在功能面板显示")

------------------------------------------------------------------------------------

local string = ""
local keysS = {"B","C","F","G","H","J","K","L","N","O","P","R","T","V","X","Z","F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","CAPSLOCK","LAlt","RAlt","LCtrl","RCtrl","LShift","RShift",}
local keyslist_S = {}
for i = 1, #keysS do
    keyslist_S[i] = {description = keysS[i], data = "KEY_"..string.upper(keysS[i])}
end

keyslist_S[#keyslist_S + 1] = {description = "关闭", data = false}

local colorlist = {
    {description = "白色",  data = "WHITE"},
    {description = "红色",    data = "FIREBRICK"},
    {description = "橙色", data = "TAN"},
    {description = "黄色", data = "LIGHTGOLD"},
    {description = "绿色",  data = "GREEN"},
    {description = "青色",   data = "TEAL"},
    {description = "蓝色" ,  data = "OTHERBLUE"},
    {description = "紫色", data = "DARKPLUM"},
    {description = "粉红" ,  data = "ROSYBROWN"},
    {description = "金色",   data = "GOLDENROD"},
}


-------------------------------------------------------
-- 切骨甲/加燃料
local opt_percent = {
	{description = "开启", data = 30, hover = "默认是30%"},
	{description = "关闭", data = false},
	{description = "5%", data = 5, hover = "最好不要带着低耐久魔光进帐篷"},
	{description = "10%", data = 10, hover = "最好不要带着低耐久魔光进帐篷"},
	{description = "20%", data = 20},
	{description = "25%", data = 25},
	{description = "50%", data = 50},
	{description = "66%", data = 66, hover = "魔光护符刚好完全修复"},
	{description = "75%", data = 75, hover = "骨头盔甲刚好完全修复"},
	{description = "80%", data = 80},
	{description = "90%", data = 90},
	{description = "99%", data = 99, hover = "噩梦燃料的快速消耗方式"},
	{description = "0%", data = -1, hover = "自动切骨甲的设置, 使其只能自动切"},
}


-----------------------------------------------------------------------------------
-- 分段标题
local function addTitle(title)
	return {
		name = "null",
		label = title,
		hover = nil,
		options = {
				{ description = "", data = 0 }
		},
		default = 0,
	}
end
-----------------------------------------------------------------------------------
-- 季节时钟
local hud_scale_options = {}
for i = 1,21 do
	local scale = (i-1)*5 + 50
	hud_scale_options[i] = {description = ""..(scale*.01), data = scale}
end
-----------------------------------------------------------------------------------
-- 表情轮盘
local scalefactors = {}
for i = 1, 20 do
	scalefactors[i] = {description = i/10, data = i/10}
end
-----------------------------------------------------------------------------------
-- 行为排队论
local function BuildNumConfig(start_num, end_num, step, percent)
    local num_table = {}
    local iterator = 1
    local suffix = percent and "%" or ""
    for i = start_num, end_num, step do
        num_table[iterator] = {description = i..suffix, data = percent and i / 100 or i}
        iterator = iterator + 1
    end
    return num_table
end
-----------------------------------------------------------------------------------
-- 物品信息

local ScaleValues = {}
for i=1, 15 do
	ScaleValues[i] = {description = "" .. (i/10), data = (i/10)}
end
-----------------------------------------------------------------------------------
-- 几何布局
local percent_options = {}
for i = 1, 10 do
	percent_options[i] = {description = i.."0%", data = i/10}
end
percent_options[11] = {description = "不限", data = false}
local placer_color_options = {
	{description = " 绿", data = "green", },
	{description = "蓝", data = "blue", },
	{description = "红", data = "red", },
	{description = "白", data = "white",},
	{description = "黑", data = "black",},
}
local color_options = {}
for i = 1, #placer_color_options do
	color_options[i] = placer_color_options[i]
end
color_options[#color_options+1] = {description = "亮白", data = "whiteoutline",}
color_options[#color_options+1] = {description = "浅黑", data = "blackoutline",}
local hidden_option = {description = "隐藏", data = "hidden",}
placer_color_options[#placer_color_options+1] = hidden_option
color_options[#color_options+1] = hidden_option
-----------------------------------------------------------------------------------
local wortox_opt = {}
for i = 0,30 do
	if (i == 12) then
		wortox_opt[i] = {hover = "12可以防止击杀大型boss爆魂",data = i,description=i}
	elseif (i > 20)  then
		wortox_opt[i] = {hover = "超出上限,但是支持某些模组", data = i,description=i}
	else
		wortox_opt[i] = {data = i,description=i,}
	end
end

-----------------------------------------------------------------------------------



-------------------------------------------------------------------------------------
configuration_options =
{
addTitle("模组提示"),
	{
		name = "sw_tip",
		label = "屏幕提示",
		hover = "部分提示语句的显示位置",
		options = {
			{description = "开启", data = "head", hover = "默认, 语句将会出现在人物头顶"},
			{description = "自己的聊天栏", data = "chat", hover = "在聊天栏的位置(仅自己可见)【旧版鸡尾酒】"},
			{description = "全局的聊天栏", data = "announce", hover = "警告：所有人都能看到你的提示消息！"},
			{description = "关闭", data = false},
		},
		default = "head",
	},
	{
		name = "sw_debugger",
		label = "智能模组",
		hover = "会显示冲突的模组, 另外该功能会关闭其他可能冲突的功能",
		options = {
			{description = "奇怪的崩溃", data = "shutup",hover = "发生某些奇怪的崩溃后选择此项@#￥%……&*？"},
			{description = "开启", data = true,hover = "帮你解决各种闪退问题，并提供技术支持"},
			{description = "警告", data = "jinggao", hover = "该功能关闭后将不再检查冲突的模组！（按右选择确认关闭）",},
			{description = "再次警告", data = "jinggao2", hover = "关了以后发生闪退就别反馈了",},
			{description = "确认关闭", data = false, hover = "该功能关闭后模组问题请自负！"},
		},
		default = true,
	},

addTitle("季节时钟"),
	{
		name = "sw_shizhong",
		label = "开关",
		hover = "显示当前世界温度、季节、月相等等, 季节时钟的总开关[原模组ID:376333686][1.8.3]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_shizhong_UNIT",
		label = "温度单位",
		hover = "选择你想要的温度单位",
		options =	{
						{description = "游戏单位", hover = "体温到0°过冷，70°过热", data = "T"},
						{description = "摄氏度", hover = "体温到0°C过冷，35°C过热", data = "C"},
						{description = "华氏度", hover = "体温到32°F过冷，158°F过热", data = "F"},
					},
		default = "T",
	},
	{
		name = "shizhong_SHOWMOON",
		label = "月相展示",
		hover = "会有一个小月亮的图标提醒你今天的月相",
		options =	{
						{description = "全天", data = 2, hover = "任何时候都能看到月相, 相当于便携的月晷"},
						{description = "仅夜晚", data = 0, hover = "白天月相会隐藏起来，就像平时那样"},
						{description = "夜晚黄昏", data = 1, hover = "从傍晚开始就能看到月相了"},
					},
		default = 2,
	},
	{
		name = "shizhong_SHOWWORLDTEMP",
		label = "降水预测",
		hover = "展示世界当前的温度, 如果启用【快捷宣告】, 会发送天气预报",
		options =	{
						{description = "开启", data = true},
						{description = "关闭", data = false},
					},
		default = true,
	},
	{
		name = "shizhong_CAVE",
		label = "洞穴时钟",
		hover = "在洞穴没有天光的地方也会显示白天、黄昏、夜晚",
		options =	{
						{description = "开启", data = true},
						{description = "关闭", data = false},
					},
		default = true,
	},
	{
		name = "shizhong_HUDSCALEFACTOR",
		label = "HUD缩放",
		hover = "缩放季节时钟的大小",
		options = hud_scale_options,
		default = 100,
	},

addTitle("小地图"),
	{
		name = "sw_minimap",
		label = "开关",
		hover = "显示当前世界的小地图的总开关",
		options = {
			{description = "开启", data = true, hover="如果小地图由于开瓶子或者探测地图消失了, 按两下 M 就会恢复"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "minimap_size",
		label = "地图大小",
		hover = "控制小地图的大小",
		options =	{
			{description = "很小", data = 0.125},
            {description = "小", data = 0.175},
            {description = "一般", data = 0.225},
            {description = "大", data = 0.275},
            {description = "很大", data = 0.325},
            {description = "巨大", data = 0.375},
		},
		default = 0.225,
	},
	{
		name = "minimap_position",
		label = "地图位置",
		hover = "控制小地图的显示位置",
		options = {
            {description = "右上角", data = "top_right"},
            {description = "左上角", data = "top_left"},
            {description = "正上方", data = "top_center"},
            {description = "正左方", data = "middle_left"},
            {description = "居中", data = "middle_center"},
            {description = "正右方", data = "middle_right"},
            {description = "左下角", data = "bottom_left"},
            {description = "正下方", data = "bottom_center"},
            {description = "右下角", data = "bottom_right"},
        },
        default = "top_right",
	},

addTitle("画面渲染"),
{
	name = "sw_huazhi",
	label = "开关",
	hover = "游戏画面调节 的总开关",
	options = {
		{description = "开启", data = true},
		{description = "允许光晕", data = "justcomfort", hover = "如果你觉得四季滤镜或者色彩调节过亮，可以打开这个"},
		{description = "关闭", data = false},
	},
	default = true,
},
	{
		name = "sw_naocan",
		label = "脑残和谐 - 精神滤镜",
		hover = "梦魇、启蒙、黑白、音效 等理智值的滤镜调节",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = 'sw_snowtile',
		label = "冬日积雪 - 雪地滤镜",
		hover = "冬天铺地皮专用, 不会影响下雪动画",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_shabao",
		label = "夏夜天体 - 沙暴滤镜",
		hover = "将去除沙暴和月亮风暴的糊满整个屏幕的效果",
		options = {
			{description = "开启", data = true, },
			{description = "关闭", data = false},
		},
		default = true,
	},{
		name = "sw_GiantTree",
		label = "雨林巨树 - 水木滤镜",
		hover = "开启后将禁止部分水中木特效",
		options = {
			{description = "开启", data = true,hover = "将移除巨树华盖、林间天光、藤蔓装饰"},
			{description = "禁止巨树华盖", data = "gt_Canopy",hover = "只禁用水中木画面上方花哨的掉帧动画，不做其他改动"},
			{description = "隐藏林间天光", data = "gt_Lightray",hover = "只隐藏花哨的丁达尔效应，不做其他改动"},
			{description = "取消藤蔓装饰", data = "gt_Deco",hover = "只隐藏水中木区域的藤蔓装饰，不做其他改动"},
			{description = "关闭", data = false, hover = "不对水中木滤镜进行任何改动"},
		},
		default = true,
	},
	{
		name = "sw_filter",
		label = "画质增强 - 四季滤镜",
		hover = "对原版昏黄或蹭亮的画质进行调节,原【美颜滤镜】",
		options = {
			{description = "开启", data = true,hover = "开启此滤镜推荐开启【雪地滤镜】，不然冬天画面太亮"},
			{description = "关闭", data = false},
		},
		default = false,
	},	
	{
		name = "sw_color",
		label = "色彩调节 - 定制滤镜",
		hover = "需要在游戏内按键自定义滤镜。开启此滤镜推荐开启【雪地滤镜】，不然冬天画面太亮",
		options = theBoardKeys,
		default = "biubiu",
	},




addTitle("表情轮盘"),
	{
		name = "sw_biaoqing",
		label = "开关",
		hover = "默认按下G快速做出各种表情 的总开关[原模组ID:352373173][1.8.1]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "biaoqing_KEYBOARDTOGGLEKEY",
		label = "快捷键",
		hover = "按下这个键唤出表情轮盘",
		options = theKeys,
		default = 103,
	},
	{
		name = "biaoqing_SCALEFACTOR",
		label = "轮盘大小",
		hover = "缩放表情轮盘的大小",
		options = scalefactors,
		default = 1,
	},

addTitle("超级宣告"),
	{
		name = "sw_xuangao",
		label = "开关",
		hover = "快捷宣告物品/状态 的总开关，支持宣告全屏物品、月圆、网络延迟",
		options = {
			{description = "开启", data = true, hover = "现已支持宣告任何实体！记得解锁珍宝柜的各种表情,让聊天内容更多彩。"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "xuangao_WHISPER",
		label = "快捷键",
		hover = "习惯性设置，在游戏中宣告可以加 Ctrl 键互相切换私密与公开",
		options =	{
						{description = "Ctrl+Alt+Shift", data = true, hover = "Alt+Shift 只有附近玩家能看到;Ctrl+Alt+Shift 全部玩家都能看到"},
						{description = "Alt+Shift", data = false, hover = "Alt+Shift 全部玩家都能看到;Ctrl+Alt+Shift 只有附近玩家能看到"},
					},
		default = true,
	},
	{
		name = "xuangao_self",
		label = "全屏宣告",
		hover = "我这里有10个树精守卫。",
		options = {
			{description = "仅统计地面", data = true, hover = "人人为我。"},
			{description = "身上物品也统计", data = false, hover = "我为人人。"},
		},
		default = true,
	},
	{
		name = "xuangao_saobao",
		label = "奇怪的宣告",
		hover = "奇怪的宣告增加了！",
		options =	{
						{description = "关闭", data = false, hover = "正常的快捷宣告"},
						{description = "喵喵叫", data = "miao", hover = "请帮人家做个火腿棒，喵~♥"},
						{description = "朕的天下", data = "boss", hover = "朕可以赏你一个火腿棒"},
						{description = "捏捏怪", data = "nie", hover = "咱啥也不知道捏"},
					},
		default = false,
	},

addTitle("功能面板"),
	{
		name = "sw_mainboard",
		label = "面板开关",
		hover = "你可以通过点击此键 或 点击屏幕右下方小蝴蝶 开启此面板【中键拖动, 右键换皮肤】",
		options = theKeys,
		default = 283,
	},
	{
		name = "sw_cookbook",
		label = "烹饪指南",
		hover = "一本菜谱 [原模组ID:2205331356][1.0.0]",
		options = theBoardKeys,
		default = "biubiu",
	},
	-- {
	-- 	name = "sw_shiguo",
	-- 	label = "石果分组",
	-- 	hover = "身上有空余格子且鼠标为空时,会10个一组丢石果,方便火药炸",
	-- 	options = theBoardKeys,
	-- 	default = "biubiu",
	-- },
	{
		name = "sw_autofish",
		label = "自动钓鱼",
		hover = "手持鱼竿时能自动河钓, 身上有材料可以自动做鱼竿并钓鱼",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "sw_winchactivator",
		label = "贝壳工厂",
		hover = "奶奶岛反复打捞海里的最后一个垃圾/雕像就能无限刷贝壳了",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "sw_snapping",
		label = "耕地对齐",
		hover = "刨地的，切换3x3,4x4,2x2,10坑模式【按住lshift+鼠标右键连续刨地】",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "sw_wow",
		label = "水上行走",
		hover = "海上按,拥有快速制作能力请同时按Ctrl",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "sw_tumbleweed",
		label = " 风滚草预测",
		hover = "路过沙漠自动预测风滚草的生成位置（只要圈起来以后就很方便啦）",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "sw_DAG",
		label = "档案馆辅助",
		hover = "靠近激活的远古档案馆, 携带【蒸馏的知识】或【空白勋章】自动做任务",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "sw_rescue",
		label = "发送Rescue",
		hover = "按下后会发送/rescue  或者  /救命",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "sw_altarfinder",
		label = "定位天体祭坛",
		hover = "放置了天体探测仪后, 会在地图上显示天体科技的位置【支持能力勋章寻宝！】",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "sw_shadowheart",
		label = "黑心工厂",
		hover = "自动制作雕像,Alt+左键点击雕像可以查看5个地皮范围内这种雕像的数量",
		options = {
			{description = "开启", data = true, hover = "靠近陶轮时生效"},
			{description = "骑士雕像", data = "knight", hover = "黑心工厂默认的设置"},
			{description = "战车雕像", data = "rook", hover = "用来制作大量战车决斗天体英雄, B站搜索【半小神】"},
			{description = "主教雕像", data = "bishop", hover = "用来制作大量主教决斗一珍八彩帝王蟹"},
			{description = "关闭", data = false},
		},
		default = true,
	},

addTitle("OB视角"),
	{
		name = "sw_OBC",
		label = "开关",
		hover = "OB视角 的总开关【蘑菇慕斯修改:+、-现在控制视角大小】",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
        name = "OBC_INITIAL_VIEW_MODE",
        label = "初始视角",
        hover = "进入游戏时显示的视角",
        options = {
            {description = "Default - 默认", data = 0},
            {description = "Aerial - 高空", data = 1},
            {description = "Vertical - 俯视", data = 2},
        },
		default = 0,
	},
	{
        name = "OBC_FUNCTION_KEY_1",
        label = "视野切换",
        hover = "在默认/高空/俯视模式间切换视角 的快捷键",
        options = theKeys,
        default = false,
    },
    {
        name = "OBC_FUNCTION_KEY_2",
        label = "游戏HUD隐藏",
        hover = "隐藏/显示游戏HUD 的快捷键",
        options = theKeys,
        default = 291,
    },
    {
        name = "OBC_FUNCTION_KEY_3",
        label = "自身角色隐藏",
        hover = "隐藏/显示自身角色 的快捷键",
        options = theKeys,
        default = false,
    },
    {
        name = "OBC_SWITCH_KEY_1",
        label = "第二方视角",
        hover = "固定视角到鼠标所指对象 的快捷键",
        options = theKeys,
        default = 111,
    },
    {
        name = "OBC_SWITCH_KEY_2",
        label = "第三方视角",
        hover = "固定视角到鼠标所指位置 的快捷键",
        options = theKeys,
        default = false,
    },
    {
        name = "OBC_RESET_KEY",
        label = "快速切视角",
        hover = "在自身与最近选定的实体/位置间切换 的快捷键",
        options = theKeys,
        default = 104,
	},
	
addTitle("温蒂辅助"),
	{
		name = "sw_wendy",
		label = "开关",
		hover = "温蒂辅助的 总开关[原模组ID:2043109179][1.1]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "wendy_summonkey",
		label = "召唤与收回",
		hover = "召唤或收回阿比盖尔的快捷键...",
		options = theKeys,
		default = 120,
	},
	{
		name = "wendy_commandkey",
		label = "激怒或安慰",
		hover = "这个按键可以激怒或安慰阿比盖尔...",
		options = theKeys,
		default = 114,
	},
	{
		name = "sw_ghost",
		label = "帮助小惊吓",
		hover = "在靠近丢失的玩具时, 脚下会有蓝色箭头指示[原模组ID:2034314229][7.21]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},

addTitle("沃托克斯辅助"),
	{
		name = "sw_wortox",
		label = "开关",
		hover = "沃托克斯辅助的 总开关[原模组ID:2087419015][0.4]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "wortox_RELEASE_KEY",
		label = "丢弃灵魂",
		hover = "按下此键会丢弃一个灵魂",
		options = theKeys,
		default = 114,
	},
	{
		name = "wortox_ex_btn",
		label = "防止爆魂",
		hover = "按下此键游戏内限制携带魂的数量",
		options = theKeys,
		default = 120,
	},
	{
		name = "wortox_ex",
		label = "爆魂上限",
		hover = "设置携带最大数量的灵魂, 超过此数量就会自动丢魂【需开启上方防止爆魂】",
		options = wortox_opt,
		default = 18,
	},
	{
		name = "wortox_hx",
		label = "恶魔纵跃功",
		hover = "鼠标中键可以进行一次最远的灵魂跳跃, 并用绿环或红环可视化跳跃终点",
		options = {
			{description = "开启", data = true, hover = "慕斯专享功能"},
			{description = "关闭", data = false},
		},
		default = true,
	},

addTitle("旺达辅助"),
	{
		name = "sw_wanda",
		label = "开关",
		hover = "旺达辅助的 总开关",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "wanda_display",
		label = "生命显示",
		hover = "【时间栏改变为生命栏】时间不在于多少, 在于如何你如何使用",
		options = {
			{description = "开启", data = true, hover = "默认是150HP的生命栏"},
			{description = "60HP", data = "60HP", hover = "60HP的生命栏"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "wanda_watch",
		label = "怀表时间",
		hover = "【怀表下方显示恢复时间】差一年,一个月,一天,一个时辰,都不算一辈子",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "wanda_weapon",
		label = "修复警告表",
		hover = "银色战车：自动为【警告表】添加噩梦燃料",
		options = {
			{description = "开启", data = 8, hover = "武器到8%时启用修复，更推荐下方的【快捷修复】功能"},
			{description = "关闭", data = false},
			{description = "25%", data = 25},
			{description = "50%", data = 50},
			{description = "75%", data = 75, hover = "修复到100%"},
		},
		default = 8,
	},
	{
		name = "watch_heal",
		label = "激活不老表",
		hover = "不灭钻石：激活一个可用的【不老表】",
		options = theKeys,
		default = 120,
	},
	{
		name = "watch_warp",
		label = "激活倒走表",
		hover = "白金之星：激活一个可用的【倒走表】",
		options = theKeys,
		default = 114,
	},
	{
		name = "watch_recall",
		label = "激活溯源表",
		hover = "黄金体验：激活一个可用的【溯源表】",
		options = theKeys,
		default = false,
	},
	{
		name = "wanda_rename",
		label = "旺达表命名",
		hover = "慕斯专享功能！你可以为自己的溯源表和裂缝表取名。",
		options = theBoardKeys,
		default = "biubiu",
	},
addTitle("沃尔夫冈辅助"),
	{
		name = "sw_lx",
		label = "开关",
		hover = "大力士辅助的 总开关",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_lx_auto",
		label = "自动健身房",
		hover = "强大健身房会自动使用",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_lx_dumbbell",
		label = "自动举哑铃",
		hover = "装备哑铃时按键举起哑铃, 没装备时按键装备哑铃",
		options = theKeys,
		default = 114,
	},
	{
		name = "sw_lx_wait",
		label = "挂机打转",
		hover = "给挂机的玩家准备,开启后挂机不再掉落健身值",
		options = theKeys,
		default = 120,
	},
addTitle("沃姆伍德辅助"),
    {
	    name = "sw_kaihua",
		label = "开花仪",
		hover = "添加一个开花计时仪到状态栏",
		options = {
		    {description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
-- addTitle("WX-78 辅助"),
-- 	{
-- 		name = "sw_wx78",
-- 		label = "充电过载时间",
-- 		hover = "机器人充电过载时间",
-- 		options = {
-- 			{ description = "开启", data = "hour", hover = "默认格式是 [时:分:秒]", },
-- 			{ description = "天-分:秒", data = "daydash", hover = "[游戏天数]-[分]:[秒]", },
-- 			-- { description = "dd:mm:ss", data = "day", hover = "[in game days]:[minutes]:[seconds]", },
-- 			{ description = "分:秒", data = "minute", hover = "[分]:[秒]", },
-- 			{ description = "秒", data = "second", hover = "[秒]", },
-- 			{description = "关闭", data = false},
-- 		},
-- 		default = "hour",
-- 	},
	

addTitle("行为排队论"),
	{
		name = "sw_Q",
		label = "开关",
		hover = "行为排队论的 总开关[原模组ID:2325441848][1.090]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "Q_action_queue_key",
		label = "排队键",
		hover = "按住此键进行队列操作, 默认是左边的Shift",
		options = keyslist_S,
		default = "KEY_LSHIFT",
	},
	{
		name = "Q_turf_grid_key",
		label = "网格显示",
		hover = "按下此键会在人物周围显示 11 × 11 大小的网格, 方便建家",
		options = keyslist_S,
		default = "KEY_F3",
	},
	{
		name = "Q_auto_collect_key",
		label = "自动采集",
		hover = "按下此键开始自动采集, 比如砍树自动捡起木头, 挖矿自动捡矿物,收集周围的浆果等等",
		options = keyslist_S,
		default = "KEY_F4",
	},
	{
		name = "Q_last_recipe_key",
		label = "重复制作",
		hover = "按下此键可以制作刚刚做过的东西",
		options = keyslist_S,
		default = "KEY_CAPSLOCK",
	},
	{
		name = "Q_farm_grid",
		label = "耕作间隔",
		hover = "3x3 耕地或 4x4 耕地",
		options = {
			{description = "3x3",  data = "3x3", hover = "设置成3x3仅会在耕地上生效, 植物人在空地上种植会切换为4x4"},
			{description = "4x4",   data = "4x4"},
		},
		default = "3x3",
	},
	{
		name = "Q_selection_color",
		label = "选中颜色",
		hover = "选中对象时对象展示的颜色",
		options = colorlist,
		default = "WHITE",
	},
	{
		name = "Q_selection_opacity",
		label = "选中透明度",
		hover = "选中对象的透明度",
		options = BuildNumConfig(5, 95, 5, true),
		default = 0.5,
	},
	{
		name = "Q_endless_deploy_key",
		label = "自动下一行按键",	
		hover = "在横向框选的基础上自动连续种植或放置下一行",
		options = keyslist_S,
		default = false,
	},
	{
		name = "Q_endless_deploy",
		label = "自动下一行默认状态",	
		hover = "自动下一行默认状态",
		options = {
			{description = "开启", data = true, hover = "默认开启"},
			{description = "关闭", data = false, hover = "默认关闭"},
		},
		default = false,
	},
	{
		name = "Q_turf_grid_color",
		label = "网格颜色",
		hover = "大网格的颜色",
		options = colorlist,
		default = "WHITE",
	},
	{
		name = "Q_double_click_range",
		label = "响应范围",
		hover = "周围可触发双击选中的范围",
		options = BuildNumConfig(10, 60, 5),
		default = 25,
	},
	{
		name = "Q_tooth_trap_spacing",
		label = "陷阱边距",
		hover = "设置狗牙陷阱的边距",
		options = BuildNumConfig(1, 4, 0.5),
		default = 1.5,
	},
	{
		name = "Q_snake",
		label = "蛇形种植",
		hover = "像贪吃蛇一样扭头种植, 一次种两行",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "Q_attack_queue",
		label = "攻击队列",
		hover = "手中有武器时可以让生物和建筑进入攻击队列, 建家或者设置触手阵时可以打开此功能批量打墙",
		options = {
			{description = "开启", data = true, hover = "如果同时开启排队论加强，手中有武器时将会同时选中并攻击生物"},
			{description = "关闭", data = false, hover = "关闭后将无法批量打墙"},
		},
		default = true,
	},


addTitle("排队论加强"),
	{
		name = "littledro",
		label = "开关",
		hover = "群友@littledro研究的结果：支持排队论自动切工具【原模组：排队论加强】",
		options = {
			{description = "开启", data = true, hover="排队论支持选择不同的目标并自动切工具"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "QAAQ_tool_container",
		label = "工具位置",
		hover = "选择工具在哪才能自动自动装备",
		options = {
			{description = "仅物品栏", data = 0},
			{description = "仅背包", data = 1},
            {description = "全部", data = 2},
		},
		default = 2,
	},
	{
		name = "QAAQ_collect_items",
		label = "收集物品",
		hover = "自动收集的砍树模式收集哪些物品",
		options = {
			{description = "收集木头和种子", data = 0},
			{description = "仅收集木头", data = 1},
			{description = "仅收集种子", data = 2},
			{description = "只铲不收集", data = 3}, 
			{description = "只增加铲树根", data = 4},
		},
		default = 0,
	},
	{
		name = "QAAQ_everything_chop",
		label = "提灯砍树",
		hover = "提灯砍树的操作",
		options = {
			{description = "开启", data = true,},
			{description = "关闭", data = false},
		},
		default = false,
	},
	{
		name = "QAAQ_crafting_allowed",
		label = "自动制作工具",
		hover = "工作队列中是否自动制造工具",
		options = {
			{description = "开启", data = true,},
			{description = "关闭", data = false},
		},
		default = false,
	},


addTitle("装备控制论"),
	{
		name = "sw_boas",
		label = "开关",
		hover = "装备控制论的 总开关",
		options = {
			{description = "开启", data = true, hover = "这个功能用来自动切装备, 学会这个可以事半功倍"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "boas_AUTO_EQUIP_CANE",
		label = "自动切手杖",
		hover = "行走时自动切手杖",
		options = {
			{description = "开启", data = true, hover = "务必搭配下方【虚拟装备栏】使用"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "boas_AUTO_EQUIP_LIGHTSOURCE",
		label = "自动切光源",
		hover = "检测到黑暗自动切光源",
		options = {
			{description = "关闭", data = false},
			{description = "开启", data = 0, hover = "务必搭配下方【虚拟装备栏】使用"},
			{description = "延后1秒", data = 1},
			{description = "延后2秒", data = 2},
			{description = "延后3秒", data = 3},
			{description = "延后4秒", data = 4},
			{description = "延后5秒", data = 5},
		},
		default = 0,
	},
	{
		name = "boas_AUTO_RE_EQUIP_WEAPON",
		label = "自动切武器",
		hover = "按F切武器",
		options = {
			{description = "开启", data = true, hover = "务必搭配下方【虚拟装备栏】使用"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "boas_AUTO_RE_EQUIP_ARMOR",
		label = "自动切护甲",
		hover = "检测到仇恨时自动切护甲, 该项与自动脱落是有点冲突的。",
		options = {
			{description = "开启", data = true, hover="注意：开启此项会使得【泰拉脱落】异常！"},
			{description = "关闭", data = false},
		},
		default = false,
	},
	{
		name = "boas_TOGGLE",
		label = "切装备按键",
		hover = "自动切手杖、武器、光源、护甲等的控制键【不包含工具！】（只是切换键，总开关在上面！）",
		options = theKeys,
		default = 290,
	},
	{
		name = "boas_AUTO_EQUIP_TOOL",
		label = "自动切工具",
		hover = "点击实体切工具",
		options = {
			{description = "关闭", data = false},
			{description = "开启", data = 1, hover = "点击只切工具不会自动制作工具"},
			{description = "点击后会制作工具", data = 2, hover = "点击后还会制作对应的工具,仅支持镐子斧子"},
		},
		default = 1,
	},
	{
		name = "boas_AUTO_REPEAT_ACTIONS",
		label = "连续工作",
		hover = "点击实体自动连续工作,已兼容排队论",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "boas_Quick",
		label = "右键加强",
		hover = "身上有物品时,右键实体可以直接使用",
		options = {
			{description = "开启", data = true, hover ="捕捉,锤,挖,加燃料,修船,拼骨架,放鸟,冰杖攻击,火杖攻击,旋风攻击,等等"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "boas_DoubleClick",
		label = "双击传送",
		hover = "右键双击才能使用懒人法杖的传送功能，防止意外消耗",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "boas_BUTTON_SHOW",
		label = "虚拟装备栏",
		hover = "添加新的一行虚拟物品栏, 左键立即切换装备, 右键设置优先装备",
		options = {
			{description = "开启", data = true, hover = "强调一下：右键单击设置装备优先级"},
			{description = "关闭", data = false, hover = "打开控制面板可以在游戏中半透明/隐藏/显示此栏"},
		},
		default = true,
	},
	{
		name = "boas_ELSE",
		label = "控制论 - 其他功能",
		hover = "自动接回旋镖,优先糖果袋,伍迪月圆退装备",
		options = {
			{description = "开启", data = true,},
			{description = "关闭", data = false},
		},
		default = true,
	},

addTitle("暴动时钟"),
	{
		name = "sw_phase",
		label = "开关",
		hover = "地下暴动时钟显示的 总开关[原模组ID:129878476][2.2]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "phase_VISIBLY_HAVE_MEDALLION",
		label = "显示条件",
		hover = "暴动时钟显示的条件",
		options = {
			{ description = "铥矿徽章", data = true  , hover='当携带铥矿徽章才会开启暴动时钟',},
			{ description = "总是显示", data = false , hover='始终显示暴动时钟',}
		},
		default = false,
	},
    {
        name    = "phase_SCALE",
        label   = "大小缩放",
        hover   = "设置暴动时钟的大小",
        options =   {
                        { description = "100%", data = 1   },
                        { description = "90%",  data = 0.9 },
                        { description = "80%",  data = 0.8 },
                        { description = "70%",  data = 0.7 },
                        { description = "60%",  data = 0.6 },
                        { description = "50%",  data = 0.5 },
                        { description = "40%",  data = 0.4 },
                        { description = "30%",  data = 0.3 },
                    },
        default = 1
    },
addTitle("呼吸检测"),
	{
		name = "sw_huxi2",
		label = "开关",
		hover = "生物动态捕捉技术, 识别人物BUFF和部分BOSS的刷新时间",
		options = {
			{description = "开启", data = true, hover= "左键宣告, 右键修改刷新时间"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_huxi",
		label = "更换样式",
		hover = "按钮或者按键：选择要显示BUFF还是显示BOSS刷新, 或者都显示",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "sw_huxi_nothing",
		label = "更改刷新",
		hover = "如果修改了服务器BOSS刷新时间,需要点击手动修改！[设置为 0 时该生物不再提示]",
		options = {
			{description = "右键点击", data = true, hover= "左键宣告, 右键修改刷新时间"},
		},
		default = true,
	},
	{
		name = "sw_huxi_announce",
		label = "自动宣告",
		options = {
			{description = "BOSS刷新宣告", data = "boss_spawn", hover = "龙蝇 已刷新！"},
			{description = "BOSS击杀宣告", data = "boss_kill", hover = "龙蝇 已被击杀！"},
			{description = "每日宣告", data = "boss_day", hover = "龙蝇 3天02分05秒刷新"},
			{description = "老流氓", data = "boss_killer", hover = "杀了, 刷新, 每日都宣告"},
			{description = "关闭", data = false, hover = "不再宣告"},
		},
		default = "boss_spawn",
	},




addTitle("物品信息"),
	{
		name = "sw_item",
		label = "开关",
		hover = "物品信息显示的 总开关[原模组ID:2049203096][0.9.6]",
		options = {
			{description = "开启", data = true,},
			{description = "关闭", data = false,},
		},
		default = true,
	},
	{
		name = "item_INFO_SCALE",
		label = "信息比例",
		hover = "设置工具提示的信息比例",
		options = ScaleValues,
		default = 1.0,
	},
	{
		name = "item_TIME_FORMAT",
		label = "时间格式",
		hover = "设置显示时间格式",
		options =	{
						{description = "小时制", data = 0},
						{description = "天数制", data = 1},
					},
		default = 1,
	},
	{
		name = "item_SHOW_EDIBLE_SHANG",
		label = "食物三维",
		hover = "如服务器未开启 Show Me，可选择开启",
		options =	{
			{description = "显示", data = true, hover = "服务器未开启show me, 选择此项更好"},
			{description = "关闭", data = false, hover = "服务器开启了show me, 选择此项更好"},
		},
		default = true,
	},
	{
		name = "item_showEquip",
		label = "装备信息显示",
		hover = "是否在右下角显示装备信息",
		options = {
			{description = "不显示", data = false, hover = "成为大佬后, 我就关了它, 右下角一堆Ui看着很乱"},
			{description = "显示", data = true, hover = "我还是萌新, 想再了解饥荒的装备"},
		},
		default = false,
	},
	{
		name = "item_SHOW_PREFABNAME",
		label = "物品代码",
		hover = "如果你想看到物品的代码名称可设置为开启",
		options =	{
						{description = "显示", data = true},
						{description = "关闭", data = false},
					},
		default = false,
	},

addTitle("耕作先驱"),
	{
		name = "sw_gardeneer",
		label = "开关",
		hover = "耕作先驱功能的 总开关",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "gardeneer_location",
		label = "显示位置",
		hover = "园艺帽显示的位置",
		options = {
			{description = "功能面板", data = 8, hover = "在功能面板"},
			{description = "右下角 ^", data = 1, hover = "在地图按钮的上面"},
			{description = "右下角 <", data = 2, hover = "在地图按钮的左边"},
			{description = "左下角", data = 3, hover = "在制作栏的下面"},
			{description = "左上角", data = 4, hover = "在制作栏的上面"},
			{description = "正上方", data = 5, hover = "正上方"},
			{description = "右上角", data = 6, hover = "在状态显示的旁边"},
			{description = "正右边", data = 7, hover = "在背包的后面"},
		},
		default = 8,
	},
	{
		name = "gardeneer_knowallplants",
		label = "图鉴解锁",
		hover = "园艺图鉴是否完全解锁",
		options = {
			{description = "标准", data = false, hover = "园艺的数据和状态需要你去记录【原生图鉴】"},
			{description = "仅种子", data = "seeds", hover = "种子的数据解锁,可以直接查看种子名"},
			{description = "已研究", data = true, hover = "园艺图鉴完全解锁【你也不能记录园艺状态】"},
		},
		default = "seeds",
	},
	{
		name = "sw_mySeedTex",
		label = "种子贴图",
		hover = "还原旧版种子贴图",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},

addTitle("圆形种植"),	
	{
		name = "sw_planting",
		label = "开关",
		hover = "圆形种植的总开关: 此功能鸣谢【可有可无的队友】大力推荐",
		options = {
			{description = "开启", data = true, hover = "开启"},
			{description = "开启并显示坐标", data = "pos", hover = "显示当前坐标"},
			{description = "关闭", data = false},
		},
		default = true,
	}, 
    {
        name = "plant_setting",
        label = "设置开关",
        hover = "打开圆形种植的设置面板",
        options = theKeys,
        default = 288,
    },
	{
        name = "plant_deploy",
        label = "圆心种植",
        hover = "按住CTRL和此键设置圆心, 单独按下此键自动种植",
        options = theKeys,
        default = 106,
    },
    {
        name = "plant_placer",
        label = "生成预览",
        hover = "按住此键预览摆放的样式",
        options = theKeys,
        default = 107,
    },
addTitle("T键控制台"),
	{
		name = "sw_T",
		label = "开关",
		hover = "T键控制台总开关, 原作者不再维护, 版本12月3日1.1.2",
		options = {
			{description = "开启", data = true, hover = "滥用该功能会减少游戏体验！"},
			{description = "关闭", data = false,},
		},
		default = true,
	},
    {
        name = "GOP_TMIP_TOGGLE_KEY",
        label = "快捷键",
        hover = "按下此键显示T键控制台",
        options = theKeys,
        default = 116,
    },
	{
		name="GOP_TMIP_CATEGORY_FONT_SIZE",
		label="标签字体大小",
		hover="如果你使用了其他字体，你可以在这里调整字体大小。",
		options={
			{description="12",data=12},{description="14",data=14},
			{description="16",data=16},{description="18",data=18},
			{description="20",data=20},{description="22",data=22},
			{description="24",data=24},{description="26",data=26},
			{description="28",data=28},{description="30",data=30},
		},
		default=24,
	},
	{
		name="GOP_TMIP_DEBUG_FONT_SIZE",
		label="菜单字体大小",
		hover="如果你使用了其他字体，你可以在这里调整字体大小。",
		options={
			{description="12",data=12},{description="14",data=14},
			{description="16",data=16},{description="18",data=18},
			{description="20",data=20},{description="22",data=22},
			{description="24",data=24},{description="26",data=26},
			{description="28",data=28},{description="30",data=30},
		},
		default=24,
	},
	{
		name="GOP_TMIP_DEBUG_MENU_SIZE",
		label="调试菜单的宽度",
		hover="如果你的分辨率为1920*1080及以上，你可以增加宽度获得更好的显示效果。",
		options={
			{description="450",data=450},{description="500",data=500},
			{description="550",data=550},{description="600",data=600},
			{description="650",data=650},{description="700",data=700},
		},
		default=550,
	},


addTitle("其他功能"),
	{
		name = "sw_craftpot",
		label = "智能锅",
		hover = "预测烹饪锅的产出料理和料理属性[原模组ID:727774324][0.14.2]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_box",
		label = "箱子记忆",
		hover = "慕斯专享, 拿起物品时自动显示已经存在该物品的容器。新增：同时地上物品会变绿",
		options = {
			{description = "开启", data = true, hover = "该功能遇到showme或insight会自动关闭"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_stat",
		label = "状态变化",
		hover = "精神值和血量的增加或减少会显示出来[原模组ID:1876137475][1.1]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_shutup",
		label = "去除噪音",
		hover = "包括装备、宠物、建筑、大便、捕鸟器、海浪地皮等各种音效",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false, hover = "该功能关闭需要退出重启游戏！"},
		},
		default = true,
	},
	{
		name = "sw_warning",
		label = "怪物警告",
		hover = "在野狗, 蠕虫, 熊大, 巨鹿, 蚁狮来临之前发出提示【粉色字体】[原模组ID:1923504381][2.0.0]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_unequip",
		label = "自动脱落",
		hover = "对于可以修复的装备或者护符等在剩下1%时自动脱落, 并以蓝色字体提示[原模组ID:1581892848][5]",
		options = {
			{description = "开启", data = 1, hover = "默认是1%"},
			{description = "3%", data = 3, hover = "常见的数值"},
			{description = "6%", data = 6},
			{description = "10%", data = 10},
			{description = "12%", data = 12,},
			{description = "20%", data = 20},
			{description = "30%", data = 30},
			{description = "50%", data = 50},
			{description = "100%", data = 100, hover = "总会脱落"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_taila",
		label = "泰拉脱落",
		hover = "眼面具 和 恐怖盾牌 的 脱落设置【需开启自动脱落】",
		options = {
			{description = "开启", data = 12, hover = "默认是12%"},
			{description = "1%", data = 1,},
			{description = "6%", data = 6, hover = "防止蜘蛛撕咬"},
			{description = "10%", data = 10},
			{description = "19%", data = 19, hover = "防止龙蝇巴掌"},
			{description = "20%", data = 20},
			{description = "30%", data = 30},
			{description = "40%", data = 40},
			{description = "50%", data = 50},
			{description = "100%", data = 100, hover = "受到攻击必定脱落"},
			{description = "禁止泰拉装备脱落", data = 0},
		},
		default = 12,
	},
	{
		name = "sw_connect",
		label = "一键直连",
		hover = "游戏内按下TAB保存服务器, 主页面可以直接连接已经保存的服务器",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_autofishing",
		label = "海钓大师",
		hover = "海钓上钩后可以帮助你自动拉鱼,按下CTRL+L查看更多信息",
		options = {
			{description = "开启", data = true, hover="注意！该功能需要开洞穴，否则换鱼铒会崩溃！"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_wall",
		label = "不要打墙",
		hover = "强制攻击不会打墙和南瓜灯, 除非按住CTRL去点",
		options = {
			{description = "开启", data = true, hover = "还包括不会攻击无敌状态的编织者, 克劳斯在周围时的食人花, 旺达不会打沙刺等"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_wormhole",
		label = "虫洞标记",
		hover = " 将虫洞标记成彩色并添加数字编号[原模组ID:1295277999][1.007]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_tele",
		label = "传送标记",
		hover = "传送生物后原地留下一个传送标记",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_justgo",
		label = "自动寻路",
		hover = " 右键点击地图即可自动到达，鹰眼模式左键点击画面也可自动到达【打开延迟补偿才能生效】",
		options = {
			{description = "开启", data = true, hover = "恶魔人需要中键点击地图才能触发"},
			{description = "允许地图传送", data = "canTele", hover = "给群友加的功能，开启创造模式后可以右击地图传送"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_autoadd",
		label = "魔光自加",
		hover = " 魔光护符少于30%耐久时自动加噩梦燃料",
		options = opt_percent,
		default = 30,
	},
	{
		name = "sw_skeleton",
		label = "骨甲自切",
		hover = "自动切换骨头盔甲, 耐久在30%以下时自动添加噩梦燃料",
		options = opt_percent,
		default = 30,
	},
	{
		name = "sw_range",
		label = "范围显示",
		hover = "按住ALT点击避雷针、投石器、雪球机、疙瘩树、夹夹绞盘就会在30秒内显示其对应覆盖的范围",
		options = {
			{description = "开启", data = true, hover="奶奶的书也会显示范围"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_showmodfolder",
		label = "模组目录",
		hover = "在模组名下方显mod存放目录[原模组ID:2007016033][1.1.1]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_keepfollow",
		label = "保持跟随",
		hover = "按住shift右击生物开启跟随, shift+ctrl右击生物开启推动生物",
		options = {
			{description = "开启", data = true, hover="该功能如果和排队论冲突, 请用框选的方式选择物体"},
			{description = "关闭", data = false, hover = "该功能会遇到【富贵险中求】mod也会自动关闭"},
		},
		default = true,
	},
	{
		name = "sw_autorow",
		label = "自动划船",
		hover = "划船动作会自动执行, 可以通过移动打断自动划船",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = 'sw_indicator',
		label = "方向指示",
		hover = "会提示附近各种生物,雕塑,甚至脚印的位置[原模组ID:1120124958][0.3]",
		options = {
			{description = "开启", data = true, hover = "该功能支持快捷宣告！"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_nickname",
		label = "昵称显示",
		hover = "房间内其他玩家的头上会显示他们的游戏用户名 [原模组ID:956206484][1.01]",
		options = {
			{description = "开启", data = "only", hover = "仅其他用户头上显示用户名, 自己头上不显示"},
			{description = "全部显示", data = "all", hover = "自己头上也显示用户名, 适合主播展示ID"},
			{description = "关闭", data = false}
		},
		default = "only",
	},
	{
		name = "sw_AUTO_EAT_FOOD",
		label = "自动吃饭",
		hover = "当饥饿时尝试吃掉身上的食物【适配其他角色或其他食物请留言】",
		options = {
			{description = "开启", data = 0, hover = "默认是饥饿为0吃食物"},
			{description = "5", data = 5,},
			{description = "10", data = 10,},
			{description = "20", data = 20,},
			{description = "50", data = 50,},
			{description = "80", data = 80,},
			{description = "100", data = 100,},
			{description = "150", data = 150,},
			{description = "200", data = 200,},
			{description = "关闭", data = false},
		},
		default = 0,
	},
	{
		name = "wagstaff_tool_giver",
		label = "科学家工具",
		hover = "显示瓦格斯塔夫需要的工具以及生成提示",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_eyeplant",
		label = "眼球草预测",
		hover = "预测眼球草生成的位置,如果启用了建筑几何, 需要按下Ctrl才能显示预测结果 [原模组ID:1273382163][1.5]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_board",
		label = "管理员面板",
		hover = "当你是管理员/房主时, 按下TAB键能看到许多功能! [原模组ID:1290774114][1.22]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	-- {
	-- 	name = 'sw_recipes',
	-- 	label = "清晰制作栏",
	-- 	hover = "未解锁的物品可以看得很清楚, 打包纸配方在优先",
	-- 	options = {
	-- 		{description = "开启", data = true},
	-- 		{description = "关闭", data = false},
	-- 	},
	-- 	default = true,
	-- },
	{
		name = 'sw_tame',
		label = "牛牛驯化度",
		hover = "被牛甩下来后会显示牛牛的驯化度，到达100%就能得到 跑牛/战牛/肥牛/普通牛 ",
		options = {
			{description = "开启", data = true, hover = "未开启showme的话这个就很方便"},
			{description = "关闭", data = false, hover = "开启了showme就不用开啦"},
		},
		default = true,
	},
	{
		name = 'sw_showhead',
		label = "模组头像显示",
		hover = "显示MOD角色的图标在存档栏",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = 'sw_peopleNum',
		label = "增加人数上限",
		hover = "创建世界时最多可选的人数, 点击应用才能生效",
		options = {
			{description = "开启", data = 6, hover = "开了或者关了都是默认的6人, 默认打开是为了和上面对齐, 图好看"},
			{description = "关闭", data = false, hover = "关了也是默认的6人, 不做任何修改"},
			{description = "8人", data = 8, hover = "记得去创建世界的那里修改人数"},
			{description = "12人", data = 12, hover = "记得去创建世界的那里修改人数"},
			{description = "16人", data = 16, hover = "记得去创建世界的那里修改人数"},
			{description = "24人", data = 24, hover = "记得去创建世界的那里修改人数"},
			{description = "36人", data = 36, hover = "记得去创建世界的那里修改人数"},
			{description = "50人", data = 50, hover = "嚯, 哥们你这配置多少钱一斤啊~"},
			{description = "100人", data = 100, hover = "你是故意来找茬的吧！"},
		},
		default = 6,
	},
	{
		name = "sw_skinQueue",
		label = "分解重复皮肤",
		hover = "添加一个【分解重复皮肤】的按钮，帮助获得线轴",
		options = {
			{description = "开启", data = true},
			{description = "强力分解", data = "chong", hover = "允许分解多余的不可编织的皮肤【挂直播掉落多余的皮肤】",},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_skinHistory",
		label = "局内开启礼物",
		hover = "无需科技开启礼物, 并添加一个【历史皮肤数据】的按钮，记录获得的皮肤",
		options = {
			{description = "开启", data = true, hover = "帮我自动开皮肤, 也记录历史皮肤数据"},
			{description = "不要动我的礼物", data = "leavemealone", hover = "不要自动开皮肤, 但是记录部分历史皮肤数据"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = 'sw_hidecrown',
		label = "关掉启迪之冠",
		hover = "上下洞穴和进入世界后自动关闭启迪之冠",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = 'sw_swingboy',
		label = "旋转角色模型",
		hover = "人物界面可以旋转人物模型",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
addTitle("辅助器"),
	{
		name = "sw_cheat",
		label = "开关",
		hover = "辅助功能和作弊功能 的总开关[0.0.2]",
		options = {
			{description = "开启", data = true},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "cheat_fullmap",
        label = "鹰眼全图",
        hover = "俯视全图地形,点击地图会自动走向目的地 的快捷键",
        options = theKeys,
        default = 282,
	},
	{
		name = "option_fullmap",
        label = "鹰眼视角",
        hover = "设置鹰眼视角变换方式",
        options = {
			{description = "默认~鹰眼", data = 0},
			{description = "大视野~鹰眼", data = 1,},
			{description = "默认~大视野~鹰眼", data = 2},
			{description = "默认~大视野", data = 3, hover = "鹰眼如果失去鹰眼，还是鹰眼吗？"},
		},
        default = 1,
	},
	{
		name = "cheat_nightversion",
        label = "智能夜视",
        hover = "晚上自动开, 白天自动关, 推荐顺便打开上面的【四季滤镜】, 会舒服很多",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "sw_jungler",
		label = "攻击范围",
		hover = "提示敌对生物的位置并显示攻击范围, 以及提示脚印的位置【默认关闭，游戏中按下设置的快捷键开启】",
		options = theKeys,
		default = 286,
	},
	{
		name = "attack_timer",
		label = "攻击CD",
		hover = "提示敌对生物攻击间隔和技能CD",
		options = {
			{description = "开启", data = true, hover = "开启上方【攻击范围】才能生效"},
			{description = "关闭", data = false},
		},
		default = false,
	},
	{
		name = "jungler_starfish",
		label = "海星清远古",
		hover = "种在圆上就好啦！按住Ctrl查看圆, 然后种在圆周上！",
		options = {
			{description = "开启", data = true, hover = "开启上方【攻击范围】才能生效"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "sw_showaggro",
        label = "关系显示",
        hover = "在生物头上显示仇恨目标和跟随目标【如果安装了简易血条, 可能会被遮挡】[原模组ID:1120124958][1.7.3]",
        options = theKeys,
        default = 287,
	},
	{
		name = "sw_manualAdd",
        label = "快捷修复",
        hover = "按下此键 有燃料时修复装备【修复到80%, 兼容神话书说和精灵公主】",
        options = theKeys,
        default = 118,
	},
	{
		name = "sw_toggle",
        label = "一键延迟",
        hover = "一键开关延迟补偿的快捷键",
        options = theKeys,
        default = 110,
	},
	{
		name = "sw_lantern",
        label = "按键丢物品",
        hover = "一键丢提灯、灯笼、南瓜灯, 靠近热源可以丢暖石",
        options = theKeys,
        default = 122,
	},


addTitle("几何布局"),
	{
		name = "sw_GEO",
		label = "开关",
		hover = "几何布局的 总开关",
		options = {
			{description = "开启", data = true, hover = "几何布局的按键必须是A-Z！其他按键设置不会生效！"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "KEYBOARDTOGGLEKEY",
		label = "配置面板",
		hover = "在游戏内唤出设置面板 的快捷键",
		options = theKeys,
		default = 98,
	},
	{
		name = "GEOMETRYTOGGLEKEY",
        label = "形状切换键",
        options = theKeys,
        default = false,
		hover = "一键切换到最近使用的几何\n(例如，方形和X-六角形的切换)",
	},
	{
		name = "CTRL",
		label = "Ctrl切换MOD状态",
		options =	{
						{description = "开启", data = true},
						{description = "关闭", data = false},
					},
		default = false,
		hover = "按住Ctrl键是否启用或禁用几何MOD.",
	},
	{
        name = "SHOWMENU",
        label = "游戏内菜单",
		options =	{
						{description = "开启", data = true},
						{description = "关闭", data = false},
					},
        default = true,
		hover = "如果打开，按修改配置按键启动.\n如果关闭，它只能Ctrl切换开启和关闭模组.",
	},
	{
        name = "SNAPGRIDKEY",
        label = "捕捉网格",
        options = {
			{description = "None", data = ""},
		},
        default = "",
		-- hover = "A key to snap the grid to have a point centered on the hovered object or point. No controller binding.\nI recommend setting this with the Settings menu in DST.",
		hover = "A key to snap the grid to have a point centered on the hovered object or point. No controller binding.",
    },      
	{
		name = "BUILDGRID",
		label = "显示构建网格",
		options =	{
						{description = "开启", data = true},
						{description = "关闭", data = false},
					},
		default = true,	
		hover = "是否显示构建网格.",
	},
	{
		name = "GEOMETRY",
		label = "网格几何",
		options =	{
						{description = "方形", data = "SQUARE"},
						{description = "菱形", data = "DIAMOND"},
						{description = "X 六角形", data = "X_HEXAGON"},
						{description = "Z 六角形", data = "Z_HEXAGON"},
						{description = "平 六角形", data = "FLAT_HEXAGON"},
						{description = "尖 六角形", data = "POINTY_HEXAGON"},
					},
		default = "SQUARE",	
		hover = "使用什么构建网格几何.",
	},
	{
		name = "TIMEBUDGET",
		label = "刷新速度",
		options = percent_options,
		default = 0.1,	
		hover = "有多少可用时间用于刷新网格。禁用或设置过高可能会导致延迟.",
	},
	{
		name = "HIDEPLACER",
		label = "隐藏放置物体虚影",
		options =	{
						{description = "开启", data = true},
						{description = "关闭", data = false},
					},
		default = false,
		hover = "是否隐藏放置物，隐藏它可以帮助您更好地查看网格.",
	},
	{
		name = "HIDECURSOR",
		label = "隐藏鼠标项",
		options =	{
						{description = "隐藏所有", data = 1},
						{description = "显示数量", data = true},
						{description = "显示所有", data = false},
					},
		default = false,	
		hover = "是否隐藏鼠标项，以更好地查看网格.",
	},
	{
		name = "SMARTSPACING",
		label = "智能间距",
		options =	{
						{description = "关闭", data = false},
					},
		default = false,	
		hover = "天天有人说几何对不齐，不如干脆写死了，就是只能关闭, 无法打开",
	},
	{
		name = "ACTION_TILL",
		label = "耕地网格",
		options =	{
						{description = "开启", data = true},
						{description = "关闭", data = false},
					},
		default = true,	
		hover = "是否使用网格耕作农田土壤。\n 使用“Snapping Tills”mod时，该功能会自动关闭。",
	},
	{
		name = "SMALLGRIDSIZE",
		label = "精细网格尺寸",
		options = smallgridsizeoptions,
		default = 10,	
		hover = "使用精细网格(结构、植物等)的物体的网格有多大.",
	},
	{
		name = "MEDGRIDSIZE",
		label = "墙网格大小",
		options = medgridsizeoptions,
		default = 6,	
		hover = "墙的格子有多大.",
	},
	{
		name = "BIGGRIDSIZE",
		label = "地皮的网格尺寸",
		options = biggridsizeoptions,
		default = 2,	
		hover = "地皮/干草叉的格子有多大.",
	},
	{
		name = "GOODCOLOR",
		label = "建筑放置颜色",
		options = color_options,
		default = "green",	
		hover = "可以在其中放置建筑.",
	},
	{
		name = "BADCOLOR",
		label = "建筑不可放置颜色",
		options = color_options,
		default = "red",	
		hover = "用于不能放置建筑颜色.",
	},
	{
		name = "NEARTILECOLOR",
		label = "最近的地皮颜色",
		options = color_options,
		default = "white",	
		hover = "用于最近的地皮颜色.",
	},
	{
		name = "GOODTILECOLOR",
		label = "地皮放置颜色",
		options = color_options,
		default = "whiteoutline",	
		hover = "可以在其中放置草皮.",
	},
	{
		name = "BADTILECOLOR",
		label = "地皮不可放置颜色",
		options = color_options,
		default = "blackoutline",	
		hover = "在那里你不能放置地皮.",
	},
	{
		name = "GOODPLACERCOLOR",
		label = "建筑放置颜色",
		options = placer_color_options,
		default = "white",	
		hover = "用于显示建筑放置颜色.",
	},
	{
		name = "BADPLACERCOLOR",
		label = "建筑不可放置颜色",
		options = placer_color_options,
		default = "black",	
		hover = "用于显示不可放置建筑颜色.",
	},

addTitle("自动做饭"),
	{
		name = "sw_autocook",
		label = "开关",
		hover = "自动烹饪的总开关",
		options = {
			{description = "开启", data = true,},
			{description = "关闭", data = false},
		},
		default = true,
	},
    {
        name = "autocook_Ctrl",
        label = "控制键",
        hover = "按下此键+点击锅 开始自动做饭",
        options = theKeys,
        default = 306,
    },
    {
        name = "autocook_last",
        label = "上道菜",
        hover = "按下此键将制作刚刚做过的菜",
        options = theKeys,
        default = false,
    },
    {
        name = "autocook_selnum",
        label = "锅的数量",
        hover = "选择更多或更少的烹饪锅",
        options =
        {
            {description = "更少", data = 2.5, hover = "选择更少的锅"},
            {description = "默认", data = 2},
            {description = "更多", data = 1.5, hover = "选择更多的锅，容易抢队友做的饭"},
        },
        default = 2
    },
	{
        name = "autocook_sel",
        label = "做饭速度",
        options = {
			{data = true, description = "高速", hover = "高速会看不到烹饪过放的啥, 适合熟悉自动做饭的玩家",},
			{data = false, description = "普通", hover = "旧版蘑菇慕斯的设置, 推荐萌新使用",},
		},
        default = true,
	},

addTitle("Tony YYDS"),
	{
		name = "sw_Tony",
		label = "Tony的开关",
		hover = "这个开关是之后所有功能的总开关, 其实现都依赖Tony, 他的B站主页：space.bilibili.com/326122271",
		options = {
			{description = "开启", data = true, hover = "已包括模组卡顿优化"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "tony_thesame",
		label = "视为同类",
		hover = "将宝石、贝壳、鹿角、饰品、玩具、孢子、杂草、蓝图草图广告、远古雕像当作是同样的物品参与排队论",
		options = {
			{description = "开启", data = true, hover="详情请在B站搜索Lazy Controls"},
			{description = "植物也是同类", data = "plant", hover="将种子和蔬菜、巨大蔬菜也视为同类~ 植物的命也是命󰀍"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "tony_reconn",
		label = "快速重连",
		hover = "在主页和游戏内添加【快速重连服务器】按钮",
		options = {
			{description = "开启", data = true, hover="开启上方Tony的开关才能生效"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "tony_repeat",
		label = "快速丢弃",
		hover = "Shift右键双击物品可以丢弃全部同种物品, Shift+Ctrl右键双击挨个丢弃同类物品",
		options = {
			{description = "开启", data = "normal_drop",  hover="开启上方Tony的开关才能生效"},
			{description = "丢弃在格点", data = "drop_on_grid", hover="会丢弃在网格上"},
			{description = "左键放格点", data = "drop_on_grid_leftclick", hover="左击放网格，右击正常丢弃"},
			{description = "关闭", data = false},
		},
		default = "normal_drop",
	},
	{
		name = "tony_doublego",
		label = "快速转移",
		hover = "Shift+左键双击可以转所有同类物品到容器",
		options = {
			{description = "开启", data = true,hover="开启上方Tony的开关才能生效"},
			{description = "快速打包", data = "autowrap",hover = "如果目标包裹已满并且装的物品都是同类的时候自动打包, 按下空格也会强制打包"},
			{description = "双击可以移动到厨具", data = "stewer",hover = "允许批量移动到厨具（不推荐）"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "tony_zoom",
		label = "快速缩放",
		hover = "Shift + 鼠标滚轮快速放大/缩小镜头",
		options = {
            {description = "4", data = 4},
            {description = "8", data = 8},
            {description = "12",data = 12},
            {description = "开启",hover="默认步长16", data = 16},
            {description = "20", data = 20},
            {description = "24", data = 24},
            {description = "28", data = 28},
            {description = "关闭", data = false}
        },
        default = 16
	},
	{
		name = "tony_easy_anchor",
		label = "快速用锚",
		hover = "使用最近的船锚",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "tony_easy_steering",
		label = "快速用舵",
		hover = "使用最近的船舵",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "tony_auto_carnival_feeding",
		label = "鸟吃虫虫",
		hover = "自动玩夏季盛宴鸟鸟吃虫虫",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "tony_honey",
		label = "引火取蜜",
		hover = "火把收蜂蜜",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "tony_compare_fish",
		hover = "重复比较鱼的重量, 吃最重的鱼！",
		label = "笼鸟池鱼",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "tony_killfish",
		label = "自动宰鱼",
		hover = "会宰掉身上的淡水鱼, 鳗鱼, 海鱼, 蜘蛛【不会宰活龙虾】",
		options = {
			{description = "开启", data = true, hover = "携带鱼或蜘蛛时生效"},
			{description = "不杀季节鱼和口水鱼", data = "yhz", hover = "群友【永恒者】定制的保护措施"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "tony_wagstaff_tool_giver",
		label = "走近科学",
		hover = "自动递给瓦格斯塔夫工具获得决战天体的材料",
		options = theBoardKeys,
		default = "biubiu",
	},
	{
		name = "tony_aqchange",
		label = "懒人排队论",
		hover = "Tony个人的一些排队论优化",
		options = {
			{description = "开启", data = true, hover="详情请在B站搜索Lazy Controls"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "tony_no_space",
		label = "空格删选器",
		hover = "按下空格不再响应或捡起这些东西, 只能点击触发",
		options = {
			{description = "开启", data = "evil_only", hover = "默认是仅不捡恶魔花"},
			{description = "不要捡花", data = "normal_only", hover = "不要捡小花儿, 如果做了养蜂场就打开吧"},
			{description = "仅夹夹绞盘", data = "winch_only", hover = "仅不触发夹夹绞盘, 别的维持原样"},
            {description = "恶魔花和正常花", data = "no_flower", hover = "恶魔花和正常花都不捡"},
			{description = "夹夹绞盘和花", data = "no_winch_using", hover = "按下空格不会过去开夹夹绞盘和花"},
			{description = "关闭", data = false},
		},
		default = "evil_only",
	},
	{
		name = "tony_reweapons",
		label = "自动更换武器",
		hover = "武器耐久用完自动换下一把",
		options = {
			{description = "开启", data = true, hover="站撸BOSS很好用, 比如做了黑心工厂用影刀站撸蟾蜍王"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "tony_bundle_first",
		label = "优先放入容器",
		hover = "shift+点击身上的物品, 优先放入哪个容器",
		options = {
			{description = "开启", data = true, hover = "默认是优先放入打包纸和锅"},
			{description = "优先打包纸", data = 2, hover = "只优先打包纸, 不优先锅"},
			{description = "优先厨具", data = 3, hover = "只优先锅, 不优先打包纸"},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "tony_unblocked_castspell",
		label = "取消施法限制",
		hover = "你可以在猪王屁股上点唤星了",
		options = {
			{description = "开启", data = true,},
			{description = "关闭", data = false},
		},
		default = true,
	},
	{
		name = "tony_endless_repeat_key",
		label = "切换排队论无尽重复模式",
		hover = "重复进行可行的工作",
		options = theKeys,
		default = false,
	},


	addTitle("开发者模式"),
		{
			name = "sw_author",
			label = "调试总开关",
			hover = "蘑菇慕斯调试用的, 非作者不要打开",
			options = {
				{description = "开启", data = true,},
				{description = "关闭", data = false},
			},
			default = true,
		},
		{
			name = "sw_testworld",
			label = "攻速测试",
			hover = "开发人员使用, 其他人慎开, 会造成卡顿！",
			options = {
				{description = "开启", data = true,},
				{description = "关闭", data = false},
			},
			default = false,
		},
		{
			name = "sw_dev_board",
			label = "调试面板",
			hover = "",
			options = {
				{description = "开启", data = true},
				{description = "关闭", data = false},
			},
			default = true,
		},
		{
			name = "sw_testfunc",
			label = "卡海与解控",
			hover = "慕斯的测试功能, 非开发者请勿开启[启用测试面板来开放此项]",
			options = {
				{description = "开启", data = true},
				{description = "关闭", data = false},
			},
			default = true,
		},
		{
			name = "sw_eyeofterror",
			label = "内部测试",
			hover = "内部测试功能, 仅供呼吸测试",
			options = {
				{description = "开启", data = true,},
				{description = "关闭", data = false},
			},
			default = true,
		},
		{
			name = "sw_looktietu",
			label = "查看代码贴图动画",
			hover = "",
			options = {
				{description = "开启", data = true},
				{description = "关闭", data = false},
			},
			default = false,
		},
}

for i = 1, #configuration_options do
    local opt = configuration_options[i]
    if opt.options == theKeys or opt.options == theBoardKeys  then
        opt.oklist = true
    end
end