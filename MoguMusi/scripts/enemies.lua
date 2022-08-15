local enemies = {}
local ent
local FRAMES = TheSim:GetTickTime()
local default_attack_time = 4
--To-can't: Abigail(attacking), Ghost(attacking), Deerclops(Laser is random CD), Deciduous tree(Root attack and birchnut drakes)(Not sure if worth sacrificing performance, because these dudes don't have a different prefab from the normal tree)(Will possibly leave this when I do timers for objects, I'll hide timers there, so it should be more optimized with this tree), crabking(didn't account for his yellow gems , because it's too hard to get that number)(For server-side, you can get it as inst.socketed, but client-side might only be possible via the modification of the OverrideSymbol function); Pig Elites(Spawned from Pig Token)
--Not sure if ghosts are possible. They attack with their own period, they don't have any special animation for attacking(One can see this when Abigail is far from Wendy and Abigail gets hit by some monster)
--Deciduous Tree isn't really a mob. It has no health, but it does attack. Not sure how I can do this one. Leaving it off for when(More like if) I'm doing objects.

local function AddPrefab(prefab,default_attack_period,attack_period_special,internal_timers)
    enemies[prefab] = {}
    enemies[prefab]["attack_period"] = default_attack_period
    enemies[prefab]["attack_period_special"] = attack_period_special--Insert a table of tables.
    --Considering there are mobs who change their attack speed from different states, it would be wise to just have a table of attack speeds and their conditions. That would make stuff easier to read, in my opinion, and it would be easier to implement new mobs.
    enemies[prefab]["int_timers"] = internal_timers
    --Internal timers should be formatted like so:
    --name = name(Eg. name = "Slam"),time = time(eg. time = 10) condition = condition (eg. condition = inst.AnimState:IsCurrentAnimation("atk"))
    --The internal_timers should be a table with tables of timer name, timer time, timer condition. Changing attack period should be fine as it is. Hope I don't regret those words.
    --Note: Should add some distinctive conditions as some stuff might overlap in the future.
    --For the conditions you should do something like "ANIMATION POUND" "TAG CHASEANDATTACK" and then have timer.lua check what it has to check by grabbing the first word for the function.
    -- Possible inputs might include "TAG X"; "ANIM Y"...
end

local function AddInternalTimer(inst,name,time,condition,const, offcooldown, alwayshidden,condition2)
table.insert(inst,#inst+1,{name = name, time = time, condition = condition, constant = const or false, canoffcooldown = offcooldown or false, alwayshidden = alwayshidden or false, condition2 = condition2})    --constant: has to constantly satisfy condition for timer not to reset. Added after slurtle_timer_table fire timer.
--canoffcooldown: Should it not be able to retrigger while it isn't available(is on cooldown).
--alwayshidden: Cooldown will be hidden unless it is active.
end
--Note 1: It doesn't seem like charge is something that's time based, but distance based, so I can't actually time it that well, people will just have to deal with it. Sorry.
--Note 2: Battlecry time is random (as seen in the components/combat.lua at the Combat:ResetBattleCryCooldown function), thus I can't do a cooldown for it. Sorry again.
--Note 3: Perhaps I should notify people when stuff is random? Don't want to confuse anyone, especially the newer players. This mod is for utility after all.
--Added [Rand.] on internal cooldowns that have some randomness. 
local dragonfly_timer_table = {} -- 龙蝇
AddInternalTimer(dragonfly_timer_table, "[蜻蜓] 三连拍", TUNING.DRAGONFLY_POUND_CD, "taunt") -- 20
AddInternalTimer(dragonfly_timer_table, "[蜻蜓] 眩晕持续时间", TUNING.DRAGONFLY_STUN_DURATION, "hit_large") -- 10
AddInternalTimer(dragonfly_timer_table, "[蜻蜓] 眩晕冷却", TUNING.DRAGONFLY_STUN_COOLDOWN, "hit_large") -- 60
AddInternalTimer(dragonfly_timer_table, "[蜻蜓] 暴怒冷却", TUNING.DRAGONFLY_ENRAGE_DURATION, "fire_on") -- 60
local minotaur_timer_table = {} -- 远古犀牛
AddInternalTimer(minotaur_timer_table,"[犀牛] 冲锋", 44*FRAMES, "paw_loop")
local rook_timer_table = {} -- 发条战车
AddInternalTimer(rook_timer_table,"冲锋", 30*FRAMES,"paw_loop")
local rook_nightmare_timer_table = {}
local deerclops_timer_table = {}
local cookiecutter_timer_table = {}
AddInternalTimer(cookiecutter_timer_table,"Eat", TUNING.COOKIECUTTER.EAT_DELAY,"drill_pst")
AddInternalTimer(cookiecutter_timer_table,"Drill Time",TUNING.COOKIECUTTER.DRILL_TIME,"drill_loop")
AddInternalTimer(cookiecutter_timer_table,"Flee",TUNING.COOKIECUTTER.FLEE_DURATION,"run_pre")
local spat_timer_table = {}
AddInternalTimer(spat_timer_table,"Spit", 3,"snot_pre")
local penguin_timer_table = {}
local monkey_timer_table = {}
local bearger_timer_table = {}
AddInternalTimer(bearger_timer_table,"[熊大] 打哈欠",TUNING.BEARGER_YAWN_COOLDOWN,"yawn")--14
AddInternalTimer(bearger_timer_table,"[熊大] 拍地板",TUNING.BEARGER_NORMAL_GROUNDPOUND_COOLDOWN,"ground_pound") --10
--AddInternalTimer(bearger_timer_table,"[BG] Max Charge Time",TUNING.BEARGER_MAX_CHASE_TIME,"ChaseAndRam")--9.5. There's no distinctive animation for charge, except the "charge_roar_loop" animation, but that one, as the name implies, loops and thus I can't really know when bearger started his charge :/--Future me: Bearger does get a "ChaseAndRam" tag when he's charging, but he loses it when he yawns mid-charge, which messes things up. I'll work on this in the future.
local mossling_timer_table = {}
AddInternalTimer(mossling_timer_table,"Spin",(15+72)*FRAMES,"spin_pre")--+74 if the player is within 7.5 units of the mossling when first spin is over. The mossling will start a second spin and will start a recovery after animation is over.
AddInternalTimer(mossling_timer_table,"Spin_2",(15+72+74)*FRAMES,"spin_pre")--Feels really annoying to add in that condition. And the timer will feel weird if it just randomly gains delay, so I'll try to do this instead? Hope this doesn't cause any confusion. Will need to write a note about this in the mod's page.
AddInternalTimer(mossling_timer_table,"[Rand. Â±0.5]Recover from Spin",5+4*FRAMES,"spin_pst")--Recovery from spin cooldown is math.random() + 4.5(SGMossling.lua, Line 396), so all I can do really is take the average of 5s.
local deciduoustree_timer_table = {}
local antlion_timer_table = {}
AddInternalTimer(antlion_timer_table,"沙子堡垒", TUNING.ANTLION_WALL_CD,"cast_sandcastle")
local beequeen_timer_table = {}
AddInternalTimer(beequeen_timer_table,"[蜂王] 繁殖蜜蜂",TUNING.BEEQUEEN_SPAWNGUARDS_CD[1],"spawn" )
AddInternalTimer(beequeen_timer_table,"[蜂王] 集中攻击",TUNING.BEEQUEEN_FOCUSTARGET_CD[1],"command2",nil,true)
local crabking_timer_table = {}
AddInternalTimer(crabking_timer_table,"[帝王蟹] 毁灭施法",TUNING.CRABKING_CAST_TIME+22*FRAMES,"cast_purple_pre")--Changes based on yellow gems.
AddInternalTimer(crabking_timer_table,"[帝王蟹] 冻结魔法",TUNING.CRABKING_CAST_TIME_FREEZE+22*FRAMES,"cast_blue_pre")--Changes based on yellow gems
AddInternalTimer(crabking_timer_table,"[帝王蟹] 自愈治疗",TUNING.CRABKING_HEAL_DELAY+10,"fix_pre")
AddInternalTimer(crabking_timer_table,"[帝王蟹] 召唤蟹拳",TUNING.CRABKING_FIX_TIME,"fix_pre")
local houndcorpse_timer_table = {}
AddInternalTimer(houndcorpse_timer_table,"Revive",228*FRAMES,"mutated_hound_reviving_pre")
local slurtle_timer_table = {}
AddInternalTimer(slurtle_timer_table,"Explode",8-2*FRAMES,"fire",true,nil,true)
AddInternalTimer(slurtle_timer_table,"Hide",47*FRAMES,"hide_loop")
local deer_red_timer_table = {}
AddInternalTimer(deer_red_timer_table,"Cast Fire Spell", TUNING.DEER_FIRE_CAST_CD,"atk_magic_pre")
local deer_blue_timer_table = {}
AddInternalTimer(deer_blue_timer_table,"Cast Ice Spell", TUNING.DEER_ICE_CAST_CD,"atk_magic_pre")
local malbatross_timer_table = {}
local mutated_penguin_timer_table = {}
local warg_timer_table = {}
AddInternalTimer(warg_timer_table,"Howl", TUNING.WARG_SUMMONPERIOD,"howl")
local fruitdragon_timer_table = {}
AddInternalTimer(fruitdragon_timer_table,"Fire Attack",TUNING.FRUITDRAGON.FIREATTACK_COOLDOWN,"attack_fire")
local toadstool_timer_table = {}--attack_infection, attack_channeling_idle, attack_basic
AddInternalTimer(toadstool_timer_table,"[蛤蟆] 蘑菇炸弹", TUNING.TOADSTOOL_ATTACK_PERIOD_LVL[0], "attack_basic")--CD Changes
AddInternalTimer(toadstool_timer_table,"[蛤蟆] 蘑菇树", TUNING.TOADSTOOL_MUSHROOMSPROUT_CD,"attack_channeling_pst")
AddInternalTimer(toadstool_timer_table,"[蛤蟆] 腐坏毒气", TUNING.TOADSTOOL_SPOREBOMB_CD_PHASE[1], "attack_infection")--CD Changes
AddInternalTimer(toadstool_timer_table,"[蛤蟆] 拍地板", TUNING.TOADSTOOL_POUND_CD, "attack_pound_pre")
local klaus_timer_table = {}
AddInternalTimer(klaus_timer_table,"[克劳斯] 指挥鹿", TUNING.KLAUS_COMMAND_CD,"command_pst")
AddInternalTimer(klaus_timer_table,"[克劳斯] 啃噬",TUNING.KLAUS_CHOMP_CD,"attack_chomp")
local spiderqueen_timer_table = {}
AddInternalTimer(spiderqueen_timer_table,"[蜘蛛女王] 孵化蜘蛛", TUNING.SPIDERQUEEN_GIVEBIRTHPERIOD+18*FRAMES,"poop_pst")
local stalker_timer_table = {}
AddInternalTimer(stalker_timer_table, "[复活骷髅]陷阱冷却时间", TUNING.STALKER_SNARE_CD,"attack1")
local stalker_atrium_timer_table = {}--taunt3; summon_pre;
--disappear is the death animation of shadow channelers(sweet)
--use replica.health:IsDead() to find out if a stalker minion is dead
AddInternalTimer(stalker_atrium_timer_table,"[中庭] 骨牢", TUNING.STALKER_SNARE_CD,"attack1")
AddInternalTimer(stalker_atrium_timer_table,"[中庭] 骨刺",TUNING.STALKER_SPIKES_CD,"spike")
AddInternalTimer(stalker_atrium_timer_table,"[中庭] 精神控制",TUNING.STALKER_MINDCONTROL_CD,"control_pre")
AddInternalTimer(stalker_atrium_timer_table,"[中庭] 召唤仆从",TUNING.STALKER_MINIONS_CD,"MISSING stalker_minion")
AddInternalTimer(stalker_atrium_timer_table,"[中庭] 召唤暗影之手", TUNING.STALKER_CHANNELERS_CD,"MISSING shadowchanneler")
local stalker_minion_timer_table = {}
AddInternalTimer(stalker_minion_timer_table,"[Rand. Â±5]Death",TUNING.STALKER_MINIONS_LIFESPAN,"spawn")--45s but it also has a variance of 5s(STALKER_MINIONS_LIFESPAN_VARIANCE)(up to +5 or -5), which means I once again have to take an average :/
local gnarwail_timer_table = {}
AddInternalTimer(gnarwail_timer_table,"Eat",TUNING.GNARWAIL.EAT_DELAY,"chew")
AddInternalTimer(gnarwail_timer_table,"Toss",TUNING.GNARWAIL.TOSS_DELAY,"toss")
--AddInternalTimer(gnarwail_timer_table,"Horn attack",TUNING.GNARWAIL.ATTACK_PERIOD,"emerge")--Gnarwail transforms into a seperate entity when trying to break stuff with horn. I can't really keep track of his other cooldowns when he does this, so I don't think this is worth keeping.
local spider_hider_timer_table = {}
AddInternalTimer(spider_hider_timer_table,"Hide",81*FRAMES,"hide_loop")
local lavae_timer_table = {}
AddInternalTimer(lavae_timer_table,"Death",TUNING.LAVAE_LIFESPAN,"taunt",nil,true)
local slurtlehole_timer_table = {}
AddInternalTimer(slurtlehole_timer_table,"Explode",30,"fire",true,nil,true)
local sporecloud_timer_table = {}
AddInternalTimer(sporecloud_timer_table,"Decay",TUNING.TOADSTOOL_SPORECLOUD_LIFETIME+40*FRAMES,"sporecloud_pre")--Lifetime timer starts after sporebomb has been deployed.
local wobster_timer_table = {}
AddInternalTimer(wobster_timer_table,"[Rand. Â±2] Stunned duration",5,"stunned_loop",nil,true,true)--Stun duration is random number between 3 and 7. Can only take average :/
local canary_poisoned_timer_table = {}
AddInternalTimer(canary_poisoned_timer_table,"[Rand. Â±0.56]Explode",(10+16*3+14+41)*FRAMES,"struggle_idle_pre",nil,true,true)--10 Frames of struggle_idle_pre, 16 Frames of struggle_idle_loop1 3~ times, 14 frames of struggle_idle_pst, 50/82 frames of struggle_explode into explosion.
AddInternalTimer(canary_poisoned_timer_table,"[Rand. Â±0.56]Unpickupable",45*FRAMES,"struggle_idle_pre",nil,nil,true)

local shark_timer_table = {}
AddInternalTimer(shark_timer_table,"Bite after Jump in", 35*FRAMES,"jump_pst",nil,true)

local mushgnome_timer_table = {}
AddInternalTimer(mushgnome_timer_table,"Spin CD",TUNING.MUSHGNOME_ATTACK_PERIOD+19*FRAMES,"atk_pre")
local spore_moon_timer_table = {}
AddInternalTimer(spore_moon_timer_table,"Explode",26*FRAMES,"rumble")
AddInternalTimer(spore_moon_timer_table,"[Â±1]Death",TUNING.MOONSPORE_PERISH_TIME+103*FRAMES,"cough_out")-- + Some randomness I'm not sure about.
local archive_centipede_timer_table = {}
AddInternalTimer(archive_centipede_timer_table,"AOE Attack",TUNING.ARCHIVE_CENTIPEDE.ATTACK_PERIOD,"atk_aoe")--It's just a follow-up attack to its normal attack.
AddInternalTimer(archive_centipede_timer_table,"Roll",50*FRAMES,"atk_roll_pre",nil,nil,true)--Rolls for 40 frames.
AddInternalTimer(archive_centipede_timer_table,"Roll CD",28*FRAMES,"atk_roll_pst",nil,nil)
--It also spawns Moon Spores occassionaly(2-4s) but there's no special animation for that, so no timer.

local lordfruitfly_timer_table = {}
AddInternalTimer(lordfruitfly_timer_table,"召唤果蝇",TUNING.LORDFRUITFLY_SUMMONPERIOD or 30,"plant_dance_pre",nil,true)

local alterguardian_phase1_timer_table = {}
AddInternalTimer(alterguardian_phase1_timer_table,"[天体1阶] 翻滚",TUNING.ALTERGUARDIAN_PHASE1_ROLLCOOLDOWN,"roll_pst")
AddInternalTimer(alterguardian_phase1_timer_table,"[天体1阶] 召唤月灵",TUNING.ALTERGUARDIAN_PHASE1_SUMMONCOOLDOWN,"shield",nil,true)

local alterguardian_phase2_timer_table = {}
AddInternalTimer(alterguardian_phase2_timer_table,"[天体2阶] 大风车",TUNING.ALTERGUARDIAN_PHASE2_SPINCD,"attk_spin_pst",nil,nil)
AddInternalTimer(alterguardian_phase2_timer_table,"[天体2阶] 召唤月灵",TUNING.ALTERGUARDIAN_PHASE2_SUMMONCOOLDOWN,"MISSING alterguardian_summon_fx",nil,true)
AddInternalTimer(alterguardian_phase2_timer_table,"[天体2阶] 画地为牢",TUNING.ALTERGUARDIAN_PHASE2_SPIKECOOLDOWN,"attk_stab_pre",nil,nil)

local alterguardian_phase3_timer_table = {}
AddInternalTimer(alterguardian_phase3_timer_table,"[天体3阶] 召唤月灵",TUNING.ALTERGUARDIAN_PHASE3_SUMMONCOOLDOWN,"attk_stab2_pst",nil,true)
AddInternalTimer(alterguardian_phase3_timer_table,"[天体3阶] 落石头",TUNING.ALTERGUARDIAN_PHASE3_TRAP_CD+44*FRAMES,"attk_skybeam",nil,true) --SG says the timer only starts 44 frames after the SG started.

local spider_healer_timer_table = {}
AddInternalTimer(spider_healer_timer_table,"AoE Heal",TUNING.SPIDER_HEALING_COOLDOWN+30*FRAMES,"heal") --Healing is done only after 30 frames.
--Don't forget to assign these to the mob when adding prefab :P
--For mobs with random attack timers, one might consider timing those and then using that value without changing it.
--That's also somewhat hard due to the fact that mobs aren't likely to attack instantly. The player won't always let the mob do an attack once the CD is up, so this isn't a very effective tactic.


--AddPrefab("abigail",1)--Abigail attack speed display buggy because she's a ghost with attack loop attacks
AddPrefab("minotaur",TUNING.MINOTAUR_ATTACK_PERIOD,nil,minotaur_timer_table) -- 远古守护者 Need special case for charge time+++--2
-- AddPrefab("bat",TUNING.BAT_ATTACK_PERIOD)--1 -- 蝙蝠
-- AddPrefab("bee",TUNING.BEE_ATTACK_PERIOD)--2 -- 蜜蜂
-- AddPrefab("killerbee",TUNING.BEE_ATTACK_PERIOD)--2 -- 杀人蜂
-- AddPrefab("beefalo",4) -- 牛牛
-- AddPrefab("bunnyman",TUNING.BUNNYMAN_ATTACK_PERIOD) --  兔人 Beardlords don't attack faster in DST.--2
-- AddPrefab("bishop",TUNING.BISHOP_ATTACK_PERIOD)--4 发条主教
-- AddPrefab("bishop_nightmare",TUNING.BISHOP_ATTACK_PERIOD)--4 损坏的发条主教
-- AddPrefab("knight",TUNING.KNIGHT_ATTACK_PERIOD)--2 发条骑士
-- AddPrefab("knight_nightmare",TUNING.KNIGHT_ATTACK_PERIOD)--2 损坏的发条骑士
-- AddPrefab("rook",TUNING.ROOK_ATTACK_PERIOD,nil,rook_timer_table) --发条战车Need special case for charge time+++--2
-- AddPrefab("rook_nightmare",TUNING.ROOK_ATTACK_PERIOD,nil,rook_timer_table) -- 损坏的发条战车Need special case for charge time+++--2
AddPrefab("deerclops",TUNING.DEERCLOPS_ATTACK_PERIOD) --巨鹿Need special case for laser+++--4
-- AddPrefab("worm",TUNING.WORM_ATTACK_PERIOD)--4 蠕虫
-- AddPrefab("spat",3,nil,spat_timer_table) --钢羊Need special case for her spit and normal attacking.+++--Her spit doesn't really have a cooldown, she just won't spit if her TARGET is affected by it, thus I can't add a cooldown for it. I might be able to add a cooldown for the player cc'ed duration though. Her attack should be constant too.
-- AddPrefab("frog",TUNING.FROG_ATTACK_PERIOD)--1 青蛙
--AddPrefab("ghost",TUNING.GHOST_DMG_PERIOD) --I really hate these ghosts and their attack loops and they stay in their "angry" state even when not hitting you 'n'
-- AddPrefab("hound",TUNING.HOUND_ATTACK_PERIOD) --狗Game says 2, yet they somehow attack faster. Likely because of different animation start time. --Future me:Ok, hounds attack with their atk_pre animation too, just like krampus.
-- AddPrefab("firehound",TUNING.HOUND_ATTACK_PERIOD) --火狗Check hound--2
-- AddPrefab("icehound",TUNING.HOUND_ATTACK_PERIOD)--2 冰狗
-- AddPrefab("eyeturret",FRAMES*113) --眼球塔Similar situation as hound
-- AddPrefab("koalefant_summer",4) --大象Similar situation to hound
-- AddPrefab("koalefant_winter",4) --冬象Similar situation to hound
-- AddPrefab("krampus",TUNING.KRAMPUS_ATTACK_PERIOD) --小偷It seems like krampus attack timer starts with his atk_pre animation--1.2
-- AddPrefab("walrus",TUNING.WALRUS_ATTACK_PERIOD)--3 海象
-- AddPrefab("little_walrus",TUNING.LITTLE_WALRUS_ATTACK_PERIOD)--5.1 小海象
-- AddPrefab("merm",TUNING.MERM_ATTACK_PERIOD)--3 鱼人
-- AddPrefab("mermguard",TUNING.MERM_GUARD_ATTACK_PERIOD)--3 鱼人战士
-- AddPrefab("eyeplant",TUNING.EYEPLANT_ATTACK_PERIOD)--1 眼球草
-- AddPrefab("mosquito",TUNING.MOSQUITO_ATTACK_PERIOD)--7 文字
-- AddPrefab("penguin",TUNING.PENGUIN_ATTACK_PERIOD) -- 企鹅Special case for charge or bite+++--3--Penguin attack pattern feels very clunky(randomly standing up, animation starting,stopping), that's why I won't add a charge case.
-- AddPrefab("pigman",TUNING.PIG_ATTACK_PERIOD,{{["value"] = TUNING.WEREPIG_ATTACK_PERIOD, ["condition"] = "BUILD werepig_build"}})--猪人Special case for werepig+++--3;2
-- AddPrefab("pigguard",TUNING.PIG_GUARD_ATTACK_PERIOD,{{["value"] = TUNING.WEREPIG_ATTACK_PERIOD, ["condition"] = "BUILD werepig_build"}}) --猪人守卫Special case for werepig??+++--1.5--No special case for werepig, pigguards do attack slower when in wereform.
-- AddPrefab("moonpig",TUNING.WEREPIG_ATTACK_PERIOD)--2 月猪
-- AddPrefab("moonhound",TUNING.HOUND_ATTACK_PERIOD) --Check hound--2 月狗
-- AddPrefab("rocky",3)-- 石虾No TUNING value, just a 3 in rocky.lua
-- AddPrefab("slurtle",TUNING.SLURTLE_ATTACK_PERIOD,nil,slurtle_timer_table)--4 蛞蝓龟
-- AddPrefab("snurtle",nil,nil,slurtle_timer_table) -- 蜗牛龟
-- AddPrefab("monkey",TUNING.MONKEY_ATTACK_PERIOD)--Special case for poop throwing and biting+++--2
-- AddPrefab("spider",TUNING.SPIDER_ATTACK_PERIOD)--3
-- AddPrefab("spider_warrior",TUNING.SPIDER_WARRIOR_ATTACK_PERIOD+1) -- Spider warrior attack speed is 4-6, so I take an average, because I can't get that value elsewise.--5
AddPrefab("spiderqueen",TUNING.SPIDERQUEEN_ATTACKPERIOD,nil,spiderqueen_timer_table)--3--Special case for spider summoning and, possibly, transforming back to nest.
-- AddPrefab("spider_hider",TUNING.SPIDER_HIDER_ATTACK_PERIOD,nil,spider_hider_timer_table)
-- AddPrefab("spider_spitter",6) --Spitter attack speed is 5-7, can't know real value client-side, so averaging it.
-- AddPrefab("spider_dropper",TUNING.SPIDER_SPITTER_ATTACK_PERIOD) -- Also averaging it because it's random and unknown client-side.--5
-- AddPrefab("tallbird",TUNING.TALLBIRD_ATTACK_PERIOD)--2
-- AddPrefab("teenbird",TUNING.TEENBIRD_ATTACK_PERIOD)--2
-- AddPrefab("smallbird",TUNING.SMALLBIRD_ATTACK_PERIOD)--1
-- AddPrefab("tentacle",51*FRAMES) -- Might need special. Game said tentacle has 2 attack speed, but it seems like a 1.7??--Tentacle does its attack in 22 frames, then does a 30 frame idle.
-- AddPrefab("tentacle_pillar_arm",1.23)--3--They seem to actually attack every 37 frames, not sure why.
AddPrefab("leif",TUNING.LEIF_ATTACK_PERIOD)--3
AddPrefab("leif_sparse",TUNING.LEIF_ATTACK_PERIOD)--3
AddPrefab("bearger",TUNING.BEARGER_ATTACK_PERIOD,nil,bearger_timer_table) --Special case for yawn and slam.+++--3
-- AddPrefab("buzzard",TUNING.BUZZARD_ATTACK_PERIOD) --2
-- AddPrefab("catcoon",TUNING.CATCOON_ATTACK_PERIOD,nil) --2
AddPrefab("dragonfly",TUNING.DRAGONFLY_ATTACK_PERIOD,{{["value"] = TUNING.DRAGONFLY_FIRE_ATTACK_PERIOD, ["condition"] = "BUILD dragonfly_fire_build"},{["value"] = TUNING.DRAGONFLY_FIRE_ATTACK_PERIOD, ["condition"] = "BUILD dragonfly_fire_yule_build"}},dragonfly_timer_table) --Special case for her slam and enrage and stun duration+++--4;3
AddPrefab("moose",TUNING.MOOSE_ATTACK_PERIOD)--3
-- AddPrefab("mossling",nil,nil,mossling_timer_table) -- Need special case for spin and when they recover from it+++
--AddPrefab("deciduoustree") -- Need special case for checking spawned attacks+++
-- AddPrefab("birchnutdrake",2)
-- AddPrefab("warg",TUNING.WARG_ATTACKPERIOD,nil,warg_timer_table)--3
-- AddPrefab("lightninggoat",TUNING.LIGHTNING_GOAT_ATTACK_PERIOD)--2
AddPrefab("antlion",TUNING.ANTLION_MAX_ATTACK_PERIOD,nil,antlion_timer_table) --Need special case for spike summoning. And/Or castle.+++
AddPrefab("beequeen",TUNING.BEEQUEEN_ATTACK_PERIOD,nil,beequeen_timer_table) --Might need special case, but I think her AS is const. Special case for summoning bees needed though. SPAWNGUARDS_CD = {18,16,7,12} 'n'. Not sure if I can keep track of her stage. +++--2
AddPrefab("crabking",5.3,nil,crabking_timer_table) --Special case for spells needed.+++--Will need to keep track of what gems he has and such. Might also need to keep track of his stage
-- AddPrefab("cookiecutter",1.2,nil,cookiecutter_timer_table)--They don't seem to actually have an attack, looks more like thorn effect. A weird mob indeed.
-- AddPrefab("deer_red",TUNING.DEER_ATTACK_PERIOD,nil,deer_red_timer_table) --Special case for spell+++--2
-- AddPrefab("deer_blue",TUNING.DEER_ATTACK_PERIOD,nil,deer_blue_timer_table) -- Special case for spell+++--2
-- AddPrefab("beeguard",TUNING.BEEGUARD_ATTACK_PERIOD) --2
-- AddPrefab("mutatedhound",TUNING.MUTATEDHOUND_ATTACK_PERIOD)--2.5
-- AddPrefab("lavae",TUNING.LAVAE_ATTACK_PERIOD,nil,lavae_timer_table)--4
-- AddPrefab("deer",TUNING.DEER_ATTACK_PERIOD) --Deer will only attack blockers structures, but it's still an attack!--2
AddPrefab("malbatross",TUNING.MALBATROSS_ATTACK_PERIOD) --Might need special case for her charge or whatever she does.+++
-- AddPrefab("mutated_penguin",TUNING.PENGUIN_ATTACK_PERIOD)--Case for charge+++--3
-- AddPrefab("fruitdragon",TUNING.FRUITDRAGON.ATTACK_PERIOD,nil,fruitdragon_timer_table) -- Also need timer for his fire move if he's ripe.+++--2
-- AddPrefab("spider_moon",TUNING.SPIDER_MOON_ATTACK_PERIOD)--3
AddPrefab("toadstool",5.3,nil,toadstool_timer_table) -- Need a crapton of timers for his boomshrooms, sporecaps, slam, sporebombs.+++
AddPrefab("toadstool_dark",5.5,nil,toadstool_timer_table)
AddPrefab("klaus",TUNING.KLAUS_ATTACK_PERIOD,{{ ["value"] = TUNING.KLAUS_ATTACK_PERIOD/TUNING.KLAUS_ENRAGE_SCALE, ["condition"] = "SCALE 1.6799999475479"}},klaus_timer_table) -- Special case for enraged klaus and for form transforming chomp klaus+++--3;~2.14--Klaus skips attack frames (start frame 15) when he chomps successfully onto a player.
AddPrefab("stalker",TUNING.STALKER_ATTACK_PERIOD,nil,stalker_timer_table) --Special case for cage.+++--4
AddPrefab("stalker_atrium",TUNING.STALKER_ATRIUM_ATTACK_PERIOD,nil,stalker_atrium_timer_table) --Special case for minion summoning, hand summoning, mind controlling.+++--3
-- --Special cases for shadow pieces and their respective levels.
AddPrefab("shadow_knight",TUNING.SHADOW_KNIGHT.ATTACK_PERIOD[1],{{["value"] = TUNING.SHADOW_KNIGHT.ATTACK_PERIOD[2], ["condition"] = "SCALE 1.7000000476837"}, {["value"] = TUNING.SHADOW_KNIGHT.ATTACK_PERIOD[3], ["condition"] = "SCALE 2.5"}})--Scales 3, 2.5, 2; Respectively size: 1, 1.7000000476837,  2.5
AddPrefab("shadow_bishop",TUNING.SHADOW_BISHOP.ATTACK_PERIOD[1],{{["value"] = TUNING.SHADOW_BISHOP.ATTACK_PERIOD[2], ["condition"] = "SCALE 1.6000000238419"}, {["value"] = TUNING.SHADOW_BISHOP.ATTACK_PERIOD[3], ["condition"] = "SCALE 2.2000000476837"}})--Scales 15, 14, 12; Respectively size: 1, 1.6000000238419, 2.2000000476837
AddPrefab("shadow_rook",TUNING.SHADOW_ROOK.ATTACK_PERIOD[1],{{["value"] = TUNING.SHADOW_ROOK.ATTACK_PERIOD[2], ["condition"] = "SCALE 1.2000000476837"}, {["value"] = TUNING.SHADOW_ROOK.ATTACK_PERIOD[3], ["condition"] = "SCALE 1.6000000238419"}})-- Scales 6, 5.5, 5; Respectively size: 1,1.2000000476837, 1.6000000238419
-- AddPrefab("crawlinghorror",TUNING.CRAWLINGHORROR_ATTACK_PERIOD)--2.5
-- AddPrefab("nightmarebeak",TUNING.TERRORBEAK_ATTACK_PERIOD)--1.5
-- AddPrefab("crawlingnightmare",TUNING.CRAWLINGHORROR_ATTACK_PERIOD)--2.5
-- AddPrefab("terrorbeak",TUNING.TERRORBEAK_ATTACK_PERIOD)--1.5
-- AddPrefab("slurper",TUNING.SLURPER_ATTACK_PERIOD) --5
-- AddPrefab("squid",TUNING.SQUID_ATTACK_PERIOD,nil)--4
-- AddPrefab("houndcorpse",nil,nil,houndcorpse_timer_table)
-- AddPrefab("stalker_minion",nil,nil,stalker_minion_timer_table)
-- AddPrefab("stalker_minion1",nil,nil,stalker_minion_timer_table)
-- AddPrefab("stalker_minion2",nil,nil,stalker_minion_timer_table)
-- AddPrefab("gnarwail",(51+16)*FRAMES,nil,gnarwail_timer_table)--51 frames of "attack_2", 16 frames of waiting.
-- AddPrefab("slurtlehole",nil,nil,slurtlehole_timer_table)
-- AddPrefab("bernie_big",TUNING.BERNIE_BIG_ATTACK_PERIOD)
-- AddPrefab("winona_catapult",TUNING.WINONA_CATAPULT_ATTACK_PERIOD)
-- AddPrefab("sporecloud",nil,nil,sporecloud_timer_table)
-- AddPrefab("wobster_sheller_land",nil,nil,wobster_timer_table)
-- AddPrefab("wobster_moonglass_land",nil,nil,wobster_timer_table)
-- AddPrefab("canary_poisoned",nil,nil,canary_poisoned_timer_table)
-- AddPrefab("waterplant",TUNING.WATERPLANT.ATTACK_PERIOD,nil,nil)--{{["value"] = TUNING.WATERPLANT.YELLOW_ATTACK_PERIOD, ["condition"] = "STAGE 1"}}
-- AddPrefab("shark",36*FRAMES,nil,shark_timer_table)
-- AddPrefab("oceanhorror",TUNING.OCEANHORROR.ATTACK_PERIOD,nil,nil)
-- AddPrefab("molebat",TUNING.MOLEBAT.ATTACK_PERIOD,nil,nil)--It does have more cooldowns, but they're too long to be useful if known.
-- AddPrefab("mushgnome",nil,nil,mushgnome_timer_table)
-- AddPrefab("spore_moon",nil,nil,spore_moon_timer_table)
-- AddPrefab("archive_centipede",TUNING.ARCHIVE_CENTIPEDE.ATTACK_PERIOD,nil,archive_centipede_timer_table)
-- AddPrefab("lordfruitfly",TUNING.LORDFRUITFLY_ATTACK_PERIOD or 2,nil,lordfruitfly_timer_table)
-- AddPrefab("fruitfly",TUNING.FRUITFLY_ATTACK_PERIOD or 2,nil,nil)
-- AddPrefab("bird_mutant",TUNING.MUTANT_BIRD_ATTACK_COOLDOWN,nil,nil)
-- AddPrefab("bird_mutant_spitter",TUNING.MUTANT_BIRD_ATTACK_COOLDOWN,nil,nil)
AddPrefab("alterguardian_phase1",TUNING.ALTERGUARDIAN_PHASE1_ATTACK_PERIOD,nil,alterguardian_phase1_timer_table) -- Boss has some weird pauses between attacks. +8 frames perhaps? -- Removing 1 second to match boss attack syncing: Normal attack, attack timer has 1 second left, roll, roll has 1.17s left, repeat
AddPrefab("alterguardian_phase2",TUNING.ALTERGUARDIAN_PHASE2_ATTACK_PERIOD,nil,alterguardian_phase2_timer_table) -- Are the pauses just the full idle anims?
AddPrefab("alterguardian_phase3",TUNING.ALTERGUARDIAN_PHASE3_ATTACK_PERIOD,nil,alterguardian_phase3_timer_table)
-- AddPrefab("spider_healer",TUNING.SPIDER_ATTACK_PERIOD,nil,spider_healer_timer_table)
-- AddPrefab("grassgator",default_attack_time,nil,nil)
-- AddPrefab("spider_water",TUNING.SPIDER_WATER_ATTACK_PERIOD+1,nil,nil) -- It's SPIDER_WATER_ATTACK_PERIOD + math.random() * 2, but I can't deal with random values.
--///////////////////--
-------The Forge-------
--///////////////////--
local pitpig_timer_table = {}
AddInternalTimer(pitpig_timer_table,"Dash",(TUNING.FORGE and TUNING.FORGE.PITPIG and TUNING.FORGE.PITPIG.DASH_CD+1.1) or 0,"attack2",nil,true)--CD triggers when it's done.
-- AddPrefab("pitpig",(TUNING.FORGE and TUNING.FORGE.PITPIG and TUNING.FORGE.PITPIG.ATTACK_PERIOD) or nil,nil,pitpig_timer_table)

local crocommander_rapidfire_timer_table = {}
AddInternalTimer(crocommander_rapidfire_timer_table,"Taunt",TUNING.FORGE and TUNING.FORGE.TAUNT_CD or 8,{"taunt","taunt_2"})--Also does his taunt after 4 attacks.
AddInternalTimer(crocommander_rapidfire_timer_table,"Spit",23*FRAMES,"spit")--Cooldown is 0.2, but he can't attack that fast because of his animation so he only attacks every 23 frames.
-- AddPrefab("crocommander_rapidfire",(TUNING.FORGE and TUNING.FORGE.CROCOMMANDER_RAPIDFIRE and TUNING.FORGE.CROCOMMANDER_RAPIDFIRE.ATTACK_PERIOD) or 0,nil,crocommander_rapidfire_timer_table)

local crocommander_timer_table = {}
AddInternalTimer(crocommander_timer_table,"Taunt",TUNING.FORGE and TUNING.FORGE.TAUNT_CD or 8,{"taunt","taunt_2"})--Also does his taunt after 4 attacks.
AddInternalTimer(crocommander_timer_table,"Spit",(TUNING.FORGE and TUNING.FORGE.CROCOMMANDER and TUNING.FORGE.CROCOMMANDER.SPIT_ATTACK_PERIOD) or 0,"spit")
AddInternalTimer(crocommander_timer_table,"Place Banner",(TUNING.FORGE and TUNING.FORGE.CROCOMMANDER and TUNING.FORGE.CROCOMMANDER.BANNER_CD) or 0,"banner_summon",nil,true) --CD starts when his banner gets destroyed, but without the ability to know who owns which banner, it's impossible to start the cooldown.
-- AddPrefab("crocommander",(TUNING.FORGE and TUNING.FORGE.CROCOMMANDER and TUNING.FORGE.CROCOMMANDER.ATTACK_PERIOD+0.1) or 0,nil,crocommander_timer_table)

local snortoise_timer_table = {}
AddInternalTimer(snortoise_timer_table,"Hide",4.3,"hide_pre",nil,true,true)
AddInternalTimer(snortoise_timer_table,"Flipped",(TUNING.FORGE and TUNING.FORGE.SNORTOISE and TUNING.FORGE.SNORTOISE.FLIP_TIME+2) or 0,"flip_pre",nil,nil,true)
AddInternalTimer(snortoise_timer_table,"Taunt",TUNING.FORGE and TUNING.FORGE.TAUNT_CD or 8,"taunt")--Also taunts after 2 attacks
AddInternalTimer(snortoise_timer_table,"Spin CD", (TUNING.FORGE and TUNING.FORGE.SNORTOISE and TUNING.FORGE.SNORTOISE.SPIN_CD+45*FRAMES) or 0,"attack2_loop")--CD triggers when he's done spinning. Spin can be cancelled or finished naturally. The CD will keep resetting if I base it on "attack2_loop" so it's perfect to know when he's done.
AddInternalTimer(snortoise_timer_table,"Shield CD",(TUNING.FORGE and TUNING.FORGE.SNORTOISE and TUNING.FORGE.SNORTOISE.SHIELD_CD) or 0,"hide_pst",nil,true)
-- AddPrefab("snortoise",(TUNING.FORGE and TUNING.FORGE.SNORTOISE and TUNING.FORGE.SNORTOISE.ATTACK_PERIOD) or 0,nil,snortoise_timer_table)

local scorpeon_timer_table = {}
AddInternalTimer(scorpeon_timer_table,"Taunt",TUNING.FORGE and TUNING.FORGE.TAUNT_CD or 8,"taunt")--Also taunts after 2 attacks
AddInternalTimer(scorpeon_timer_table,"Spit",(TUNING.FORGE and TUNING.FORGE.SCORPEON and TUNING.FORGE.SCORPEON.SPIT_CD) or 0,"spit")
-- AddPrefab("scorpeon",(TUNING.FORGE and TUNING.FORGE.SCORPEON and TUNING.FORGE.SCORPEON.ATTACK_PERIOD) or 0, {{["value"] = ((TUNING.FORGE and TUNING.FORGE.SCORPEON and TUNING.FORGE.SCORPEON.ATTACK_PERIOD_ENRAGED) or 1.5), ["condition"] = "STAGE >0"}},scorpeon_timer_table)

local boarilla_timer_table = {}
--Boarilla taunts after 6 attacks
AddInternalTimer(boarilla_timer_table,"Taunt",TUNING.FORGE and TUNING.FORGE.TAUNT_CD*3 or 24,"taunt")--Taunt timer gets reduced from each attack? Boarilla taunts after 6 attacks.
AddInternalTimer(boarilla_timer_table,"Roll",(TUNING.FORGE and TUNING.FORGE.BOARILLA and TUNING.FORGE.BOARILLA.ROLL_DURATION+1) or 0,"roll_pre",nil,nil,true)
AddInternalTimer(boarilla_timer_table,"Hide",5.2,"hide_pre",nil,nil,true)
AddInternalTimer(boarilla_timer_table,"[(-9) Low Health]Roll CD",(TUNING.FORGE and TUNING.FORGE.BOARILLA and TUNING.FORGE.BOARILLA.ROLL_CD-2) or 0,"roll_pre")--Same as for snortoises spin cd.
AddInternalTimer(boarilla_timer_table,"Slam CD",(TUNING.FORGE and TUNING.FORGE.BOARILLA and TUNING.FORGE.BOARILLA.SLAM_CD) or 0,"attack1",nil,nil)--He can roll_slam and that puts slam on cd. He can roll_slam even when slam is on cd...
AddInternalTimer(boarilla_timer_table,"Shield CD",(TUNING.FORGE and TUNING.FORGE.BOARILLA and (TUNING.FORGE.BOARILLA.SHEILD_CD or TUNING.FORGE.BOARILLA.SHIELD_CD+14*FRAMES) or 0),"hide_loop",nil,nil)--Doing a special effect can stop him from shielding and then he doesn't go to this animation.
-- AddPrefab("boarilla",(TUNING.FORGE and TUNING.FORGE.BOARILLA and TUNING.FORGE.BOARILLA.ATTACK_PERIOD) or 0,nil,boarilla_timer_table)

local rhinocebro_timer_table = {}
--Taunts after 2 atttacks; No Timer
AddInternalTimer(rhinocebro_timer_table,"Cheer Duration", (TUNING.FORGE and TUNING.FORGE.RHINOCEBRO and TUNING.FORGE.RHINOCEBRO.CHEER_TIMEOUT) or 0,"cheer_post",nil,nil,true)
AddInternalTimer(rhinocebro_timer_table,"Cheer CD", (TUNING.FORGE and TUNING.FORGE.RHINOCEBRO and TUNING.FORGE.RHINOCEBRO.CHEER_CD) or 0,"cheer_loop")
AddInternalTimer(rhinocebro_timer_table,"Charge CD",(TUNING.FORGE and TUNING.FORGE.RHINOCEBRO and TUNING.FORGE.RHINOCEBRO.CHARGE_CD+12*FRAMES) or 0,"attack2_loop")
-- AddPrefab("rhinocebro",(TUNING.FORGE and TUNING.FORGE.RHINOCEBRO and TUNING.FORGE.RHINOCEBRO.ATTACK_PERIOD) or 0,nil,rhinocebro_timer_table)
-- AddPrefab("rhinocebro2",(TUNING.FORGE and TUNING.FORGE.RHINOCEBRO and TUNING.FORGE.RHINOCEBRO.ATTACK_PERIOD) or 0,nil,rhinocebro_timer_table)

local boarrior_timer_table = {}
AddInternalTimer(boarrior_timer_table,"Taunt",TUNING.FORGE and TUNING.FORGE.TAUNT_CD or 8,"taunt")--Also taunts after 2 attacks.
-- AddPrefab("boarrior",(TUNING.FORGE and TUNING.FORGE.BOARRIOR and TUNING.FORGE.BOARRIOR.ATTACK_PERIOD) or 0,nil,boarrior_timer_table)--Uhh, doesn't seem like he has any cooldowns? Seems like it's just a different type of main attack, which I already time.

local swineclops_timer_table = {}
--Taunt only seems to proc on health; No Timer
--AddInternalTimer(swineclops_timer_table,"Guard Time", (TUNING.FORGE and TUNING.FORGE.SWINECLOPS and TUNING.FORGE.SWINECLOPS.GUARD_TIME) or 0,"block_pre",nil,nil,true)--Or block_pst?
AddInternalTimer(swineclops_timer_table,"Body Slam CD",(TUNING.FORGE and TUNING.FORGE.SWINECLOPS and TUNING.FORGE.SWINECLOPS.BODY_SLAM_CD) or 0,"bellyflop_pre")
-- AddPrefab("swineclops",(TUNING.FORGE and TUNING.FORGE.SWINECLOPS and TUNING.FORGE.SWINECLOPS.ATTACK_PERIOD-0.7) or 0,{{["value"] = (TUNING.FORGE and TUNING.FORGE.SWINECLOPS and TUNING.FORGE.SWINECLOPS.ATTACK_PERIOD) or 0,["condition"] = "STAGE 1"},{["value"] = 13*FRAMES,["condition"] = "STAGE 2"}},swineclops_timer_table)
-----------------------
--////////////////////////--
-------Hallowed Forge-------
--////////////////////////--
local pitpig_zombie_timer_table = {}
AddInternalTimer(pitpig_zombie_timer_table,"Dash",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.PITPIG_ZOMBIE and TUNING.HALLOWED_FORGE.PITPIG_ZOMBIE.DASH_CD+1.1) or 0,"attack2",nil,true)
-- AddPrefab("pitpig_zombie",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.PITPIG_ZOMBIE.ATTACK_PERIOD) or nil,nil,pitpig_zombie_timer_table)

