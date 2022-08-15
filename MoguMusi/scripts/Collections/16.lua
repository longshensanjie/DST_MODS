if GLOBAL.TheNet and
    (GLOBAL.TheNet:GetIsServer() and GLOBAL.TheNet:GetServerIsDedicated() or
        GLOBAL.TheNet:GetIsClient() and not GLOBAL.TheNet:GetIsServerAdmin()) then return end

local _G = GLOBAL
local require = _G.require

local TheSim = _G.TheSim
local TheNet = _G.TheNet
local TheInput = _G.TheInput

local STRINGS = _G.STRINGS
local MOVE_LEFT = _G.MOVE_LEFT
local MOVE_RIGHT = _G.MOVE_RIGHT
local CONTROL_ACCEPT = _G.CONTROL_ACCEPT
local CONTROL_SECONDARY = _G.CONTROL_SECONDARY
local CONTROL_CONTROLLER_ALTACTION = _G.CONTROL_CONTROLLER_ALTACTION
local CONTROL_SHOW_PLAYER_STATUS = _G.CONTROL_SHOW_PLAYER_STATUS
local IS_GHOST = _G.USERFLAGS.IS_GHOST

local json = _G.json
local subfmt = _G.subfmt
local distsq = _G.distsq
local checkbit = _G.checkbit
local shallowcopy = _G.shallowcopy
local LookupPlayerInstByUserID = _G.LookupPlayerInstByUserID
local ExecuteConsoleCommand = _G.ExecuteConsoleCommand
local UserToName = _G.UserToName
local GetTime = _G.GetTime

local ImageButton = require "widgets/imagebutton"
local UserCommands = require "usercommands"
local PlayerStatusScreen = require "screens/playerstatusscreen"
local PopupDialogScreen = require "screens/redux/popupdialog"
local PlayerHud = require "screens/playerhud"

local max_pos_size = 3
local max_distance_moved = 16

local persistdata = {}
local world_key = ""
local back_positions = {}
local function SaveData()
	persistdata[world_key] = back_positions or {}
	local str = json.encode(persistdata)
	TheSim:SetPersistentString("AdminScoreboard+", str, false)
end
local function LoadData()
	TheSim:GetPersistentString("AdminScoreboard+", function(success, str)
		if success and str ~= nil then
			persistdata = json.decode(str) or {}
		end
	end)
	back_positions = persistdata[world_key] or {}
end
AddSimPostInit(function()
	local world = _G.TheWorld		-- if worlds have same seed, rip
	world_key = (world:HasTag("cave") and "cave_" or "surface_") .. world.meta.seed
end)

-- config options loaded into locals
local scoreboard_toggle   = true
local gather_enabled      = true
local supergod_enabled    = true
local pickup_cooldown     = 8
local drop_confirm        = true
local kill_confirm        = true
local god_confirm         = true
local creative_confirm    = true
local repair_confirm      = true
local despawn_confirm     = true
local drop_announce       = true
local extinguish_announce = true
local god_announce        = true
local creative_announce   = true
local repair_announce     = true
local despawn_announce    = true

local function SavePositions()
	if _G.ThePlayer == nil then print("[管理员面板] ERROR: ThePlayer is nil!") return end
	local start = _G.ThePlayer:GetPosition()
	_G.ThePlayer:DoTaskInTime(1, function()
		local dest = _G.ThePlayer:GetPosition()
		if distsq(dest, start) >= max_distance_moved then
			LoadData()
			if back_positions and #back_positions == max_pos_size then
				table.remove(back_positions, 1)
			end
			table.insert(back_positions, { x = start.x, y = start.y, z = start.z })
			SaveData()
		end
	end)
end

-- no_tp is true when don't want cave tp and save position
local function SendCommand(fnstr, kuid, no_tp)
	local x, _, z = TheSim:ProjectScreenPos(TheSim:GetPosition())
	local is_valid_time_to_use_remote = TheNet:GetIsClient() and TheNet:GetIsServerAdmin()
	local send_str = string.format("local player = LookupPlayerInstByUserID('%s') if player then " .. fnstr .. (not no_tp and " else local cave = GetClosestInstWithTag('migrator', ThePlayer, 1000) c_goto(cave) end" or " end"), kuid)
	if is_valid_time_to_use_remote then
		TheNet:SendRemoteExecute(send_str, x, z)
		if not no_tp then
			SavePositions()
		end
	else
		ExecuteConsoleCommand(send_str)
	end
