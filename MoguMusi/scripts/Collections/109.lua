if GetModConfigData("sw_huazhi") == "justcomfort" then return end

AddClassPostConstruct("screens/playerhud", function(self)
	local _CreateOverlays = self.CreateOverlays
	self.CreateOverlays = function(self, owner, ...)
		_CreateOverlays(self, owner, ...)
		self.vig:GetAnimState():OverrideSymbol("vigpaint", "hx_trans", "hx_trans")
		-- self.vig:GetAnimState():SetDeltaTimeMultiplier(2) -- Insanity veins anim look smoother
	end
end)