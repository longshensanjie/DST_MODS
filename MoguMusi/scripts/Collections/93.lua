GLOBAL.Profile:SetDistortionEnabled(false)
GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})

STRINGS.PXL_42_RADJUSTMENTS = {}

STRINGS.PXL_42_RADJUSTMENTS.APPLY = "应用"
STRINGS.PXL_42_RADJUSTMENTS.BACK = "返回"
STRINGS.PXL_42_RADJUSTMENTS.BACKTITLE = "放弃更改"
STRINGS.PXL_42_RADJUSTMENTS.BACKBODY = "要放弃更改吗？"
STRINGS.PXL_42_RADJUSTMENTS.YES = "是"
STRINGS.PXL_42_RADJUSTMENTS.NO = "否"
STRINGS.PXL_42_RADJUSTMENTS.BASICSETTINGS = "基本设置"
STRINGS.PXL_42_RADJUSTMENTS.COLOURCUBE = "游戏原版滤镜"
STRINGS.PXL_42_RADJUSTMENTS.ENABLED = "开启"
STRINGS.PXL_42_RADJUSTMENTS.DISABLED = "关闭"
STRINGS.PXL_42_RADJUSTMENTS.LIGHTNESSANDCONTRAST = "亮度/对比度"
STRINGS.PXL_42_RADJUSTMENTS.LIGHTNESS = "亮度"
STRINGS.PXL_42_RADJUSTMENTS.CONTRAST = "对比度"
STRINGS.PXL_42_RADJUSTMENTS.HUEANDSATURATION = "色相/饱和度"
STRINGS.PXL_42_RADJUSTMENTS.HUE = "色相"
STRINGS.PXL_42_RADJUSTMENTS.SATURATION = "饱和度"
STRINGS.PXL_42_RADJUSTMENTS.VALUE = "明度"
STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE = "色彩平衡"
STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_CRS = "青-红[阴影]"
STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_MGS = "洋红-绿[阴影]"
STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_YBS = "黄-蓝[阴影]"
STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_CRM = "青-红[中间调]"
STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_MGM = "洋红-绿[中间调]"
STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_YBM = "黄-蓝[中间调]"
STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_CRH = "青-红[高光]"
STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_MGH = "洋红-绿[高光]"
STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_YBH = "黄-蓝[高光]"

local function IsHUDScreen()
	local defaultscreen = false
	if TheFrontEnd and TheFrontEnd:GetActiveScreen() and TheFrontEnd:GetActiveScreen().name and type(TheFrontEnd:GetActiveScreen().name) == "string" and (TheFrontEnd:GetActiveScreen().name == "HUD" or TheFrontEnd:GetActiveScreen().name == "Pxl_42_Color_Adjustments") then
		defaultscreen = true
	end
	return defaultscreen
end

AddModShadersInit(function()
	-- if not IsHUDScreen() then return end
	PostProcessorEffects.PXL_42_COLOR = PostProcessor:AddPostProcessEffect(resolvefilepath("shaders/pxl_42_color.ksh"))
	UniformVariables.PXL_42_LIGHTNESS = PostProcessor:AddUniformVariable("PXL_42_LIGHTNESS", 1)
	UniformVariables.PXL_42_CONTRAST = PostProcessor:AddUniformVariable("PXL_42_CONTRAST", 1)
	UniformVariables.PXL_42_COLOR_BALANCE_SHADOW = PostProcessor:AddUniformVariable("PXL_42_COLOR_BALANCE_SHADOW", 3)
	UniformVariables.PXL_42_COLOR_BALANCE_MIDTONES = PostProcessor:AddUniformVariable("PXL_42_COLOR_BALANCE_MIDTONES", 3)
	UniformVariables.PXL_42_COLOR_BALANCE_HIGHLIGHTS = PostProcessor:AddUniformVariable("PXL_42_COLOR_BALANCE_HIGHLIGHTS", 3)
	UniformVariables.PXL_42_HUE = PostProcessor:AddUniformVariable("PXL_42_HUE", 1)
	UniformVariables.PXL_42_SATURATION = PostProcessor:AddUniformVariable("PXL_42_SATURATION", 1)
	UniformVariables.PXL_42_VALUE = PostProcessor:AddUniformVariable("PXL_42_VALUE", 1)
	PostProcessor:SetUniformVariable(UniformVariables.PXL_42_LIGHTNESS, 0)
	PostProcessor:SetUniformVariable(UniformVariables.PXL_42_CONTRAST, 1)
	PostProcessor:SetUniformVariable(UniformVariables.PXL_42_COLOR_BALANCE_SHADOW, 0, 0, 0)
	PostProcessor:SetUniformVariable(UniformVariables.PXL_42_COLOR_BALANCE_MIDTONES, 0, 0, 0)
	PostProcessor:SetUniformVariable(UniformVariables.PXL_42_COLOR_BALANCE_HIGHLIGHTS, 0, 0, 0)
	PostProcessor:SetUniformVariable(UniformVariables.PXL_42_HUE, 0)
	PostProcessor:SetUniformVariable(UniformVariables.PXL_42_SATURATION, 1)
	PostProcessor:SetUniformVariable(UniformVariables.PXL_42_VALUE, 1)
	PostProcessor:SetEffectUniformVariables(
		PostProcessorEffects.PXL_42_COLOR,
		UniformVariables.PXL_42_LIGHTNESS,
		UniformVariables.PXL_42_CONTRAST,
		UniformVariables.PXL_42_COLOR_BALANCE_SHADOW,
		UniformVariables.PXL_42_COLOR_BALANCE_MIDTONES,
		UniformVariables.PXL_42_COLOR_BALANCE_HIGHLIGHTS,
		UniformVariables.PXL_42_HUE,
		UniformVariables.PXL_42_SATURATION,
		UniformVariables.PXL_42_VALUE
	)

	UniformVariables.PXL_42_OVERRIDECC_LAYER_PARAMS = PostProcessor:AddUniformVariable("PXL_42_OVERRIDECC_LAYER_PARAMS", 1)
end)

