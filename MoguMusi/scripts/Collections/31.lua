GLOBAL.Profile:SetDistortionEnabled(false)


AddGamePostInit(function()
	local PostProcessor = GLOBAL.PostProcessor
	local PostProcessor_metatable = GLOBAL.getmetatable(PostProcessor)
	if PostProcessor_metatable
	then
		local NullFunction = function() end
		local PostProcessor_metatableindex = PostProcessor_metatable.__index or {}
		local CheckForMore = {
			SetDistortionFactor = true,
			SetDistortionRadii = true,
			SetColourModifier = true,
			SetColourCubeLerp = true,
			SetColourCubeData = true,
			SetEffectTime = true,
		}
		for k,_ in pairs(PostProcessor_metatableindex)
		do
			if CheckForMore[k] == nil
			then
				GLOBAL.print("WARN: PostProcessor function", k, "is not being disabled!")
			end
		end
		for k,_ in pairs(CheckForMore)
		do
			if PostProcessor_metatableindex[k] == nil
			then
				GLOBAL.print("WARN: PostProcessor function", k, "is no longer defined!")
				PostProcessor_metatableindex[k] = NullFunction
			end
		end
		
		PostProcessor_metatableindex.SetDistortionFactor(PostProcessor, 0)--失真系数
		PostProcessor_metatableindex.SetDistortionRadii(PostProcessor, 0.5, 0.685)--失真半径
		PostProcessor_metatableindex.SetColourModifier(PostProcessor, 1.4)--对比度
		PostProcessor_metatableindex.SetColourCubeLerp(PostProcessor, 0, 100)--颜色立方体
		PostProcessor_metatableindex.SetColourCubeLerp(PostProcessor, 1, 0)
		local IDENTITY_COLOURCUBE = "images/colour_cubes/identity_colourcube.tex"
		PostProcessor_metatableindex.SetColourCubeData(PostProcessor, 0, IDENTITY_COLOURCUBE, IDENTITY_COLOURCUBE)
		PostProcessor_metatableindex.SetColourCubeData(PostProcessor, 1, IDENTITY_COLOURCUBE, IDENTITY_COLOURCUBE)
		PostProcessor_metatableindex.SetEffectTime(PostProcessor, 0)
		
		PostProcessor_metatableindex.SetDistortionFactor = NullFunction
		PostProcessor_metatableindex.SetDistortionRadii = NullFunction
		PostProcessor_metatableindex.SetColourModifier = NullFunction
		PostProcessor_metatableindex.SetColourCubeLerp = NullFunction
		PostProcessor_metatableindex.SetColourCubeData = NullFunction
		PostProcessor_metatableindex.SetEffectTime = NullFunction
	end
end)