end

local TheNetMetatableIndex = _G.getmetatable(_G.TheNet).__index
local old_TheNet_Ban = TheNetMetatableIndex["Ban"]
TheNetMetatableIndex["Ban"] = function(self, userid)
	SendCommand("if player.components.inventory then player.components.inventory:DropEverything() end", userid, true)
	old_TheNet_Ban(self, userid)
end
local old_TheNet_BanForTime = TheNetMetatableIndex["BanForTime"]
TheNetMetatableIndex["BanForTime"] = function(self, userid, seconds)
	SendCommand("if player.components.inventory then player.components.inventory:DropEverything() end", userid, true)
	old_TheNet_BanForTime(self, userid, seconds)
end

---------------------------------------------------------------------------------------------------------

-- name: the .tex file name (unless condition) and internal playerListing.admin_buttons index

-- condition: function that replaces name for tex file and returns the correct hover text, userid and whether hover is passed, replaces confirm string as well

-- hover: the hover text (used for confirm box title as well)
-- fn_str: the string to be sent to be executed, "player" in string is server side
-- fn: function that will be executed instead of fn_str, userid is passed
-- announce: string to be sent and announced if enabled, {name} represents formatted player's name
-- announce_extra: string code to be ran server side in the place of {extra} in the announce string (used for rmb too)
-- confirm: returns confirm string if enabled, {name} represents formatted player's name

-- rmb_hover: the hover text to be displayed for rmb
-- rmb_fn_str: the string to be sent to be executed on rmb, "player" in string is server side
-- rmb_fn: function that will be executed instead of rmb_fn_str, userid is passed
-- rmb_announce: string to be sent and announced if enabled on rmb, {name} represents formatted player's name
-- rmb_confirm: returns confirm string for rmb if enabled, {name} represents formatted player's name

-- cooldown: how long in seconds until another same command can be sent (for each playerListing)

-- additional fields:
-- 		atlas: name of the atlas .xml file
-- 		tex: name of the .tex inside the atlas file
-- 		rotation: rotation applied to image

