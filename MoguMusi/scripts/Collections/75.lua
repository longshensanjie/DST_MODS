-- 这个文件是全局可以调用的函数和私货
local function RGB(r, g, b)
    return {r / 255, g / 255, b / 255, 1}
end

COLORS = {
    WHITE = RGB(255, 255, 255),
    BLACK = RGB(0, 0, 0),
    RED = RGB(207, 61, 61),
    PINK = RGB(255, 192, 203),
    YELLOW = RGB(255, 255, 0),
    BLUE = RGB(0, 0, 255),
    GREEN = RGB(59, 222, 99),
    PURPLE = RGB(184, 87, 198),
    BROWN = RGB(127, 76, 51)
}
function InGame()
    return GLOBAL.ThePlayer and GLOBAL.ThePlayer.HUD and not GLOBAL.ThePlayer.HUD:HasInputFocus()
    -- 允许打开制作栏时使用功能，输入的时候不让使用就行了
    --  and not GLOBAL.ThePlayer.HUD:IsCraftingOpen()
end

function Say(str)
    local talker = GLOBAL.ThePlayer.components.talker
    if talker then
        talker:Say(str)
    end
end

function TIP(stat, color, content, way)
    if GLOBAL.GetTimePlaying() < 5 then return end
    if type(stat) == "string" and not color and not content and not way then
        GLOBAL.ChatHistory:AddToHistory(GLOBAL.ChatTypes.Message, nil, nil, "Message", stat, COLORS.GREEN)
        return
    end
    local loca = GetModConfigData("sw_tip")
    local tcolor = color and COLORS[string.upper(color)] or COLORS.WHITE
    if way then
        loca = way
    end
    if type(content) == "boolean" and content then
        content = "开启"
    end
    if type(content) == "boolean" and not content then
        content = "关闭"
    end

    if InGame() and GLOBAL.ThePlayer.components.talker then
        if loca == "announce" then
            GLOBAL.TheNet:Say(stat .. "：" .. content)
        elseif loca == "head" then
            GLOBAL.ThePlayer.components.talker:Say(stat .. "：" .. content, nil, nil, nil, nil, tcolor)
        elseif loca == "chat" then
            GLOBAL.ChatHistory:AddToHistory(GLOBAL.ChatTypes.Message, nil, nil, stat, content, tcolor)
        else
            GLOBAL.ThePlayer.components.talker:Say(stat .. "：" .. content, nil, nil, nil, nil, tcolor)
        end
    end
end

-- 这两表存数据呢
MUSHROOM_ban_list = {}
MUSHROOM_con_mod_list = {}

-- 返回value集合但什么都不查
function mergeTable(...)
    local mTable = {}
    for _, v in pairs({...}) do
        if type(v) == "table" then
            for _, k in pairs(v) do
                table.insert(mTable, k)
            end
        end
    end
    return mTable
end

-- 获取装备物品
function GetEquippedItemFrom(slot)
    return GLOBAL.ThePlayer and GLOBAL.ThePlayer.replica.inventory:GetEquippedItem(slot)
end
-- 获取容器内的物品
function GetItemsFromOpenContainer()
    local items = {}
    if not GLOBAL.ThePlayer or not GLOBAL.ThePlayer.replica.inventory then
        return items
    end
    for container, v in pairs(GLOBAL.ThePlayer.replica.inventory:GetOpenContainers()) do
        if container and container.replica and container.replica.container then
            local items_container = container.replica.container:GetItems()
            items = mergeTable(items, items_container)
        end
    end
    return items
end
-- 获取所有物品（未指定prefab则获取全部）
function GetItemsFromAll(prefab)
    local items = {}
    local initems = GLOBAL.ThePlayer and GLOBAL.ThePlayer.replica.inventory:GetItems() or {}
    local equipitems = GLOBAL.ThePlayer and GLOBAL.ThePlayer.replica.inventory:GetEquips() or {}
    local containeritems = GetItemsFromOpenContainer() or {}
    for _, v in pairs(mergeTable(equipitems, initems, containeritems)) do
        if (v and v.prefab == prefab) or (prefab == nil) then
            table.insert(items, v)
        end
    end
    return items
end
-- 获取所有容器的单个物品
function GetItemFromAll(prefab, tag)
    local prefabs = GetItemsFromAll(prefab)
    for _, v in pairs(prefabs) do
        if tag and v:HasTag(tag) then
            return v
        end
        if not tag then
            return v
        end
    end
