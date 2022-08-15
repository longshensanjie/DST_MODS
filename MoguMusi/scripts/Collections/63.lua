-- 快速缩放
local zoom_step = GetModConfigData("tony_zoom")


AddComponentPostInit("playercontroller", function(self, inst)
    local Old_DoCameraControl = self.DoCameraControl
    self.DoCameraControl = function(self, ...)
        Old_DoCameraControl(self, ...)
        if not GLOBAL.TheCamera:CanControl()
            or (self.inst.HUD ~= nil and
                self.inst.HUD:IsCraftingOpen()) then
            return
        end
        
        if IsScrollModifierDown() then
            if GLOBAL.TheInput:IsControlPressed(GLOBAL.CONTROL_ZOOM_IN) then
                GLOBAL.TheCamera:ZoomIn(zoom_step)
            elseif TheInput:IsControlPressed(GLOBAL.CONTROL_ZOOM_OUT) then
                GLOBAL.TheCamera:ZoomOut(zoom_step)
            end
        end
    end
end)
