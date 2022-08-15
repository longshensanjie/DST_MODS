local _G = GLOBAL
local require = _G.require
local loadfile = _G.loadfile
local TheSim = _G.TheSim
local EQUIPSLOTS = _G.EQUIPSLOTS
local TUNING = _G.TUNING
local ACTIONS = _G.ACTIONS
local RPC = _G.RPC

local SendRPCToServer = _G.SendRPCToServer
local UpvalueHacker = require("upvaluehacker")

local modconfig_optimumpos = true

local function HackLureFile()
    local _lures_file = loadfile("prefabs/oceanfishinglure")
    if type(_lures_file) ~= "function" then return {} end
    local lures = {}
    -- {_lures_file()}为{unpack(ret)}为表ret
    -- 该表由Prefab单个项目表组成
    -- Prefab.fn为所对应实体的构造函数
    for k, v in ipairs({_lures_file()}) do
        local name = UpvalueHacker.GetUpvalue(v.fn, "name")
        local data = UpvalueHacker.GetUpvalue(v.fn, "v")
        lures[name] = data.lure_data
    end
    return lures
end

local LURES = HackLureFile()
local FISH = require("prefabs/oceanfishdef").fish

for k, v in pairs(TUNING.OCEANFISHING_LURE) do
    if k == "SEED" then
        LURES["seeds"] = v
    elseif k == "BERRY" then
        LURES["berries"] = v
    elseif k == "SPOILED_FOOD" then
        LURES["spoiled_food"] = v
    end
end

-- 获取鱼竿实体
local function GetFishingRod()
    local fishingrod = _G.ThePlayer.replica.inventory and _G.ThePlayer.replica.inventory:GetEquippedItem(
                           EQUIPSLOTS.HANDS)
    if fishingrod ~= nil and fishingrod.replica.oceanfishingrod ~= nil then
        return fishingrod
    end
end

-- 获取该鱼的鱼饵列表
local function get_fishlurestable(fishprefab)
    local pref
    if FISH[fishprefab] ~= nil then
        pref = FISH[fishprefab].lures
    elseif string.sub(fishprefab, 0, 7) == "wobster" then
        pref = TUNING.OCEANFISH_LURE_PREFERENCE.WOBSTER
    end
    return pref
end

-- 获取鱼饵本身效力
local function getlureeffforfish(lureprefab, fishprefab, notreel)
    if lureprefab == nil or fishprefab == nil then return 0 end
    lureprefab = lureprefab == "berries_juicy" and "berries" or lureprefab

    local data = LURES[lureprefab]
    if data == nil then data = TUNING.OCEANFISHING_LURE.HOOK end

    local state_eff = data.timeofday ~= nil and
                          data.timeofday[_G.TheWorld.state.phase] or 0
    local perish_eff = 1
    --[[
	if lure.replica.inventoryitem~=nil and lure.replica.inventoryitem.classified~=nil then
        perish_eff=math.min(lure.replica.inventoryitem.classified.perish:value()/62,1)
    end
	--]]
    local weather = _G.TheWorld.state.israining and "raining" or
                        _G.TheWorld.state.issnowing and "snowing" or "default"
    local weather_eff = data.weather ~= nil and data.weather[weather] or
                            TUNING.OCEANFISHING_LURE_WEATHER_DEFAULT[weather] or
                            1
    local fish_prefs = get_fishlurestable(fishprefab)
    -- data.style为当前饵料类型
    local fish_prefs_eff = fish_prefs == nil and 1 or data.style ~= nil and
                               fish_prefs[data.style] or 0
    -- spoon
    -- spineer
    local reel_charm = data.reel_charm or 0

    local reel_eff = (data.charm + reel_charm) * state_eff * perish_eff *
                         weather_eff * fish_prefs_eff
    local notreel_eff = data.charm * state_eff * perish_eff * weather_eff *
                            fish_prefs_eff

    -- reel_eff = reel_eff and reel_eff <= 0 and notreel_eff or reel_eff

    local eff = notreel and notreel_eff or reel_eff

    eff = eff and eff < 0 and 0 or eff

    return eff
end


local function Tab_MergeTables(...)
    local tabs = {...}
    if not tabs then return {} end
    local origin = tabs[1]
    for i = 2, #tabs do
        if origin then
            if tabs[i] then
                for k, v in pairs(tabs[i]) do
                    table.insert(origin, v)
                end
            end
        else
            origin = tabs[i]
        end
    end
    return origin
end