end

-- 发送RPC
-- 燃料A加到B
function SendRPCAtoB(rpc, action, A, B)
    local buffact = BufferedAction(ThePlayer, B, action, A)
    if not TheWorld.ismastersim then
        local function cb()
            SendRPCToServer(rpc, action.code, B, A, action.mod_name)
        end
        if ThePlayer.components.locomotor then
            buffact.preview_cb = cb
        else
            cb()
        end
    end
    ThePlayer.components.playercontroller:DoAction(buffact)
end

-- 用A召唤收回B
-- 右键单击T
function SendRPCAwithB(rpc, action, A, B)
    local buffact = GLOBAL.BufferedAction(GLOBAL.ThePlayer, B, action, A)
    if not GLOBAL.TheWorld.ismastersim then
        local function cb()
            GLOBAL.SendRPCToServer(rpc, action.code, A, B, action.mod_name)
        end
        if GLOBAL.ThePlayer.components.locomotor then
            buffact.preview_cb = cb
        else
            cb()
        end
    end
    GLOBAL.ThePlayer.components.playercontroller:DoAction(buffact)
end

-- 左键点击某个位置
function SendRPCclk(rpc, action, position)
    local buffact = BufferedAction(ThePlayer, nil, action, nil, position)
    if not TheWorld.ismastersim then
        local function cb()
            SendRPCToServer(rpc, action.code, position.x, position.z, nil, false, 0, true)
        end
        if ThePlayer.components.locomotor then
            buffact.preview_cb = cb
        else
            cb()
        end
    end
    ThePlayer.components.playercontroller:DoAction(buffact)
end

-- 模组检测器 item是否在str里
function str_contains(str, item)
    local t = {}
    local l = {}
    local index = 0
    for i = 1, string.len(str) do
        table.insert(t, string.byte(string.sub(str, i, i)))
    end

    for i = 1, string.len(item) do
        table.insert(l, string.byte(string.sub(item, i, i)))
    end
    if #l > #t then
        return false
    end

    for k, v1 in pairs(t) do
        index = index + 1
        if v1 == l[1] then
            local iscontens = true
            for i = 1, #l do
                if t[index + i - 1] ~= l[i] then
                    iscontens = false
                end
            end
            if iscontens then
                return iscontens
            end
        end
    end
    return false
end

local modsnametable = {}
local allMods = GLOBAL.KnownModIndex:GetModsToLoad()
for k, v in pairs(allMods) do
    local themod = GLOBAL.KnownModIndex:GetModInfo(v)
    if themod and themod.name then
        table.insert(modsnametable, themod.name)
    end
end

function HasModName(modname)
    -- 服务器包含此模组时返回 服务器重复的模组名
    -- 不包含时返回false
    if not GetModConfigData("sw_debugger") then
        return false
    end
    local mods = allMods
    local A, _ = string.gsub(string.upper(modname), "%s+", "")
    for key, name in pairs(modsnametable) do
        if name then
            local B, _ = string.gsub(string.upper(name), "%s+", "")
            if str_contains(B, A) then
                return name
            end
        end
    end
    return false
end

function IsInMODlist(modlist)
    if type(modlist) ~= "table" then
        return HasModName(modlist)
    end
    for _, modname in pairs(modlist) do
        if HasModName(modname) then
            return true
        end
    end
    return false
end

function c_anim(anims, ent)
    if not ent then
        return
    end
    if type(anims) == "table" then
        for _,anim in pairs(anims)do
            if ent.AnimState:IsCurrentAnimation(anim) then
                return true
            end
        end
        return false
    else
        return ent.AnimState:IsCurrentAnimation(anims)
    end
end

function PlayerFindEnts(range, allowTags, banTags)
    local pos = GLOBAL.ThePlayer:GetPosition()
    return GLOBAL.TheSim:FindEntities(pos.x, 0, pos.z, range, allowTags, banTags)
end


