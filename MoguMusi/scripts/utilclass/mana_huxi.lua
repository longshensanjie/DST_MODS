local DataUtil = require("QAQ/breathydata")

local ManaHuxi = Class(function(self)
    self.mana_boss = {}
    self.mana_buff = {}
    self.style = DataUtil.GetStyle()
end)
local function Say(content)
    if (IsSteam() or not TheWorld.ismastersim) and TheInventory:CheckOwnership("emoji_hambat") then
        content = ":hambat:"..content..":hambat:"
    end
    if TheNet and ThePlayer then
        TheNet:Say(content)
    end
end

local ReTime = 88888888                                                                     -- 除非一天的时间大于这个值才会出bug
local function GetNowTime()
    local state_time = TheWorld.state.time
    local state_cycles = TheWorld.state.cycles
    local day_time = TUNING.TOTAL_DAY_TIME
    local sys_time = (state_cycles + state_time) * day_time
    -- 科雷的bug, 只能自己适配了
    local diff_time = sys_time - ReTime                                                     -- 正常来说 diff应该在0-2之间
    if state_time < 0.98 or diff_time > day_time + 5 or diff_time < day_time - 5 then
        ReTime = sys_time
    end
    return ReTime
end


function ManaHuxi:read()
    local data = DataUtil.Load()
    if not data or not data.boss or not data.buff then return end
    for boss_name, boss_data in pairs(data.boss)do
        local getbossdata = DataUtil.GetBossData(boss_name)
        if not getbossdata then break end

        self.mana_boss[boss_name] = {
            death_time = boss_data.death_time,
            duration = boss_data.duration,
            descripe = getbossdata.descripe,
            image = getbossdata.image,
        }
    end
    for buff_name, buff_data in pairs(data.buff)do
        local getbuffdata = DataUtil.GetBuffData(buff_name)
        if not getbuffdata then break end
        self.mana_buff[buff_name] = {
            birth_time = GetTimePlaying(),
            duration_left = buff_data.duration_left - 1,      -- 实际剩余时长应该少一点
            descripe = getbuffdata.describe or "未知BUFF",
            image = getbuffdata.image,
        }
    end
end

function ManaHuxi:save()
    local boss_save = {}
    for boss_name,boss_data in pairs(self.mana_boss)do
        boss_save[boss_name] = {
            death_time = boss_data.death_time,
            duration = boss_data.duration,
        }
    end
    local buff_save = {}
    for buff_name, buff_data in pairs(self.mana_buff)do
        buff_save[buff_name] = {
            duration_left = self:getBuffLeft(buff_name)
        }
    end
    DataUtil.Save({boss = boss_save, buff = buff_save})
end

function ManaHuxi:getBuffLeft(buffname)
    local buff = self.mana_buff[buffname]
    local left_time = 0
    if buff then 
        left_time = buff.duration_left - (GetTimePlaying() - buff.birth_time)
    end
    return left_time > 0 and left_time or 0 
end
function ManaHuxi:getBossLeft(bossname)
    local boss = self.mana_boss[bossname]
    local left_time = 0
    if boss then
        left_time = boss.death_time + boss.duration - GetNowTime()
    end
    return left_time > 0 and left_time or 0
end
function ManaHuxi:addBuff(buff)
    -- 如果没有这种buff 或者 这种buff的真实剩余时间更长
    if not self.mana_buff[buff.name] or self:getBuffLeft(buff.name) < buff.duration then
        self.mana_buff[buff.name] = {
            birth_time = GetTimePlaying(),                  -- buff时间是根据玩家游玩时长决定
            duration_left = buff.duration,
            descripe = buff.describe or "未知BUFF",
            image = buff.image,
        }
    end
end
function ManaHuxi:addBoss(boss)
    -- boss数据无需判断是否有更新的刷新时间
    if (DataUtil.GetAnn() == "boss_kill" or DataUtil.GetAnn() == "boss_killer") then
        Say(boss.descripe.." 已被击杀！")
    end
    self.mana_boss[boss.name] = {
        death_time = GetNowTime(),            -- boss时间是由世界天数决定           
        duration = boss.duration and boss.duration+20 or 20,
        descripe = boss.descripe,
        image = boss.image,
    }
end

function ManaHuxi:removeBuff(buff_name)
   self.mana_buff[buff_name] = nil 
end

function ManaHuxi:removeBoss(boss_name)
    if (DataUtil.GetAnn() == "boss_spawn" or DataUtil.GetAnn() == "boss_killer") and self.mana_boss[boss_name].duration > 0 then
        Say(self.mana_boss[boss_name].descripe.." 已刷新")
    end
    self.mana_boss[boss_name] = nil 
 end

local function formatTime(time)
    if time > TUNING.TOTAL_DAY_TIME then
        local day = math.floor(time / TUNING.TOTAL_DAY_TIME)
        local modtime = math.floor(time) % TUNING.TOTAL_DAY_TIME
        local minute = math.floor(modtime / 60)
        local second = math.floor(modtime) % 60
        return string.format("%02d-%02d:%02d", day, minute, second)
    else
        local minute = math.floor(time / 60)
        local second = math.floor(time) % 60
        return string.format("%02d:%02d", minute, second)
    end