-- 获取当前所有饵料针对该鱼的效果
local function getalllureeff(fishprefab, treeltype)
    if not fishprefab then return end
    local eff_treel = {}
    local eff_nottreel = {}
    local eff_mergetreel = {}
    local eff_mergetreel_cache = {}

    for k, v in pairs(LURES) do
        if v then
            local efficiency = getlureeffforfish(k, fishprefab, nil)
            table.insert(eff_treel, {prefab = k, efficiency = efficiency})
        end
    end

    for k, v in pairs(LURES) do
        if v then
            local efficiency = getlureeffforfish(k, fishprefab, true)
            table.insert(eff_nottreel, {prefab = k, efficiency = efficiency})
        end
    end

    for k, v in pairs(Tab_MergeTables(eff_treel, eff_nottreel)) do
        if v and v.prefab then
            local efficiency = v.efficiency
            local efficiency_cache = eff_mergetreel_cache[v.prefab] or -1 / 0
            if efficiency > efficiency_cache then
                eff_mergetreel_cache[v.prefab] = efficiency
            end
        end
    end

    for k, v in pairs(eff_mergetreel_cache) do
        if v then
            table.insert(eff_mergetreel, {prefab = k, efficiency = v})
        end
    end

    if treeltype == 1 then
        return eff_treel
    elseif treeltype == 2 then
        return eff_nottreel
    else
        return eff_mergetreel
    end

end

-- 获取当前饵料实体
local function getlurenowuse()
    local fishingrod = GetFishingRod()
    if fishingrod == nil then return end
    return fishingrod.replica.container:GetItems()[2] or nil
end

-- 获取身上饵料效果最高的饵料包括已经装备的饵料
local function getbetterlurefrominv(fishprefab)
    if not fishprefab then return end
    local lureefflist = getalllureeff(fishprefab, nil)
    local best = {-1 / 0, nil}
    local lures = _G.ThePlayer.replica.inventory:GetItems()
    table.insert(lures, getlurenowuse())
    for k, v in pairs(lures) do
        if v:HasTag("oceanfishing_lure") then
            local efficiency = 0
            if v and v.prefab then
                for k2, v2 in pairs(lureefflist) do
                    if v2 and v2.prefab and v2.prefab == v.prefab then
                        efficiency = v2.efficiency
                        break
                    end
                end
            end
            if best[1] < efficiency then best = {efficiency, v} end
        end
    end
    return best and best[2]
end

-- 获取饵料效果最高的排名
local function getbetterlurelist(fishprefab)
    if not fishprefab then return end
    local lureefflist = getalllureeff(fishprefab, nil)

    table.sort(lureefflist, function(a, b)
        a = a.efficiency
        b = b.efficiency
        return a > b
    end)

    return lureefflist
end

local function findfish(x, z)
    local ents = TheSim:FindEntities(x, 0, z, 3.5, {"oceanfishable"},
                                     {"INLIMBO"})
    return ents and _G.next(ents) and ents[1] or nil
end

local function GetPrefabFancyName(prefab)
    return _G.STRINGS.NAMES[string.upper(prefab)] or prefab
end

local function Say(text) TIP("自动海钓","white",text) end

local function getname(x, z)
    local fish = findfish(x, z)
    if fish then
        local nowlure = getlurenowuse()
        local best_now = getbetterlurefrominv(fish.prefab)
        local best_list = getbetterlurelist(fish.prefab)

        local fishname = fish and fish:GetBasicDisplayName() or "愿者上钩"

        local nowlurename = nowlure and nowlure:GetBasicDisplayName()
        nowlurename = nowlurename and nowlurename .. " " ..
                          getlureeffforfish(nowlure.prefab, fish.prefab) .. "/" ..
                          getlureeffforfish(nowlure.prefab, fish.prefab, true) or
                          "愿者上钩"

        local best_now_name = best_now and best_now:GetBasicDisplayName()
        best_now_name = best_now_name and best_now_name .. " " ..
                            getlureeffforfish(best_now.prefab, fish.prefab) ..
                            "/" ..
                            getlureeffforfish(best_now.prefab, fish.prefab, true) or
                            "愿者上钩"

        local best_list_name
        for k, v in ipairs(best_list) do
            local addtext = string.format("%s %s\n",
                                          GetPrefabFancyName(v.prefab),
                                          getlureeffforfish(v.prefab,
                                                            fish.prefab) .. "/" ..
                                              getlureeffforfish(v.prefab,
                                                                fish.prefab,
                                                                true))
            best_list_name = best_list_name and best_list_name .. addtext or
                                 addtext
            if k == 10 then break end
        end
        best_list_name = best_list_name or "愿者上钩"

        local text = [[
目标鱼类:%s
当前使用鱼饵:%s
推荐使用鱼饵:%s
...
下列为推荐鱼饵鱼钩【已排序】
重量级鱼饵会钓到同类鱼中的大鱼, 钓鱼效果仅对大鱼有效
...
名称 抖饵效果\不抖饵效果
%s
]]
        text = string.format(text, fishname, nowlurename, best_now_name,
                             best_list_name)
        print(text)

        -- 人物讲话
        local best_list_name2
        for k, v in ipairs(best_list) do
            local addtext = string.format("%s %s\n",
                                          GetPrefabFancyName(v.prefab),
                                          getlureeffforfish(v.prefab,
                                                            fish.prefab) .. "/" ..
                                              getlureeffforfish(v.prefab,
                                                                fish.prefab,
                                                                true))
            best_list_name2 = best_list_name2 and best_list_name2 .. addtext or
                                  addtext
            if k == 4 then break end
        end
        best_list_name2 = best_list_name2 or "愿者上钩"

        local textsay = string.format("%s: %s\n%s\n【按下CTRL+L查看更多信息】", fishname, nowlurename,
                                      best_list_name2)

        Say(textsay)
    end
