if GetModConfigData("sw_peopleNum")==6 then
    return
else
    TUNING.MAX_SERVER_SIZE = GetModConfigData("sw_peopleNum")
end