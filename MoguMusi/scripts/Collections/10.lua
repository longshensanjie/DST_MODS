local gan_hunter_true = false


local player_indicators = {}

local _G = GLOBAL
local shutup = false

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

local function SetCol(inst,col)
	if col then
		inst.AnimState:SetMultColour(col[1],col[2],col[3],col[4])
	end
end

local function OnTrackRemove(inst)
	if not inst.my_children then
		return
	end
	for child,_ in pairs(inst.my_children) do
		child.my_parent = nil
		child:Remove()
	end
	inst.my_children = nil
	if inst.my_children_task then
		inst.my_children_task:Cancel()
	end
end


-- 踪迹追踪【这尼玛啥玩意】
local function TrackUpdate(inst)
	if inst.my_children_stop_update > 0 then 
		inst.my_children_stop_update = inst.my_children_stop_update - 1
		return
	end
	if not inst:IsValid() then 
		inst.my_children_task:Cancel()
		return
	end
	local x,y,z = inst.Transform:GetWorldPosition()

	local changed = true
	for k,v in pairs(inst.my_children) do
		if not k:IsValid() then 
			inst.my_children[k]=nil
		else
			local x0,y0,z0 = k.Transform:GetWorldPosition()
			if math.abs(x-x0) + math.abs(z-z0) < 0.001 then
				changed = false
				break
			else
				k.Transform:SetPosition(x,0,z) 
			end
		end
	end
	
	if changed then
		inst.my_children_no_move = -1800 
		for k,v in pairs(inst.my_children) do
			if k.condition_fn and not k.condition_fn() then 
				k.my_parent = nil
				inst.my_children[k] = nil
				k:Remove()
			end
		end
	else
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
	child.ishide = false
	if not gan_hunter_true then child:Hide() child.ishide = true end
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
			if not indicator.ishide and gan_hunter_true and (math.abs(dx) > 5 or math.abs(dy) > 5) then -- 隐藏箭头 Shang  
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
		if condition ~= nil then
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




local function CJST()
    local inst = _G.CreateEntity()
    inst:AddTag("FX")
    inst:AddTag("NOCLICK")
    inst.entity:SetCanSleep(false)
    inst.persists = false
    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    _G.MakeInventoryPhysics(inst)
    _G.RemovePhysicsColliders(inst)
    inst.AnimState:SetBank("qm_jiantou")
    inst.AnimState:SetBuild("qm_jiantou")
    inst.AnimState:PlayAnimation("ldie_1")
    inst.AnimState:SetOrientation(_G.ANIM_ORIENTATION.OnGround)
    return inst
