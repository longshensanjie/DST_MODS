local function Init()
    local PlayerController = GLOBAL.ThePlayer and GLOBAL.ThePlayer.components.playercontroller

    if not PlayerController then
        return
    end

    local OldGetAttackTarget = PlayerController.GetAttackTarget
    function PlayerController:GetAttackTarget(...)
        local force_target = OldGetAttackTarget(self, ...)

        if GLOBAL.EQUIPSLOTS and GLOBAL.EQUIPSLOTS.MEDAL then
            local medal = GetEquippedItemFrom(GLOBAL.EQUIPSLOTS.MEDAL)
            if medal and medal.prefab == "valkyrie_test_certificate" then
                if force_target and force_target:HasTag("smallcreature") then
                    GLOBAL.ThePlayer.replica.inventory:ControllerUseItemOnSelfFromInvTile(medal)
                    TIP("自动脱落","blue","勋章防爆","head")
                end
            end
        end

        return force_target
    end
end


local function OnWorldPostInit(inst)
    inst:ListenForEvent("playeractivated", Init, GLOBAL.TheWorld)
end
AddPrefabPostInit("world", OnWorldPostInit)