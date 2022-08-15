
local SU = "noise/GetOut/quiet"
-- 宠物
local pet_sounds = {
    ["dontstarve/creatures/together/pupington/"] = { "emote_scratch","pant","bark","tail","growl","sleep", },
    ["dontstarve/creatures/together/sheepington/"] = { "stallion","walk","grunt","yell","curious","chew","angry","bodyfall","sleep", },
    ["dontstarve/creatures/together/perdling/"] = { "walk","nuzzle","wingflap","distress","eat_pre","distress_long","sleep_pre","sleep_in","sleep_out", },
    ["dontstarve_DLC001/creatures/together/dragonling/"] = { "buttstomp","buttstomp_voice","blink","sleep_pre","emote_flame","swipe","emote_combat","emote_combat_2","eat_pre","eat","angry","emote","fly_LP","sleep", },
    ["dontstarve_DLC001/creatures/together/glomling/"] = { "flap_LP","bounce_voice","bounce_ground","emote_2","emote_combat","clap","eat_loop","vomit_voice","sleep_voice"},
    ["dontstarve_DLC001/creatures/together/puft/"]  = { "flap_LP","bounce_voice","bounce_ground","emote_2","emote_combat","clap","eat_loop","vomit_voice","sleep_voice"},
    ["dontstarve_DLC001/creatures/together/kittington/"] = { "yawn","emote_lick","emote","emote_nuzzle","hiss","pounce","eat_pre","eat","disstress","sleep", },
    ["turnoftides/creatures/together/lunarmothling/"] = { "emote1", "emote2", "emote_nuzzle", "idle", "emote_cute", "emote_combat", "interact_active", "interact_passive", "vo_cute", "eat_pre", "eat_LP", "distress", "walk", "emote_pet", "sleep_pre", "sleep_in", "sleep_out", "sleep_pst" },
    ["terraria1/mini_eyeofterror/"] = {"emote1", "emote2", "emote_cute", "emote_pet", "emote_combat", "interact_active", "eat_lp", "eat_loop", "eat_pst", "eat_pre", "distress", "emote_nuzzle", "sleep_pre", "sleep_pst",},
}
for k,v in pairs(pet_sounds) do
    for i = 1,  #pet_sounds[k] do
        RemapSoundEvent( tostring(k)..pet_sounds[k][i] , SU )
    end
end


-- 格罗姆
RemapSoundEvent("dontstarve_DLC001/creatures/glommer/sleep_voice", SU)
RemapSoundEvent("dontstarve_DLC001/creatures/glommer/idle_voice", SU)
RemapSoundEvent("dontstarve_DLC001/creatures/glommer/flap",SU)
RemapSoundEvent("dontstarve_DLC001/creatures/glommer/bounce_voice",SU)
RemapSoundEvent("dontstarve_DLC001/creatures/glommer/bounce_ground",SU)
RemapSoundEvent("dontstarve/creatures/together/pupington/clap",SU)


-- 果蝇
RemapSoundEvent("farming/creatures/fruitfly/LP", SU)
RemapSoundEvent("farming/creatures/fruitfly/sleep", SU)
RemapSoundEvent("farming/creatures/fruitfly/hit", SU)

--大便
RemapSoundEvent("dontstarve/common/flies", SU)

--曼德拉草
RemapSoundEvent("dontstarve/creatures/mandrake/walk", SU)

--捕鸟器
RemapSoundEvent("dontstarve/common/birdtrap_rustle", SU)

--机器人过载
RemapSoundEvent("dontstarve/characters/wx78/charged", SU)

--灭火器
RemapSoundEvent("dontstarve_DLC001/common/firesupressor_idle", SU)
-- RemapSoundEvent("dontstarve_DLC001/common/firesupressor_shoot", SU)
RemapSoundEvent("dontstarve_DLC001/common/firesupressor_spin", SU)
RemapSoundEvent("dontstarve_DLC001/common/firesupressor_chuff", SU)
-- RemapSoundEvent("dontstarve_DLC001/common/firesupressor_idle_LP", SU)

-- 蜂窝
RemapSoundEvent("dontstarve/bee/bee_box_LP", SU)
RemapSoundEvent("dontstarve/bee/bee_hive_LP", SU)


-- 炼金引擎·
RemapSoundEvent("dontstarve/common/researchmachine_lvl3_idle", SU)
RemapSoundEvent("dontstarve/common/researchmachine_lvl3_idle_LP", SU)
RemapSoundEvent("dontstarve/common/researchmachine_lvl2_idle_LP", SU)

-- 智囊团
RemapSoundEvent("turnoftides/common/together/seafaring_prototyper/LP", SU)

-- 冰箱
RemapSoundEvent("dontstarve/common/ice_box_LP", SU)

--研磨器
RemapSoundEvent("dontstarve/common/together/portable/blender/proximity_LP", SU)

-- 薇诺娜发电机
RemapSoundEvent("dontstarve/common/together/spot_light/electricity", SU)

-- 天体传送门
RemapSoundEvent("dontstarve/common/together/spawn_vines/spawnportal_idle_LP", SU)
RemapSoundEvent("dontstarve/common/together/spawn_vines/spawnportal_idle", SU)--火烟
RemapSoundEvent("dontstarve/common/together/spawn_vines/spawnportal_scratch", SU)
RemapSoundEvent("dontstarve/common/together/spawn_vines/spawnportal_jacob", SU)
RemapSoundEvent("dontstarve/common/together/spawn_vines/spawnportal_blink", SU)--眨眼睛
RemapSoundEvent("dontstarve/common/together/spawn_vines/vines", SU)--葡萄藤

