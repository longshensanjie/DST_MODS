local function fn()
    GLOBAL.TheNet:SendSlashCmdToServer("rescue")
end

if GetModConfigData("sw_rescue") == "biubiu" then

DEAR_BTNS:AddDearBtn(GLOBAL.GetInventoryItemAtlas("unknown_hand.tex"), "unknown_hand.tex", "发送Rescue", "地下卡虚空用, 相当于打出 /rescue 或 /救命", true, fn)
end


AddBindBtn("sw_rescue", fn)

