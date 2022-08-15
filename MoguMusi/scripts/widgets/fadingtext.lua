local Widget = require("widgets/widget")
local Text = require("widgets/text")

local FadingText = Class(Widget, function(self, text)
    Widget._ctor(self, "FadingText")

	self.text = self:AddChild(Text(BODYTEXTFONT, STATDISPLAY_FONTSIZE or 33, text))
	self.currentpos = 0
	
	self:StartUpdating()
end)

function FadingText:OnUpdate(dt)
	self.currentpos = self.currentpos + (10*dt)
	local pos = self.text:GetPosition()
	self.text:SetPosition(0, pos.y+(10*dt))
	
	if self.currentpos > 10 then
		local newalpha = 1-((self.currentpos-10)/10)
		self.text:SetColour(1,1,1, newalpha )
		if newalpha <= 0 then
			self:Kill()
		end
	end
end

return FadingText