local modoptions = {
	format = "%Y/%m/%d %H:%M:%S",
	log_menugift = true
}
local MODROOT = MODROOT
local modinfo = modinfo
local LOL = {
	DAILY_GIFT = "每日礼物",
	DEFAULT = "感谢赏玩", 
	TWITCH_DROP = "直播掉落", 
	YOTP = "猪王之年", 
	YOTB = "皮弗牛娄之年", 
	LUNAR = "火鸡之年", 
	VARG = "座狼之年", 
	ANRARG = "远古手杖和箱子", 
	ARG = "远古火炬", 
	CUPID = "情人节", 
	ONI = "缺氧", 
	WINTER = "冬季盛宴", 
	ROT2 = "贝壳鱼类", 
	TOT = "改潮换代", 
	HAMLET = "哈姆雷特", 
	HOTLAVA = "炽热熔岩", 
	ROG = "巨人国赏玩", 
	ROGR = "巨人国购买", 
	SW = "海难赏玩", 
	SWR = "海难购买", 
	GORGE = "暴食", 
	GORGE_TOURNAMENT = "暴食锦标赛", 
	STORE = "商店购买", 
}
local mods = GLOBAL.rawget(_G, "mods")
if not mods then
	mods = {}
	GLOBAL.rawset(_G, "mods", mods)
end

if mods.open_skins then
	return
end

mods.open_skins = {
	root = MODROOT,
	name = modinfo.name,
	version = modinfo.version,
	strings = (
		{
			WARNING = "警告！",
			UPDATE_BODY = "你需要更新"..modinfo.name.."!最新版本:",
			UPDATE = "更新!",
			history = "历史皮肤数据",
			clear = "清空",
			clear_title = "清空皮肤数据?",
			clear_body = "确定要删除保存的皮肤数据吗?",
			write_fail_title = "存储文件错误",
			write_fail_body = "存储皮肤数据失败。请检查你的游戏文件和存储设置。",
			no_items = "你没有任何皮肤数据",
		}
	),
}

GLOBAL.require "skin_saver"

AddGamePostInit(function ()
	GLOBAL.scheduler:ExecuteInTime(GLOBAL.FRAMES, function() SkinSaver:LoadData() end)
end)

if GetModConfigData("sw_skinHistory") ~= "leavemealone" then
	AddGamePostInit(function()
		local updateskins = GLOBAL.scheduler:ExecutePeriodic(GLOBAL.FRAMES, function()
			local inst = GLOBAL.TheGlobalInstance
			if not inst then
				return
			end

			local unopened = #GLOBAL.TheInventory:GetUnopenedItems()
			if unopened > 0 then
				inst:PushEvent("gift_recieved")
			end
		end)

	end)

	
	AddClassPostConstruct("widgets/controls", function(self)
		if self.item_notification then
			self.item_notification:Hide()
		end
	end)
end


local TEMPLATES = GLOBAL.require "widgets/redux/templates"
local SkinsHistory = GLOBAL.require "screens/skinshistory"
local function lockOnclick()
	GLOBAL.TheFrontEnd:PushScreen(SkinsHistory(modoptions))
end

-- 收藏页面添加按钮
AddClassPostConstruct("screens/redux/playersummaryscreen", function(self)
	self.skin_history = self.bottom_root:AddChild(TEMPLATES.StandardButton(lockOnclick, mods.open_skins.strings.history, {225, 40}))
	self.skin_history:SetPosition(-300, 10)
end)

DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("researchlab2_pod.tex"), "researchlab2_pod.tex", "历史皮肤", "查看已经保存的皮肤数据【现在支持快捷宣告！】", true, lockOnclick)

AddGlobalClassPostConstruct("frontend", "FrontEnd", function(self)
	local Widget = require "widgets/widget"
	local GiftItemToast = require "widgets/giftitemtoast_fox"

	if not self.fixoverlay then
		self.fixoverlay = self.overlayroot:AddChild(Widget(""))
		self.fixoverlay:SetVAnchor(GLOBAL.ANCHOR_MIDDLE)
		self.fixoverlay:SetHAnchor(GLOBAL.ANCHOR_MIDDLE)
		self.fixoverlay:SetScaleMode(GLOBAL.SCALEMODE_PROPORTIONAL)
	end

	self.skinopen = self.fixoverlay:AddChild(GiftItemToast())
	self.skinopen:SetPosition(-450, 250)
end)



-- 统计皮肤
AddClassPostConstruct("screens/thankyoupopup", function(self)
	local _OpenGift = self.OpenGift
	function self:OpenGift(...)
		local skin = self.items[self.current_item]
		if skin 
		-- and skin.item_id ~= 0 				-- 允许每日皮肤
		 then
			-- printwrap("skin", skin)	
			-- if skin.item_id == 0 and skin.gifttype == "DAILY_GIFT"	
			if modoptions.log_menugift then
				if LOL and LOL[skin.gifttype] then
					SkinSaver:AddSkin(skin.item, skin.item_id, LOL[skin.gifttype])
				else
					if skin.gifttype and type(skin.gifttype)=="string" then
						SkinSaver:AddSkin(skin.item, skin.item_id, skin.gifttype)
					else
						SkinSaver:AddSkin(skin.item, skin.item_id, "每周礼物")
					end
				end
			end
		end
		return _OpenGift(self, ...)
	end
end)