---------------------------------------------------------------------------------------------------------
local buttons = {
	[1] = {
		{
			name = "goto",
			hover = "跳转",
			fn_str = "if ThePlayer.Physics then ThePlayer.Physics:Teleport(player.Transform:GetWorldPosition()) else ThePlayer.Transform:SetPosition(player.Transform:GetWorldPosition()) end",
			rmb_hover = "聚集",
			rmb_fn_str = gather_enabled and "if player.Physics then player.Physics:Teleport(ThePlayer.Transform:GetWorldPosition()) else player.Transform:SetPosition(ThePlayer.Transform:GetWorldPosition()) end",
			cooldown = 0,
		},
		{
			name = "drop",
			hover = "物品掉落",
			fn_str = string.format("if player.components.inventory then player.components.inventory:DropEverything() end local old_itemtyperestrictions = player.components.itemtyperestrictions player.components.itemtyperestrictions = { IsAllowed = function(self, item) return false end } player:DoTaskInTime(%d, function() player.components.itemtyperestrictions = old_itemtyperestrictions end)", pickup_cooldown or 8),
			announce = drop_announce and "{name}的物品已经掉落, 8秒后才能捡起物品",
			confirm = drop_confirm and "掉落 {name} 的物品",
			cooldown = 0,
		},
		{
			name = "kill",
			condition = function(userid, hover, confirm)
				local player_inst = LookupPlayerInstByUserID(userid)
				local revivable_corpse = player_inst and player_inst.components.revivablecorpse and player_inst:HasTag("corpse")
				local client = TheNet:GetClientTableForUser(userid)
				local dead = client and client.userflags and checkbit(client.userflags, IS_GHOST) or revivable_corpse
				local hover_str = dead and "复活" or "杀死"
				hover_str = hover and hover_str or hover_str:lower()
				if confirm then hover_str = hover_str .. " {name}" end 
				return hover_str
			end,
			hover = "死亡",
			fn = function(userid)
				local client = TheNet:GetClientTableForUser(userid)
				local is_ghost = client and client.userflags and checkbit(client.userflags, IS_GHOST)
				if is_ghost then
					SendCommand("if player:HasTag('playerghost') then player:PushEvent('respawnfromghost') player:DoTaskInTime(2, function() if player.components.health then player.components.health:SetPercent(1) end if player.components.sanity then player.components.sanity:SetPercent(1) end if player.components.hunger then player.components.hunger:SetPercent(1) end end) end", userid)
				else
					SendCommand("if player.components.revivablecorpse and player:HasTag('corpse') then player.components.revivablecorpse:Revive(ThePlayer) player:DoTaskInTime(2, function() if player.components.health then player.components.health:SetPercent(1) end end) elseif player.components.health then player.components.health:SetPercent(0) end", userid)
				end
			end,
			confirm = kill_confirm and "kill/revive {name}",
			cooldown = 3.5,
		},
		{
			name = "extinguish",
			hover = "熄灭附近的火焰",
			fn_str = "local x,y,z = player.Transform:GetWorldPosition() for _,ent in ipairs(TheSim:FindEntities(x,y,z, 40, nil, {'FX','DECOR','INLIMBO','burnt'}, {'fire','smolder'})) do if ent.components.burnable then ent.components.burnable:Extinguish() end end",
			announce = extinguish_announce and "玩家 {name} 附近的火焰已经熄灭",
			cooldown = 0,
		},
		{
			name = "repair",
			hover = "修复被烧毁的建筑",
			fn_str = "local x,y,z = player.Transform:GetWorldPosition() for _,ent in ipairs(TheSim:FindEntities(x,y,z, 24, {'burnt','structure'}, {'INLIMBO'})) do local orig_pos = ent:GetPosition() ent:Remove() local inst = SpawnPrefab(tostring(ent.prefab), tostring(ent.skinname), nil, player.userid) if inst then inst.Transform:SetPosition(orig_pos:Get()) end end",
			announce = repair_announce and "玩家 {name} 附近被烧毁的建筑被重新修复",
			confirm = repair_confirm and "修复 {name} 附近被烧毁的建筑",
			cooldown = 5,
		},
	},
	[2] = {
		{
			name = "godmode",
			hover = "上帝模式",
			fn_str = "if player.components.health then player.components.health:SetInvincible(not player.components.health.invincible) end",
			announce = god_announce and "玩家 {name} 的上帝模式已经 {extra}",
			announce_extra = "\" .. (player.components.health.invincible and 'enabled' or 'disabled') .. \"",
			confirm = god_confirm and "启用/关闭 {name} 的上帝模式",
			rmb_hover = "超级上帝模式",
			rmb_fn_str = supergod_enabled and "if player.components.health then local gmode = player.components.health.invincible player.components.health:SetInvincible(not gmode) if not gmode then local old_debug = GetDebugEntity() SetDebugEntity(player) c_sethealth(1) c_setsanity(1) c_sethunger(1) c_settemperature(25) c_setmoisture(0) c_setbeaverness(1) SetDebugEntity(old_debug) end end",
			rmb_announce = god_announce and "玩家 {name} 的超级上帝模式已经 {extra}",
			rmb_confirm = god_confirm and "启用/关闭 {name} 的超级上帝模式",
			cooldown = 2,
		},
		{	
			name = "creative",
			hover = "创造模式",
			fn_str = "if player.components.builder then player.components.builder:GiveAllRecipes() end",
			announce = creative_announce and "{name} 的创造模式已经 {extra}",
			announce_extra = "\" .. (player.components.builder.freebuildmode and 'enabled' or 'disabled') .. \"",
			confirm = creative_confirm and "启用/关闭 {name} 的创造模式",
			cooldown = 0,
		},
		{
			name = "despawn",
			hover = "重选人物【保留科技】",
			fn_str = "if player.components.inventory then player.components.inventory:DropEverything() end if not TheWorld:HasTag('cave') then player:PushEvent('ms_playerreroll') TheWorld.admin_save = TheWorld.admin_save or {} TheWorld.admin_save[player.userid] = player.SaveForReroll and player:SaveForReroll() if TheWorld.admin_listen == nil then TheWorld.admin_listen = TheWorld:ListenForEvent('ms_newplayerspawned', function(world, p) if world.admin_save[p.userid] and p.LoadForReroll then p:LoadForReroll(world.admin_save[p.userid]) world.admin_save[p.userid] = nil end end) end end TheWorld:PushEvent('ms_playerdespawnanddelete', player)",
			announce = despawn_announce and "玩家 {name} 可以重选人物了",
			confirm = despawn_confirm and "{name} 重选角色【保留科技】",
			rmb_hover = "重选人物【不保留科技】",
			rmb_fn_str = "if player.components.inventory then player.components.inventory:DropEverything() end TheWorld:PushEvent('ms_playerdespawnanddelete', player)",
			rmb_announce = despawn_announce and "{name} 可以重选人物了",
			rmb_confirm = despawn_confirm and "{name} 重选人物【不保留科技】",
			cooldown = 5,
		},
		{
			name = "invisible",
			hover = "隐身模式",
			fn = function()
				if not _G.ThePlayer:HasTag("playerghost") and not _G.ThePlayer:HasTag("corpse") then
					if not _G.ThePlayer:HasTag("noplayerindicator") then
						SendCommand("if player.components.health then player.components.health:SetInvincible(true) end player:Hide() player.DynamicShadow:Enable(false) player.MiniMapEntity:SetEnabled(false) player:AddTag('notarget') player:AddTag('noplayerindicator') player:AddTag('mime') player.SoundEmitter:SetMute(true) player.components.locomotor:SetTriggersCreep(false) RemovePhysicsColliders(player)", _G.ThePlayer.userid, true)
					else
						SendCommand("if player.components.health then player.components.health:SetInvincible(false) end player:Show() player.DynamicShadow:Enable(true) player.MiniMapEntity:SetEnabled(true) player:RemoveTag('notarget') player:RemoveTag('noplayerindicator') if player.prefab ~= 'wes' then player:RemoveTag('mime') end player.SoundEmitter:SetMute(false) player.components.locomotor:SetTriggersCreep(not player:HasTag('spiderwhisperer')) ChangeToCharacterPhysics(player)", _G.ThePlayer.userid, true)
					end
				else
					_G.ThePlayer.components.talker:Say("Must be alive to toggle visibility!")
				end
			end,
			cooldown = 0,
		},
	}
}
-- store reference to buttons that are checked OnUpdate (faster than looping thru all page button for all listing)
local condition_buttons = {}
for page,page_buttons in ipairs(buttons) do
	for i,button in ipairs(page_buttons) do
		if button.condition then
			condition_buttons[tostring(button.name)] = button.condition
		end
	end