local pitpig_zombie_armored_timer_table = {}
AddInternalTimer(pitpig_zombie_armored_timer_table,"Dash",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.PITPIG_ZOMBIE and TUNING.HALLOWED_FORGE.PITPIG_ZOMBIE.DASH_CD+1.1) or 0,"attack2",nil,true)
-- AddPrefab("pitpig_zombie_armored",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.PITPIG_ZOMBIE_ARMORED and TUNING.HALLOWED_FORGE.PITPIG_ZOMBIE_ARMORED.ATTACK_PERIOD) or nil,nil,pitpig_zombie_armored_timer_table)

local crocommander_necro_timer_table = {}
AddInternalTimer(crocommander_necro_timer_table,"Spit",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.CROCOMMANDER_NECRO and TUNING.HALLOWED_FORGE.CROCOMMANDER_NECRO.SPIT_ATTACK_PERIOD) or 0,"spit")
-- AddPrefab("crocommander_necro",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.CROCOMMANDER_NECRO and TUNING.HALLOWED_FORGE.CROCOMMANDER_NECRO.ATTACK_PERIOD+0.1) or 0,nil,crocommander_necro_timer_table)

local snortoise_ghost_timer_table = {}
AddInternalTimer(snortoise_ghost_timer_table,"Hide",4.3,"hide_pre",nil,true,true)
AddInternalTimer(snortoise_ghost_timer_table,"Spin CD", (TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.SNORTOISE_GHOST and TUNING.HALLOWED_FORGE.SNORTOISE_GHOST.SPIN_CD+45*FRAMES) or 0,"attack2_loop")
AddInternalTimer(snortoise_timer_table,"Shield CD",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.SNORTOISE_GHOST and TUNING.HALLOWED_FORGE.SNORTOISE_GHOST.SHIELD_CD) or 0,"hide_pst",nil,true)
-- AddPrefab("snortoise_ghost",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.SNORTOISE_GHOST and TUNING.HALLOWED_FORGE.SNORTOISE_GHOST.ATTACK_PERIOD) or 0,nil,snortoise_timer_table)

