require "util"

local options = {
    {
        label = STRINGS.PXL_42_RADJUSTMENTS.BASICSETTINGS,
        is_header = true,
    },
    {
        key = "colourcube",
        label = STRINGS.PXL_42_RADJUSTMENTS.COLOURCUBE,
        spin_options = {
            {text = STRINGS.PXL_42_RADJUSTMENTS.ENABLED, data = true},
            {text = STRINGS.PXL_42_RADJUSTMENTS.DISABLED, data = false},
        },
        effect = "ColourCube",
        default = false,
        value = true,
    },
    {
        label = STRINGS.PXL_42_RADJUSTMENTS.LIGHTNESSANDCONTRAST,
        is_header = true,
    },
    {
        key = "lightness",
        label = STRINGS.PXL_42_RADJUSTMENTS.LIGHTNESS,
        uniformvariable = {
            name = "PXL_42_LIGHTNESS",
            num = 1,
        },
        max = 1,
        min = -1,
        default = 0,
        value = 0,
    },
    {
        key = "contrast",
        label = STRINGS.PXL_42_RADJUSTMENTS.CONTRAST,
        uniformvariable = {
            name = "PXL_42_CONTRAST",
            num = 1,
        },
        max = 2,
        min = 0,
        default = 1,
        value = 1,
    },
    {
        label = STRINGS.PXL_42_RADJUSTMENTS.HUEANDSATURATION,
        is_header = true,
    },
    {
        key = "hue",
        label = STRINGS.PXL_42_RADJUSTMENTS.HUE,
        uniformvariable = {
            name = "PXL_42_HUE",
            num = 1,
        },
        max = 1,
        min = 0,
        default = 0,
        value = 0,
    },
    {
        key = "saturation",
        label = STRINGS.PXL_42_RADJUSTMENTS.SATURATION,
        uniformvariable = {
            name = "PXL_42_SATURATION",
            num = 1,
        },
        max = 2,
        min = 0,
        default = 1,
        value = 1,
    },
    {
        key = "value",
        label = STRINGS.PXL_42_RADJUSTMENTS.VALUE,
        uniformvariable = {
            name = "PXL_42_VALUE",
            num = 1,
        },
        max = 2,
        min = 0,
        default = 1,
        value = 1,
    },
    {
        label = STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE,
        is_header = true,
    },
    {
        key = "cb_c_r_shadow",
        label = STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_CRS,
        uniformvariable = {
            name = "PXL_42_COLOR_BALANCE_SHADOW",
            num = 1,
        },
        max = 100,
        min = -100,
        default = 0,
        value = 0,
    },
    {
        key = "cb_m_g_shadow",
        label = STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_MGS,
        uniformvariable = {
            name = "PXL_42_COLOR_BALANCE_SHADOW",
            num = 2,
        },
        max = 100,
        min = -100,
        default = 0,
        value = 0,
    },
    {
        key = "cb_y_b_shadow",
        label = STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_YBS,
        uniformvariable = {
            name = "PXL_42_COLOR_BALANCE_SHADOW",
            num = 3,
        },
        max = 100,
        min = -100,
        default = 0,
        value = 0,
    },
    {
        key = "cb_c_r_midtones",
        label = STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_CRM,
        uniformvariable = {
            name = "PXL_42_COLOR_BALANCE_MIDTONES",
            num = 1,
        },
        max = 100,
        min = -100,
        default = 0,
        value = 0,
    },
    {
        key = "cb_m_g_midtones",
        label = STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_MGM,
        uniformvariable = {
            name = "PXL_42_COLOR_BALANCE_MIDTONES",
            num = 2,
        },
        max = 100,
        min = -100,
        default = 0,
        value = 0,
    },
    {
        key = "cb_y_b_midtones",
        label = STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_YBM,
        uniformvariable = {
            name = "PXL_42_COLOR_BALANCE_MIDTONES",
            num = 3,
        },
        max = 100,
        min = -100,
        default = 0,
        value = 0,
    },
    {
        key = "cb_c_r_highlights",
        label = STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_CRH,
        uniformvariable = {
            name = "PXL_42_COLOR_BALANCE_HIGHLIGHTS",
            num = 1,
        },
        max = 100,
        min = -100,
        default = 0,
        value = 0,
    },
    {
        key = "cb_m_g_highlights",
        label = STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_MGH,
        uniformvariable = {
            name = "PXL_42_COLOR_BALANCE_HIGHLIGHTS",
            num = 2,
        },
        max = 100,
        min = -100,
        default = 0,
        value = 0,
    },
    {
        key = "cb_y_b_highlights",
        label = STRINGS.PXL_42_RADJUSTMENTS.COLORBALANCE_YBH,
        uniformvariable = {
            name = "PXL_42_COLOR_BALANCE_HIGHLIGHTS",
            num = 3,
        },
        max = 100,
        min = -100,
        default = 0,
        value = 0,
    },
}

local function getoptions()
    local settings = {}
    TheSim:GetPersistentString("pxl_42_coloradjustments",
    function(load_success, str)
        if load_success then
            if str ~= nil and string.len(str) > 0 then
                settings = TrackedAssert("TheSim:GetPersistentString pxl_42_coloradjustments", json.decode, str)
                if settings then
                    for k, v in pairs(options) do
                        if v.key and settings[v.key] ~= nil then
                            v.value = settings[v.key]
                        end
                    end
                end
            end
        end
    end)
    return options
end

return getoptions()