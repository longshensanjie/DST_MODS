local G = GLOBAL
local verbose = true
local unravelMarketable = false
if GetModConfigData("sw_skinQueue") == "chong" then
    unravel = true
end

local function printd (...)
	return verbose and print(...)
end

local function unravelByConfig (...)
	if unravelMarketable
    then
        return true
    else
        return G.IsItemMarketable(...) ~= true
    end
end

local HUD = {
	timetaken = 0,
}

local DupesPopup = {}

local Queuer = {
	queue = {},
	itemQueueCount = {},
	count = 1,
	timetaken = 0,
}

local DupeSeller = {}


local Text = G.require("widgets/text")
local Widget = G.require("widgets/widget")
local Screen = G.require("widgets/screen")
local ItemImage = G.require("widgets/redux/itemimage")
local UIAnim = G.require("widgets/uianim")
local BarterScreen = G.require("screens/redux/barterscreen")
local PlayerSummaryScreen = G.require("screens/redux/playersummaryscreen")
local PopupDialog = G.require("screens/redux/popupdialog")
local TEMPLATES = G.require("widgets/redux/templates")


------------------------------
-------Console Commands-------
------------------------------

G.sq_stop = function ()
	Queuer.stopQueue(true)
end


G.sq_unravel = function (key, val)
	Queuer.addQueue(key, val)
end
G.sq_sell = G.sq_unravel


G.sq_weave = function (key, val)
	Queuer.addQueue(key, val, true)
end
G.sq_buy = G.sq_weave


G.sq_listqueue = function (console)

	local queue = Queuer.queue

	if console == false then
	elseif #queue > 0 then
		for i = 1, #queue do
			if i == Queuer.count then
				print(
					i,
					queue[i].key,
					queue[i].val,
					queue[i].buy and "buying..." or "selling..."
				)
			elseif i < Queuer.count then
				print(
					i,
					queue[i].key,
					queue[i].val,
					queue[i].buy and "bought" or "sold"
				)
			else
				print(i, queue[i].key, queue[i].val)
			end
		end
	else
		print("There is no queue")
	end

	return queue

end


G.sq_listdupes = function (separator)

	local dupes = DupeSeller.getAllDupes()
	local str = ""

	if separator ~= false then
		if #dupes > 0 then
			for i = 1, #dupes do
				str = str..dupes[i]..(separator or ", ")
			end
			print(str)
		else
			print("未找到重复皮肤")
		end
	end

	return dupes

end


G.sq_sellalldupes = function ()
	DupeSeller.sellAllDupes()
end


------------------------------
----------Queue HUD-----------
------------------------------

HUD.create = function (parent)

	local self = Text(G.DEFAULTFONT, 20, nil, G.UICOLOURS.WHITE)

	self.inst:AddTag("NOCLICK")
	self.inst.persists = false

	parent:AddChild(self)
	self:MoveToFront()

	self:SetVAnchor(G.ANCHOR_TOP)
	self:SetHAnchor(G.ANCHOR_RIGHT)
	self:SetHAlign(G.ANCHOR_RIGHT)

	local SetString_Old = self.SetString or (function() end)

	self.SetString = function (self, ...)

		SetString_Old(self, ...)

		local w, h = self:GetRegionSize()
		self:SetPosition(-w / 2 - 5, -h / 2 - 5)

	end

	return self

end


