-- 合集中禁止覆盖环境
-- 只能记录位置固定的容器，因为切斯特这种太麻烦了
--[[
    根据位置确定容器
    格式：INFO = {
        posx ={
            posz = {
                prefab = {...}
            }
        },
    }
]]

local TheInput = GLOBAL.TheInput
local STRINGS = GLOBAL.STRINGS
local file_id = "BOX_"
local pos_id = "POS_"
local world_seed
local INFO = {}
local funcTip = "箱子记忆"
local checkRange = 80
local function prlog(...)
    print(funcTip, ...)
end


local function GetPosID(pos)
    if type(pos) == "number" then
        return string.format(pos_id.."%.2f", pos)
    else
        prlog("传递POSID错误", pos)
    end
end


local function GetIDPos(str)
    local pos = string.gsub(str, "^"..pos_id, "")
    return pos and tonumber(pos)
end

local function GetCheckRange(r1, r2)
    if r1 and r2 and math.abs(r1-r2) < checkRange then
        return true
    end
    return false
end



local dyeing_containers = {}
local function ModifyContainerColor(container, reset)
    if container and container.AnimState then
        if reset then
            container.AnimState:SetMultColour(1,1,1,1)
        else
            container.AnimState:SetMultColour(0,1,0,1)
            table.insert(dyeing_containers, container)
        end
    end
end


local function ClearAllContainersColor()
    for _, dye_cont in pairs(dyeing_containers)do
        ModifyContainerColor(dye_cont, true)
    end
    dyeing_containers = {}
end

AddPrefabPostInit("world", function (inst)
    inst:DoTaskInTime(3, function()
        world_seed = GetWorldSeed()
        if type(world_seed) == "string" then
            INFO = LoadModData(file_id..world_seed) or {}
        else
            prlog("种子丢失, 无法加载世界配置")
        end
    end)
end)

local function ModifyPrefabsFromSingleContainer(container)
    local container_prefab = container.prefab
    local cont_pos = container:GetPosition()
    if container.replica and container.replica.container and container_prefab and cont_pos then
        local cont_items = container.replica.container:GetItems() or {}
        local item_table = {}
        for _,item in pairs(cont_items)do
            if item.prefab and not table.contains(item_table, item.prefab) then
                table.insert(item_table, item.prefab)
            end
        end
        -- prlog("记录", GetPosID(cont_pos.x), GetPosID(cont_pos.z), container_prefab)
        SetTableMultiLevel(INFO, {GetPosID(cont_pos.x), GetPosID(cont_pos.z), container_prefab}, item_table)
    end
end

local function ModifyAllPrefabsFromAdditionalContainer()
    local bodyitems = GLOBAL.ThePlayer.replica.inventory:GetItems() or {}
    local equipitems = GLOBAL.ThePlayer.replica.inventory:GetEquips() or {}
    local containers = GLOBAL.ThePlayer.replica.inventory:GetOpenContainers() or {}
    for container in pairs(containers)do
        -- 只对箱子记录
        if not table.contains(mergeTable(bodyitems, equipitems), container) then
            ModifyPrefabsFromSingleContainer(container)
        end
    end
end

local function GetAllMeetContainers(prefab)
    local data = {}
    if not prefab or prefab == "" then return data end
    local player_pos = GLOBAL.ThePlayer:GetPosition() or {}
    for pos_x, pos_x_t in pairs(INFO)do  
        if GetCheckRange(GetIDPos(pos_x), player_pos.x) then
            for pos_z, pos_z_t in pairs(pos_x_t)do
                if GetCheckRange(GetIDPos(pos_z), player_pos.z) then
                    for cont_prefab, cont_data in pairs(pos_z_t)do
                        if table.contains(cont_data, prefab)then
                            -- prlog("获取到数据", pos_x, pos_z, cont_prefab)
                            table.insert(data, {pos = {x = GetIDPos(pos_x), z = GetIDPos(pos_z)}, prefab = cont_prefab})
                        end
                    end
                end
            end
        end
    end
    return data
end