end

local function ExecuteCommand(lmb, button, userid)
	local fn = (lmb and button.fn) or (not lmb and button.rmb_fn)
	local fn_str = (lmb and button.fn_str) or (not lmb and button.rmb_fn_str)
	local announce = (lmb and button.announce) or (not lmb and button.rmb_announce)
	if fn then
		fn(userid)
	elseif fn_str then
		SendCommand(fn_str, userid)
	end
	if announce then
		-- to prevent send command string manipulation, let the server handle the name string
		announce = "subfmt(\"" .. announce .. "\", {name=name:match('^[^\\n\\v\\f\\r]*'):sub(1,20)})"
		if button.announce_extra then
			announce = subfmt(announce, { extra = button.announce_extra })
		end
		SendCommand("local name = player.name or 'N/A' TheNet:Announce(" .. announce .. ", ThePlayer.entity, nil, 'default')", userid, true)
	end
end

local function ButtonClick(button, playerListing, lmb)
	local userid = playerListing.userid
	if userid == nil then print("[AdminScoreboard+] ERROR: No userid found for player listing!") return end
	local listing_button = playerListing[button.name]
	local cur_time = GetTime()
	local old_time = listing_button.time or -5
	if (cur_time - old_time) >= button.cooldown then
		local confirm = (lmb and button.confirm) or (not lmb and button.rmb_confirm)
		if confirm then
			if not scoreboard_toggle and not TheInput:ControllerAttached() then _G.TheFrontEnd:PopScreen() end
			local username = UserToName(userid) or "N/A"
			local action_str = (lmb and (button.condition and button.condition(userid, true) or button.hover)) or (not lmb and button.rmb_hover)
			confirm = lmb and button.condition and button.condition(userid, false, true) or confirm
			_G.TheFrontEnd:PushScreen(
				PopupDialogScreen( "真的要 " .. action_str .. "?",
					subfmt("你确定你想要 " .. confirm .. " ({userid})?", { name = username:match("^[^\n\v\f\r]*"):sub(1,20), userid = userid }),
					{
						{ text = STRINGS.UI.PLAYERSTATUSSCREEN.OK, cb = function() _G.TheFrontEnd:PopScreen() ExecuteCommand(lmb, button, userid) listing_button.time = GetTime() end },
						{ text = STRINGS.UI.PLAYERSTATUSSCREEN.CANCEL, cb = function() _G.TheFrontEnd:PopScreen() end }
					} 
				)
			)
		else
			ExecuteCommand(lmb, button, userid)
			listing_button.time = GetTime()
		end
	end