function PlayerFindEnt(name, range, allowTags, banTags, allowAnims, banAnims)
    if not range then
        range = 80
    end
    if type(allowTags) ~= "table" then
        allowTags = nil
    end
    if type(banTags) ~= "table" then
        banTags = {'FX','DECOR','INLIMBO','NOCLICK'}
    end
    if type(banAnims) == nil then
        banAnims = {"death"}
    end

    local neardist = 6400
    local player_pos = GLOBAL.ThePlayer:GetPosition()
    local all_ents = GLOBAL.TheSim:FindEntities(player_pos.x, 0, player_pos.z, range, allowTags, banTags)
    local nearent
    for _,ent in pairs(all_ents)do
        if (type(name) == "table" and table.contains(name, ent.prefab)) or name == ent.prefab
        and ((allowAnims and c_anim(allowAnims, ent)) or (not allowAnims))
        and (banAnims and not c_anim(banAnims, ent))
        then
            local dist = ent:GetPosition():DistSq(player_pos)
            if dist and dist < neardist then
                neardist = dist
                nearent = ent
            end
        end
    end
    return nearent
end


local function nearEye()
    -- 返回最近的boss
    local mypos = GLOBAL.Vector3(GLOBAL.ThePlayer.Transform:GetWorldPosition())
    local eyes = PlayerFindEnts(40, {"epic"}, nil)
    local neareye
    local neardist = 1000
    for _,eyeboss in pairs(eyes)do
        if table.contains(bigeye, eyeboss.prefab) and eyeboss.Transform then
            local epos = GLOBAL.Vector3(eyeboss.Transform:GetWorldPosition())
            if epos:Dist(mypos) < neardist then
                neardist = epos:Dist(mypos)
                neareye = eyeboss
            end
        end
    end
    return neareye
end

-- 面板功能绑定
function AddBindBtn(bnd, fn)
    local bind = GetModConfigData(bnd)
    if type(bind) == "number" then
        GLOBAL.TheInput:AddKeyUpHandler(bind, function ()
            if InGame() then fn() end
        end)
    end
end

--- 调试用
function fep(Ttable)
    if type(Ttable) ~= "table" then
        print("NOT: table 丨 TYPE:",type(Ttable))
        if type(Ttable) == "string" or type(Ttable) == "number" or type(Ttable) == "boolean" then
            print("The Value:", Ttable)
        end
    else          
        for k, v in pairs(Ttable) do
            print(k, v)
        end
    end
end
function fepp(Ttable)
    print("********************欢迎帮助fepp开发***************************")
    fep(Ttable)
    print("********************fepp结束*********************")
end
local testid = 0
function GLOBAL.FEP(Ttable)
    print("********************欢迎帮助FEP开发***************************")
    fep(Ttable)
    print("********************FEP", testid ,"结束*********************")
    testid = testid + 1
end
function GLOBAL.LATELY(time, func)
    print("一个任务将会在",time,"后执行")
    GLOBAL.ThePlayer:DoTaskInTime(time, func)
end

--- 响应左键右键，提取自管理员面板
-- custom left n right click button handler, based/copied from imagebutton oncontrol
function LROnControl(button, control, down)
	if not button:IsEnabled() or not button.focus or GLOBAL.TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) then return end
	if button:IsSelected() and not button.AllowOnControlWhenSelected then return false end
	local click = control == button.control and 1 or (control == GLOBAL.CONTROL_SECONDARY or control == GLOBAL.CONTROL_CONTROLLER_ALTACTION) and 2 or 0
	if click == 0 then return end
	if down and not button.down then
		if button.has_image_down then
			button.image:SetTexture(button.atlas, button.image_down)
			if button.size_x and button.size_y then 
				button.image:ScaleToSize(button.size_x, button.size_y)
			end
		end
		GLOBAL.TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
		button.o_pos = button:GetLocalPosition()
		if button.move_on_click then
			button:SetPosition(button.o_pos + button.clickoffset)
		end
		button.down = true
		-- to store which button made it down
		button.left = click == 1
		if button.whiledown then
			button:StartUpdating()
		end
		if button.ondown then
			button.ondown()
		end
	-- make sure button released is one that made it down
	elseif not down and button.down and button.left == (click == 1) then
		if button.has_image_down then
			button.image:SetTexture(button.atlas, button.image_focus)
			if button.size_x and button.size_y then 
				button.image:ScaleToSize(button.size_x, button.size_y)
			end
		end
		button.down = false
		button.left = nil
		button:ResetPreClickPosition()
		if button.onclick then
			button.onclick(click == 1)
		end
		button:StopUpdating()
	end
	return true
end

