AddPlayerPostInit(function(inst)
    inst:DoTaskInTime(0.88, function()
        if inst.replica.inventory then
            local hl = inst.replica.inventory:GetEquippedItem("head")
            if hl and hl.prefab == "alterguardianhat" then
                if hl.replica._ and hl.replica._.container and (not hl.replica._.container._isopen) then return end
                inst.replica.inventory:UseItemFromInvTile(hl)       -- 真正的关闭一晃而过
            end
        end
    end)
end)
