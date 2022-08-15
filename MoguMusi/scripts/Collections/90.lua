local recordTime = 0
local shortTime = 0.5
local minPoses = 4
local judgeLands = 2
local tw_poses = {}
local recordPoses = {}
local SaveDataName = "TW_Pos_"
local SaveSWName = "TW_Switch"
local DearSW = true
local tw_points = {}

local function CheckTW(pos, now)
    if now - recordTime > shortTime then return false end
    for _, tw_pos in pairs(tw_poses) do
        local dist = pos:Dist(tw_pos)
        if dist > judgeLands * 4 then return false end
    end
    return true
end
local function TW_Save()
    if GetWorldSeed() then
        SaveModData(SaveDataName .. GetWorldSeed(), recordPoses)
    end
end

AddPrefabPostInit("tumbleweed", function(inst)
    inst:DoTaskInTime(0.25, function(inst)
        local now = GLOBAL.GetTime()
        if inst.Transform and now and DearSW then
            local pos = GLOBAL.Vector3(inst.Transform:GetWorldPosition())
            if pos.x == 0 then return end
            if not CheckTW(pos, now) then
                recordTime = now
                tw_poses = {}
            end
            recordTime = now
            table.insert(tw_poses, pos)
            if #tw_poses == minPoses then
                local recordPos = {}
                for _, tw_pos in pairs(tw_poses) do
                    if not recordPos.x or not recordPos.y then
                        recordPos = tw_pos
                    else
                        recordPos.x = (tw_pos.x + recordPos.x) / 2
                        recordPos.z = (tw_pos.z + recordPos.z) / 2
                    end
                end

                table.insert(recordPoses, recordPos)
                local newPoint = GLOBAL.SpawnPrefab("reticule")
                newPoint.Transform:SetPosition(recordPos.x, 0, recordPos.z)
                newPoint.AnimState:SetAddColour(1, 0, 0, 0)
                TIP("风滚草预测", "green", "预测完成")
                table.insert(tw_points, newPoint)
                TW_Save()
            end
        end
    end)
end)

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(1.66, function()
        if inst == GLOBAL.ThePlayer then
            local data = LoadModData(SaveSWName)
            if data == nil then DearSW = true end
            if GetWorldSeed() then
                recordPoses = LoadModData(SaveDataName .. GetWorldSeed(),
                                          recordPoses) or {}
                if recordPoses and DearSW then
                    for _, recordPos in pairs(recordPoses) do
                        local newPoint = GLOBAL.SpawnPrefab("reticule")
                        newPoint.Transform:SetPosition(recordPos.x, 0,
                                                       recordPos.z)
                        newPoint.AnimState:SetAddColour(1, 1, 0, 0)
                        table.insert(tw_points, newPoint)
                    end
                end
            end
        end
    end)
end)

local temp = true
local function fn()
    if GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_LALT) and DearSW then
        if temp then
            for _, point in pairs(tw_points) do point:Hide() end
            TIP("奇怪的操作", "brown", "仅隐藏风滚草预测")
        else
            for _, point in pairs(tw_points) do point:Show() end
            TIP("奇怪的操作", "brown", "显示风滚草预测")
        end
        temp = not temp
        return
    end

    DearSW = not DearSW
    TIP("风滚草预测", "brown", DearSW)
    if not DearSW then
        recordPoses = {}
        for _, point in pairs(tw_points) do point:Hide() end
        TW_Save()
    end
    SaveModData(SaveSWName, DearSW)
end

DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("flowersalad.tex"),
                     "flowersalad.tex", "风滚草预测",
                     "注意！关闭此功能将删除该世界已经保存的风滚草记录！",
                     true, fn)

AddBindBtn("sw_tumbleweed", fn)
