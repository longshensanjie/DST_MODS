local G = GLOBAL
G.STATDISPLAY_FONTSIZE = 33
local function round(num)
	return math.ceil(num)
end
local offset = {x=0, y=20, z=0}
AddClassPostConstruct("widgets/statusdisplays", function(self)
	local FadingText = G.require("widgets/fadingtext")
	
	local old_healthdelta = self.HealthDelta
	local old_hungerdelta = self.HungerDelta
	local old_sanitydelta = self.SanityDelta
	-- 增加大力士的健身值变化
	local old_MightinessDelta = self.MightinessDelta

	function self:MightinessDelta(data, ...)
		if data and not data.overtime then
			local maxhealth = G.TUNING.MIGHTINESS_MAX
			local delta = round((data.newpercent*maxhealth)-(data.oldpercent*maxhealth))
			local str = tostring(delta)
			if delta > 0 then str = "+"..str end
			local text = self:AddChild(FadingText(str))
			local pos = self.mightybadge:GetPosition()
			text:SetPosition(pos.x+offset.x, pos.y+offset.y, pos.z+offset.z)
		end
		old_MightinessDelta(self, data, ...)
	end
	
	function self:HealthDelta(data, ...)
		if data and not data.overtime then
			local maxhealth = self.owner.replica.health:Max()
			local delta = round((data.newpercent*maxhealth)-(data.oldpercent*maxhealth))
			local str = tostring(delta)
			if delta > 0 then str = "+"..str end
			local text = self:AddChild(FadingText(str))
			local pos = self.heart:GetPosition()
			text:SetPosition(pos.x+offset.x, pos.y+offset.y, pos.z+offset.z)
		end
		old_healthdelta(self, data, ...)
	end
	
	function self:HungerDelta(data, ...)
		if data and not data.overtime then
			local maxhealth = self.owner.replica.hunger:Max()
			local delta = round((data.newpercent*maxhealth)-(data.oldpercent*maxhealth))
			local str = tostring(delta)
			if delta > 0 then str = "+"..str end
			local text = self:AddChild(FadingText(str))
			local pos = self.stomach:GetPosition()
			text:SetPosition(pos.x+offset.x, pos.y+offset.y, pos.z+offset.z)
		end
		old_hungerdelta(self, data, ...)
	end
	
	function self:SanityDelta(data, ...)
		if data and not data.overtime then
			local maxhealth = self.owner.replica.sanity:Max()
			local delta = round((data.newpercent*maxhealth)-(data.oldpercent*maxhealth))
			local str = tostring(delta)
			if delta > 0 then str = "+"..str end
			local text = self:AddChild(FadingText(str))
			local pos = self.brain:GetPosition()
			text:SetPosition(pos.x+offset.x, pos.y+offset.y, pos.z+offset.z)
		end
		old_sanitydelta(self, data, ...)
	end
	
	self.sanity_history = {}
	if self.owner ~= nil and self.owner.replica.sanit ~= nil then
		self.owner:DoPeriodicTask(1, function(inst)
			if #self.sanity_history >= 60 then
				table.remove(self.sanity_history, 1)
			end
			local sanity = self.owner.replica.sanity:GetCurrent()
			table.insert(self.sanity_history, sanity)
		end)
	end
	function self:GetPerMinuteSanityRate()
		return (self.sanity_history[#self.sanity_history] - self.sanity_history[1])/60
	end
	function self:GetPerSecondSanityRate()
		return self.sanity_history[#self.sanity_history] - self.sanity_history[#self.sanity_history-1]
	end
end)