--- https://tomoya92.github.io/dstmod-tutorial/#/sample-addcontainer ---
-- 鼠标跟随
local function ModFollowMouse(self)
    --GetWorldPosition获得的坐标是基于屏幕原点的，默认为左下角，当单独设置了原点的时候，这个函数返回的结果和GetPosition的结果一样了，达不到我们需要的效果
    --因为官方没有提供查询原点坐标的接口，所以需要修改设置原点的两个函数，将原点位置记录在widget上
    --注意：虽然默认的屏幕原点为左下角，但是每个widget默认的坐标原点为其父级的屏幕坐标；
        --而当你单独设置了原点坐标后，不仅其屏幕原点改变了，而且坐标原点的位置也改变为屏幕原点了
    local old_sva = self.SetVAnchor
    self.SetVAnchor = function (_self, anchor, ...)
        self.v_anchor = anchor
        return old_sva(_self, anchor, ...)
    end

    local old_sha = self.SetHAnchor
    self.SetHAnchor = function (_self, anchor, ...)
        self.h_anchor = anchor
        return old_sha(_self, anchor, ...)
    end

    --默认的原点坐标为父级的坐标，如果widget上有v_anchor和h_anchor这两个变量，就说明改变了默认的原点坐标
    --我们会在GetMouseLocalPos函数里检查这两个变量，以对这种情况做专门的处理
    --这个函数可以将鼠标坐标从屏幕坐标系下转换到和wiget同一个坐标系下
    local function GetMouseLocalPos(ui, mouse_pos)        --ui: 要拖拽的widget, mouse_pos: 鼠标的屏幕坐标(Vector3对象)
        local g_s = ui:GetScale()                    --ui的全局缩放值
        local l_s = GLOBAL.Vector3(0,0,0)
        l_s.x, l_s.y, l_s.z = ui:GetLooseScale()    --ui本身的缩放值
        local scale = GLOBAL.Vector3(g_s.x/l_s.x, g_s.y/l_s.y, g_s.z/l_s.z)    --父级的全局缩放值

        local ui_local_pos = ui:GetPosition()        --ui的相对位置（也就是SetPosition的时候传递的坐标）
        ui_local_pos = GLOBAL.Vector3(ui_local_pos.x * scale.x, ui_local_pos.y * scale.y, ui_local_pos.z * scale.z)
        local ui_world_pos = ui:GetWorldPosition()
        --如果修改过ui的屏幕原点，就重新计算ui的屏幕坐标（基于左下角为原点的）
        if not (not ui.v_anchor or ui.v_anchor == ANCHOR_BOTTOM) or not (not ui.h_anchor or ui.h_anchor == ANCHOR_LEFT) then
            local screen_w, screen_h = GLOBAL.TheSim:GetScreenSize()        --获取屏幕尺寸（宽度，高度）
            if ui.v_anchor and ui.v_anchor ~= ANCHOR_BOTTOM then    --如果修改了原点的垂直坐标
                ui_world_pos.y = ui.v_anchor == ANCHOR_MIDDLE and screen_h/2 + ui_world_pos.y or screen_h - ui_world_pos.y
            end
            if ui.h_anchor and ui.h_anchor ~= ANCHOR_LEFT then        --如果修改了原点的水平坐标
                ui_world_pos.x = ui.h_anchor == ANCHOR_MIDDLE and screen_w/2 + ui_world_pos.x or screen_w - ui_world_pos.x
            end
        end

        local origin_point = ui_world_pos - ui_local_pos    --原点坐标
        mouse_pos = mouse_pos - origin_point

        return GLOBAL.Vector3(mouse_pos.x/ scale.x, mouse_pos.y/ scale.y, mouse_pos.z/ scale.z)    --鼠标相对于UI父级坐标的局部坐标
    end

    --修改官方的鼠标跟随，以适应所有情况
    local old_follow = self.FollowMouse
    self.StartFollowMouse = function(_self, ...)
        if _self.followhandler == nil then
            _self.followhandler = GLOBAL.TheInput:AddMoveHandler(function(x, y)
                local loc_pos = GetMouseLocalPos(_self, GLOBAL.Vector3(x, y, 0))    --主要是将原本的x,y坐标进行了坐标系的转换，使用转换后的坐标来更新widget位置
                _self:UpdatePosition(loc_pos.x, loc_pos.y)
            end)
            _self:SetPosition(GetMouseLocalPos(_self, GLOBAL.TheInput:GetScreenPosition()))
        end
        return old_follow(_self, ...)
    end
end

