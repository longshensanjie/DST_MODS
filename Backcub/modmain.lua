PrefabFiles = {
    "foods_jyys",
	"backcub",
    "backcub_plus"
}

Assets = {
    Asset("IMAGE", "images/paofuc.tex"), Asset("ATLAS", "images/paofuc.xml")
}

GLOBAL.setmetatable(env,{__index=function(t,k) return GLOBAL.rawget(GLOBAL,k) end})


local foods = require("foods")
for k,recipe in pairs (foods) do
	AddCookerRecipe("cookpot", recipe)
	AddCookerRecipe("portablecookpot", recipe)
	AddCookerRecipe("archive_cookpot", recipe)
end

local spicedfoods = require("foodspicer")
for k, recipe in pairs(spicedfoods) do
    AddCookerRecipe("portablespicer", recipe)
end

local USE_UPGRADEKIT = Action({ priority = 5, mount_valid = false })
USE_UPGRADEKIT.id = "USE_UPGRADEKIT"
USE_UPGRADEKIT.str = "背包升级"
USE_UPGRADEKIT.fn = function(act)
    if act.doer.components.inventory ~= nil then
        local kit = act.doer.components.inventory:RemoveItem(act.invobject)
        if kit ~= nil and kit.components.upgradekit ~= nil and act.target ~= nil then
            local result = kit.components.upgradekit:Upgrade(act.doer, act.target)
            if result then
                return true
            else
                act.doer.components.inventory:GiveItem(kit)
            end
        end
    end
end
AddAction(USE_UPGRADEKIT)

AddComponentAction("USEITEM", "upgradekit", function(inst, doer, target, actions, right)
    if not (doer.replica.rider ~= nil and doer.replica.rider:IsRiding()) --不能骑牛
        and not (target.replica.inventoryitem ~= nil and target.replica.inventoryitem:IsGrandOwner(doer)) --对象不会在物品栏里
        and inst:HasTag(target.prefab .. "_upkit")
        and right
    then
        table.insert(actions, ACTIONS.USE_UPGRADEKIT)
    end
end)

AddStategraphActionHandler("wilson", ActionHandler(ACTIONS.USE_UPGRADEKIT, "dolongaction"))
AddStategraphActionHandler("wilson_client", ActionHandler(ACTIONS.USE_UPGRADEKIT, "dolongaction"))


local _G = GLOBAL
local STRINGS = _G.STRINGS

local S_NAMES = STRINGS.NAMES                   --各种对象的名字
local S_RECIPE_DESC = STRINGS.RECIPE_DESC       --科技栏里的描述

S_NAMES.BACKCUB = "靠背熊"
S_RECIPE_DESC.BACKCUB = "一只会偷吃的小熊背包"

S_NAMES.BACKCUB_PLUS = "靠背熊pro"
S_RECIPE_DESC.BACKCUB_PLUS = "升级版的小熊背包"

S_NAMES.PAOFU = "泡芙"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.PAOFU = "特地加了很多奶油"

-- local config = {
--     theme = "TheForge",
--     bgBrightness = 0.6,
--     bgOpacity = 1,
--     maxHunger = 375
-- }


-- AddClassPostConstruct("widgets/statusdisplays", function (self,owner)
--         local BearBadge = require "widgets/BearBadge"
--         self.BearBadge = self:AddChild(BearBadge(config, {215 / 255, 165 / 255, 0 / 255, 1}, "status_hunger", nil, true))
--         self.BearBadge:SetPosition(self.stomach:GetPosition().x -84, self.stomach:GetPosition().y +15, 0)
--         -- self.BearBadge:SetPercent(100 / config.maxHunger, config.maxHunger)
--         self.BearBadge:Hide()
-- end)

-- AddReplicableComponent("starve")

