----------------------------------------------------------------------I-BG----------------------------------------------------------------------------------------
local _G = GLOBAL
local i_bg_flair = "[ Insanity Begone ] " -- Flair
-----------------------
-- *Insanity Begone* --
-----------------------
------------
-- Visual --
------------

-- Insanity & Moon Island Sanity Colour Cube
AddComponentPostInit("playercontroller", function(self, inst)
    if inst ~= _G.ThePlayer then return end
	-- 消除启蒙
	local lunacy_cc = true
	-- 消除黑白
	local insanity_cc = true
    local insanity_channel, lunacy_channel = 1, 2
    local PostProcessor = _G.PostProcessor
    local PostProcessor_mt = _G.getmetatable(PostProcessor)
    local PostProcessorSetColourCubeLerp = PostProcessor_mt.__index.SetColourCubeLerp
    PostProcessor_mt.__index.SetColourCubeLerp = function(self, channel, blend_amount)
        if channel == insanity_channel and insanity_cc then
            blend_amount = 0
        elseif channel == lunacy_channel and lunacy_cc then
            blend_amount = 0
        end
        PostProcessorSetColourCubeLerp(self, channel, blend_amount)
    end
--------
    if insanity_cc then
        PostProcessor:SetDistortionFactor(1)
        PostProcessor_mt.__index.SetDistortionFactor = function() -- Disable Insanity CC
		end
    end
--------
    if lunacy_cc and PostProcessor.SetOverlayBlend then
        PostProcessor:SetOverlayBlend(0)
        PostProcessor_mt.__index.SetOverlayBlend = function() -- Disable Lunacy CC
		end
    end
end)

-- 消除梦魇
local PlayerHud = _G.require("screens/playerhud")
function PlayerHud:GoInsane()
	self:GoSane()
end



local PlayerVision = _G.require("components/playervision")
function PlayerVision:UpdateCCTable()
	local cctable =
		(self.ghostvision and GHOSTVISION_COLOURCUBES)
		or self.overridecctable
		or ((self.nightvision or self.forcenightvision) and NIGHTVISION_COLOURCUBES)
		or (self.nightmarevision and NIGHTMARE_COLORCUBES)
		or nil

	local ccphasefn = 
		(cctable == NIGHTVISION_COLOURCUBES and NIGHTVISION_PHASEFN)
		or (cctable == NIGHTMARE_COLORCUBES and NIGHTMARE_PHASEFN)
		or nil

	if cctable ~= self.currentcctable then
		self.currentcctable = cctable
		self.currentccphasefn = ccphasefn
		self.inst:PushEvent("ccoverrides", cctable)
		self.inst:PushEvent("ccphasefn", ccphasefn)
	end
end


-----------
-- Sound --
-----------


local insanity_vol_lvl = 1.0
local lunacy_vol_lvl = 1.0


-- 消除音效
RemapSoundEvent( "dontstarve/sanity/gonecrazy_stinger", "" )
insanity_vol_lvl = 0.0

-- Ruins Nightmare Ambience
RemapSoundEvent( "dontstarve/cave/nightmare", "" )
RemapSoundEvent( "dontstarve/AMB/caves/nightmare", "" )
lunacy_vol_lvl = 0.0

-- Insanity & Lunacy Ambience Volume
----
AddComponentPostInit("ambientsound", function(self)
    if self.OnUpdate then
		local OnUpdate_old = self.OnUpdate
		self.OnUpdate = function(self, dt, ...)
			OnUpdate_old(self, dt, ...)
			local sanity = _G.ThePlayer ~= nil and _G.ThePlayer.replica.sanity or nil
			local sanityparam = (sanity ~= nil and sanity:IsInsanityMode()) and (1 - sanity:GetPercent()) or 0
			if _G.ThePlayer ~= nil and _G.ThePlayer:HasTag("dappereffects")
			then
				sanityparam = sanityparam * sanityparam
			end
			if sanityparam > insanity_vol_lvl
			then
				sanityparam = insanity_vol_lvl
			end
			self.inst.SoundEmitter:SetParameter("SANITY", "sanity", sanityparam)
			
---------------------------------------

			local sanity = _G.ThePlayer ~= nil and _G.ThePlayer.replica.sanity or nil
			local enlightparam = (sanity ~= nil and sanity:IsLunacyMode()) and (sanity:GetPercent()) or 0
			if _G.ThePlayer ~= nil and _G.ThePlayer:HasTag("dappereffects") 
			then
				enlightparam = enlightparam * enlightparam
			end
			if enlightparam > lunacy_vol_lvl
			then
				enlightparam = lunacy_vol_lvl
			end
			self.inst.SoundEmitter:SetParameter("ENLIGHT", "sanity", enlightparam)
		end
    end
end
)