-- 奇怪的崩溃
if GetModConfigData("sw_debugger") ~= "shutup" then
    AddClassPostConstruct("widgets/widget", ModFollowMouse)
end


--- copy Tony --
function is_entity(t)
    return t and t.is_a and t:is_a(GLOBAL.EntityScript)
end
-- 获取物品
function GetItemSlot(item)
    if not GLOBAL.ThePlayer and GLOBAL.ThePlayer.replica.inventory then
        return
    end
    for container, v in pairs(GLOBAL.ThePlayer.replica.inventory:GetOpenContainers()) do
        if container and container.replica and container.replica.container and container:HasTag("backpack") then
            local items_container = container.replica.container:GetItems()
            for k, v in pairs(items_container) do
                if v.prefab == item then
                    return container.replica.container, k
                end
            end
        end
    end
    for k, v in pairs(GLOBAL.ThePlayer.replica.inventory:GetItems()) do
        if v.prefab == item then
            return GLOBAL.ThePlayer.replica.inventory, k
        end
    end
end
-- 返回基点
function returnBases()
    if not GLOBAL.ThePlayer then
        return
    end
    local x, _, z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
    local bases = {}
    for _, ent in ipairs(GLOBAL.TheSim:FindEntities(x, 0, z, 40)) do
        if ent.prefab == "archive_resonator_base" or -- 兼容能力勋章
        ent.prefab == "medal_resonator_base" then
            local alive_time = ent:GetTimeAlive()
            local index = #bases + 1
            for i, v in ipairs(bases) do
                if alive_time < v:GetTimeAlive() then
                    index = i
                    break
                end
            end
            table.insert(bases, index, ent)
        end
    end
    return bases
end
-- 移动打断
function InterruptedByMobile(get_thread, stop_thread)
    local interrupt_controls = {}
    for control = GLOBAL.CONTROL_ATTACK, GLOBAL.CONTROL_MOVE_RIGHT do
        interrupt_controls[control] = true
    end
    
    AddComponentPostInit("playercontroller", function(self, inst)
        if inst ~= GLOBAL.ThePlayer then return end
        
        inst:ListenForEvent("aqp_threadstart", function(inst) stop_thread() end)
    
        local mouse_controls = {[GLOBAL.CONTROL_PRIMARY] = true, [GLOBAL.CONTROL_SECONDARY] = true}
        
        local PlayerControllerOnControl = self.OnControl
        self.OnControl = function(self, control, down)
            local mouse_control = mouse_controls[control]
            local interrupt_control = interrupt_controls[control]
            if InGame() and (interrupt_control or mouse_control and not GLOBAL.TheInput:GetHUDEntityUnderMouse()) then
                if down and get_thread() then
                    stop_thread()
                end
            end
            PlayerControllerOnControl(self, control, down)
        end
    end)
end
-- 右键操作身上的（过时, 推荐用下面的UseItemOnSelf）
function UseItemSelf(item, action_code)
    -- action_code : like ACTIONS.MURDER.code
    if not item then return end
    local inventory = GLOBAL.ThePlayer.components.inventory
    local playercontroller = GLOBAL.ThePlayer.components.playercontroller
    if inventory then
        local playercontroller_deploy_mode = playercontroller.deploy_mode
        playercontroller:ClearControlMods()
        playercontroller.deploy_mode = false
        inventory:ControllerUseItemOnSelfFromInvTile(item, action_code)
        playercontroller.deploy_mode = playercontroller_deploy_mode
    else
        GLOBAL.SendRPCToServer(GLOBAL.RPC.ControllerUseItemOnSelfFromInvTile, action_code, item)
    end
end
-- 按下Shift
function IsScrollModifierDown()
    return GLOBAL.TheInput:IsKeyDown(rawget(GLOBAL, "KEY_SHIFT"))
end
-- 判断双击间隔
function InDoubleClickTime(cur, last)
    return cur - last < 0.3
end
-- 右键操作视野中的
function UseItemOnScene(item, act)
    local inventory = GLOBAL.ThePlayer.components.inventory
    if inventory then
        inventory:ControllerUseItemOnSceneFromInvTile(item, act.target, act.action.code, act.action.mod_name)
    else
        GLOBAL.ThePlayer.components.playercontroller:RemoteControllerUseItemOnSceneFromInvTile(act, item)
    end
