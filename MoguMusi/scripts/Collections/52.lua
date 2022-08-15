local Widget = require("widgets/widget")

local function fn(self)

    if not self.owner then return end

    self.sanddustover_disabler_root = self.dust:GetParent():AddChild(Widget("sanddustover_disabler_root")) -- KLEI YYDSB
    self.sanddustover_disabler_root:AddChild(self.dust)
    self.bg:Hide()
    self.sanddustover_disabler_root:Hide()

end

AddClassPostConstruct("widgets/sandover", fn)
AddClassPostConstruct("widgets/moonstormover", fn)
AddClassPostConstruct("widgets/gogglesover", function(self)
    function self:ToggleGoggles(show)
        -- 啥也别动
    end
end)

AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(1.33, function()
        if inst and inst == GLOBAL.ThePlayer and inst.prefab == "woodie" then
            inst:ListenForEvent("weremodedirty", function(inst)
                if inst.HUD and inst.HUD.beaverOL then inst.HUD.beaverOL:Hide() end
            end)
        end
    end)
end)