end
------------------------------------------------------------------------打野辅助
_G.TheInput:AddKeyUpHandler(GetModConfigData("sw_jungler"), function()
	-- 关了就打开
	if not gan_hunter_true and _G.ThePlayer and InGame() then
		local x, y, z = _G.ThePlayer.Transform:GetWorldPosition()
		local ents = TheSim:FindEntities(x, y, z, 100)
		local ten_n = 0
		for k, v in pairs(ents) do
			if v.prefab == "private_circle" then v:Show() v.ishide = false end --v:Show() v.ishide = false
			
			if v.prefab == "private_arrow_down" then v:Show() v.ishide = false end
			
			if v.prefab == "tentacle" then
				ten_n = ten_n + 1

				v:DoTaskInTime(.1, function(inst)
					local ten_x, ten_y, ten_z = v.Transform:GetWorldPosition()
					local ten_ents = TheSim:FindEntities(ten_x, ten_y, ten_z, 0)

					local _private_arrow_down = false
					local _private_circle = false
					
					for i,t in pairs(ten_ents) do
						if t.prefab == "private_arrow_down" then
							_private_arrow_down = true
						end
						if t.prefab == "private_circle" then
							_private_circle = true
						end
					end
					
					if not _private_arrow_down then
						MyAddChild(v,"private_arrow_down") --,must_track,anim,scale) 
					end
					
					if not _private_circle then
						local circle = MyAddChild(v,"private_circle") --,must_track,anim,scale)
						if circle then
							local r = _G.TUNING.TENTACLE_ATTACK_DIST or 4
							circle:SetRadius(r)
							SetCol(circle,COL_RED)
						end
					end
				end)
			end
		end
		local ten_text = ten_n ~= 0 and ("，周围有 " .. ten_n .. " 只触手已显示攻击范围") or ""
		local texts = ("开启"..ten_text)
		gan_hunter_true = true
		TIP("打野辅助", "green", texts)
		local world = TheWorld.net.components.weather ~= nil and "Surface" or "Caves"
		if GetModConfigData("jungler_starfish") and (not shutup) and world == "Caves" then
			TIP("海星清远古", "green", "将为您标记远古生物位置，请在圆周上种植海星【注意是圆周不是圆内】","chat")
			shutup = true
		end
	else
		if  _G.ThePlayer then 
			local x, y, z = _G.ThePlayer.Transform:GetWorldPosition()
			local ents = TheSim:FindEntities(x, y, z, 99)
			for k, v in pairs(ents) do
				if v.prefab == "private_circle" then v:Hide() v.ishide = true end -- v.ishide = true
				if v.prefab == "private_arrow_down" then v:Hide() v.ishide = true end
			end
			
			gan_hunter_true = false
			TIP("打野辅助", "red", "关闭")
		end
	end
end)

AddPrefabPostInit("animal_track",function(inst)
	inst._jiantou = inst:DoPeriodicTask(0.5, function()
		if inst.ishide or not gan_hunter_true then return false end
		if inst and inst:IsValid() and inst.Transform then
			local sss = 2
			local jiaodu = inst.Transform:GetRotation() + 90
			local x,y,z = inst.entity:LocalToWorldSpace(0,0,-40)
			local a = _G.TheSim:FindEntities(x,0,z, 10, {"dirtpile"}, { "locomotor", "INLIMBO" })
			local sd = CJST()
			sd.Transform:SetPosition(inst.Transform:GetWorldPosition())
			sd.Transform:SetRotation(jiaodu)
			if a[1] ~= nil then
				local x1,y1,z1 = a[1].Transform:GetWorldPosition()
				sss = math.max(math.sqrt(inst:GetDistanceSqToPoint(x1,y1,z1)) / 20,0.01)
				sd:FacePoint(Point(x1,y1,z1))
			end
			sd:DoTaskInTime(sss or 2, sd.Remove)
			sd.AnimState:SetLightOverride(1)
			sd.Physics:SetMotorVel(20,0,0)
		end
	end)
end)


local EmptyFunction = function() return 1 end --we have to return a number


AddPlayersPostInitEasy = function(fn)
	for i,v in ipairs(_G.DST_CHARACTERLIST) do
		AddPrefabPostInit(v,fn)
	end
	for i,v in ipairs(_G.MODCHARACTERLIST) do
		AddPrefabPostInit(v,fn)
	end
end

AddPrefabPostInit("tentacle",function(inst)
	inst:DoTaskInTime(.1, function(inst)
		MyAddChild(inst,"private_arrow_down") --,must_track,anim,scale) 
	
		local circle = MyAddChild(inst,"private_circle") --,must_track,anim,scale)
		if circle then
			local r = _G.TUNING.TENTACLE_ATTACK_DIST or 4
			circle:SetRadius(r)
			SetCol(circle,COL_RED)
		end
	end)
end)

--[[
AddPrefabPostInit("lureplant",function(inst)
	inst:DoTaskInTime(.1, function(inst)
		local circle = MyAddChild(inst,"private_circle") --,must_track,anim,scale)
		if circle then
			circle:SetRadius(11)
		end
	end)
end)
]]

