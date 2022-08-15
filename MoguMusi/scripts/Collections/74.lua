
local ArchiveTask_thread = nil
local center,smalls
local rightPoints = {}

local function ResetAll()
    if smalls then
        for _, small in pairs(smalls) do
            small.pos = nil
            small.flag = nil
            small = nil
        end
    end
    if rightPoints then
        for _, point in pairs(rightPoints) do
            point.pos = nil
            point.flag = nil
            point = nil
        end
    end
    center = nil
    rightPoints = {}
    smalls = {}
    TIP("档案馆辅助", "red", "任务终止")
end

local function ToggleLagCompensation()  -- 用来切补偿的
    local playercontroller = GLOBAL.ThePlayer.components.playercontroller
    local movementprediction = not GLOBAL.Profile:GetMovementPredictionEnabled()
    if playercontroller:CanLocomote() then
        playercontroller.locomotor:Stop()
    else
        playercontroller:RemoteStopWalking()
    end
    GLOBAL.ThePlayer:EnableMovementPrediction(movementprediction)
    GLOBAL.Profile:SetMovementPredictionEnabled(movementprediction)
end
 
local locomotor_lag = false
local function ClearArchiveTaskThread() 					-- 杀线程
    if ArchiveTask_thread then
        GLOBAL.KillThreadsWithID(ArchiveTask_thread.id)
        ResetAll()
        ArchiveTask_thread:SetList(nil)
        ArchiveTask_thread = nil
        if locomotor_lag then   							-- 切回去原来的补偿状态
            ToggleLagCompensation()
        end
    end
end

local function SendAction(act, fn)
    local ThePlayer = GLOBAL.ThePlayer
    local playercontroller = ThePlayer.components.playercontroller
    if playercontroller.ismastersim then
        ThePlayer.components.combat:SetTarget(nil)
        playercontroller:DoAction(act)
        return
    end

    if playercontroller.locomotor then
        act.preview_cb = fn
        playercontroller:DoAction(act)
    else
        fn()
    end
end

local function table_leng(t)
    local leng = 0
    for k, v in pairs(t) do
        leng = leng + 1
    end
    return leng
end

local function OffsetPos(point1, point2, distance) -- 将point1向point2偏移distance,返回point1的位置
	point1.x = point1.x - ((point1.x - point2.x)/math.abs(point1.x - point2.x))*math.cos(math.atan((point1.z - point2.z)/(point1.x - point2.x)))*distance -- 偏移后的x
	point1.z = point1.z - ((point1.z - point2.z)/math.abs(point1.z - point2.z))*math.abs(math.sin(math.atan((point1.z - point2.z)/(point1.x - point2.x))))*distance	--偏移后的z
    return point1
end

local function FindItemFromTile(prefab, num) -- 从地皮上寻找给定数目的实体, 如果num不提供,则返回找到的第一个
	local prefabs = {}
	local pos = GLOBAL.ThePlayer:GetPosition()
	for k,v in pairs(GLOBAL.TheSim:FindEntities(pos.x,0,pos.z,50,nil,{"INLIMBO"})) do
		if v and v:IsValid() and v.prefab == prefab then
			prefabs[#prefabs + 1] = v
		end
	end
    if not num then
        return prefabs[1]
    elseif num == #prefabs then
        return prefabs
    end
    return nil
end

local function WalkToTarget(target) -- 走向目标偏移后的位置,到达后返回true
    local player_pos
    local target_pos = target.pos or target:GetPosition()
    while true do
        player_pos = GLOBAL.ThePlayer:GetPosition()
        SendAction(GLOBAL.BufferedAction(GLOBAL.ThePlayer, nil, GLOBAL.ACTIONS.WALKTO, nil, target_pos), function ()
            GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, GLOBAL.ACTIONS.WALKTO.code, target_pos.x, target_pos.z)
        end)
        GLOBAL.Sleep(GLOBAL.FRAMES * 3)
        local nowPlayer_pos = GLOBAL.ThePlayer:GetPosition()
        if player_pos == target_pos or player_pos == nowPlayer_pos then
            return true
        end
    end
    return false
end 

local function Archive_Init()   -- 对基座和点位进行初始化
    if ArchiveTask_thread then
        ClearArchiveTaskThread()
        return false
    end
    center = FindItemFromTile("archive_orchestrina_base")
    if not center then
        TIP("档案馆辅助", "red", "档案馆不在周围")
        return false
    end
	center.pos = center:GetPosition()
    smalls = FindItemFromTile("archive_orchestrina_small", 8)
    if smalls and table_leng(smalls) == 8 then
        for _, small in pairs(smalls) do
            small.pos = OffsetPos(small:GetPosition(), center.pos, 1)
            small.flag = nil
        end
        TIP("档案馆辅助", "green", "开始")
        return true
    else
        TIP("档案馆辅助", "red", "档案馆不在周围")
        return false
    end
end

