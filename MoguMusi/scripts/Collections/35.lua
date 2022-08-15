local _G = GLOBAL
local TheInput = GLOBAL.TheInput
local TheWorld = GLOBAL.TheWorld
local RPC = GLOBAL.RPC
local SendRPCToServer = GLOBAL.SendRPCToServer
local ACTIONS = GLOBAL.ACTIONS
local TheNet = GLOBAL.TheNet
local TheSim = GLOBAL.TheSim
local EQUIPSLOTS = GLOBAL.EQUIPSLOTS
local Sleep = _G.Sleep
local FRAMES = _G.FRAMES
local ThePlayer

local y_offset = 2
local default_font = 12
local MUSTHAVE_TAGS = true
local CANTHAVE_TAGS = {
    "bird", "wall", "glommer", "butterfly", "berrythief", "rabbit", "mole",
    "grassgekko", "chester", "hutch", "player"
}
local MUSTONEOF_TAGS = true
local show_specialcolours = true
local colour_mobaggroyou = 1
local colour_mobaggroplayer = 6
local colour_mobfriendyou = 2
local colour_mobfriendother = 8
local colour_mobaggrofollower = 9
local default_showaggro = false
local default_befriended = false

local mob_fontsize = {["default"] = 18}
local mob_offset = {
    ["eyeplant"] = 1,
    ["cookiecutter"] = 1,
    ["wobysmall"] = 1,
    ["bee"] = 1.5,
    ["killerbee"] = 1.5,
    ["worm"] = 1.5,
    ["frog"] = 1.5,
    ["mosquito"] = 1.5,
    ["spider"] = 1.5,
    ["spider_warrior"] = 1.5,
    ["spider_hider"] = 1.5,
    ["spider_spitter"] = 1.5,
    ["spider_dropper"] = 1.5,
    ["spider_moon"] = 1.5,
    ["smallbird"] = 1.5,
    ["catcoon"] = 1.5,
    ["birchnutdrake"] = 1.5,
    ["lavae"] = 1.5,
    ["fruitdragon"] = 1.5,
    ["little_walrus"] = 2.5,
    ["merm"] = 2.5,
    ["mermguard"] = 2.5,
    ["pigman"] = 2.5,
    ["pigguard"] = 2.5,
    ["moonpig"] = 2.5,
    ["bat"] = 3,
    ["beefalo"] = 3,
    ["bunnyman"] = 3,
    ["knight"] = 3,
    ["knight_nightmare"] = 3,
    ["rook"] = 3,
    ["rook_nightmare"] = 3,
    ["rocky"] = 3,
    ["crawlinghorror"] = 3,
    ["crawlingnightmare"] = 3,
    ["deer_red"] = 3,
    ["deer_blue"] = 3,
    ["wobybig"] = 3,
    ["walrus"] = 3.5,
    ["abigail"] = 3.8,
    ["bishop"] = 4,
    ["bishop_nightmare"] = 4,
    ["spat"] = 4,
    ["ghost"] = 4,
    ["koalefant_summer"] = 4,
    ["koalefant_winter"] = 4,
    ["eyeturret"] = 4,
    ["krampus"] = 4,
    ["nightmarebeak"] = 4,
    ["terrorbeak"] = 4,
    ["spiderqueen"] = 4,
    ["teenbird"] = 4,
    ["warg"] = 4,
    ["lightninggoat"] = 4,
    ["antlion"] = 4,
    ["minotaur"] = 5,
    ["tallbird"] = 5,
    ["toadstool"] = 6,
    ["toadstool_dark"] = 6,
    ["klaus"] = 6,
    ["dragonfly"] = 8,
    ["beequeen"] = 8,
    ["leif"] = 8,
    ["leif_sparse"] = 8,
    ["stalker"] = 8,
    ["stalker_atrium"] = 8,
    ["crabking"] = 8,
    ["deerclops"] = 10,
    ["bearger"] = 10,
    ["malbatross"] = 10,
    ["moose"] = 14,
    ["default"] = 2,
    -------Forge-------
    ["crocommander_rapidfire"] = 3,
    ["crocommander"] = 3,
    ["scorpeon"] = 3,
    ["boarilla"] = 4,
    ["rhinocebro"] = 4,
    ["rhinocebro2"] = 4,
    ["boarrior"] = 5,
    ["swineclops"] = 5
    -------------------
}

