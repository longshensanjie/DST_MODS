local _G = GLOBAL
local player_indicators = {}

--范围警示齿轮追踪
local COL_RED = {1,0,0,1}
local COL_GREEN = {0,1,0,1}
local COL_SPRINGGREEN = {0.5,1,0.7,1}
local COL_ORANGE = {1,0.5,0,1}
local COL_DARKBLUE = {0,0,1,1}
local COL_BLUE = {0,0.4,1,1}
local COL_YELLOW = {1,0.8,0,1}
local COL_PINK = {1,0,1,1}
local COL_BLACK = {0,0,0,1}
local COL_WHITE = {1,1,1,1}
local COL_BROWN = {0.5,0.3,0.2,1}

local LAZY_TICKS = 40

-- 设置颜色
local function SetCol(inst,col)
	if col then
		inst.AnimState:SetMultColour(col[1],col[2],col[3],col[4])
	end
end

-- 毁灭实体的孩子们
local function OnTrackRemove(inst)
	-- 实体没有孩子就返回
	if not inst.my_children then
		return
	end
	-- 有孩子则变成杀了孩子
	for child,_ in pairs(inst.my_children) do
		child.my_parent = nil
		child:Remove()
	end
	-- 将孩子名单也清空，孩子的任务也取消
	inst.my_children = nil
	if inst.my_children_task then
		inst.my_children_task:Cancel()
	end
end


-- 踪迹追踪【这尼玛啥玩意】
local function TrackUpdate(inst)
	-- stop_update 默认40
	-- no_move 默认0
	-- 该函数0.01秒循环执行

	-- 该函数在0.4秒后执行
	if inst.my_children_stop_update > 0 then 
		inst.my_children_stop_update = inst.my_children_stop_update - 1
		return
	end
	if not inst:IsValid() then 
		inst.my_children_task:Cancel()
		return
	end
	local x,y,z = inst.Transform:GetWorldPosition()

	-- change表示是否挺远
	local changed = true
	for k,v in pairs(inst.my_children) do
		if not k:IsValid() then 
			inst.my_children[k]=nil
		else
			local x0,y0,z0 = k.Transform:GetWorldPosition()
			-- 孩子和父母的距离过近时change为假
			if math.abs(x-x0) + math.abs(z-z0) < 0.001 then
				changed = false
				break
			else
			-- 不近时标记孩子的动画位置
				k.Transform:SetPosition(x,0,z) 
			end
		end
	end
	
	if changed then
		-- 挺远则 NO_MOVE = -1800
		inst.my_children_no_move = -1800 
		for k,v in pairs(inst.my_children) do
			-- 如果孩子有条件且不满足条件则移除孩子
			if k.condition_fn and not k.condition_fn() then 
				k.my_parent = nil
				inst.my_children[k] = nil
				k:Remove()
			end
		end
	else
		-- 挺近时加一，18秒很近则0.4秒后刷新
		inst.my_children_no_move = inst.my_children_no_move + 1 
		if inst.my_children_no_move > LAZY_TICKS then
			inst.my_children_stop_update = LAZY_TICKS 
		end
	end
end

local function MyAddChild(inst,prefab,must_track,anim,scale,condition_fn)
	if inst == nil then return false end
	
	if inst.my_children == nil then
		inst.my_children = {}
	end
	local child = _G.SpawnPrefab(prefab)
	if not (child and child.Transform) then
		return
	end
	if condition_fn and type(condition_fn) == "function" then
		child.condition_fn = condition_fn
	end
	child.my_parent = inst
	inst.my_children[child] = true 
	inst:ListenForEvent("onremove", OnTrackRemove) 
	inst:DoTaskInTime(0,function(inst)
		if not inst:IsValid() then return end
		local x,y,z = inst.Transform:GetWorldPosition()
		child.Transform:SetPosition(x, 0, z)
		if anim ~= nil then
			child.AnimState:PlayAnimation(anim)
		end
		if scale ~= nil then
			child.Transform:SetScale(scale,scale,scale)
		end
		if must_track ~= nil and inst.my_children_task == nil then 
			inst.my_children_stop_update = LAZY_TICKS 
			inst.my_children_no_move = 0 
			inst.my_children_task = inst:DoPeriodicTask(0.01,TrackUpdate)
		end
		--child.AnimState:SetMultColour(r,g,b,a)
	end)
	return child