HUD.onQueueUpdate = function (timetaken)

	if #Queuer.queue <= 0 then
		HUD.text:SetString("")
		HUD.timetaken = 0
		return
	end

	local lines = {}

	local current = Queuer.queue[Queuer.count]

	local nextkey = Queuer.queue[Queuer.count + 1]
		and Queuer.queue[Queuer.count + 1].key

	if current then
		lines[#lines + 1] = (current.buy and "正在合成 " or "正在拆解 ")
			..current.key
			.." 为 "
			..current.val
			.." 个线轴..."
	end

	if nextkey then
		lines[#lines + 1] = " 下一个拆 "..nextkey
	end

	lines[#lines + 1] = Queuer.count
		.."/"
		..#Queuer.queue
		.." ("
		..math.floor( 100 * ( Queuer.count / #Queuer.queue ) + 0.5 )
		.."%) 个物品"

	if timetaken then
		HUD.timetaken = timetaken
	end

	if HUD.timetaken > 0 then
		lines[#lines + 1] = HUD.getETR(
				HUD.timetaken * ( #Queuer.queue - ( Queuer.count - 1 ) )
			)
			.." etr"
	end

	HUD.text:SetString(table.concat(lines, "\n"))
end


HUD.getETR = function (x)

	local secs = math.max(0, math.ceil(x / 30))

	if secs >= 3600 then 
		return G.os.date("!%X", secs)
	elseif secs > 86400 then
		return math.floor(secs / 3600)
			..":"
			..G.os.date("!%M:%S", secs)
	end

	return G.os.date("!%M:%S", secs)

end


HUD.timerTask = G.scheduler:ExecutePeriodic(1/15, function ()
	if G.TheFrontEnd ~= nil then
		HUD.onFindFrontEnd(G.TheFrontEnd)
	end
end)


HUD.onFindFrontEnd = function (fe)

	if not fe then
		return
	end

	if HUD.timerTask ~= nil then
		HUD.timerTask:Cancel()
		HUD.timerTask = nil
	end

	HUD.text = HUD.create(G.TheFrontEnd.overlayroot)

end


------------------------------
---------Dupes Popup----------
------------------------------

DupesPopup.create = function (duplicates)

	local self = Screen("DupesPopup")

	self:SetVAnchor(G.ANCHOR_MIDDLE)
	self:SetHAnchor(G.ANCHOR_MIDDLE)
	self:SetScaleMode(G.SCALEMODE_PROPORTIONAL)

	self.dupes  = duplicates or DupeSeller.getAllDupes()

	self.bg = self:AddChild(TEMPLATES.BackgroundTint())

	if not G.TheInput:ControllerAttached() then
		self.back_button = self:AddChild(TEMPLATES.BackButton(
			function()
				self:Close()
			end
		))
	end

	self.title = self:AddChild(
		Text(
			G.HEADERFONT,
			28,
			#self.dupes.." 个重复皮肤",
			G.UICOLOURS.GOLD_SELECTED
		)
	)
	self.title:SetPosition(0, 222)

	self.dialog = self:AddChild(TEMPLATES.RectangleWindow(736, 406))
	local r, g, b = G.unpack(G.UICOLOURS.BROWN_DARK)
	self.dialog:SetBackgroundTint(r, g, b, 0.8)
	self.dialog:SetPosition(0, -5)
	self.dialog.top:Hide()

	self.button = self:AddChild(
		TEMPLATES.StandardButton(
			function ()
				self:Accept()
			end,
			"全部分解",
			{200, 60}
		)
	)
	self.button:SetPosition(290, -240)

	self.total = self:AddChild(
		Text(
			G.HEADERFONT,
			28,
			nil,
			G.UICOLOURS.GOLD_SELECTED
		)
	)
	self.total:SetString(
		G.TheInventory:GetCurrencyAmount()
		.."(现有线轴) + "
		..DupeSeller.getDupesTotalWorth(self.dupes)
		.."(重复线轴) = "
		..G.TheInventory:GetCurrencyAmount()
		+ DupeSeller.getDupesTotalWorth(self.dupes)
		.." 个线轴"
	)
	local w, h = self.total:GetRegionSize()
	self.total:SetPosition(w / 2 - 380, -245)

	self.grid = self:AddChild(DupesPopup.buildGrid(self))
	self.grid:SetPosition(-10, -4.5)
	self.grid.end_offset = 1
	self.grid._GetScrollAmountPerRow = function (self)
		return 1
	end
	self.grid:SetItemsData(self.dupes)

	self.default_focus = self.button
	self.button:SetFocusChangeDir(G.MOVE_UP, self.grid)
	self.grid:SetFocusChangeDir(G.MOVE_DOWN, self.button)
	self.grid:SetFocusChangeDir(G.MOVE_LEFT, self.button)
	self.grid:SetFocusChangeDir(G.MOVE_RIGHT, self.button)

	self.OnControl = function (self, control, down)
		if self._base.OnControl(self, control, down) then
			return true
		end
		if not down and control == G.CONTROL_CANCEL then
			self:Close()
			return true
		end
	end

	self.Accept = function (self)
		DupeSeller.sellAllDupes(self.dupes)
		self:Close()
	end

	self.Close = function (self)
		G.TheFrontEnd:PopScreen()
	end

	return self

end


DupesPopup.buildGrid = function (self)

	local function scrollWidgetCtorFn (context, index)

		local w = Widget("DuplicateItem")

		w.backing = w:AddChild(
			TEMPLATES.ListItemBackground(
				235,
				120,
				function() end
			)
		)
		w.backing:SetPosition(#self.dupes > 9 and -6 or 6, 0)
		w.backing.move_on_click = true

		w.item = w.backing:AddChild(
			ItemImage(
				context.user_profile,
				context.screen
			)
		)
		w.item:Disable()
		w.item:SetPosition(-55, 0)
		w.item:ScaleToSize(90)
		w.item.warn_marker:Hide()

		w.name = w.backing:AddChild(
			Text(
				G.HEADERFONT,
				20,
				nil,
				G.UICOLOURS.GOLD_SELECTED
			)
		)

		w.doodad = w.backing:AddChild(Widget("doodad"))
		w.doodad:SetScale(0.2, 0.16)
		w.doodad:SetPosition(20, -24)

		w.doodad.shadow = w.doodad:AddChild(UIAnim())
		w.doodad.shadow.inst.AnimState:SetBank("spool")
		w.doodad.shadow.inst.AnimState:SetBuild("spool")
		w.doodad.shadow.inst.AnimState:PlayAnimation("idle", true)
		w.doodad.shadow.inst.AnimState:SetMultColour(0, 0, 0, 1)
		w.doodad.shadow:SetScale(1.05)

		w.doodad.front = w.doodad:AddChild(UIAnim())
		w.doodad.front.inst.AnimState:SetBank("spool")
		w.doodad.front.inst.AnimState:SetBuild("spool")
		w.doodad.front.inst.AnimState:PlayAnimation("idle", true)

		w.value = w.backing:AddChild(
			Text(
				G.CHATFONT_OUTLINE,
				20,
				nil,
				G.UICOLOURS.WHITE
			)
		)

		w.focus_forward = w.backing

		w.ongainfocusfn = function()
			self.grid:OnWidgetFocus(w)
		end

		return w

	end

	local function scrollWidgetApplyFn (context, widget, data, index)

		if not data then
			widget.backing:Hide()
			widget:Disable()
			return
		end

		widget.item:SetItem(
			G.GetTypeForItem(data),
			data
		)

		widget.name:SetMultilineTruncatedString(
			G.GetSkinName(data),
			2,
			110
		)
		widget.name:SetPosition(48, 18)

		widget.value:SetString("×"
			..G.TheItems:GetBarterSellPrice(data)
		)
		local w, h = widget.value:GetRegionSize()
		widget.value:SetPosition(38 + w / 2, -28)

		widget.backing:SetOnClick(function ()
			DupesPopup.onClickWidget(self, data, widget)
		end)
		widget.backing:Show()

		widget:Enable()

	end

	return TEMPLATES.ScrollingGrid(
		{},
		{
			context = {},
			item_ctor_fn = scrollWidgetCtorFn,
			apply_fn = scrollWidgetApplyFn,
			widget_width = 245,
			widget_height = 130,
			num_visible_rows = 3,
			num_columns = 3,
			scrollbar_offset = 0,
			scrollbar_height_offset = -70,
			scroll_per_click = 0.5,
			scissor_pad = 16,
			peek_percent = 0,
			allow_bottom_empty_row = true,
		}
	)

end


DupesPopup.onClickWidget = function (self, key, widget)

	for i = 1, #self.dupes do
		if self.dupes[i] == key then
			table.remove(self.dupes, i)
			break
		end
	end

	self.grid:SetItemsData(self.dupes)

	self.title:SetString(#self.dupes.." 个重复的皮肤")

	if #self.dupes <= 0 then
		self.total:SetString("")
		self.button:Disable()
	else
		self.total:SetString(
			G.TheInventory:GetCurrencyAmount()
			.." + "
			..DupeSeller.getDupesTotalWorth(self.dupes)
			.." = "
			..G.TheInventory:GetCurrencyAmount()
			+ DupeSeller.getDupesTotalWorth(self.dupes)
			.." 个线轴"
		)
		local w, h = self.total:GetRegionSize()
		self.total:SetPosition(w / 2 - 380, -245)
	end

end


------------------------------
--------Barter Screen---------
------------------------------

local BuildDialog_Old = BarterScreen._BuildDialog or (function() end)

BarterScreen._BuildDialog = function (self, ...)

	local currencyAmount = G.TheInventory:GetCurrencyAmount()
	local GetCurrencyAmount_Old = G.getmetatable(G.TheInventory).__index.GetCurrencyAmount

	G.getmetatable(G.TheInventory).__index.GetCurrencyAmount = function ()
		return Queuer.getCurrencyAmount(currencyAmount)
	end

	local dialog = BuildDialog_Old(self, ...)

	G.getmetatable(G.TheInventory).__index.GetCurrencyAmount = GetCurrencyAmount_Old

	if self.is_buying then

		if self.doodad_net < 0 then
			return dialog
		end

		dialog.actions.items[1]:SetOnClick(function ()
			G.TheFrontEnd:PopScreen()
			Queuer.addQueue(self.item_key, self.doodad_value, true)
		end)

		return dialog

	end

	if Queuer.getItemCount(self.item_key) == 1 then

		dialog.body:SetString(
			"警告: 这是你的最后一个\n\n"
			..dialog.body:GetString():match("^(.*)\n")
		)

	elseif Queuer.getItemCount(self.item_key) <= 0 then

		dialog.body:SetString("You have no "
			..G.GetSkinName(self.item_key)
			.." left to unravel.\n\n请等待队列完成。")

		dialog.actions.items[1]:Disable()

	end

	dialog.actions.items[1]:SetOnClick(function ()
		G.TheFrontEnd:PopScreen()
		Queuer.addQueue(self.item_key, self.doodad_value)
	end)

	return dialog

end


------------------------------
----Player Summary Screen-----
------------------------------

local BuildItemsSummary_Old = PlayerSummaryScreen._BuildItemsSummary or (function() end)

PlayerSummaryScreen._BuildItemsSummary = function (self, ...)
	local width = 300
	local root = BuildItemsSummary_Old(self, ...)

	local UpdateItems_Old = root.UpdateItems or (function() end)

	-- root.dupesfound = root:AddChild(
		-- Text(
			-- G.CHATFONT,
			-- 25,
			-- nil,
			-- G.UICOLOURS.WHITE
		-- )
	-- )
	-- root.dupesfound:SetPosition(60,-20)
	-- root.dupesfound:SetRegionSize(width,30)
	-- root.dupesfound:Hide()

	root.selldupes = root:AddChild(
		TEMPLATES.StandardButton(
			function ()
				G.TheFrontEnd:PushScreen(
					DupesPopup.create(DupeSeller.getAllDupes())
				)
			end,
			"分解重复皮肤",
			{200, 40}
		)
	)
	root.selldupes:SetPosition(300,10)
	root.selldupes:Hide()

	root.UpdateItems = function (...)

		UpdateItems_Old(...)

		local dupes = DupeSeller.getAllDupes()

		-- if #dupes <= 0 then
		-- 	--root.dupesfound:Hide()
		-- 	root.selldupes:Hide()
		-- 	--self:_DoFocusHookups()
		-- 	return
		-- end

		--root.items:Hide()
		--root.no_items:Hide()

		-- root.dupesfound:SetString(
			-- #dupes
			-- .." duplicate items found"
		-- )
		--root.dupesfound:Show()
		root.selldupes:Show()

		--self:_DoNewFocusHookups()

	end

	return root

end


PlayerSummaryScreen._DoNewFocusHookups = function (self, new)

	self.menu:SetFocusChangeDir(G.MOVE_RIGHT, self.new_items.selldupes)
	self.new_items.selldupes:SetFocusChangeDir(G.MOVE_LEFT, self.menu)

	if self.festivals_badges ~= nil then
		self.new_items.selldupes:SetFocusChangeDir(G.MOVE_RIGHT, self.festivals_badges[1])
		for i,_ in pairs(self.festivals_badges) do
			self.festivals_badges[i]:SetFocusChangeDir(G.MOVE_UP, self.festivals_badges[i-1])
			self.festivals_badges[i]:SetFocusChangeDir(G.MOVE_LEFT, self.new_items.selldupes)
			self.festivals_badges[i]:SetFocusChangeDir(G.MOVE_DOWN, self.festivals_badges[i+1])
		end
	end

end


------------------------------
------------Queuer------------
------------------------------

Queuer.getItemCount = function (key, n)
	return (n or G.GetOwnedItemCounts()[key] or 0)
		- (Queuer.itemQueueCount[key] or 0)
end


Queuer.addQueue = function (key, value, buy)

	if buy then
		return Queuer.addBuyQueue(key, value)
	elseif (G.GetOwnedItemCounts()[key] or 0) <= 0 then
		printd(" (线轴分解) 错误: 你没有自己的 "..key)
		return
	elseif Queuer.getItemCount(key) <= 0 then
		printd(" (分解线轴) 错误: You don't have any "..key.." left to sell")
		return
	end

	val = value or G.TheItems:GetBarterSellPrice(key)

	if val <= 0 then
		printd(" (线轴分解)  错误: 你无法分解 "..key.." 得到任何线轴")
		return
	end

	Queuer.itemQueueCount[key] = (Queuer.itemQueueCount[key] or 0) + 1

	Queuer.queue[#Queuer.queue + 1] = {
		key = key,
		val = val
	}

	printd(" (线轴分解) 队列 "..key.." 被分解为 "..val.." 个线轴")

	if #Queuer.queue == 1 then
		Queuer.startQueue()
	end

	HUD.onQueueUpdate()

end


Queuer.addBuyQueue = function (key, value)

	val = value or G.TheItems:GetBarterBuyPrice(key)

	if val <= 0 then
		printd(" (分解线轴) 错误: 你不能购买 "..key)
		return
	end

	Queuer.itemQueueCount[key] = (Queuer.itemQueueCount[key] or 0) - 1

	Queuer.queue[#Queuer.queue + 1] = {
		key = key,
		val = val,
		buy = true
	}

	printd(" (分解线轴) 队列 "..key.." 被购买为 "..val.." 个线轴")

	if #Queuer.queue == 1 then
		Queuer.startQueue()
	end

	HUD.onQueueUpdate()

end


Queuer.startQueue = function ()

	printd(" (分解线轴) 开始分解...")

	Queuer.doQueue()

	Queuer.timerTask = G.scheduler:ExecutePeriodic(1/30, function()
		Queuer.timetaken = Queuer.timetaken + 1
	end)

end


Queuer.doQueue = function ()

	local q = Queuer.queue[Queuer.count]

	if not q then
		Queuer.stopQueue()
		return
	elseif q.buy then
		Queuer.weaveFn(q.key, q.val)
	else
		Queuer.unravelFn(q.key, q.val)
	end

	HUD.onQueueUpdate(Queuer.timetaken)

end


Queuer.stopQueue = function (forced)

	Queuer.queue = {}
	Queuer.itemQueueCount = {}
	Queuer.count = 1
	Queuer.timetaken = 0

	if Queuer.timerTask ~= nil then
		Queuer.timerTask:Cancel()
		Queuer.timerTask = nil
	end

	if forced then
		printd(" (分解线轴) 分解停止")
	else
		printd(" (分解线轴) 完成分解")
	end

	HUD.onQueueUpdate()

end


Queuer.unravelFn = function (key, val)

	local item_id = G.GetFirstOwnedItemId(key)

	if not item_id then

		local server_error = PopupDialog(
			G.STRINGS.UI.TRADESCREEN.SERVER_ERROR_TITLE,
			G.STRINGS.UI.TRADESCREEN.SERVER_ERROR_BODY,
			{ {
				text = G.STRINGS.UI.TRADESCREEN.OK,
				cb = function ()
					print("错误: 以物易物。")
					G.SimReset()
				end
			} }
		)

		G.scheduler:ExecuteInTime(0, function ()
			G.TheFrontEnd:PushScreen(server_error)
		end)

		return

	end

	printd(" (分解线轴) 正在拆解 "..key.."...")

	G.TheItems:BarterLoseItem(
		item_id,
		val,
		function (success, status)

		G.scheduler:ExecuteInTime(0, function ()
			Queuer.unravelComplete(
				success,
				status,
				{"dontstarve/HUD/Together_HUD/collectionscreen/unweave"},
				key
			)
			Queuer.onUnravel(success, key, val)
		end)

	end)

end


Queuer.onUnravel = function (success, key, val)

	if success then
		printd(" (分解线轴) 成功: 分解 "..key.." 换为 "..val.." 个线轴")
	else
		printd(" (分解线轴) 错误: 无法分解 "..key)
	end

	Queuer.itemQueueCount[key] = Queuer.itemQueueCount[key] - 1
	Queuer.count = Queuer.count + 1
	Queuer.doQueue()
	Queuer.timetaken = 0

end


Queuer.unravelComplete = function (success, status, sounds, key)

	if not success then

		local server_error = PopupDialog(
			G.STRINGS.UI.BARTERSCREEN.FAILED_TITLE,
			G.STRINGS.UI.BARTERSCREEN.FAILED_BODY, 
			{ {
				text = G.STRINGS.UI.BARTERSCREEN.OK,
				cb = function ()
					print(
						"错误: 无法连接到科雷服务器. 状态码=",
						status
					)
					G.SimReset()
				end
			} }
		)

		G.scheduler:ExecuteInTime(0, function ()
			G.TheFrontEnd:PushScreen(server_error)
		end)

		return

	end

	for _, v in ipairs(sounds) do
		G.TheFrontEnd.gameinterface.SoundEmitter:PlaySound(v)
	end

	local screen = Queuer.getScreen()

	if screen.RefreshInventory then
		Queuer.unravelRefresh(
			screen.subscreener.sub_screens[screen.subscreener.active_key],
			screen,
			key
		)
	elseif screen.doodad_count then
		screen.doodad_count:SetCount(
			G.TheInventory:GetCurrencyAmount(),
			true
		)
	end

end


Queuer.unravelRefresh = function (sub, screen, key)

	local self = sub.picker

	if not self then
		screen:RefreshInventory(true)
		return
	end

	local target = Queuer.findItem(self, key)

	if target and target.owned_count <= 1 then

		local data = Queuer.findItem(self, key)

		if self.scroll_list.context.selection_type then
			self:_SetItemActiveFlag(data, false)
		end

		for i, receiver in ipairs(self.scroll_list.context.input_receivers) do
			if receiver.OnClickedItem then
				receiver:OnClickedItem(data, false)
			end
		end

	end

	screen:RefreshInventory(true)
	self:RefreshItems()

end


Queuer.weaveFn = function (key, val)

	printd(" (分解线轴) 正在购买 "..key.."...")

	G.TheItems:BarterGainItem(
		key,
		val,
		function (success, status)

		G.scheduler:ExecuteInTime(0, function ()
			Queuer.weaveComplete(
				success,
				status,
				{
					"dontstarve/HUD/Together_HUD/collectionscreen/weave",
					"dontstarve/HUD/Together_HUD/collectionscreen/unlock"
				},
				key
			)
			Queuer.onWeave(success, key, val)
		end)

	end)

end


Queuer.onWeave = function (success, key, val)

	if success then
		printd(" (分解线轴) 成功: Bought "..key.." for "..val.." spools")
	else
		printd(" (分解线轴) 错误: 无法分解 "..key)
	end

	Queuer.itemQueueCount[key] = Queuer.itemQueueCount[key] + 1
	Queuer.count = Queuer.count + 1
	Queuer.doQueue()
	Queuer.timetaken = 0

end


Queuer.weaveComplete = function (success, status, sounds, key)

	if not success then

		local server_error = PopupDialog(
			G.STRINGS.UI.BARTERSCREEN.FAILED_TITLE,
			G.STRINGS.UI.BARTERSCREEN.FAILED_BODY, 
			{ {
				text = G.STRINGS.UI.BARTERSCREEN.OK,
				cb = function ()
					print(
						"错误: 无法连接到科雷服务器。 状态码=",
						status
					)
					G.SimReset()
				end
			} }
		)

		G.scheduler:ExecuteInTime(0, function ()
			G.TheFrontEnd:PushScreen(server_error)
		end)

		return

	end

	for _, v in ipairs(sounds) do
		G.TheFrontEnd.gameinterface.SoundEmitter:PlaySound(v)
	end

	local screen = Queuer.getScreen()

	if screen.RefreshInventory then
		Queuer.weaveRefresh(
			screen.subscreener.sub_screens[screen.subscreener.active_key],
			screen,
			key
		)
	elseif screen.doodad_count then
		screen.doodad_count:SetCount(
			G.TheInventory:GetCurrencyAmount(),
			true
		)
	end

end


Queuer.weaveRefresh = function (sub, screen, key)

	local self = sub.picker

	if not self then
		screen:RefreshInventory(true)
		return
	end

	local data = Queuer.findItem(self, key)
	local purchased_widget = data and data.widget or nil

	screen:RefreshInventory(true)
	self:RefreshItems()

	if purchased_widget ~= nil
		and purchased_widget.data.is_owned
		and purchased_widget.PlayUnlock
	then
		purchased_widget:PlayUnlock()
	end

end


Queuer.findItem = function (self, key)

	if not self.scroll_list then
		return
	end

	local items = self.scroll_list.items

	for i = 1, #items do
		if items[i].item_key == key then
			return items[i]
		end
	end

end


Queuer.getScreen = function ()

	if not (G.TheFrontEnd
		and G.TheFrontEnd.screenstack
		and #G.TheFrontEnd.screenstack > 0)
	then
		return {}
	end

	local stack = G.TheFrontEnd.screenstack

	for i = #stack, 1, -1 do
		
		if stack[i].doodad_count then
			return stack[i]
		elseif stack[i].panel
			and stack[i].panel.loadout
			and stack[i].panel.loadout.doodad_count
		then
			return stack[i].panel.loadout
		end
 
	end

	return {}

end


Queuer.getCurrencyAmount = function (amount)

	local doodads = amount or G.TheInventory:GetCurrencyAmount()

	if #Queuer.queue > 0 then
		for i = Queuer.count, #Queuer.queue do
			doodads = doodads
				+ Queuer.queue[i].val
				* (Queuer.queue[i].buy and -1 or 1)
		end
	end

	return doodads

end


------------------------------
---------Dupe Seller----------
------------------------------

DupeSeller.sellAllDupes = function (duplicates)

	local dupes = duplicates or DupeSeller.getAllDupes()

	if #dupes <= 0 then
		printd(" (分解线轴) 你没有任何重复皮肤。")
		return
	end

	for i = 1, #dupes do
		Queuer.addQueue(dupes[i], nil)
	end

end


DupeSeller.getAllDupes = function ()

	local dupes = {}

	for k, v in pairs(G.GetOwnedItemCounts()) do
		if G.TheItems:GetBarterSellPrice(k) > 0
			and unravelByConfig(k)
			and Queuer.getItemCount(k, v) > 1
		then
			for i = 1, (Queuer.getItemCount(k, v) - 1) do
				dupes[#dupes + 1] = k
			end
		end
	end

	return dupes

end


DupeSeller.getDupesTotalWorth = function (duplicates)

	local dupes = duplicates or DupeSeller.getAllDupes()
	local total = 0

	for i = 1, #dupes do
		total = total + G.TheItems:GetBarterSellPrice(dupes[i])
	end

	return total

end