end

-- stores what buttons are shown for each page and what page for each player indexed by userid
local player_pages = {}

-- order of buttons, used for focus and showing/hiding
local all_buttons = { [-1] = {}, [0] = { "viewprofile", "mute", "shareloc", "kick", "ban", "useractions" } }
for page,page_buttons in ipairs(buttons) do
	all_buttons[page] = {}
	for i,button in ipairs(page_buttons) do
		table.insert(all_buttons[page], button.name)
	end
end
table.insert(all_buttons[1], 1, "back")

local UpdateShown

local function ChangePage(playerListing, right)
	local userid = playerListing.userid
	player_pages[userid].page = (player_pages[userid].page or 0) + (right and 1 or -1)
	playerListing.page = player_pages[userid].page
	local shown = UpdateShown(playerListing)
	return right and shown[1] or shown[#shown]
end

UpdateShown = function(playerListing)
	local page = playerListing.page
	local shown = {}
	if page >= 0 then
		for _,button_name in ipairs(player_pages[playerListing.userid][page]) do
			playerListing[button_name]:Show()
			table.insert(shown, playerListing[button_name])
		end
		local is_self = playerListing.userid == TheNet:GetUserID()
		if not is_self then
			playerListing["back"]:Hide()
			playerListing["invisible"]:Hide()
		else
			playerListing["goto"]:Hide()
		end
	end
	-- hide other buttons for other pages
	for button_page,page_buttons in pairs(all_buttons) do
		if button_page ~= page then
			for _,button_name in ipairs(page_buttons) do
				if playerListing[button_name] and playerListing[button_name].shown then
					playerListing[button_name]:Hide()
				end
			end
		end
	end
	
	playerListing["forward_arrow"]:Show()
	playerListing["backward_arrow"]:Show()
	if page == #buttons then
		playerListing["forward_arrow"]:Hide()
	end
	if page < 1 then
		playerListing["backward_arrow"]:Hide()
	end
	
	-- focus hookups
	playerListing.focus_forward = shown[1]
	for i,button in ipairs(shown) do
		if shown[i-1] then
			button:SetFocusChangeDir(MOVE_LEFT, shown[i-1])
		elseif page > 0 then
			button:SetFocusChangeDir(MOVE_LEFT, function() return ChangePage(playerListing, false) end)
		end
		if shown[i+1] then
			button:SetFocusChangeDir(MOVE_RIGHT, shown[i+1])
		elseif page < #buttons then
			button:SetFocusChangeDir(MOVE_RIGHT, function() return ChangePage(playerListing, true) end)	
		end
	end
	return shown
end

local hover_font = { font = _G.NEWFONT_OUTLINE, offset_x = 0, offset_y = 30, colour = {1,1,1,1} }
local hover_font_rmb = { font = _G.NEWFONT_OUTLINE, size = 18, offset_x = 0, offset_y = 40, colour = {1,1,1,1} }

-- hover string changes based on controller active and control button for LMB/RMB buttons
local function GetHoverString(button)
	local left = TheInput:ControllerAttached() and TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_ACCEPT) or STRINGS.LMB
	local right = TheInput:ControllerAttached() and TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_CONTROLLER_ALTACTION) or STRINGS.RMB
	return left .. " " .. button.hover .. "\n" .. right .. " " .. button.rmb_hover
end

