local spicedfoods 	= {}
local foods 		= require("foods")

GenerateSpicedFoods(foods)
local list = require("spicedfoods")

for k, data in pairs(list) do
    for name, v in pairs(foods) do
        if data.basename == name then
            spicedfoods[k] = data
        end
    end
end

return spicedfoods
