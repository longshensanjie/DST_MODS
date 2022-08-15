local _G = GLOBAL
local scheduler = _G.scheduler
local subfmt = _G.subfmt
local AW_STRINGS = require("strings/chinese_s")

local function PushHuxi(type, name)
    if GLOBAL.TheWorld then
        GLOBAL.TheWorld:PushEvent("Mod_Shroomcake_Huxi", {type = type, name = name})
    end
end


local function Say(message)
    TIP("怪物预警","red",message)
end

local bosses_warning = {
    deerclops = true and {},
    bearger = true and {},
    twister = true and {}
}

local function DoBossWarning(boss, level, times)
    local time = level == 4 and times == 3 and 3
        or ((5 - level) * 30) - 15 * (times - 1)
    PushHuxi("fallInLove", {warn = boss, time = time})
    Say(subfmt(AW_STRINGS.BOSSES._format, {boss = AW_STRINGS.BOSSES[boss] or boss, time = time}))
end

local function reset_times(record_table, ...)
    local args = {...}
    for k, v in pairs(record_table) do
        if type(v) == "number" and not table.contains(args, k) then
            v = 0
        end
    end
end

for boss, record_table in pairs(bosses_warning) do
    if record_table then
        for i = 2, 4 do -- Level one is useless I guess.. (longer than 90s)
            local level = tostring(i)
            AddPrefabPostInit(boss.."warning_lvl"..level, function(inst)
                if not record_table[level] then
                    record_table[level] = 0
                end
                record_table[level] = record_table[level] + 1
                if record_table[level] > level - 1 then
                    record_table[level] = 1
                end
                reset_times(record_table, level)
                DoBossWarning(boss, i, record_table[level])

                -- Reset the times, if no warning any more
                if record_table.task then
                    record_table.task:Cancel()
                end
                record_table.task = scheduler:ExecuteInTime(60, function()
                    reset_times(record_table)
                    record_table.task = nil
                end)
            end)
        end
    end
end

local hounded_warning = {
    hound = true and {},
    worm = true and {}
}

local function DoHoundedWarning(attacker, time)
    PushHuxi("fallInLove", {warn = attacker, time = time})
    Say(subfmt(AW_STRINGS.HOUNDED._format, {attacker = AW_STRINGS.HOUNDED[attacker] or attacker, time = time}))
end

local function start_hounded_task(attacker, record_table, level)
    DoHoundedWarning(attacker, record_table.time)
    local next_warning_delay = 15
    if record_table.time == 15 then
        record_table.time = record_table.time - 12
        next_warning_delay = 12
    elseif record_table.time <= 3 then
        record_table.task = scheduler:ExecuteInTime(30, function() -- Cooldown
            record_table.task = nil
        end)
        return
    else
        record_table.time = record_table.time - 15
    end
    record_table.task = scheduler:ExecuteInTime(next_warning_delay, function()
        start_hounded_task(attacker, record_table, level)
    end)
end

for attacker, record_table in pairs(hounded_warning) do
    if record_table then
        for i = 2, 4 do
            local level = tostring(i)
            AddPrefabPostInit(attacker.."warning_lvl"..level, function(inst)
                if record_table.task
                    and (record_table.current_level == nil or record_table.current_level > i) then
                        
                    record_table.task:Cancel()
                    record_table.time = (5 - i) * 30
                    start_hounded_task(attacker, record_table, i)
                elseif not record_table.task then

                    record_table.time = (5 - i) * 30
                    start_hounded_task(attacker, record_table, i)
                end
                record_table.current_level = i
            end)
        end
    end
end

local antlion_warning = {
    sinkhole = true and {},
    cavein = true and {}
}

local antlion_warning_prefabs = {
    sinkhole = {"sinkhole_warn_fx_1", "sinkhole_warn_fx_2", "sinkhole_warn_fx_3"},
    cavein = {"cavein_debris"}
}

for trouble, record_table in pairs(antlion_warning) do
    if record_table then
        for _, prefab in ipairs(antlion_warning_prefabs[trouble]) do
            AddPrefabPostInit(prefab, function(inst)
                if record_table.task then return end
                PushHuxi("fallInLove", {warn = trouble, time = 10})
                Say(subfmt(AW_STRINGS.ANTLION._format, {trouble = AW_STRINGS.ANTLION[trouble] or trouble}))
                record_table.task = scheduler:ExecuteInTime(30, function()
                    record_table.task = nil
                end)
            end)
        end
    end
end
