local CookbookPopupScreen = require "screens/cookbookpopupscreen"


if GetModConfigData("sw_cookbook") == "biubiu" then
    DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("cookbook.tex"), "cookbook.tex", "烹饪指南", "打开烹饪指南", false, function()
        TheFrontEnd:PushScreen(CookbookPopupScreen(GLOBAL.ThePlayer))
    end)
end

AddBindBtn("sw_cookbook", function()
    local name_active = TheFrontEnd:GetActiveScreen().name
    if name_active == "CookbookPopupScreen" then
        TheFrontEnd:PopScreen()
    else
        TheFrontEnd:PushScreen(CookbookPopupScreen(GLOBAL.ThePlayer))
    end
end)