local scorpeon_cultist_timer_table = {}
AddInternalTimer(scorpeon_cultist_timer_table,"Spit",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.SCORPEON_CULTIST and TUNING.HALLOWED_FORGE.SCORPEON_CULTIST.SPIT_CD) or 0,"spit")
--AddInternalTimer(scorpeon_cultist_timer_table,"Spell CD",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.SCORPEON_CULTIST and TUNING.HALLOWED_FORGE.SCORPEON_CULTIST.SPELL_CD) or 0,"castspell")
-- AddPrefab("scorpeon_cultist",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.SCORPEON_CULTIST and TUNING.HALLOWED_FORGE.SCORPEON_CULTIST.ATTACK_PERIOD) or 0, {{["value"] = ((TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.SCORPEON_CULTIST and TUNING.HALLOWED_FORGE.SCORPEON_CULTIST.ATTACK_PERIOD_ENRAGED) or 1.5), ["condition"] = "STAGE >0"}},scorpeon_cultist_timer_table)

local boarilla_skeleton_timer_table = {}
AddInternalTimer(boarilla_skeleton_timer_table,"Roll",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.BOARILLA_SKELETON and TUNING.HALLOWED_FORGE.BOARILLA_SKELETON.ROLL_DURATION+1) or 0,"roll_pre",nil,nil,true)
AddInternalTimer(boarilla_skeleton_timer_table,"Hide",5.2,"hide_pre",nil,nil,true)
AddInternalTimer(boarilla_skeleton_timer_table,"[(-9) Low Health]Roll CD",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.BOARILLA_SKELETON and TUNING.HALLOWED_FORGE.BOARILLA_SKELETON.ROLL_CD-2) or 0,"roll_pre")
AddInternalTimer(boarilla_skeleton_timer_table,"Slam CD",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.BOARILLA_SKELETON and TUNING.HALLOWED_FORGE.BOARILLA_SKELETON.SLAM_CD) or 0,"attack1",nil,nil)
AddInternalTimer(boarilla_skeleton_timer_table,"Shield CD",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.BOARILLA_SKELETON and (TUNING.HALLOWED_FORGE.BOARILLA_SKELETON.SHEILD_CD or TUNING.HALLOWED_FORGE.BOARILLA.SHIELD_CD+14*FRAMES) or 0),"hide_loop",nil,nil)
-- AddPrefab("boarilla_skeleton",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.BOARILLA_SKELETON and TUNING.HALLOWED_FORGE.BOARILLA_SKELETON.ATTACK_PERIOD) or 0,nil,boarilla_skeleton_timer_table)

