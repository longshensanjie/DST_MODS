local UpvalueUtil = GLOBAL.require("lazy_controls/upvalueutil")
local getval = UpvalueUtil.GetUpvalue
local fc = GetModConfigData("tony_no_space")

local modify_table = {
    winch = (fc=="no_winch_using" or fc=="winch_only") and "inactive",
}
if fc then
    modify_table["flower"]      = (fc=="no_flower" or fc=="normal_only" or fc=="no_winch_using")  and "pickable"     -- 前面写的是不要摘的情况
    modify_table["flower_evil"] = (fc=="evil_only" or fc=="no_flower" or fc=="no_winch_using") and "pickable"
end

local function MakeGetPickupActionProxy(base_fn, path)
    local GetPickupAction, fn_i, scope_fn = getval(base_fn, path)
    if not GetPickupAction then return end

    GLOBAL.debug.setupvalue(scope_fn, fn_i, function(self, target, ...)
        local cant_tag = modify_table[target and target.prefab]
        if cant_tag then
            local has_tag = target.HasTag
            target.HasTag = function(self, tag, ...)
                if tag == cant_tag then
                    return false
                else
                    return has_tag(self, tag, ...)
                end
            end
            local ret = { GetPickupAction(self, target, ...) }
            target.HasTag = has_tag
            return GLOBAL.unpack(ret)
        else
            return GetPickupAction(self, target, ...)
        end
    end)
end

MakeGetPickupActionProxy(GLOBAL.require("components/playercontroller").GetActionButtonAction, "GetPickupAction")
MakeGetPickupActionProxy(GLOBAL.require("components/rider_replica").SetActionFilter, "ActionButtonOverride.GetPickupAction")


-- 空格不响应足够了，左键不响应的话会破坏游戏体验
-- if GetModConfigData("no_leftclick_evilflower") then
--     local COMPONENT_ACTIONS = getval(GLOBAL.EntityScript.CollectActions, "COMPONENT_ACTIONS")
--     local pickable_fn = COMPONENT_ACTIONS and COMPONENT_ACTIONS.SCENE and COMPONENT_ACTIONS.SCENE.pickable
--     if pickable_fn then
--         COMPONENT_ACTIONS.SCENE.pickable = function(inst, ...)
--             if inst.prefab == "flower_evil" and modify_table["flower_evil"] then
--                 return
--             end
--             return pickable_fn(inst, ...)
--         end
--     end
-- end