-- 火炉
RemapSoundEvent("dontstarve/common/together/dragonfly_furnace/fire_LP", SU)
RemapSoundEvent("dontstarve/common/together/dragonfly_furnace/light", SU)

-- 矮星极光
RemapSoundEvent("dontstarve/common/staff_star_LP", SU)
RemapSoundEvent("dontstarve/common/staff_coldlight_LP", SU)

-- 天体宝球
RemapSoundEvent("dontstarve/common/together/celestial_orb/idle_LP", SU)
RemapSoundEvent("dontstarve/common/together/celestial_orb/idlesound", SU)

-- 传送法阵
RemapSoundEvent("dontstarve/common/telebase_hum", SU)


-- 天体探测仪
RemapSoundEvent("grotto/common/archive_resonator/idle_LP", SU)

-- 靠近虫洞
RemapSoundEvent("dontstarve/common/teleportworm/idle", SU)


-- 火鸡
RemapSoundEvent("dontstarve/creatures/perd/gobble", SU)
RemapSoundEvent("dontstarve/creatures/perd/scream", SU)
RemapSoundEvent("dontstarve/creatures/perd/run", SU)
RemapSoundEvent("dontstarve/creatures/perd/sleep", SU)

-- 蜜蜂
RemapSoundEvent("dontstarve/bee/bee_takeoff", SU)
RemapSoundEvent("dontstarve/bee/bee_fly_LP", SU)



-- 青蛙
RemapSoundEvent("dontstarve/frog/walk", SU)
-- RemapSoundEvent("dontstarve/frog/attack_spit", SU)
RemapSoundEvent("dontstarve/frog/grunt", SU)
-- RemapSoundEvent("dontstarve/frog/attack_voice", SU)
RemapSoundEvent("dontstarve/frog/wake", SU)

-- 蚊子
RemapSoundEvent("dontstarve/creatures/mosquito/mosquito_fly_LP", SU)

-- 球状光虫
RemapSoundEvent("grotto/creatures/light_bug/fly_LP", SU)

-- 月熠
RemapSoundEvent("moonstorm/common/moonstorm/spark_LP", SU)

-- 秃鹫
RemapSoundEvent("dontstarve_DLC001/creatures/buzzard/hurt", SU)

-- 坎普斯背包
RemapSoundEvent("dontstarve/movement/foley/krampuspack", SU)
-- 晨星锤
RemapSoundEvent("dontstarve_DLC001/common/morningstar", SU)
-- 铥矿甲
RemapSoundEvent("dontstarve/movement/foley/metalarmour", SU)
-- 骨甲
RemapSoundEvent("dontstarve/movement/foley/bone", SU)
-- 魂甲
RemapSoundEvent("dontstarve/movement/foley/nightarmour", SU)

--露西斧
RemapSoundEvent("dontstarve/characters/woodie/lucytalk_LP", SU)

--其他鬼魂
RemapSoundEvent("dontstarve/ghost/ghost_girl_howl_LP", SU)
RemapSoundEvent("dontstarve/ghost/ghost_girl_howl", SU)
RemapSoundEvent("dontstarve/ghost/ghost_girl_attack_LP", SU)
RemapSoundEvent("dontstarve/ghost/ghost_girl_attack", SU)
RemapSoundEvent("dontstarve/ghost/ghost_girl_redux", SU)
RemapSoundEvent("dontstarve/ghost/ghost_howl", SU)
RemapSoundEvent("dontstarve/ghost/ghost_attack_LP", SU)
RemapSoundEvent("dontstarve/ghost/ghost_haunt", SU)
RemapSoundEvent("dontstarve/ghost/ghost_howl_LP", SU)



-- 鸟类
RemapSoundEvent("dontstarve/creatures/smallbird/wings", SU)
RemapSoundEvent("dontstarve/creatures/smallbird/chirp", SU)
RemapSoundEvent("dontstarve/creatures/smallbird/blink", SU)
RemapSoundEvent("dontstarve/creatures/smallbird/chirp_short", SU)
--RemapSoundEvent("dontstarve/creatures/smallbird/attack", SU)
RemapSoundEvent("dontstarve/creatures/smallbird/hurt", SU)
RemapSoundEvent("dontstarve/birds/flyin", SU)
RemapSoundEvent("dontstarve/birds/chirp_crow", SU)
RemapSoundEvent("dontstarve/birds/takeoff_crow", SU)
RemapSoundEvent("dontstarve/birds/chirp_robin", SU)
RemapSoundEvent("dontstarve/birds/takeoff_robin", SU)
RemapSoundEvent("dontstarve/birds/chirp_junco", SU)
RemapSoundEvent("dontstarve/birds/takeoff_junco", SU)
RemapSoundEvent("dontstarve/birds/chirp_canary", SU)
RemapSoundEvent("dontstarve/birds/takeoff_canary", SU)

-- 切斯特走路
RemapSoundEvent("dontstarve/creatures/chester/boing", SU)

-- 海浪地皮
RemapSoundEvent("hookline_2/amb/hermit_island", SU)
-- RemapSoundEvent("dontstarve_DLC001/spring/springbadlandAMB", SU)
-- RemapSoundEvent("dontstarve_DLC001/AMB/badland_summer", SU)
-- RemapSoundEvent("dontstarve/AMB/badland_rain", SU)

-- 约束静电
RemapSoundEvent("moonstorm/common/static_ball_contained/idle_LP", SU)


