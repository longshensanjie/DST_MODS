local Widget = require "widgets/widget"
local ImageButton = require "widgets/imagebutton"
local _S = STRINGS.GARDENEER_CLIENT.MODSTRINGS

local function OnToggleRegister()
	if ThePlayer.HUD.OpenPlantRegistryScreen then
		ThePlayer.HUD:OpenPlantRegistryScreen()
	end
end

local function OnToggleNutrient()
	if ThePlayer.HUD.nutrientsover then
		TheWorld:PushEvent("nutrientsvision",{enabled = not ThePlayer.HUD.nutrientsover.shown})
	end
end

local ButtonRegister = Class(Widget, function(self, display, DEAR_BTNS)
	Widget._ctor(self, "ButtonRegister")
	self.button = self:AddChild(ImageButton("images/registerBTN.xml", "registerBTN.tex", nil, nil, nil, nil, {1,1}, {0,0}))
	self.button:SetOnClick(OnToggleRegister)
	local scale = 64 / math.max(self.button:GetSize())
	self.button:SetScale(scale, scale, scale)
	local w, h = self.button:GetSize()
	self.width = w * scale
	self.height = h * scale
	self.button:SetTooltip(STRINGS.GARDENEER_CLIENT.MODSTRINGS.button_reg)

	if display and DEAR_BTNS then
		DEAR_BTNS:AddDearBtn("images/registerBTN.xml", "registerBTN.tex", "园艺图鉴", STRINGS.GARDENEER_CLIENT.MODSTRINGS.button_reg, false, OnToggleRegister)
	end
end)

local ButtonNutrient = Class(Widget, function(self, display, DEAR_BTNS)
	Widget._ctor(self, "ButtonNutrient")
	self.button = self:AddChild(ImageButton("images/nutrientBTN.xml", "nutrientBTN.tex", nil, nil, nil, nil, {1,1}, {0,0}))
	self.button:SetOnClick(OnToggleNutrient)
	local scale = 64 / math.max(self.button:GetSize())
	self.button:SetScale(scale, scale, scale)
	local w, h = self.button:GetSize()
	self.width = w * scale
	self.height = h * scale
	self.button:SetTooltip(STRINGS.GARDENEER_CLIENT.MODSTRINGS.button_hud)

	if display and DEAR_BTNS then
		DEAR_BTNS:AddDearBtn("images/nutrientBTN.xml", "nutrientBTN.tex", "土地肥度", STRINGS.GARDENEER_CLIENT.MODSTRINGS.button_hud, false, OnToggleNutrient)
	end
end)

local Text = require "widgets/text"
local focus_scale = 1.2
local text_size = 24
local text_x = 0
local text_y = 45

local NutrientDisplay = Class(Widget, function(self)
	Widget._ctor(self, "NutrientDisplay")
	self.button = self:AddChild(ImageButton("images/Empty.xml", "Empty.tex", nil, nil, nil, nil, {1,1}, {0,0}))
	local scale = 64 / math.max(self.button:GetSize())
	self.button:SetScale(scale, scale, scale)
	local w, h = self.button:GetSize()
	self.width = w * scale
	self.height = h * scale
	self.currentTexture = "Empty"


	self.text_upper = self:AddChild(Text(NUMBERFONT,text_size))
	self.text_upper:SetPosition(text_x,text_y)
	self.text_upperPos = self:AddChild(Text(NUMBERFONT,text_size))
	self.text_upperPos:SetPosition(text_x,text_y)
	self.text_upperPos:SetColour(1.0/2,1,1.0/2,1)
	self.text_upperNeg = self:AddChild(Text(NUMBERFONT,text_size))
	self.text_upperNeg:SetPosition(text_x,text_y)
	self.text_upperNeg:SetColour(1,(1.0/3+1.0)/2,1.0/2,1)

	self.text_positive = self:AddChild(Text(NUMBERFONT,text_size))
	self.text_positive:SetColour(0,1,0,1)
	self.text_positive:SetPosition(text_x,text_y + text_size*0.75)

	self.text_negative = self:AddChild(Text(NUMBERFONT,text_size))
	self.text_negative:SetColour(1,1.0/3,0,1)
	self.text_negative:SetPosition(text_x,text_y + text_size*0.75)

	self.text_info = self:AddChild(Text(NUMBERFONT,text_size*focus_scale))
	self.text_info:Hide()

	self:SetOnGainFocus(function() self.text_info:Show() end)
	self:SetOnLoseFocus(function() self.text_info:Hide() end)

	self.inst:DoTaskInTime(0, function()
		-- 如果有玩家 且 玩家HUD有_StatusAnnouncer【说明支持快捷宣告】
		if ThePlayer and ThePlayer.HUD._StatusAnnouncer then
			local oldOnMouseButton = self.button.OnMouseButton
			self.button.OnMouseButton = function(_, button, down)
				-- 如果是左键点击(button==1000 and down) 并且按下检查键(inspect)
				if button == 1000 and down and TheInput:IsControlPressed(CONTROL_FORCE_INSPECT) and ThePlayer.HUD._StatusAnnouncer then
					if self.announceText then
						return ThePlayer.HUD._StatusAnnouncer:Announce(self:GetAnnounce())
					end
				else
					return oldOnMouseButton
				end
			end
		end
	end)

end)

