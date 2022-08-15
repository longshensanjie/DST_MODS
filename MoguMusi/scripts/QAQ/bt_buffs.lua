local seg_time = TUNING.SEG_TIME--一格时间，默认30秒
local total_day_time = TUNING.TOTAL_DAY_TIME--一天时间，16格，8分钟
return{
    -- 电羊果冻
    buff_electricattack = {
        image = "voltgoatjelly",
        duration = TUNING.BUFF_ELECTRICATTACK_DURATION,
        judge = {"voltgoatjelly"},
        describe = "攻击带电",
    },
    -- 升温降温用官方的代码
    -- buff_dragonchilisalad = {
    --     image = "dragonchilisalad",
    --     duration = TUNING.BUFF_FOOD_TEMP_DURATION,
    --     judge = {"dragonchilisalad"},
    --     describe = "抵御严寒",
    -- },
    -- buff_gazpacho = {
    --     image = "gazpacho",
    --     duration = TUNING.BUFF_FOOD_TEMP_DURATION,
    --     judge = {"gazpacho"},
    --     describe = "透心凉",
    -- },
    -- 蓝带鱼排
    buff_moistureimmunity = {
        image = "frogfishbowl",
        duration = TUNING.BUFF_MOISTUREIMMUNITY_DURATION,
        judge = {"frogfishbowl"},
        describe = "免疫潮湿",
    },
    wormlight_light_greater = {
        image = "glowberrymousse",
        duration = TUNING.WORMLIGHT_DURATION * 4,
        judge = {"_spice_phosphor","glowberrymousse", "dish_fleshnapoleon"},
        describe = "发光",
    },
    -- 蘑菇蛋糕
    buff_sleepresistance = {
        image = "shroomcake",
        duration = TUNING.SLEEPRESISTBUFF_TIME,
        judge = {"shroomcake"},
        describe = "蘑菇慕斯",
    },
    -- 辣
    buff_attack = {
        image = "pepper",
        duration = TUNING.BUFF_ATTACK_DURATION,
        judge = {"_spice_chili"},
        describe = "火辣伤害",
    },
    -- 蒜
    buff_playerabsorption = {
        image = "garlic",
        duration = TUNING.BUFF_PLAYERABSORPTION_DURATION,
        judge = {"_spice_garlic"},
        describe = "皮糙肉厚",
    },
    -- 甜
    buff_workeffectiveness = {
        image = "multitool_axe_pickaxe_pickaxeaxe",
        duration = TUNING.BUFF_WORKEFFECTIVENESS_DURATION,
        judge = {"_spice_sugar"},
        describe = "高效工作",
    },

    -- 糖豆
    healthregenbuff = { 
        image = "jellybean", 
        duration = TUNING.JELLYBEAN_DURATION,
        judge = {"jellybean"},
        describe = "彩虹糖",
    },
    
    sweettea_buff = {
        image = "sweettea",
        duration = TUNING.SWEETTEA_DURATION,
        judge = {"sweettea"},
        describe = "知识增加",
    },
    buff_hot = {
        image = "heatrock_fire5",
        duration = 5,
        judge = {"stuffedeggplant","dragonpie","honeyham","kabobs","hotchili","pepperpopper","bunnystew","sweettea"},
        describe = "变暖",
    },
    buff_cold = {
        image = "icehat",
        duration = 5,
        judge = {"fruitmedley","icecream","watermelonicle","bananapop","ceviche","frozenbananadaiquiri",},
        describe = "清凉",
    },

    
    -- 海难的咖啡
    buff_coffee = {
        image = "cane", 
        duration = total_day_time / 2,
        judge = {"coffee"},
        describe = "咖啡加速",
    },
}