local rhinocebro_franken_timer_table = {}
AddInternalTimer(rhinocebro_franken_timer_table,"Cheer Duration", (TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.RHINOCEBRO_FRANKEN and TUNING.HALLOWED_FORGE.RHINOCEBRO_FRANKEN.CHEER_TIMEOUT) or 0,"cheer_post",nil,nil,true)
AddInternalTimer(rhinocebro_franken_timer_table,"Cheer CD", (TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.RHINOCEBRO_FRANKEN and TUNING.HALLOWED_FORGE.RHINOCEBRO_FRANKEN.CHEER_CD) or 0,"cheer_loop")
AddInternalTimer(rhinocebro_franken_timer_table,"Charge CD",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.RHINOCEBRO_FRANKEN and TUNING.HALLOWED_FORGE.RHINOCEBRO_FRANKEN.CHARGE_CD+12*FRAMES) or 0,"attack2_loop")
-- AddPrefab("rhinocebro_franken",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.RHINOCEBRO_FRANKEN and TUNING.HALLOWED_FORGE.RHINOCEBRO_FRANKEN.ATTACK_PERIOD) or 0,nil,rhinocebro_franken_timer_table)

local boarrior_skeleton_timer_table = {}
-- AddPrefab("boarrior_skeleton",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.BOARRIOR_SKELETON and TUNING.HALLOWED_FORGE.BOARRIOR_SKELETON.ATTACK_PERIOD) or 0,nil,boarrior_skeleton_timer_table)