function NutrientDisplay:SetAnnounce(announceText, announceNumber)
	self.announceText = announceText
	self.announceNumber = announceNumber
end

-- Status Announcements, because why not?
function NutrientDisplay:GetAnnounce()
	local num = self.announceNumber and ": "..(self.announceNumber or "") or ""
	return "("..self.widget_name..num..") "..subfmt(STRINGS.GARDENEER_CLIENT.STATUSANNOUNCEMENTS[self.announceText] or "", {FERTILIZER = self.widget_name})
end

function NutrientDisplay:UpdateTextures(newTexture)
	newTexture = newTexture or "Empty"
	if self.button.currentTexture == newTexture then return false end
	self.button:SetTextures("images/"..newTexture..".xml", newTexture..".tex")
	self.button.currentTexture = newTexture
	return true
end

function NutrientDisplay:AddValues(values)
	local Text, posText, negText, endText
	for k,v in pairs(values) do
		Text    = (   Text and    Text.."\n\n" or "")..((type(v)~= "number" or v == 0)and      tostring(v) or " ")
		posText = (posText and posText.."\n\n" or "")..(type(v) == "number" and v > 0 and "+"..tostring(v) or " ")
		negText = (negText and negText.."\n\n" or "")..(type(v) == "number" and v < 0 and      tostring(v) or " ")
		endText = endText and "\n\n"..endText or " "
	end
	if Text then
		self.text_upper:Show()
		self.text_upper:SetString(Text..endText)
		self.text_upperPos:Show()
		self.text_upperPos:SetString(posText..endText)
		self.text_upperNeg:Show()
		self.text_upperNeg:SetString(negText..endText)
	else
		self.text_upper:Hide()
		self.text_upperPos:Hide()
		self.text_upperNeg:Hide()
	end
end

function NutrientDisplay:AddChangeValues(values)
	local posText, negText, endText
	for k,v in pairs(values) do
		posText = (posText and posText.."\n\n" or "")..(v > 0 and "(+"..tostring(v)..")" or "")
		negText = (negText and negText.."\n\n" or "")..(v < 0 and  "("..tostring(v)..")" or "")
		endText =  endText and "\n\n"..endText or " "
	end
	if posText then
		self.text_positive:Show()
		self.text_positive:SetString(posText..endText)
		self.text_negative:Show()
		self.text_negative:SetString(negText..endText)
	else
		self.text_positive:Hide()
		self.text_negative:Hide()
	end
end

function NutrientDisplay:AddKeywords()
	self.text_keywords = self:AddChild(Text(NUMBERFONT,text_size))
	self.text_keywords:SetPosition(text_x-80,text_y)
	self.text_keywords:SetString(_S.balance..":\n\n".._S.total..":\n\n".._S.available..":\n\n\n\n ")
	self.text_keywords:SetHAlign(ANCHOR_RIGHT)
end

function NutrientDisplay:SetName(name)
	self.widget_name = name
	self.text_info:SetString(string.gsub(name or ""," ","\n"))
end

return {ButtonRegister, ButtonNutrient, NutrientDisplay}