end
-- 右键操作身上的
function UseItemOnSelf(item)
    local playercontroller = GLOBAL.ThePlayer.components.playercontroller
    local playercontroller_deploy_mode = playercontroller.deploy_mode
    playercontroller.deploy_mode = false
    GLOBAL.ThePlayer.replica.inventory:ControllerUseItemOnSelfFromInvTile(item)
    playercontroller.deploy_mode = playercontroller_deploy_mode
end
-- 是否是有效容器
function IsValidContainer(container, cur_items)
    if not (container and container:IsOpenedBy(GLOBAL.ThePlayer)) then return end
    if not container:IsFull() then return true end
    if container:AcceptsStacks() then
        if is_entity(cur_items) then
            cur_items = { cur_items }
        end
        for _, v in pairs(container:GetItems()) do
            for _, cur_item in ipairs(cur_items) do
                if not is_entity(cur_item) then
                    cur_item = cur_item.item
                end
                if v.prefab == cur_item.prefab and v.AnimState:GetSkinBuild() == cur_item.AnimState:GetSkinBuild() then
                    if v.replica.stackable ~= nil and not v.replica.stackable:IsFull() then
                        return true
                    end
                end
            end
        end
    end
end
-- 执行act若关延迟执行fn
function SendActionAndFn(act, fn)
    local playercontroller = GLOBAL.ThePlayer.components.playercontroller
    if playercontroller.ismastersim then
        GLOBAL.ThePlayer.components.combat:SetTarget(nil)
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

-- local function SendAction(act)
--     local x, _, z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
--     SendActionAndFn(act, function()
--         GLOBAL.SendRPCToServer(GLOBAL.RPC.LeftClick, act.action.code, x, z, act.target, true)
--     end)
-- end

-- local STEERINGWHEEL_MUSTTAGS = {"steeringwheel"}
-- local STEERINGWHEEL_CANTTAGS = {"INLIMBO", "burnt", "occupied", "fire"}
-- local function SteerBoat()
--     local target = GLOBAL.FindEntity(GLOBAL.ThePlayer, 5, nil, STEERINGWHEEL_MUSTTAGS, STEERINGWHEEL_CANTTAGS)
--     if target then
--         if GLOBAL.ThePlayer:HasTag("steeringboat") then
--             SendAction(GLOBAL.BufferedAction(GLOBAL.ThePlayer, nil, GLOBAL.ACTIONS.STOP_STEERING_BOAT))
--         else
--             SendAction(GLOBAL.BufferedAction(GLOBAL.ThePlayer, target, GLOBAL.ACTIONS.STEER_BOAT))
--         end
--     else
--         TIP("快速用舵","red","附近没有需要操作的船舵")
--     end
-- end
-- 尝试制作某个物品
function TryCraft(inst)
    for recname, rec in pairs(GLOBAL.AllRecipes) do
        if GLOBAL.IsRecipeValid(recname)
            and rec.placer == nil
            and rec.sg_state == nil
            and inst.replica.builder:KnowsRecipe(recname)
            and inst.replica.builder:CanBuild(recname) then

            if inst.components.builder then
                inst.components.builder:MakeRecipeFromMenu(rec)
            else
                GLOBAL.SendRPCToServer(GLOBAL.RPC.MakeRecipeFromMenu, rec.rpc_id)
            end
            return rec
        end
    end
end



-- 文件存储 -- 
-- 文件存储 id的值应该是存储数据的ID, 不同功能绝不应该设置相同的ID
local SavePSData = require("persistentdata")
local DataContainerID = "ModSRC"
local ModDataContainer = SavePSData(DataContainerID)
local DataContainerID_re = "ModSRCRe"
local ModDataContainer_re = SavePSData(DataContainerID)
ModDataContainer:Load()
ModDataContainer_re:Load()

function SaveModData(id, value)
    if not id then return end
    ModDataContainer:SetValue(id, value)
    ModDataContainer:Save()
    ModDataContainer_re:SetValue(id, value)
    ModDataContainer_re:Save()
    print("存储数据",id,value)
end

function LoadModData(id)
    if not id then return end
    local value = ModDataContainer:GetValue(id)
    if value == nil then
        print("读取失败, 再次尝试",id)
        value = ModDataContainer_re:GetValue(id)
    end
    return value
end


-- 检索动画 --
-- copy Timer --
local function isanim(anim,entity)
    return entity and entity.AnimState and entity.AnimState:IsCurrentAnimation(anim)