AddPrefabPostInit("wasphive",function(inst)
	inst:DoTaskInTime(.1, function(inst)
		local circle = MyAddChild(inst,"private_circle") --,must_track,anim,scale)
		if circle then
			circle:SetRadius(10)
			SetCol(circle,COL_ORANGE)
		end
	end)
end)

AddPrefabPostInit("dirtpile",function(inst)
	inst:DoTaskInTime(.1, function(inst)
		local circle = MyAddChild(inst,"private_circle") --,must_track,anim,scale)
		if circle then
			circle:SetRadius(5)
			SetCol(circle,COL_BLACK)
		end
	end)
end)

local BossLists = { -- prefab, ATTACK RANGE, ATTACK colour, TARGET RANGE, TARGE colour 
	{prefab = "deerclops",       	attackrange = 8,                                 attackcolour = COL_WHITE,       targetrange = nil,                                 targetcolour = nil},        --独眼巨鹿
	{prefab = "bearger",         	attackrange = 7,                                 attackcolour = COL_BROWN,       targetrange = nil,                                 targetcolour = nil},        --熊大
	{prefab = "dragonfly",       	attackrange = 6,                                 attackcolour = COL_RED,         targetrange = 14,                                  targetcolour = COL_YELLOW}, --龙蝇
	{prefab = "moose",           	attackrange = 6,                                 attackcolour = COL_SPRINGGREEN, targetrange = nil,                                 targetcolour = nil},        --麋鹿鹅
	{prefab = "beequeen",        	attackrange = _G.TUNING.BEEQUEEN_HIT_RANGE,      attackcolour = COL_RED,         targetrange = _G.TUNING.BEEQUEEN_EPICSCARE_RANGE,  targetcolour = COL_ORANGE}, --蜂后
	{prefab = "minotaur",        	attackrange = 4,                                 attackcolour = COL_RED,         targetrange = nil,                                 targetcolour = COL_YELLOW}, --远古守卫者 _G.TUNING.MINOTAUR_TARGET_DIST
	{prefab = "toadstool",       	attackrange = _G.TUNING.TOADSTOOL_ATTACK_RANGE,  attackcolour = COL_GREEN,       targetrange = _G.TUNING.TOADSTOOL_EPICSCARE_RANGE, targetcolour = COL_YELLOW}, --蟾蜍
	{prefab = "toadstool_dark",  	attackrange = _G.TUNING.TOADSTOOL_ATTACK_RANGE,  attackcolour = COL_GREEN,       targetrange = _G.TUNING.TOADSTOOL_EPICSCARE_RANGE, targetcolour = COL_YELLOW}, --毒菌蟾蜍
	{prefab = "mushroombomb",    	attackrange = _G.TUNING.TOADSTOOL_MUSHROOMBOMB_RADIUS,  attackcolour = COL_RED,  targetrange = nil,                                 targetcolour = nil},        --炸弹
	{prefab = "mushroombomb_dark",	attackrange = _G.TUNING.TOADSTOOL_MUSHROOMBOMB_RADIUS,  attackcolour = COL_RED,  targetrange = nil,                                 targetcolour = nil},        --毒菌炸弹
	{prefab = "spat",            	attackrange = _G.TUNING.SPAT_PHLEGM_ATTACKRANGE, attackcolour = COL_PINK,        targetrange = _G.TUNING.SPAT_TARGET_DIST,          targetcolour = COL_YELLOW}, --钢羊 --鼻涕爆炸范围 _G.TUNING.SPAT_PHLEGM_RADIUS
	{prefab = "warg",            	attackrange = _G.TUNING.WARG_ATTACKRANGE,        attackcolour = COL_RED,         targetrange = _G.TUNING.WARG_TARGETRANGE,          targetcolour = COL_YELLOW}, --座狼
	{prefab = "claywarg",        	attackrange = _G.TUNING.WARG_ATTACKRANGE,        attackcolour = COL_RED,         targetrange = _G.TUNING.WARG_TARGETRANGE,          targetcolour = COL_YELLOW}, --黏土狼
	{prefab = "gingerbreadwarg", 	attackrange = _G.TUNING.WARG_ATTACKRANGE,        attackcolour = COL_RED,         targetrange = _G.TUNING.WARG_TARGETRANGE,          targetcolour = COL_YELLOW}, --姜饼狼
	{prefab = "worm",            	attackrange = _G.TUNING.WORM_ATTACK_DIST,        attackcolour = COL_RED,         targetrange = nil,                                 targetcolour = COL_YELLOW}, --深渊蠕虫 _G.TUNING.WORM_TARGET_DIST
	{prefab = "tallbird",        	attackrange = _G.TUNING.TALLBIRD_ATTACK_RANGE,   attackcolour = COL_RED,         targetrange = _G.TUNING.TALLBIRD_TARGET_DIST,      targetcolour = COL_BLACK}, --高脚鸟
	{prefab = "spiderqueen",     	attackrange = _G.TUNING.SPIDERQUEEN_ATTACKRANGE, attackcolour = COL_RED,         targetrange = 10,                                  targetcolour = COL_YELLOW}, --蜘蛛女王
	{prefab = "walrus",          	attackrange = _G.TUNING.WALRUS_ATTACK_DIST,      attackcolour = COL_PINK,        targetrange = _G.TUNING.WALRUS_TARGET_DIST,        targetcolour = COL_YELLOW}, --海象
	{prefab = "malbatross",         attackrange = _G.TUNING.MALBATROSS_AOE_RANGE,    attackcolour = COL_PINK,        targetrange = _G.TUNING.MALBATROSS_ATTACK_RANGE,   targetcolour = COL_BLUE}, --邪天翁
	{prefab = "klaus",         		attackrange = _G.TUNING.KLAUS_AGGRO_DIST,    	 attackcolour = COL_RED,         targetrange = _G.TUNING.KLAUS_HIT_RANGE, 			targetcolour = COL_GREEN}, --克劳斯
	{prefab = "klaus",         		attackrange = _G.TUNING.KLAUS_CHOMP_RANGE,    	 attackcolour = COL_ORANGE, 	 targetrange = nil,                                 targetcolour = nil}, --克劳斯
	{prefab = "crabking",         	attackrange = 7.5,    	 						 attackcolour = COL_WHITE, 	 	 targetrange = nil,      targetcolour = nil}, --一珍八紫帝王蟹
	{prefab = "stalker_atrium",     attackrange = _G.TUNING.STALKER_HIT_RANGE,    attackcolour = COL_GREEN,       	 targetrange = nil, 	 targetcolour = nil}, --编织者
	{prefab = "hound",     			attackrange = 3,    attackcolour = COL_RED,    targetrange = nil, 	 targetcolour = nil}, --猎犬
	{prefab = "icehound",     		attackrange = 3,    attackcolour = COL_RED,    targetrange = nil, 	 targetcolour = nil}, --猎犬
	{prefab = "firehound",     		attackrange = 3,    attackcolour = COL_RED,    targetrange = nil, 	 targetcolour = nil}, --猎犬
	{prefab = "bishop",     		attackrange = _G.TUNING.BISHOP_TARGET_DIST,    attackcolour = COL_RED,    targetrange = nil, 	 targetcolour = nil}, --主教
	{prefab = "rook",     			attackrange = _G.TUNING.ROOK_TARGET_DIST,    attackcolour = COL_RED,    targetrange = nil, 	 targetcolour = nil}, --战车
	{prefab = "knight",     		attackrange = _G.TUNING.KNIGHT_TARGET_DIST,    attackcolour = COL_RED,    targetrange = 3, 	 targetcolour = COL_BLUE}, --骑士
	{prefab = "bishop_nightmare",     		attackrange = _G.TUNING.BISHOP_TARGET_DIST,    attackcolour = COL_BLUE,    targetrange = nil, 	 targetcolour = nil}, --主教
	{prefab = "rook_nightmare",     		attackrange = _G.TUNING.ROOK_TARGET_DIST,    attackcolour = COL_BLUE,    targetrange = nil, 	 targetcolour = nil}, --战车
	{prefab = "knight_nightmare",     		attackrange = _G.TUNING.KNIGHT_TARGET_DIST,    attackcolour = COL_BLUE,    targetrange = 3, 	 targetcolour = COL_RED}, --骑士
	{prefab = "alterguardian_phase1",     	attackrange = _G.TUNING.ALTERGUARDIAN_PHASE1_AOERANGE,    attackcolour = COL_RED,    targetrange = nil, 	 targetcolour = nil}, --天体英雄第一阶段
	{prefab = "alterguardian_phase2",     	attackrange = _G.TUNING.ALTERGUARDIAN_PHASE2_CHOP_RANGE,    attackcolour = COL_RED,    targetrange =  _G.TUNING.ALTERGUARDIAN_PHASE2_SPIKE_RANGE, 	 targetcolour = COL_WHITE}, --天体英雄第二阶段
	{prefab = "alterguardian_phase3",     	attackrange = 18,    attackcolour = COL_BLUE,    targetrange =  _G.TUNING.ALTERGUARDIAN_PHASE3_STAB_RANGE, 	 targetcolour = COL_RED}, --天体英雄第三阶段
	
	
}



