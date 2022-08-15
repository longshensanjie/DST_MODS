--[[
    	dictionary.GetDisplayString = 
        dictionary.GetDisplayString or function(word) return dictionary.delim .. word .. dictionary.postfix end
]]
--symb和obj_swap_symbol通用的
local symbol={
    {
        width = 350,
        mode=Profile:GetChatAutocompleteMode()
    },
    {
        words = {
            "hat","object","body"
        },
        delim = "swap_",--前缀
        num_chars = 0,--数量
        -- GetDisplayString=function (words)
            
        -- end
        --skip_pre_delim_check=true
    }
}
local prefab_names={}
for name,_ in pairs(Prefabs) do
    table.insert(prefab_names, name)
end
local prefabs={
    {
        width = 400,
        mode=Profile:GetConsoleAutocompleteMode()
    },
    {
        words =prefab_names,
        delim = "",--前缀
        num_chars = 0,--数量
        -- GetDisplayString=function (words)
            
        -- end
        --skip_pre_delim_check=true
    }
}
return {
    symbol=symbol,
    prefabs=prefabs,
}