end

function SearchForAnim(anims,entity)
	if type(anims) == "table" then
		for _,anim in pairs(anims) do
			if isanim(anim,entity) then
				return true
			end
		end
	else
		return isanim(anims,entity)
	end
	
	return false
end

function SearchForReturnAnim(anims,entity)
	if type(anims) == "table" then
		for anim,_ in pairs(anims) do
			if isanim(anim,entity) then
				return anim
			end
		end
	else
		return isanim(anims,entity) and anims
	end
end

-- 多层赋值
-- copy冰汽，授权呼吸 ---
function SetTableMultiLevel(target, levels, value)
    local newLevels = {}
    for _,level in ipairs(levels)do
        if _ ~= 1 then
            table.insert(newLevels, level)
        elseif #levels == 1 then
            target[level] = value
            return
        end
    end
    for _,level in ipairs(levels)do
        if _==1 and target[level] == nil then
            target[level] = {} 
        end
        SetTableMultiLevel(target[level], newLevels, value)
        break
    end
end

function GetTableMultiLevel(target, levels)
    if type(target) ~= "table" then
        return
    end
    local newLevels = {}
    for _,level in ipairs(levels)do
        if _ ~= 1 then
            table.insert(newLevels, level)
        elseif #levels == 1 then
            return target[level]
        end
    end
    for _,level in ipairs(levels)do
        if _== 1 and target[level] == nil then
            return 
        end
        return GetTableMultiLevel(target[level], newLevels)
    end
    return target
end
-- 种子获取
function GetWorldSeed()
    if GLOBAL.TheWorld and GLOBAL.TheWorld.meta then
        return (GLOBAL.TheWorld:HasTag("cave") and "cave_" or "world_" )..
        (string.len(GLOBAL.TheWorld.meta.seed) ~= 0 and GLOBAL.TheWorld.meta.seed
        or GLOBAL.TheWorld.meta.session_identifier)
    end
end

function GetPlayerSeed()
    if GLOBAL.TheWorld and GLOBAL.TheWorld.net and GLOBAL.TheWorld.net.components.shardstate then
       return GLOBAL.TheWorld.net.components.shardstate:GetMasterSessionId() 
    end
end

-- 两点间的距离
function GetDist(x1,y1,x2,y2)
    return math.sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2))
end

-- 判断测试服
function IsDSTBeta()
    -- Branch = "staging" 测试服
    return GLOBAL.BRANCH ~= "release" and true or false
end

-- 空表
function IsEmpty(t)
    if t == nil or (type(t) == "table" and #t == 0 ) then
        return true
    end
    return false
end

-- 仇恨目标
function GetAggro(ent)
    return ent and ent:IsValid() and ent.replica.combat and ent.replica.combat:GetTarget()
end

-- 方向计算器
-- direction可选up（默认） down left right
function GetDirectionAToB(Dist, Source, Direction)
    if Direction == "left" or Direction == "right" then
        local tmp = {x = Dist.x, z = Dist.z}
        Dist.x = Source.z - tmp.z + Source.x
        Dist.z = tmp.x - Source.x + Source.z
    end
    local numy = Dist.z - Source.z
    local numx = Dist.x - Source.x
    local absx = math.abs(numx)
    local absy = math.abs(numy)
    if absx == 0 and absy == 0 then
        return 0.5, 0.5
    end
    if absx > absy then
        numx = numx / absx
        numy = numy / absx
    else
        numx = numx / absy
        numy = numy / absy
    end
    if Direction == "down" or Direction == "right" then
        return -numx/2, -numy/2
    else
        return numx/2, numy/2
    end
end


-- local id = 0
-- local oldSendRPCToServer = GLOBAL.SendRPCToServer
-- function GLOBAL.SendRPCToServer(rpc, actcode, sth, ...)
--     local rpc_init, act_init
--     id = id + 1
--     for k,v in pairs(GLOBAL.RPC)do
--         if rpc == v then
--             rpc_init = k
--         end
--     end
--     if not rpc_init then rpc_init = rpc end
--     for k,v in pairs(GLOBAL.ACTIONS)do
--         if v.code == actcode then
--             act_init = k
--         end
--     end
--     if not act_init then act_init = actcode end
--     print("ID:", id, rpc_init, act_init, "sth:",sth, "其他参数：", ...)
--     oldSendRPCToServer(rpc, actcode, sth, ...)
-- end