for k, v in ipairs(BossLists) do
	if v and v.attackrange ~= nil then
		AddPrefabPostInit(v.prefab,function(inst)
			inst:DoTaskInTime(.1, function(inst)
				local circle = MyAddChild(inst,"private_circle",true) 
				if circle then circle:SetRadius(v.attackrange) SetCol(circle, v.attackcolour) end
			end)
		end)
	end
	if v and v.targetrange ~= nil then
		AddPrefabPostInit(v.prefab,function(inst)
			inst:DoTaskInTime(.1, function(inst)
				local circle = MyAddChild(inst,"private_circle",true)
				if circle then circle:SetRadius(v.targetrange) SetCol(circle, v.targetcolour) end
			end)
		end)
	end
end

local BOSS_klaus = {
	{"hit_range",        COL_GREEN },  -- 命中半径
	{"chomp_range",      COL_ORANGE }, -- 跳杀半径
}
local function GetKlausRange(inst,k)
	local Ranges = {
		inst.hit_range,
		inst.chomp_range,
	}
	return Ranges[k]
end

for k, v in ipairs(BOSS_klaus) do
	AddPrefabPostInit("klaus",function(inst)
		inst:DoTaskInTime(1,function(inst)
			local Range = GetKlausRange(inst,k)
			local circle = MyAddChild(inst,"private_circle",true) 
			if circle then circle:SetRadius(Range) SetCol(circle, v[2]) end
		end)
	end)
