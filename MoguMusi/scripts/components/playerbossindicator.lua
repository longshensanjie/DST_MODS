-- Based entirely on Klei's playertargetindicator.lua

local PlayerBossIndicator = Class(function(self, inst)
    self.inst = inst
    self.agree = true

    self.max_range = TUNING.MAX_INDICATOR_RANGE * 1.5
    self.offScreenBosses = {}
    self.onScreenBossesLastTick = {}
    -- self.recentTargetRemoved = {}
    inst:ListenForEvent("Mod_BossIndicator", function(_, style)
        self.agree = style
    end)

    inst:StartUpdatingComponent(self)
end)

function PlayerBossIndicator:OnRemoveFromEntity()
    if self.offScreenBosses ~= nil and self.inst.HUD then
        for i, v in ipairs(self.offScreenBosses) do
            self.inst.HUD:RemoveBossIndicator(v)
        end
        self.offScreenBosses = nil
    end
end

PlayerBossIndicator.OnRemoveEntity = PlayerBossIndicator.OnRemoveFromEntity

function PlayerBossIndicator:ShouldShowIndicator(target)
    return not self:ShouldRemoveIndicator(target) and (table.contains(self.onScreenBossesLastTick, target))
end

function PlayerBossIndicator:ShouldRemoveIndicator(target)
    return 	not target:IsValid() or
			target:HasTag("nobossindicator") or
            target:HasTag("hiding") or
            not target:IsNear(self.inst, self.max_range) or
            target.entity:FrustumCheck() --or
            -- not CanEntitySeeTarget(self.inst, target)
end

function PlayerBossIndicator:OnUpdate()
	if not self.inst or not self.inst.HUD then return end

    local checked = {}

    --Check which indicators' bosses have moved within view or too far
    for i, v in ipairs(self.offScreenBosses) do
        checked[v] = true

        while self:ShouldRemoveIndicator(v) do
            self.inst.HUD:RemoveBossIndicator(v)
            table.remove(self.offScreenBosses, i)
            v = self.offScreenBosses[i]
            if v == nil then
                break
            end
            checked[v] = true
        end
    end

    --Check which bosses have moved outside of view
    for i, v in ipairs(MOD_BOSSINDICATORS.BOSSES) do
        if not (checked[v] or v == self.inst) and self:ShouldShowIndicator(v) and self.agree then
            self.inst.HUD:AddBossIndicator(v)
            table.insert(self.offScreenBosses, v)
        end
    end

    --Make a list of the bosses who are on screen so we can know who left the screen next update
    self.onScreenBossesLastTick = {}
    for i, v in ipairs(MOD_BOSSINDICATORS.BOSSES) do
        if v ~= self.inst then --and v.entity:FrustumCheck() then -- we want a larger range
            table.insert(self.onScreenBossesLastTick, v)
        end
    end
end

return PlayerBossIndicator