local missingname_name = {
    ["stalker_forest"] = "Reanimated Skeleton",
    ["stalker"] = "Reanimated Skeleton",
    ["stalker_atrium"] = "Reanimated Skeleton",
    ["shadowminer"] = "Shadow Miner",
    ["shadowdigger"] = "Shadow Digger",
    ["shadowlumber"] = "Shadow Logger",
    ["shadowduelist"] = "Shadow Duelist",
    ["wobster_sheller_land"] = "Wobster",
    ["wobster_moonglass_land"] = "Lunar Wobster"
}

local function GetColour(number)
    local r, g, b = 1, 1, 1
    if number == 1 then -- Red
        r, g, b = 1, 0, 0
    elseif number == 2 then -- Green
        r, g, b = 0, 1, 0
    elseif number == 3 then -- Dark Green
        r, g, b = 0, 51 / 255, 0
    elseif number == 4 then -- Blue
        r, g, b = 0, 0, 1
    elseif number == 5 then -- Light Blue
        r, g, b = 102 / 255, 178 / 255, 1
    elseif number == 6 then -- Orange
        r, g, b = 1, 165 / 255, 0
    elseif number == 7 then -- Orangered
        r, g, b = 1, 69 / 255, 0
    elseif number == 8 then -- Yellow
        r, g, b = 1, 1, 0
    elseif number == 9 then -- Purple
        r, g, b = 153 / 255, 0, 153 / 255
    elseif number == 10 then -- Pink
        r, g, b = 1, 102 / 255, 178 / 255
    elseif number == 11 then -- Gray
        r, g, b = 192 / 255, 192 / 255, 192 / 255

    end
    return r, g, b
end

local function GetAggroOfMob(mob)
    local target
    if mob and mob:IsValid() and mob.replica.combat then
        target = mob.replica.combat:GetTarget()
    else
        target = nil
    end
    return target
end

local function GetLeaderOfMob(mob)
    local leader
    if mob and mob:IsValid() and mob.replica.follower then
        leader = mob.replica.follower:GetLeader()
    else
        leader = nil
    end
    return leader
end

local function CreateLabel(aggressor)
    local label = aggressor.entity:AddLabel()
    default_font = (mob_fontsize[aggressor.prefab]) or mob_fontsize["default"]
    label:SetFontSize(default_font)
    label:SetFont(GLOBAL.BODYTEXTFONT)
    y_offset = mob_offset[aggressor.prefab] or mob_offset["default"]
    label:SetWorldOffset(0, y_offset, 0)
    label:SetColour(1, 1, 1)
    label:Enable(true)
    return label
end

local function GetAggressorEntities()
    if not _G.ThePlayer then return nil, "No ThePlayer for positions" end
    local playerpos = _G.ThePlayer:GetPosition()
    local entity_table = TheSim:FindEntities(playerpos.x, 0, playerpos.z, 80,
                                             MUSTHAVE_TAGS, CANTHAVE_TAGS,
                                             MUSTONEOF_TAGS)
    return entity_table
end

local function ApplyColour(mob)
    if show_specialcolours == true then
        if GetLeaderOfMob(mob) and GetLeaderOfMob(mob) == GLOBAL.ThePlayer then
            mob.entity:AddLabel():SetColour(GetColour(colour_mobfriendyou))
        elseif GetAggroOfMob(mob) and GetAggroOfMob(mob) == GLOBAL.ThePlayer then
            mob.entity:AddLabel():SetColour(GetColour(colour_mobaggroyou))
        elseif GetAggroOfMob(mob) and
            (GetAggroOfMob(mob).prefab == "bernie_active" or
                GetAggroOfMob(mob).prefab == "bernie_big" or
                GetAggroOfMob(mob).prefab == "abigail" or
                GetAggroOfMob(mob).prefab == "shadowdigger" or
                GetAggroOfMob(mob).prefab == "shadowlumber" or
                GetAggroOfMob(mob).prefab == "shadowduelist" or
                GetAggroOfMob(mob).prefab == "shadowminer") then
            mob.entity:AddLabel():SetColour(GetColour(colour_mobaggrofollower))
        elseif GetAggroOfMob(mob) and GetAggroOfMob(mob):HasTag("player") and
            GetAggroOfMob(mob) ~= GLOBAL.ThePlayer then
            mob.entity:AddLabel():SetColour(GetColour(colour_mobaggroplayer))
        elseif GetLeaderOfMob(mob) and GetLeaderOfMob(mob):HasTag("player") and
            not (GetLeaderOfMob(mob) == GLOBAL.ThePlayer) then
            mob.entity:AddLabel():SetColour(GetColour(colour_mobfriendother))
        else
            mob.entity:AddLabel():SetColour(1, 1, 1)
        end
    else
        mob.entity:AddLabel():SetColour(1, 1, 1)
    end