end

local Tcircle = MyAddChild(_G.ThePlayer,"private_circle",true)
if Tcircle then Tcircle:SetRadius(60) SetCol(Tcircle,COL_SPRINGGREEN) end





--must_track=true


AddPrefabPostInit("world",function(inst) 
	inst:DoPeriodicTask(0.2+0.01*math.random(),function(inst)
		UpdatePlayerIndicators()
	end)
end)

AddPrefabPostInit("gears",function(inst)
	AddTrackingIndicator(inst,1.5) --,nil, 0, 0.4, 1, 1)
end)
AddPrefabPostInit("greengem",function(inst)
	AddTrackingIndicator(inst,1.5) --,nil, 0, 0.4, 1, 1)
end)
AddPrefabPostInit("yellowgem",function(inst)
	AddTrackingIndicator(inst,1.5) --,nil, 0, 0.4, 1, 1)
end)

AddPrefabPostInit("moonstorm_spark",function(inst)
	AddTrackingIndicator(inst,1.5) --,nil, 0, 0.4, 1, 1)
end)
-- 海难漂流瓶
AddPrefabPostInit("ia_messagebottle",function(inst)
	AddTrackingIndicator(inst,1.5) --,nil, 0, 0.4, 1, 1)
end)
-- 海难智慧树
AddPrefabPostInit("coral_brain_rock",function(inst)
	AddTrackingIndicator(inst,1.5) --,nil, 0, 0.4, 1, 1)
