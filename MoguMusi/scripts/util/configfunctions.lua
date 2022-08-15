local TIP = require("util/tip")

local ConfigFunctions = {}

function ConfigFunctions:DoToggle(str, bool)
    bool = not bool
    TIP(str,"pink",bool,"head")
    return bool
end

return ConfigFunctions