local old_PlayerStatusScreen_OnUpdate = PlayerStatusScreen.OnUpdate
function PlayerStatusScreen:OnUpdate(...)
	old_PlayerStatusScreen_OnUpdate(self, ...)
	-- update scrolling updater with proper refreshing info (klei bug fix?)
	-- since old is called 1st, it will be remade if needed (dif player count), so safe to copy over
	local ClientObjs = TheNet:GetClientTable()
	if self.scroll_list then
		self.scroll_list.items = ClientObjs
	end
	
	local admin = self.owner.Network:IsServerAdmin()
	if not admin then return end
	
	-- update condition button's image and hover
	if self.scroll_list ~= nil then
		for _,playerListing in ipairs(self.player_widgets) do
			for button_name, condition in pairs(condition_buttons) do
				local listing_button = playerListing[button_name]
				if listing_button and playerListing.userid then
					local new_tex = condition(playerListing.userid, false)
					if listing_button.old_value ~= new_tex then
						listing_button:SetHoverText(condition(playerListing.userid, true), hover_font)
						listing_button.image:SetTexture("images/admin_icons.xml", new_tex .. ".tex")
						listing_button:SetTextures("images/admin_icons.xml", new_tex .. ".tex")
						listing_button.old_value = new_tex
					end
				end
			end
		end
	end
end