end)
-- 白色气泡
AddPrefabPostInit("whale_bubbles",function(inst)
	AddTrackingIndicator(inst,1.5) --,nil, 0, 0.4, 1, 1)
end)
-- 金币
AddPrefabPostInit("dubloon",function(inst)
	AddTrackingIndicator(inst,1.5) --,nil, 0, 0.4, 1, 1)
end)


local function AddBossIndicator(inst)
	AddTrackingIndicator(inst,2.8)
    -- print('Found Boss:',inst.prefab and inst.prefab:upper()) 
end
--boss部分
AddPrefabPostInit("deerclops",AddBossIndicator)
AddPrefabPostInit("dragonfly",AddBossIndicator)
AddPrefabPostInit("bearger",AddBossIndicator)
AddPrefabPostInit("minotaur",AddBossIndicator)
AddPrefabPostInit("toadstool",AddBossIndicator)
AddPrefabPostInit("beequeen",AddBossIndicator)
AddPrefabPostInit("klaus",AddBossIndicator)
AddPrefabPostInit("stalker",AddBossIndicator)
AddPrefabPostInit("antlion",AddBossIndicator)
AddPrefabPostInit("moose",AddBossIndicator)
AddPrefabPostInit("warg",AddBossIndicator)
AddPrefabPostInit("malbatross",AddBossIndicator) --邪天翁
AddPrefabPostInit("klaus_sack",AddBossIndicator) --克劳斯袋
AddPrefabPostInit("alterguardian_phase1",AddBossIndicator) --天体英雄
AddPrefabPostInit("alterguardian_phase2",AddBossIndicator) --天体英雄
AddPrefabPostInit("alterguardian_phase3",AddBossIndicator) --天体英雄



local function sf_start(inst)
	-- local ents = TheSim:FindEntities(x, y, z, 0)
	local jiantou = _G.SpawnPrefab("private_arrow_down")
	local yuan1 = _G.SpawnPrefab("private_circle")
	local yuan2 = _G.SpawnPrefab("private_circle")
	local centor = _G.SpawnPrefab("private_circle")
	inst:DoTaskInTime(0,function(inst)
		local x, y, z = inst.Transform:GetWorldPosition()
		jiantou.Transform:SetPosition(x, 0, z)

		yuan1.Transform:SetPosition(x, 0, z)
		yuan1.Transform:SetRotation(8)
		yuan1:SetRadius(666)
		SetCol(yuan1, COL_YELLOW)

		yuan2.Transform:SetPosition(x, 0, z)
		yuan2.Transform:SetRotation(0)
		yuan2:SetRadius(666)
		SetCol(yuan2, COL_YELLOW)

		centor.Transform:SetPosition(x, 0, z)
		centor:SetRadius(777)
		SetCol(centor, COL_WHITE)
	end)
	if not gan_hunter_true then
		jiantou:Hide()
		yuan1:Hide()
		yuan2:Hide()
		centor:Hide()
	end
end

if GetModConfigData("sw_jungler") and GetModConfigData("jungler_starfish") then
	AddPrefabPostInit("bishop_nightmare", sf_start)
	AddPrefabPostInit("rook_nightmare", sf_start)
	AddPrefabPostInit("knight_nightmare", sf_start)
	AddPrefabPostInit("minotaur", sf_start)
	AddPrefabPostInit("antlion", sf_start)
end