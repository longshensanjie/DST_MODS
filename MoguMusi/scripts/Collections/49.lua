local function Test(self)

	self.UpdateCaveClock = function(self)
	
	
		------------start--------------
		if self._lastsinkhole ~= nil and
			self._lastsinkhole:IsValid() and
			self._lastsinkhole.Light:IsEnabled() and
			self._lastsinkhole:IsNear(owner, CalculateLightRange(self._lastsinkhole.Light, self._caveopen)) then
			-- Still near last found sinkhole, can skip FineEntity =)
			self:OpenCaveClock()
			return
		end

		self._lastsinkhole = GLOBAL.FindEntity(owner, 20, function(guy) return guy:IsNear(owner, CalculateLightRange(guy.Light, self._caveopen)) end, { "sinkhole", "lightsource" })

		if self._lastsinkhole ~= nil then
			self:OpenCaveClock()
		--else
			--self:CloseCaveClock()
		end
		
		---------end-----------------------------------------
		
	end

end



AddClassPostConstruct("widgets/uiclock", Test)