local flag = false

AddPlayerPostInit(function()
	if flag then return end
	flag = true
	PostProcessor:SetPostProcessEffectAfter(PostProcessorEffects.PXL_42_COLOR, PostProcessorEffects.Lunacy)
	PostProcessor:EnablePostProcessEffect(PostProcessorEffects.PXL_42_COLOR, true)
	--UniformVariables.CC_LAYER_PARAMS = UniformVariables.PXL_42_OVERRIDECC_LAYER_PARAMS

	local options = require "pxl_42_coloradjustment_options"

	for k, v in pairs(options) do
        if v.uniformvariable then
            if v.uniformvariable.num then
                if v.uniformvariable.num == 1 then
                    PostProcessor:SetUniformVariable(UniformVariables[v.uniformvariable.name], v.value)
                elseif v.uniformvariable.num == 2 then
                    PostProcessor:SetUniformVariable(UniformVariables[v.uniformvariable.name], nil, v.value)
                else
                    PostProcessor:SetUniformVariable(UniformVariables[v.uniformvariable.name], nil, nil, v.value)
                end
            end
        end
        if v.spin_options then
            PostProcessor:EnablePostProcessEffect(PostProcessorEffects[v.effect], v.value)
        end
    end
end)



local Pxl_42_Color_Adjustments = require "screens/pxl_42_coloradjustments"

AddClassPostConstruct("screens/playerhud", function(self)
	function self:OpenPxl_42_Color_AdjustmentsScreen()
		TheCamera:PopScreenHOffset(self)

		if self.pxl_42_coloradjustmentspopup ~= nil then
			TheFrontEnd:PopScreen(self.pxl_42_coloradjustmentspopup)
		end

		self.pxl_42_coloradjustmentspopup = Pxl_42_Color_Adjustments()

		self:OpenScreenUnderPause(self.pxl_42_coloradjustmentspopup)
		return true
	end
	function self:ClosePxl_42_Color_AdjustmentsScreen()
		TheCamera:PopScreenHOffset(self)

		if self.pxl_42_coloradjustmentspopup ~= nil then
			TheFrontEnd:PopScreen(self.pxl_42_coloradjustmentspopup)
			self.pxl_42_coloradjustmentspopup = nil
		end
	end
	local function fn()
		if IsHUDScreen() then
			if TheFrontEnd and TheFrontEnd:GetActiveScreen() and TheFrontEnd:GetActiveScreen().name == "Pxl_42_Color_Adjustments" then
				self:ClosePxl_42_Color_AdjustmentsScreen()
			else
				self:OpenPxl_42_Color_AdjustmentsScreen()
			end
		end
	end


	if GetModConfigData("sw_color") == "biubiu" then
		DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("opalpreciousgem.tex"), "opalpreciousgem.tex", "色彩调节", "自定义你的滤镜", true, fn)
	end
		
	AddBindBtn("sw_color", fn)
end)