local function ShowMeetContainersWithPrefab(prefab)
    ClearAllContainersColor()
    local containers_data = GetAllMeetContainers(prefab)
    for _,cont_data in pairs(containers_data)do
        local pos = cont_data.pos
        local allconts = GLOBAL.TheSim:FindEntities(pos.x, 0, pos.z, 0.01)
        for _, acont in pairs(allconts)do
            if acont.prefab == cont_data.prefab then
                ModifyContainerColor(acont, false)
            end
        end
    end
end



local pointer
-- is_display
---- true:展示该prefab
---- false:移除该prefab的展示
local function ShowPrefabView(prefab, is_display)
    if is_display then
        pointer = prefab
    else
        if pointer == prefab then
            pointer = nil
        end
    end
    ShowMeetContainersWithPrefab(pointer)
end

local function Save_REAT_Data()
    world_seed = GetWorldSeed()
    if type(world_seed) == "string" then
        SaveModData(file_id..world_seed, INFO)
    end
end

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(2.5, function()
        if inst == GLOBAL.ThePlayer then
            inst:ListenForEvent("refreshinventory", function()
                if GLOBAL.ThePlayer and GLOBAL.ThePlayer.replica.inventory then
                    local active_item = GLOBAL.ThePlayer.replica.inventory:GetActiveItem()
                    if active_item then
                        ShowMeetContainersWithPrefab(active_item.prefab)
                    else
                        ClearAllContainersColor()
                    end
                    ModifyAllPrefabsFromAdditionalContainer()
                end
            end)
            inst:WatchWorldState("startday", Save_REAT_Data)
        end
    end)
end)

local _DoRestart = GLOBAL.DoRestart
function GLOBAL.DoRestart(val)
	if val then
        Save_REAT_Data()
	end
	_DoRestart(val)
end
local _MigrateToServer = GLOBAL.MigrateToServer
function GLOBAL.MigrateToServer(ip,port,...)
	if ip and port then
        Save_REAT_Data()
	end
	_MigrateToServer(ip,port,...)
end

AddClassPostConstruct("components/container_replica", function (self, ent)
    local _Open = self.Open
    function self.Open(...)
        ModifyPrefabsFromSingleContainer(ent)
        _Open(...)
    end
end)


-- 侧边栏显示
AddClassPostConstruct("widgets/redux/craftingmenu_pinslot", function (self, ...)
    local _OnGainFocus = self.OnGainFocus
    function self.OnGainFocus(self, ...)
        ShowPrefabView(self.recipe_name, true)
        return _OnGainFocus(self, ...)
    end    
    
    local _OnLoseFocus = self.OnLoseFocus
    function self.OnLoseFocus(self, ...)
        ShowPrefabView(self.recipe_name, false)
        return _OnLoseFocus(self, ...)
    end
end)


-- 直接抄show me
-- 配方显示
AddClassPostConstruct("widgets/ingredientui", function (self, ...)
    local _OnGainFocus = self.OnGainFocus
    function self.OnGainFocus(self, ...)
        local prefab = self.ing and self.ing.texture and self.ing.texture:match('[^/]+$'):gsub('%.tex$', '')
        local player = self.parent and self.parent.parent and self.parent.parent.owner

        if prefab and player then
            ShowPrefabView(prefab, true)
        end
        if _OnGainFocus then
            return _OnGainFocus(self, ...)
        end
    end

    local _OnLoseFocus = self.OnLoseFocus
    function self.OnLoseFocus(self, ...)
        local prefab = self.ing and self.ing.texture and self.ing.texture:match('[^/]+$'):gsub('%.tex$', '')
        local player = self.parent and self.parent.parent and self.parent.parent.owner

        if prefab and player then
            ShowPrefabView(prefab, false)
        end
        if _OnLoseFocus then
            return _OnLoseFocus(self, ...)
        end
    end
end)

-- 制作栏按钮显示
-- 不写了，不好定位按钮，初步定位在
-- ThePlayer.HUD.controls.craftingmenu.craftingmenu.recipe_grid
-- 下次接着看