local old_PlayerStatusScreen_DoInit = PlayerStatusScreen.DoInit
function PlayerStatusScreen:DoInit(...)
	old_PlayerStatusScreen_DoInit(self, ...)
	
	local admin = self.owner.Network:IsServerAdmin()
	if not admin then
		print("[Admin Scoreboard+] User is not an admin!")
		return
	end
	
	if not self.scroll_list.admin_old_update then
		for _,playerListing in ipairs(self.player_widgets) do			
			local forward_back_size_x = 18
			local forward_back_size_y = 32
			local forward_back_buttons = {
				[1] = { name = "forward_arrow", x_pos = 249, rotate = 0, hover = "下一页", right = true },
				[2] = { name = "backward_arrow", x_pos = 19, rotate = 180, hover = "上一页", right = false },
			}
			for _,button in ipairs(forward_back_buttons) do
				local arrow = tostring(button.name)
				playerListing[arrow] = playerListing:AddChild(ImageButton("images/admin_icons.xml", "turnarrow_icon.tex", "turnarrow_icon_over.tex", nil, nil, nil, {1,1}, {0,0}))
				playerListing[arrow].name = arrow
				playerListing[arrow]:SetPosition(button.x_pos, 3, 0)
				playerListing[arrow].image:SetRotation(button.rotate)
				playerListing[arrow]:SetHoverText(button.hover, hover_font)
				local w, h = playerListing[arrow].image:GetSize()
				local scale_x = forward_back_size_x / w
				local scale_y = forward_back_size_y / h
				playerListing[arrow]:SetNormalScale(scale_x, scale_y)
				playerListing[arrow]:SetFocusScale(scale_x*1.1, scale_y*1.1)
				playerListing[arrow]:SetFocusSound("dontstarve/HUD/click_mouseover")
				playerListing[arrow]:SetOnClick(function() ChangePage(playerListing, button.right) end)
				playerListing[arrow]:Hide()
			end
			
			-- used to support any image dimension as button, could be dynamic based on normal buttons
			local button_size = 39
			local button_x = 50
			local button_x_incr = 42
			for page,page_buttons in ipairs(buttons) do
				for i,button in ipairs(page_buttons) do
					local button_name = tostring(button.name)
					local hover = button.hover
					local hover_params = hover_font
					if button.rmb_hover and (button.rmb_fn_str or button.rmb_fn) then
						hover = GetHoverString(button)
						hover_params = hover_font_rmb
					end
					local tex = (button.tex or button.name) .. ".tex"
					playerListing[button_name] = playerListing:AddChild(ImageButton(button.atlas or "images/admin_icons.xml", tex))
					playerListing[button_name].name = button_name
					playerListing[button_name]:SetPosition(button_x + button_x_incr*(i-1), 3, 0)
					playerListing[button_name]:SetHoverText(hover, hover_params)
					playerListing[button_name].image:SetRotation(button.rotation or 0)
					local w, h = playerListing[button_name].image:GetSize()
					local scale = math.min(button_size / w, button_size / h)
					playerListing[button_name]:SetNormalScale(scale)
					playerListing[button_name]:SetFocusScale(scale*1.1)
					playerListing[button_name]:SetFocusSound("dontstarve/HUD/click_mouseover")
					playerListing[button_name]:SetOnClick(function() ButtonClick(button, playerListing, true) end)
					if button.rmb_fn_str or button.rmb_fn then
						playerListing[button_name].OnControl = function(button, control, down) return LROnControl(button, control, down) end
						playerListing[button_name]:SetOnClick(function(lmb) ButtonClick(button, playerListing, lmb) end)
						playerListing[button_name]:SetOnGainFocus(function() playerListing[button_name]:SetHoverText(GetHoverString(button), hover_params) end)
					end
					playerListing[button_name]:Hide()
				end
			end
			playerListing["back"] = playerListing:AddChild(ImageButton("images/admin_icons.xml", "goto.tex"))
			playerListing["back"].name = "back"
			playerListing["back"]:SetPosition(50, 3, 0)
			playerListing["back"]:SetHoverText("返回", hover_font)
			local w, h = playerListing["back"].image:GetSize()
			local scale = math.min(button_size / w, button_size / h)
			playerListing["back"]:SetNormalScale(scale)
			playerListing["back"]:SetFocusScale(scale*1.1)
			playerListing["back"]:SetFocusSound("dontstarve/HUD/click_mouseover")
			playerListing["back"].image:SetRotation(180)
			playerListing["back"]:SetOnClick(function()
				LoadData()
				local back_pos = back_positions and back_positions[#back_positions]
				if back_pos and _G.ThePlayer and _G.ThePlayer.userid then
					table.remove(back_positions, #back_positions)
					local command = subfmt("if player.Physics then player.Physics:Teleport({x},{y},{z}) else player.Transform:SetPosition({x},{y},{z}) end", { x = back_pos.x, y = back_pos.y, z = back_pos.z })
					SendCommand(command, _G.ThePlayer.userid, true)
					SaveData()
				end
			end)
			playerListing["back"]:Hide()
			
			-- move days left to compensate for large day counts overlap onto backward arrow
			playerListing.age:SetPosition(-27, 0, 0)
		end
		
		self.scroll_list.admin_old_update = self.scroll_list.updatefn
		self.scroll_list.updatefn = function(playerListing, ...)
			self.scroll_list.admin_old_update(playerListing, ...)
			
			if not playerListing.shown then return end
			
			-- if dedicated host then hide shown and return out
			local this_user_is_dedicated_server = playerListing.ishost and not TheNet:GetServerIsClientHosted()
			if this_user_is_dedicated_server then
				playerListing.name:SetHoverText("Dedicated Server", hover_font)
				playerListing.page = -1
				UpdateShown(playerListing)
				playerListing["forward_arrow"]:Hide()
				return
			end
			
			-- make performance smaller and move over so room for forward arrow
			playerListing.perf:SetScale(0.9)
			playerListing.perf:SetPosition(300, 4, 0)
			
			local userid = playerListing.userid or ""
			-- hover name will show Klei ID
			playerListing.name:SetHoverText(userid, hover_font)
			
			-- set up buttons per player
			if player_pages[userid] == nil then
				player_pages[userid] = {}
				player_pages[userid].page = 0
				player_pages[userid][1] = shallowcopy(all_buttons[1])
				player_pages[userid][2] = shallowcopy(all_buttons[2])
				-- remove goto for self user and remove invis n back for others
				local is_self = userid == TheNet:GetUserID()
				table.remove(player_pages[userid][1], is_self and 2 or 1)
				if not is_self then
					table.remove(player_pages[userid][2], 4)
				end
			end
			-- refresh default page with what is shown
			player_pages[userid][0] = {}
			for _,button_name in ipairs(all_buttons[0]) do
				if playerListing[button_name] and playerListing[button_name].shown then
					table.insert(player_pages[userid][0], button_name)
				end
			end
			
			-- update what's shown/hidden and do focus hookups
			playerListing.page = player_pages[userid].page
			UpdateShown(playerListing)
		end
		
		-- call new updatefn after init
		self.scroll_list:RefreshView()
	end
end

if scoreboard_toggle then
	local old_PlayerHud_ShowPlayerStatusScreen = PlayerHud.ShowPlayerStatusScreen
	function PlayerHud:ShowPlayerStatusScreen(...)
		if not TheInput:IsControlPressed(CONTROL_SHOW_PLAYER_STATUS) then
			old_PlayerHud_ShowPlayerStatusScreen(self, ...)
		end
	end

	local old_PlayerHud_OnControl = PlayerHud.OnControl
	function PlayerHud:OnControl(control, down)
		local ret = old_PlayerHud_OnControl(self, control, down)
		if not ret then
			if not down and control == CONTROL_SHOW_PLAYER_STATUS then
				self:ShowPlayerStatusScreen()
				ret = true
			end
		end
		return ret
	end
end