local function ResetWrongPoints()   -- 重置错误点的状态
    for _, small in pairs(smalls) do
        if small.flag ~= 1 then
            small.flag = nil
        end
    end
end




local function GoToNextPoint() -- 这个函数能找出与当前所在点距离最近的一个不明状态点
    local MinDistance = 10000
    local point
    for _, small in pairs(smalls) do
        if not small.flag then
            local Distance = GLOBAL.ThePlayer:GetPosition():DistSq(small.pos)
            if Distance < MinDistance then
                MinDistance = Distance
                point = small
            end
        end
    end
    if point then
        WalkToTarget(point)
    else
        TIP("档案馆辅助", "red", "任务异常, 请主动打断！","chat")
    end
    return point
end

local function GoToRightPoints()            -- 走一遍对的点
    local point
    if table_leng(rightPoints) == 0 then    -- 如果对的表为空
        point = GoToNextPoint()             -- 直接走向下一个点
        return point
    end
    for _, _point in pairs(rightPoints) do  -- 走一遍已经对的点
        WalkToTarget(_point)
        point = _point
    end
    return point
end

local anim_all = {"one", "two", "three", "four", "five", "six", "seven", "eight"}
local function isanim(entity,anim)  -- 来自呼吸的判断动画
    return entity and entity.AnimState and entity.AnimState:IsCurrentAnimation(anim)
end

local function CheckNowPoint(ent)
	for i,v in ipairs(anim_all) do
		if isanim(ent, v) or isanim(ent, v.."_pre") then
			return i 
		end
	end
end

local function GetItem()    -- 蒸馏知识或者空白勋章
    ThePlayer = GLOBAL.ThePlayer
	local items = {"archive_lockbox", "blank_certificate",}
    if not ThePlayer and ThePlayer.replica.inventory then return false end
	for i,item in ipairs(items) do
		for container,v in pairs(ThePlayer.replica.inventory:GetOpenContainers()) do
			if container and container.replica and container.replica.container
			then
				local items_container = container.replica.container:GetItems()
				for k,v in pairs(items_container) do
					if v.prefab == item then
						return v, k, container.replica.container
					end
				end
			end
		end
		for k,v in pairs(ThePlayer.replica.inventory:GetItems()) do
			if v.prefab == item then
				return v, k, ThePlayer.replica.inventory
			end
		end
	end
    return false
end

local function GoToCenterAndPutDown()
    local item = GetItem()
    if item then
        WalkToTarget(center)
        GLOBAL.ThePlayer.replica.inventory:DropItemFromInvTile(item)
		TIP("档案馆辅助", "green", "尝试放下蒸馏的知识")
        return true
    end
	TIP("档案馆辅助", "red", "未携带蒸馏的知识")
    return false
end

local function ArchiveTask()
    if not InGame() then return end			-- 不在游戏中退出
	if not Archive_Init()  then return end	-- 初始化失败退出
    ArchiveTask_thread = GLOBAL.ThePlayer:StartThread(function ()
        if GoToCenterAndPutDown() then		-- 去中心然后放下
            if not GLOBAL.ThePlayer.components.playercontroller.locomotor then -- 麻瓜办法,既然关延迟不行,就检测如果关了帮开延迟
                locomotor_lag = true
                ToggleLagCompensation() 
            end
            GLOBAL.Sleep(GLOBAL.FRAMES * 10)	
            local num = 0					-- 计数器置0
            local point = GoToNextPoint()	-- 去下一个点
            while true and point do
                if CheckNowPoint(point) then		-- 检测现在所在点是不是对的
                    if point.flag ~= 1 then			-- 新的对的点
                        num = num + 1               -- 计数器加1
                        rightPoints[num] = point    -- 记录新的点到表中
                        point.flag = 1              -- 表示对的点
                        ResetWrongPoints()          -- 除对的点外其他点的flag重置为nil 
                    end
                    point = GoToNextPoint()         -- 去下一个点
                else
                    point.flag = 0                  -- 表示错的点
                    point = GoToRightPoints()       -- 走一遍对的点
                end
                GLOBAL.Sleep(GLOBAL.FRAMES * 15)					-- 这个延迟来保证动画可以被检测到
                if table_leng(rightPoints) == table_leng(smalls) - 1 then	-- 任务完成后,退出循环并提示
					TIP("档案馆辅助", "green" ,"我滴任务完成辣！","chat")
                    break
                end
            end
        end
        ClearArchiveTaskThread() -- 任务做完全清
    end, "ArchiveTask_thread_id")
end


InterruptedByMobile(function()
    return ArchiveTask_thread
end, ClearArchiveTaskThread)

if GetModConfigData("sw_DAG") == "biubiu" then
DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("archive_lockbox.tex"), "archive_lockbox.tex", "档案馆任务", "携带蒸馏的知识去科技馆吧！(也支持能力勋章)", false, ArchiveTask)
end

AddBindBtn("sw_DAG", ArchiveTask)