end

local function UpdatePlayerIndicators()
	if not _G.ThePlayer then
		return
	end
	local x0,y0,z0 = _G.ThePlayer.Transform:GetWorldPosition()
	for player,indicator in pairs(player_indicators) do
		if not player:IsValid() or not indicator:IsValid() then
			player_indicators[player] = nil 
		else
			local x,y,z = player.Transform:GetWorldPosition()
			local dx,dy = (x-x0), (z-z0)
			if math.abs(dx) > 5 or math.abs(dy) > 5 then
				local alpha = math.deg(math.atan2(dx,dy)) + 180
				indicator.Transform:SetRotation(alpha)
				indicator:Show()
				--check color
				local col = indicator.colours
				local col_new
				
				if player.name == "Astro" then --admin?
					col_new = {0, 0.4, 1, 1} 
				elseif player:HasTag("playerghost") then
					col_new = {0, 0, 1, 1} 
				elseif indicator.custom_rgba then
					col_new = indicator.custom_rgba
				else
					col_new = {1, 1, 1, 1} 
				end
				if col[1] ~= col_new[1] or col[2] ~= col_new[2] or col[3] ~= col_new[3] or col[4] ~= col_new[4] then
					indicator.colours = col_new
					indicator.AnimState:OverrideMultColour(col_new[1],col_new[2],col_new[3],col_new[4]) --[02:35:44]: Stale Component Reference: 
				end
			else
				indicator:Hide()
			end
		end
	end
end



local function AddTrackingIndicator(inst,scale,condition,r,g,b,a)
	inst:DoTaskInTime(0,function(inst) 
		if _G.ThePlayer == nil then
			return print("No local player",inst)
		end
		if condition ~= nil and not condition then
			return --print("Bad condition",inst)
		end
		local indicator = MyAddChild(_G.ThePlayer,
			"private_circle", --prefab
			true, 
			"up", --arrow up anim
			scale, --scale
			condition --condition function
		)
		if indicator then
			if r ~= nil then
				indicator.custom_rgba = {r,g,b,a}
			end
			player_indicators[inst] = indicator
			inst:ListenForEvent("onremove", function()
				if indicator:IsValid() then
					if indicator.my_parent then
						indicator.my_parent.my_children[indicator] = nil
					end
					indicator.my_parent = nil
					indicator:Remove()
				end 
			end)
			UpdatePlayerIndicators()
		end
	end)
end


--------------- 正式内容



AddPrefabPostInit("world",function(inst) 
	inst:DoPeriodicTask(0.2+0.01*math.random(),function(inst)
		UpdatePlayerIndicators()
	end)
end)

--wendy 更新 协助小惊吓辅助 c_gonext("gravestone")
local xjx_toy_types =
{
    "lost_toy_1",
    "lost_toy_2",
    "lost_toy_7",
    "lost_toy_10",
    "lost_toy_11",
    "lost_toy_14",
    "lost_toy_18",
    "lost_toy_19",
    "lost_toy_42",
    "lost_toy_43",
}

for k,v in pairs(xjx_toy_types) do
	AddPrefabPostInit(v,function(inst)
		inst:DoTaskInTime(.1, function(inst)
			AddTrackingIndicator(inst,1.5,nil, 0, 0.4, 1, 1)
			MyAddChild(inst,"private_arrow_down")
			local circle = MyAddChild(inst,"private_circle") --,must_track,anim,scale)
			if circle then
				circle:SetRadius(4)
				SetCol(circle,COL_BLUE)
			end
		end)
	end)
end