end


-- 是否张力过高
local function IsCriticalTension()
    local fishingrod = GetFishingRod()
    if fishingrod ~= nil then
        return fishingrod.replica.oceanfishingrod:IsLineTensionHigh()
    end
end

-- 返回是否钓鱼和目标
local function IsFishing(onlyfish)
    local fishingrod = GetFishingRod()
    if fishingrod == nil then return false end
    local target = fishingrod.replica.oceanfishingrod:GetTarget()
    if not onlyfish then
        return target ~= nil, target
    elseif target ~= nil then
        return target:HasTag("oceanfishable"), target
    end
end

-- 收线
local function Reel()
    local fishing, target = IsFishing()
    if fishing then
        local pos = target:GetPosition()
        SendRPCToServer(RPC["RightClick"], ACTIONS.OCEAN_FISHING_REEL.code,
                        pos.x, pos.z)
    end
end

-- 捕获
local function Catch()
    local fishing, target = IsFishing()
    if fishing then
        local pos = target:GetPosition()
        SendRPCToServer(RPC["RightClick"], ACTIONS.OCEAN_FISHING_CATCH.code,
                        pos.x, pos.z)
    end
end

-- 钓鱼
local function FishingTask()
    if IsFishing() then
        local fishing, fish = IsFishing(true)
        if fishing then
            if not IsCriticalTension() then
                if fish:HasTag("oceachfishing_catchable") then
                    Catch()
                else
                    Reel()
                end
            end
        end
    end
end

local function GetBetterPos(px, pz, tx, tz)
    if not (px and pz and tx and tz) then return end

    local pt_d = _G.math.sqrt((tx - px) * (tx - px) + (tz - pz) * (tz - pz))

    for i = 0, 5, 0.001 do
        local nx = (tx - px) * i / pt_d + px
        local nz = (tz - pz) * i / pt_d + pz
        if _G.distsq(px, pz, nx, nz) >= 7.2 then return nx, nz end
    end
    return nil
end

local function ChoosePos(tx, tz)
    local p1x, _, p1z = _G.ThePlayer.Transform:GetWorldPosition()

    if _G.math.sqrt((p1x - tx) * (p1x - tx) + (p1z - tz) * (p1z - tz)) <= 4 then
        local pos_x, pos_z = GetBetterPos(p1x, p1z, tx, tz)
        if pos_x and pos_z then
            SendRPCToServer(RPC["RightClick"], ACTIONS.OCEAN_FISHING_CAST.code,
                            pos_x, pos_z)
            return true
        end
    end
    return false

end

if modconfig_optimumpos then
    local function CanCastFishingNetAtPoint(thrower, target_x, target_z)
        local min_throw_distance = 0 -- 2.9 or 2 
        local thrower_x, thrower_y, thrower_z =
            thrower.Transform:GetWorldPosition()

        if _G.TheWorld.Map:IsOceanAtPoint(target_x, 0, target_z) and
            _G.VecUtil_LengthSq(target_x - thrower_x, target_z - thrower_z) >
            min_throw_distance * min_throw_distance then return true end
        return false
    end

    local _COMPONENT_ACTIONS = UpvalueHacker.GetUpvalue(
                                   _G.EntityScript.CollectActions,
                                   "COMPONENT_ACTIONS")
    UpvalueHacker.SetUpvalue(_COMPONENT_ACTIONS.POINT.oceanfishingrod,
                             CanCastFishingNetAtPoint,
                             "CanCastFishingNetAtPoint")
end

AddComponentPostInit("playercontroller", function(PlayerController, inst)
    if not TheWorld.ismastersim then
        inst:DoPeriodicTask(.6, FishingTask)

        local old_OnRightClick = PlayerController.OnRightClick
        function PlayerController:OnRightClick(a, ...)
            if a == true then
                local act = PlayerController:GetRightMouseAction()
                local position = _G.TheInput:GetWorldPosition()

                if act and act.action and act.action == ACTIONS.OCEAN_FISHING_CAST then
                    getname(position.x, position.z)

                    if modconfig_optimumpos and ChoosePos(position.x, position.z) then
                        return
                    end
                end
            end
            old_OnRightClick(PlayerController, a, ...)
        end

        local old_OnLeftClick = PlayerController.OnLeftClick
        function PlayerController:OnLeftClick(a, ...)
            if a == true then
                local act = PlayerController:GetRightMouseAction()
                local position = _G.TheInput:GetWorldPosition()
                
                if act and act.action and act.action.code and act.action.code == ACTIONS.STOP_STEERING_BOAT.code and GetFishingRod() then 
                    getname(position.x, position.z) 
                end
            end
            old_OnLeftClick(PlayerController, a, ...)
        end
    
    end

end)