local swineclops_mummy_timer_table = {}
AddInternalTimer(swineclops_mummy_timer_table,"Body Slam CD",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.SWINECLOPS_MUMMY and TUNING.HALLOWED_FORGE.SWINECLOPS_MUMMY.BODY_SLAM_CD) or 0,"bellyflop_pre")
-- AddPrefab("swineclops_mummy",(TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.SWINECLOPS_MUMMY and TUNING.HALLOWED_FORGE.SWINECLOPS_MUMMY.ATTACK_PERIOD-0.7) or 0,{{["value"] = (TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.SWINECLOPS_MUMMY and TUNING.HALLOWED_FORGE.SWINECLOPS_MUMMY.ATTACK_PERIOD) or 0,["condition"] = "STAGE 1"},{["value"] = 13*FRAMES,["condition"] = "STAGE 2"}},swineclops_mummy_timer_table)

local cursed_helmet_timer_table = {}
AddInternalTimer(cursed_helmet_timer_table,"Slam CD",TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.CURSED_HELMET and TUNING.HALLOWED_FORGE.CURSED_HELMET.SLAM_CD,"fall_pst")
AddInternalTimer(cursed_helmet_timer_table,"Black Hole CD",TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.CURSED_HELMET and TUNING.HALLOWED_FORGE.CURSED_HELMET.BLACK_HOLE_CD+6*FRAMES,"charge_down_pst")
-- AddPrefab("cursed_helmet",TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.CURSED_HELMET and TUNING.HALLOWED_FORGE.CURSED_HELMET.ATTACK_PERIOD,nil,cursed_helmet_timer_table)

-- AddPrefab("cursed_mummy",TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.CURSED_MUMMY and TUNING.HALLOWED_FORGE.CURSED_MUMMY.ATTACK_PERIOD,nil,nil)

-- AddPrefab("roach_beetle",TUNING.HALLOWED_FORGE and TUNING.HALLOWED_FORGE.ROACH_BEETLE and TUNING.HALLOWED_FORGE.ROACH_BEETLE.ATTACK_PERIOD,nil,nil)
----------------------------
return enemies