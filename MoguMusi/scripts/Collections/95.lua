-- 大力士举哑铃【没啥用的功能】
local keybind = GetModConfigData("sw_lx_dumbbell")
if not keybind then
    return
end

local bellT = {"dumbbell_gem", "dumbbell_marble", "dumbbell_golden", "dumbbell"}

GLOBAL.TheInput:AddKeyUpHandler(keybind, function()
    if not InGame() then
        return
    end
    if not ThePlayer or ThePlayer.prefab ~= "wolfgang" then
        return
    end
    local eq = GetEquippedItemFrom("hands")
    if eq and eq:HasTag("dumbbell") and ThePlayer.replica and ThePlayer.replica.inventory then
        if ThePlayer.player_classified and ThePlayer.player_classified.currentmightiness and ThePlayer.player_classified.currentmightiness:value() < TUNING.MIGHTINESS_MAX then
            ThePlayer.replica.inventory:UseItemFromInvTile(eq)
        end
    else
        for _, v in pairs(bellT) do
            local eqs = GetItemsFromAll(v)
            for _,eq in pairs(eqs)do
                if eq and eq:HasTag("dumbbell") and ThePlayer.replica and ThePlayer.replica.inventory then
                    ThePlayer.replica.inventory:UseItemFromInvTile(eq)
                    return
                end
            end
        end
    end
end)
