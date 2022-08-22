-- 总配置表
-- 注意, 此表加载顺序请勿随意修改, 牵一发而动全身

-- 如需增删改查配置，请按照此格式
--[[
{
    "sw_shizhong",                                                                  -- 第一个参数 写检查的config名, 类型为字符串或者表, 该项不存在不会加载下面的模组且不会捕捉提示
    {"季节时钟","Combined Staus", "组合状态", "合并状态栏",},                         -- 第二个参数 写要检查的模组, 类型为字符串或者表, 第一个参数是功能提示, 冲突后会有提示. 而且关闭之后的模组
    {1, 49},                                                                        -- 第三个参数  写加载的模组, 类型为字符串，数字或者表，模组位置必须在 scripts/Collections/ 这个目录下
    "哈哈哈.lua",                                                                    -- 第四个参数（可选）, 写要加载的模组详细位置, 这里的模组会优先第三个参数加载
},
]]

ShroomCakeModsTable = 
{
    -- 测试功能不应该受其他部分导入的影响, 应该置顶
    {
        {"sw_author", "sw_eyeofterror",},
        {},
        {123, 127},
    },
    {
        {},
        {"修复五格"},
        117,
    },
    {
        {},
        {"按键配置模组","In-game Client Mod Management","游戏内设置","lazy control"},
        107,
    },
    {
        {"sw_autodragon","sw_mainboard"},
        {"自动打龙蝇"},
        {126},
    },
    {
        "sw_shizhong",
        {"季节时钟","Combined Staus", "组合状态", "合并状态栏",},
        {1},
    },
    {
        {"shizhong_CAVE","sw_shizhong"},
        {"洞穴时钟", "Cave Clock"},
        49,
    },
    {
        "sw_minimap",
        {"小地图","Minimap HUD", "Small Map",},
        2,
    },
    {
        "sw_showmodfolder",
        {"模组目录","Show Mod Folder",},
        3,
    },
    {
        "sw_craftpot",
        { "智能锅", "Craft Pot", "工艺壶","SmartCrockPot"},
        4,
    },
    {
        {"sw_huazhi", "sw_naocan",},
        {"清除脑残画面", "Insanity Begone", "滤镜"},
        5,
    },
    {
        {"sw_huazhi", "sw_snowtile",},
        {"积雪去除", "积雪", "snow tile disabler","weather fx disabler" ,"滤镜"},
        37,
    },
    {
        {"sw_huazhi", "sw_filter",},
        {"四季滤镜", "美颜", "色彩调节", "画质","滤镜","Color Adjustments"},
        {31,109},
    },
    {
        {"sw_huazhi", "sw_color",},
        {"色彩调节","美颜", "画质","滤镜","Color Adjustments"},
        {93,109},
    },
    {
        {"sw_huazhi","sw_shabao",},
        {"去除沙暴","去除风暴","Disable Sanddustover","滤镜",},
        52,
    },
    {
        {"sw_huazhi","sw_GiantTree",},
        {"水木滤镜","Decoration Disabler",},
        55,
    },
    {
        "sw_AUTO_EAT_FOOD",
        {"自动吃饭", "autoeat",},
        85,
    },
    {
        "sw_indicator",
        {"BOSS指示","Indicators","方向指示"},
        19,
    },
    {
        "sw_Q",
        {"行为排队论", "排队论", "行为学", "ActionQueue",},
        15,
    },
    {
        "sw_boas",
        {"装备控制论", "Equipment Control", "快捷装备",},
        82,
    },
    {
        {"littledro","sw_Q",},
        {"排队论加强","quickactionforactionqueue",},
        86,
    },
    {
        {"sw_huxi2"},
        {"呼吸检测","生物呼吸"},
        {111,},
    },
    {
        "sw_item",
        {"物品信息", "信息显示", "insight", "showme", "提示语句", "Foodvalue"},
        26,
    },
    {
        "sw_box",
        {"箱子记忆","insight", "showme", "提示语句",},
        119,
    },
    {
        "sw_box",
        {"箱子记忆","insight",},
        125,
    },
    {
        "sw_autocook",
        {"自动做饭", "auto cooking","Crockpot Repeater", "自动烹饪",},
        43,
    },
    {
        "sw_hidecrown",
        {"隐藏启迪之冠","Concealed Crown"},
        87,
    },
    {
        "sw_xuangao",
        {"快捷宣告","Status Announcements"},
        {7,},
    },
    {
        "sw_tele",
        {"传送标记",},
        80,
    },
    {
        {"sw_lx_dumbbell","sw_lx"},
        {"自动举哑铃","大力士辅助"},
        95,
    },
    {
        {"sw_lx_wait","sw_lx"},
        {"挂机打转","大力士辅助"},
        96,
    },
    {
        {"sw_lx_auto","sw_lx"},
        {"自动健身", "健身","auto gym"},
        79,
    },
    {
        {"sw_biaoqing", "biaoqing_KEYBOARDTOGGLEKEY"},
        {"表情轮盘", "Gesture Wheel"},
        6,
    },
    {
        {"sw_eyeplant",},
        {"眼球预测", "食人花预测", "eyeplant", "Lureplant"},
        8,
    },
    {
        {"sw_range"},
        {"范围显示", "insight", "display all range" , "Fling Range"},
        9,
    },
    {
        {"sw_OBC"},
        {"OB视角","Observer Camera",},
        11,
    },
    {
        {"sw_cheat",},
        {"鹰眼视角", "高空鹰眼", "智能鹰眼", "鹰眼模式", "视野辅助", "鹰眼全图"},
        12,
    },
    {
        {"sw_cheat", "sw_lantern",},
        {"按键丢物品"},
        30,
    },
    {
        {"sw_cheat","sw_manualAdd"},
        {"快捷修复"},
        84,
    },
    {
        {"sw_cheat", "sw_toggle",},
        {"切换延迟补偿","延迟补偿","compensation"},
        45,
    },
    {
        {"sw_cheat","sw_showaggro"},
        {"关系显示","仇恨显示","show aggro"},
        35,
    },
    {
        {"sw_cheat", "sw_jungler", },
        {"打野辅助", "攻击范围", "AttackRange",},
        10,
    },
    {
        {"sw_cheat", "sw_jungler", "attack_timer"},
        {"攻击CD", "attack timer", "小狐狸", "KEMOMIMI",},
        94,
    },
    {
        {"sw_wendy"},
        {"温蒂辅助", "Abigail Keybinds","比盖尔快捷键"},
        14,
    },
    {
        {"sw_wendy", "sw_ghost"},
        {"小惊吓辅助", "小惊吓"},
        23,
    },
    {
        {"sw_keepfollow"},
        {"保持跟随", "自动跟随", "如影随形", "keep following", "富贵险中求"},
        47,
    },
    {
        {"sw_board"},
        {"管理员面板", "Admin Scoreboard",},
        16,
    },
    {
        "sw_warning",
        {"怪物警告", "Advanced Warning"},
        17,
    },
    {
        "sw_unequip",
        {"自动脱落", "Auto-unequip"},
        {18, 124},
    },
    {
        "sw_debugger",
        {"智能模组", "模组冲突", "错误报告检查器", "Don't Starve Debugger"},
        {21,},
        "libs/env.lua",
    },
    {
        "sw_wormhole",
        {"虫洞标记", "虫洞", 
        -- "Wormhole"
    },
        22,
    },
    {
        "sw_stat",
        {"状态变化", "状态显示", "Stat Change Display"},
        24,
    },
    {
        "sw_nickname",
        {"昵称显示", "nickname"},
        25,
        "libs/lib_ver.lua",
    },
    {
        "sw_GEO",
        {"几何布局", "Geometric Placement", "建筑几何"},
        27,
    },
    {
        "sw_phase",
        {"暴动时钟", "nightmare phase indicator",},
        28,
    },
    {
        "sw_wall",
        {"不要打墙", "No wall attack", "打墙", "高级控制", "Advanced Attack", "Advanced Controls"},
        29,
    },
    {
        {"sw_wortox", "wortox_ex","wortox_ex_btn"},
        {"恶魔人防止爆魂"},
        73,
    },
    {
        {"sw_wortox", "wortox_RELEASE_KEY"},
        {"恶魔人快速治疗","Wortox Quick Heal", "no wasted souls"},
        32,
    },
    {
        {"sw_wortox", "wortox_hx"},
        {"恶魔人快速挪移", "恶魔人辅助"},
        116,
    },
    {
        {"sw_wanda"},
        {"旺达快捷键", "wanda keybinds"},
        64,
    },
    {
        {"sw_wanda", "wanda_display"},
        {"旺达血量条", "wanda health meter", "旺达的血量", "healthbadge", "血量显示"},
        65,
    },
    {
        {"sw_wanda", "wanda_watch"},
        {"显示冷却时间", "Show cooldown time"},
        66,
    },
    {
        {"sw_wanda", "wanda_weapon"},
        {"旺达武器修复"},
        67,
    },
    {
        {"sw_wanda", "wanda_rename"},
        {},
        118,
    },
    {
        {"sw_autofishing"},
        {"自动海钓", "Auto fishing", "海钓", "独行长路", "Don't Starve Alone"},
        34,
    },
    {
        "sw_gardeneer",
        {"耕种园艺帽","园艺帽","Gardeneer Hat"},
        40,
    },
    {
        {"sw_gardeneer","sw_mySeedTex"},
        {"种子贴图", "Item icon", "高清图标"},
        83,
    },
    {
        {"sw_cookbook","sw_mainboard"},
        {"烹饪指南", "Cookbook",},
        39,
    },
    {
        "sw_justgo",
        {"自动寻路", "Never get lost"},
        41,
    },
    {
        "sw_shutup",
        {"去除噪音", "噪音", "noise"},
        33,
    },
    {
        "sw_autoadd",
        {"魔光护符自动加燃料", "魔光", "Magiluminescence"},
        42,
    },
    {
        "sw_skeleton",
        {"骨甲自动切换", "骨甲", "bone armor"},
        44,
    },
    {
        "sw_connect",
        {"一键直连", "Connection Manager", "直连"},
        13,
    },
    {
        "sw_peopleNum",
        {"增加人数上限", "人数上限"},
        54,
    },
    {
        "sw_showhead",
        {"角色存档图标", "Show Character Portrait"},
        72,
    },
    {
        -- 该项加载必须在其他"sw_tony"之前
        {"sw_Tony",},
        {"Tony相关所有功能","lazy control",},
        {110,
            108,            -- 私货, 注释此行将取消
        },
        "scripts/lazy_controls/util.lua",
    },
    {
        {"sw_Tony", "tony_repeat"},
        {"重复丢弃", "lazy control",},
        58,
    },
    {
        {"sw_Tony", "tony_reconn"},
        {"快速重连", "Quick Connect",},
        71,
    },
    {
        {"sw_Tony", "tony_doublego"},
        {"快速转移", "lazy control",},
        62,
    },
    {
        {"sw_Tony", "tony_zoom"},
        {"快速缩放", "lazy control",},
        63,
    },
    {
        {"wagstaff_tool_giver"},
        {"发明家工具辅助","WagstaffToolInfo"},
        103,
    },
    {
        {"sw_Tony", "tony_wagstaff_tool_giver"},
        {"走近科学", "lazy control",},                          -- 此处环境已经被修改，未知哪个文件，待修复
        120,
    },
    {
        {"sw_Tony", "tony_bundle_first"},
        {"优先放入容器", "lazy control",},
        104,
    },
    {
        {"sw_Tony", "tony_aqchange"},
        {"懒人排队论", "lazy control",},
        98,
    },
    {
        {"sw_Tony", "tony_auto_carnival_feeding","tony_aqchange"},
        {"鸟吃虫虫", "lazy control","懒人排队论"},
        102,
    },
    {
        {"sw_Tony", "tony_no_space"},
        {"空格筛选器", "lazy control",},
        106,
    },
    {
        {"sw_Tony", "tony_reweapons"},
        {"自动更换武器", "lazy control",},
        56,
    },
    {
        {"sw_Tony", "tony_honey"},
        {"引火取蜜", "lazy control",},
        59,
    },
    -- {
    --     {"sw_mainboard", "sw_shiguo"},
    --     {"自动分石果","石果分组", "石果丢弃"},
    --     48,
    -- },
    {
        {"sw_Tony", "tony_killfish"},
        {"自动宰鱼","lazy control"},
        50,
    },
    {
        {"sw_Tony", "tony_compare_fish"},
        {"笼鸟池鱼","lazy control"},
        60,
    },
    {
        {"sw_Tony", "tony_unblocked_castspell"},
        {"取消施法限制","lazy control"},
        61,
    },
    {
        {"sw_mainboard", "sw_shadowheart"},
        {"黑心工厂",},
        51,
    },
    {
        {"sw_mainboard", "sw_altarfinder"},
        {"寻找天体",},
        57,
    },
    {
        {"sw_mainboard", "sw_autofish"},
        {"自动钓鱼","autofish"},
        38,
    },
    {
        {"sw_mainboard", "sw_winchactivator"},
        {"贝壳工厂",},
        70,
    },
    {
        {"sw_mainboard", "sw_snapping"},
        {"Snapping Tills", "ingTill"},
        69,
    },
    {
        {"sw_mainboard", "sw_DAG"},
        {"自动做档案馆任务", "档案馆任务", "ArchiveTask","档案馆标记","档案馆标记"},
        {74,115,},
    },
    {
        {"sw_mainboard", "sw_wow"},
        {"解控"},
        46,
    },
    {
        {"sw_mainboard", "sw_rescue"},
        {"一键Rescue"},
        91,
    },
    {
        "sw_autorow",
        {"自动划船", "lazy control", "rowing"},
        53,
    },
    {
        {"sw_planting", "plant_setting", "plant_deploy", "plant_placer",},
        {"圆形种植", "Round Deploy"},
        68,
    },
    {
        {"sw_tame"},
        {"显示驯化度","domestication", "insight", "show me", "信息显示", "提示语句", "beefalo","牛牛驯化度"},
        77,
    },
    {
        {"sw_skinQueue"},
        {"分解重复皮肤","重复皮肤", "SkinQueue"},
        78,
    },
    {
        {"sw_T", "GOP_TMIP_TOGGLE_KEY"},
        {"T键控制台", "Too Many", "T键"},
        36,
    },
    {
        {"sw_author", "sw_looktietu"},
        {"显示代码贴图", "looktietu"},
        76,
    },
    {
        {"sw_author", "sw_testworld",},
        {"攻速测试"},
        97,
    },
    {
        {"sw_author", "sw_dev_board","sw_mainboard"},
        {"调试面板", "Modder辅助"},
        99,
    },
    {
        {"sw_skinHistory"},
        {"局内开启皮肤","Skins extender","自动开礼物","挂机开皮肤","super AFK"},
        89,
    },
	{
        {"sw_swingboy"},
        {"旋转角色模型","Rotate Character Model"},
        101,
    },
	{
        {"sw_kaihua"},
        {"开花仪","沃姆伍德辅助","Wormwood Bloom Predictor"},
        114,
    },
	{
        {"sw_tumbleweed"},
        {"风滚草预测","风滚草"},
        90,
    },
    {
        {"sw_mainboard"},
        "视频简介",
        121,
    },
    -- 以下内容为模组核心, 请勿做任何改动！
    {
        {"sw_mainboard", "sw_debugger"},
        "蘑菇慕斯的功能冲突查询",
        113,
    },
    {
        -- 此内容必须在所有功能之后！
        {"sw_mainboard"},
        "蘑菇面板",
        88,
    },
    
}

-- 合集mod就不支持合集，冲突了别找我，看着火大
ShroomCakeBanMods = {
    "鸡尾酒-永远的神",      -- 先给自己一刀
    "生存辅助", "小白客户端", "超级客户端", "Keeth客户端", "小妖", "作弊器", "一键客户端", "Pusheen", "欺诈客户端"}

-- 如需本地使用，请改文件夹名为 `shroomcake` 或 在这里添加文件夹名
-- 如需无授权传创意工坊，qnmngbd, 收一堆垃圾邮件, 谁爱维护去维护
AuthorizationMods = {"shroomcake", "workshop-2732260441","workshop-2199027653598535018","workshop-2199027653598531546"}