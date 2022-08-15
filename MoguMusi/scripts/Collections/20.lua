if GLOBAL.TheNet and
    (GLOBAL.TheNet:GetIsServer() and GLOBAL.TheNet:GetServerIsDedicated() or
        GLOBAL.TheNet:GetIsClient() and not GLOBAL.TheNet:GetIsServerAdmin()) then return end

local PDS = GLOBAL.require "screens/redux/popupdialog"
local quotation =
    "这个世界你已经游玩超过30天了, 你确定要继续世界重设吗?\n如果你不小心挂机而导致这个事件发生, 请点击『我知道了』并准备回档。"


AddClassPostConstruct("widgets/worldresettimer", function(self)
    local old_UpdateCountdown = self.UpdateCountdown  
    self.UpdateCountdown = function(self, time)
        if time == 30 and GLOBAL.TheWorld.state.cycles >= 29 then
            GLOBAL.TheNet:SetServerPaused(true)
            TheFrontEnd:PushScreen(PDS("蘑菇慕斯 󰀜 谏言", quotation , {{
                text = "继续重设！",
                cb = function()
                    GLOBAL.TheNet:SetServerPaused(false)
                    TheFrontEnd:PopScreen()
                end
            }, {
                text = "我知道了",
                cb = function()
                    TheFrontEnd:PopScreen()
                end
            }}))
        end
        old_UpdateCountdown(self, time)
    end
end)
