local key_board = GetModConfigData("sw_mainboard")
if not key_board then return end
local key_strange = GetModConfigData("sw_debugger") == "shutup"

local TEMPLATES = require "widgets/redux/templates"
local Mainboard = require "widgets/huxi_window"
local TextBtn = require "widgets/textbutton"
local ImageButton = require "widgets/imagebutton"

local POSDATA = "Pos"		-- 存储四个数据 位置(X,Y), 贴图(altas,tex)
local TEXDATA = "Tex"
local SaveSHide = "butterfly"
local SHide = false

local function ViewLicon()
	if InGame() and GLOBAL.ThePlayer.HUD.controls and GLOBAL.ThePlayer.HUD.controls.lIcon then
		if SHide then
			GLOBAL.ThePlayer.HUD.controls.lIcon:Hide()
		else
			GLOBAL.ThePlayer.HUD.controls.lIcon:Show()
		end
	end
end

DEAR_BTNS:AddDearBtn("modicon.xml", "modicon.tex", "蓝蝴蝶", "重置你的图标设置并关闭面板", true, function()
	if InGame() and GLOBAL.ThePlayer.HUD.controls and GLOBAL.ThePlayer.HUD.controls.lIcon then
		local img = GLOBAL.ThePlayer.HUD.controls.lIcon
		local screen_w, screen_h = GLOBAL.TheSim:GetScreenSize()
		local D_x,D_y,D_altas,D_tex= screen_w*1750/1920,screen_h*50/1080,"modicon.xml","modicon.tex"
		img:SetVAnchor(GLOBAL.ANCHOR_BOTTOM)    --设置原点到屏幕下方
		img:SetHAnchor(GLOBAL.ANCHOR_LEFT)        --设置原点到屏幕左方，综合起来就是左下方
		img:SetPosition(D_x, D_y)
		img:SetTextures(D_altas, D_tex)
		local sizeX, sizeY = img:GetSize()
		local trans_scale = math.min(100 / sizeX, 100 / sizeY)
		img:SetNormalScale(trans_scale)
		img:SetFocusScale(trans_scale * 1.2)
		SaveModData(TEXDATA, {
            altas = D_altas,
            tex = D_tex,
        })
		SaveModData(POSDATA, {
            posX = D_x,
            posY = D_y,
        })

		if GLOBAL.TheInput:IsKeyDown(GLOBAL.KEY_LALT) then
			SHide = true
			TIP("图标隐藏", "green", SHide)
			ViewLicon()
			SaveModData(SaveSHide, SHide)
		else
			SHide = false
			ViewLicon()
			SaveModData(SaveSHide, SHide)
		end
	end
end)

AddClassPostConstruct("widgets/controls", function(self)
	local function ToggleShowBoard()
		if InGame() and self.mainboard then
			if self.mainboard:IsVisible() then
				self.mainboard:CloseIt()
			else
				self.mainboard:ShowIt()
			end 
		end
	end
	-- 按钮
	local texdata = LoadModData(TEXDATA)
	local posdata = LoadModData(POSDATA)
	SHide = LoadModData(SaveSHide)
	local length_img = 70
	local tex = texdata and texdata.tex or "modicon.tex"
	local altas = texdata and texdata.altas or "modicon.xml"
	local screen_w, screen_h = GLOBAL.TheSim:GetScreenSize()
	local D_x,D_y= screen_w*1750/1920,screen_h*50/1080
	local posX = posdata and posdata.posX or D_x
	local posY = posdata and posdata.posY or D_y
	-- 随机图标
	local function SetFixedImg(img, length_img, tex, altas)
		if not altas then
			altas = GLOBAL.GetInventoryItemAtlas(tex)
		end
		img:SetTextures(altas, tex)
		local sizeX, sizeY = img:GetSize()
		local trans_scale = math.min(length_img / sizeX, length_img / sizeY)
		img:SetNormalScale(trans_scale)
		img:SetFocusScale(trans_scale * 1.2)
		
		SaveModData(TEXDATA, {
			altas = altas,
			tex = tex,
		})
	end
	local function GetRandomImg()
		if GLOBAL.PREFAB_SKINS then
			local filters = GLOBAL.GetRandomItem(PREFAB_SKINS)
			if type(filters) == "table" then
				local tex = GLOBAL.GetRandomItem(filters)
				if type(tex) == "string" then
					tex = tex..".tex"
					local atlas = GLOBAL.GetInventoryItemAtlas(tex)
					if atlas and GLOBAL.TheSim:AtlasContains(atlas, tex) then
						return tex
					end
				end
			end
		end
	end
	local function SetRandomImg(img, oldtex)
		local flag = true
		local newtex
		while flag do
			newtex = GetRandomImg()
			if newtex and newtex ~= oldtex then
				flag = false
			end
		end
		SetFixedImg(img, length_img, newtex)
	end
	local function GetPosStr()
		local x, _, z = GLOBAL.ThePlayer.Transform:GetWorldPosition()
		return "我的坐标: ("..string.format("%.2f", x).." , "..string.format("%.2f",z)..")"
	end

	local img = self:AddChild(ImageButton())
	SetFixedImg(img, length_img, tex, altas)
	self.lIcon = self.sidepanel:AddChild(img)
	self.lIcon:SetVAnchor(ANCHOR_BOTTOM)    --设置原点到屏幕下方
	self.lIcon:SetHAnchor(ANCHOR_LEFT)        --设置原点到屏幕左方，综合起来就是左下方
	self.lIcon:SetPosition(posX, posY)
	-- 这是种糟糕的写法，暂时没啥好的写法，鸽了
	self.lIcon:SetTooltip(GLOBAL.STRINGS.RMB.."刷新\n"..GLOBAL.TheInput:GetLocalizedControl(GLOBAL.TheInput:GetControllerID(), 61).."拖拽")
	-- 鼠标跟随
	if not key_strange then
		self.lIcon.OnMouseButton = function(_self, button, down, x, y)    --注意:此处应将self.drag_button替换为你要拖拽的widget
			if button == GLOBAL.MOUSEBUTTON_MIDDLE and down then    --鼠标中键按下
				_self.draging = true    --标志这个widget正在被拖拽，不需要可以删掉
				_self:StartFollowMouse()     --开启控件的鼠标跟随
			elseif button == GLOBAL.MOUSEBUTTON_MIDDLE then            --鼠标中键抬起
				_self.draging = false        --标志这个widget没有被拖拽，不需要可以删掉
				_self:StopFollowMouse()        --停止控件的跟随
				-- print("退出拖拽")
				SaveModData(POSDATA, {
					posX = x,
					posY = y,
				})
			end

			if down and GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_FORCE_INSPECT) and GLOBAL.ThePlayer.HUD._StatusAnnouncer then
				if button == GLOBAL.MOUSEBUTTON_LEFT then
					GLOBAL.ThePlayer.HUD._StatusAnnouncer:Announce(os.date("今天是 %Y年%m月%d日, 当前时间 %H:%M:%S ") )
				elseif button == GLOBAL.MOUSEBUTTON_RIGHT then 
					GLOBAL.ThePlayer.HUD._StatusAnnouncer:Announce(GetPosStr())
				end
			end
		end
	end
	img.OnControl = LROnControl
    img:SetOnClick(function(lmb)
		if lmb then ToggleShowBoard() else SetRandomImg(img, tex) end
	end)
	img:MoveToFront()
	if SHide then
		img:Hide()
	else
		img:Show()
	end

	-- mainboard
    self.mainboard = self:AddChild(Mainboard(DEAR_BTNS:GetBtns()))

	AddBindBtn("sw_mainboard", ToggleShowBoard)
end)