end

local function StopShowAggroThread()
    if _G.ThePlayer and _G.ThePlayer.showaggro_thread then
        _G.KillThreadsWithID(_G.ThePlayer.showaggro_thread.id)
        _G.ThePlayer.showaggro_thread:SetList(nil)
        _G.ThePlayer.showaggro_thread = nil
    end
end

local function StartShowAggroThread() -- Instead of doing a periodic task, it now uses a thread. I also used this opportunity to clean the very unclean code.
    if _G.ThePlayer then
        _G.ThePlayer.showaggro_thread = _G.ThePlayer:StartThread(function()
            while _G.ThePlayer and _G.ThePlayer.showaggro_thread do
                Sleep(FRAMES)
                if (default_showaggro or default_befriended) and _G.ThePlayer then
                    local ent_table = GetAggressorEntities()
                    if not ent_table then return nil end
                    for _, ent in pairs(ent_table) do
                        if ent then
                            CreateLabel(ent)
                            ApplyColour(ent)
                            local leader = GetLeaderOfMob(ent)
                            local aggro = GetAggroOfMob(ent)
                            local leader_name = leader and
                                                    ((leader.name ~=
                                                        "MISSING NAME" and
                                                        leader.name) or
                                                        leader.name ==
                                                        "MISSING NAME" and
                                                        (missingname_name[leader.prefab] or
                                                            leader.prefab))
                            local aggro_name = aggro and
                                                   ((aggro.name ~=
                                                       "MISSING NAME" and
                                                       aggro.name) or aggro.name ==
                                                       "MISSING NAME" and
                                                       (missingname_name[aggro.prefab] or
                                                           aggro.prefab))
                            if leader_name and aggro_name and
                                (default_showaggro and default_befriended) then
                                ent.entity:AddLabel():SetText(string.format(
                                                                  "仇恨: %s ; 跟随: %s",
                                                                  aggro_name,
                                                                  leader_name))
                            elseif leader_name and (default_befriended) then
                                ent.entity:AddLabel():SetText(string.format(
                                                                  "跟随: %s",
                                                                  leader_name))
                            elseif aggro_name and (default_showaggro) then
                                ent.entity:AddLabel():SetText(string.format(
                                                                  "仇恨: %s",
                                                                  aggro_name))
                            else
                                ent.entity:AddLabel():SetText("")
                            end

                        end
                    end
                else
                    for _, ent in pairs(GetAggressorEntities() or {}) do -- Ents should have their labels reset if the player despawns.
                        if ent then
                            ent.entity:AddLabel():SetText("")
                            ent.entity:AddLabel():Enable(false)
                        end
                    end
                    StopShowAggroThread()
                end
            end
        end)
        _G.ThePlayer.showaggro_thread.id = "mod_show_aggro_thread"
    end
end

TheInput:AddKeyUpHandler(GetModConfigData("sw_showaggro"), function()
    if not InGame() then
        return
    else
        if default_showaggro then
            default_showaggro = false
        elseif not default_showaggro then
            default_showaggro = true
            if not _G.ThePlayer.showaggro_thread then
                StartShowAggroThread()
            end
        end
        TIP("关系显示", "white", default_showaggro)
    end
end)

TheInput:AddKeyUpHandler(GetModConfigData("sw_showaggro"), function()
    if not InGame() then
        return
    else
        if default_befriended then
            default_befriended = false
        elseif not default_befriended then
            default_befriended = true
            if not _G.ThePlayer.showaggro_thread then
                StartShowAggroThread()
            end
        end
    end
end)

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(1, function()
        if inst == GLOBAL.ThePlayer then
            if default_showaggro or default_befriended then
                StartShowAggroThread()
            end
        end
    end)
end)
