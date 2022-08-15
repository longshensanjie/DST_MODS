local gt = GetModConfigData("sw_GiantTree")
if not gt then return end
local allow = false
if type(gt) == "boolean" then allow = true end


if gt == "gt_Canopy" or allow then
    AddClassPostConstruct("widgets/leafcanopy", function(self)
        self:Hide()
        self.OnUpdate = function() --[[disabled]] end
    end)
end

if gt == "gt_Lightray" or allow then
    AddPrefabPostInit("lightrays_canopy", function(inst)
        inst:Hide()
        -- Set its build to a wrong thing to prevent it from showing up again when phase change
        -- You gonna blame Klei about those bad codes NGL
        inst.AnimState:SetBuild("oceantree_short")
        inst:CancelAllPendingTasks() -- Cancel update task
        if inst.components.distancefade then
            inst:RemoveComponent("distancefade")
        end
    end)
end

if gt == "gt_Deco" or allow then
    AddPrefabPostInit("oceanvine_deco", function(inst)
        inst:Hide()
	end)
end