end

local function formatTimeChin(time)
    if time > TUNING.TOTAL_DAY_TIME then
        local day = math.floor(time / TUNING.TOTAL_DAY_TIME)
        local modtime = math.floor(time) % TUNING.TOTAL_DAY_TIME
        local minute = math.floor(modtime / 60)
        local second = math.floor(modtime) % 60
        return string.format("%02d天%02d分%02d秒", day, minute, second)
    else
        local minute = math.floor(time / 60)
        local second = math.floor(time) % 60
        return string.format("%02d分%02d秒", minute, second)
    end
end

function ManaHuxi:GetBosses()
    -- BOSS数据
    local bosses = {}
    local nowtime = GetNowTime()
    for boss_name,boss in pairs(self.mana_boss)do
        local timeleft = self:getBossLeft(boss_name)
        if timeleft>0 and (nowtime+120)> boss.death_time then
            table.insert(bosses, {
                name = boss_name, 
                duration_text = formatTime(timeleft), 
                description = boss.descripe.."刷新", 
                image = boss.image,
                textcolor = timeleft < 120 and UICOLOURS.RED
            })
        else
            self:removeBoss(boss_name)
        end
    end
    return bosses
end

function ManaHuxi:GetBuffs()
    -- BUFF数据
    local buffs = {}
    for buff_name,buff in pairs(self.mana_buff)do
        local timeleft = self:getBuffLeft(buff_name)
        if timeleft>0 then
            table.insert(buffs, {
                name = buff_name, 
                duration_text = formatTime(timeleft), 
                description = buff.descripe, 
                image = buff.image,
                textcolor = timeleft < 10 and UICOLOURS.RED
            })
        else
            self:removeBuff(buff_name)
        end
    end
    return buffs
end


function ManaHuxi:Product()
    local products = {}
    if self.style == "all" or self.style == "boss" then
        for _,__ in pairs(self:GetBosses())do
            table.insert(products,__)
        end
    end
    if self.style == "all" or self.style == "buff" then
        for _,__ in pairs(self:GetBuffs())do
            table.insert(products,__)
        end
    end
    return products
end

function ManaHuxi:shout()
    local content = {}
    for boss_name,boss in pairs(self.mana_boss)do
        local timeleft = formatTimeChin(self:getBossLeft(boss_name))
        table.insert(content, boss.descripe.."倒计时："..timeleft)
    end
    if GetTableSize(content) > 0 and (DataUtil.GetAnn() == "boss_day" or DataUtil.GetAnn() == "boss_killer") then
        Say(table.concat(content, ", "))
    end
end

function ManaHuxi:Permiss(name)
    if self.mana_boss[name] then
        return true
    end
end

function ManaHuxi:Process(data)
    if not data or not data.type then return end
    if data.type == "food" then
        local aFoodBuffs = DataUtil.GetFoodBuffForPrefab(data.name)
        for _,aFoodBuff in pairs(aFoodBuffs)do
            self:addBuff(aFoodBuff)
        end
    elseif data.type == "boss" then
        local info = DataUtil.GetBossData(data.name)
        if info then self:addBoss(info)end
    elseif data.type == "style" then
        self.style = data.name
    elseif data.type == "removeboss" then
        if self.mana_boss[data.name] then
            self.mana_boss[data.name] = nil
        end
    elseif data.type == "ins" then
        if data.name == "ReadAndShow" then
            self:read()
            self.style = DataUtil.GetStyle()
        elseif data.name == "SaveAllData" then
            self:save()
        elseif data.name == "ClearBuff" then
            self.mana_buff = {}
        elseif data.name == "Morning" then
            self:shout()
            self:save()
        end
    elseif data.type == "fallInLove" then
        if data.name and data.name.warn and data.name.time then
            local bossdata = DataUtil.GetBossData(data.name.warn)
            if bossdata then
                self.mana_boss[data.name.warn] = {
                    death_time = GetNowTime(),
                    duration = data.name.time,
                    descripe = bossdata.descripe,
                    image = bossdata.image,
                }
            end
        end
    elseif data.type == "setBossTimer" then
        local boss_name = data.name.name
        local daytime = data.name.time
        if boss_name and daytime then
            if self.mana_boss[boss_name] then
                self.mana_boss[boss_name].duration = daytime * TUNING.TOTAL_DAY_TIME
                self:save()
            end
        end 
    elseif data.type == "sayIt" then
        local name = data.name
        if name and self.mana_boss[name] then
            Say(self.mana_boss[name].descripe .. "刷新时间"..formatTimeChin(self:getBossLeft(name)))
        end
        if name and self.mana_buff[name] then
            Say("我拥有BUFF:" .. self.mana_buff[name].descripe.."("..formatTime(self:getBuffLeft(name)) ..")")
        end
    end
end


return ManaHuxi