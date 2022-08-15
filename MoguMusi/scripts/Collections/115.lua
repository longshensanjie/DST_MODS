local r_interval = 1/30

local anim_all = {"one", "two", "three", "four", "five", "six", "seven"}
local CustomLabels = {}
local point = 0
local function ClearAll()
    -- print("我滴任务完成辣")
    for _,label in pairs(CustomLabels)do
        label:SetText("")
    end
end

local function isanim(anim,entity)
    return entity and entity.AnimState and entity.AnimState:IsCurrentAnimation(anim)
end

AddPrefabPostInit("archive_orchestrina_small", function (inst)
    local label = inst.entity:AddLabel()
    label:SetFont(GLOBAL.CHATFONT_OUTLINE)
    label:SetFontSize(35)
    label:SetWorldOffset(0, 1, 0)
    label:SetColour(0,1,0,0)
    label:Enable(true)
    table.insert(CustomLabels, label)
    inst:DoPeriodicTask(r_interval, function()
        for order, anim in pairs(anim_all)do
            if isanim(anim.."_pre", inst) then
                -- 为什么Label没有 GetString 或 GetText 方法？
                if order == 1 and point ~= inst.GUID then
                    ClearAll()
                    point = inst.GUID
                end
                label:SetText(tostring(order))
            end
        end
        if isanim("eight_activation", inst) then
            ClearAll()
        end
    end)
end)
